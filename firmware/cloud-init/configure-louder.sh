#!/bin/bash
# Configures Louder Raspberry Pi hardware (TAS5805M amplifier driver)
# Mirrors playbooks/0-hardware/1-louder-raspberry-pi.yml
#
# Usage (cloud-init):
#   runcmd:
#     - curl -sL https://raw.githubusercontent.com/sonocotta/raspberry-media-center/refs/heads/main/firmware/cloud-init/configure-louder.sh | bash

set -euo pipefail

TAS5805M_REPO="https://github.com/sonocotta/tas5805m-driver-for-raspbian"
TAS5805M_DEST="/src/tas5805m-driver-for-raspbian"
TAS5805M_I2C_ADDRESS="0x2d"
CONFIG_PATH="/boot/firmware/config.txt"

# ---------------------------------------------------------------------------
# Detect architecture and select appropriate kernel headers package
# ---------------------------------------------------------------------------
KERNEL_ARCH=$(uname -m)
case "$KERNEL_ARCH" in
    aarch64|arm64)
        KERNEL_HEADERS_PKG="linux-headers-rpi-v8"
        ;;
    armv7l)
        KERNEL_HEADERS_PKG="linux-headers-rpi-v7"
        ;;
    *)
        KERNEL_HEADERS_PKG="linux-headers-rpi-v6"
        ;;
esac
echo "[louder] Architecture: $KERNEL_ARCH → headers package: $KERNEL_HEADERS_PKG"

# ---------------------------------------------------------------------------
# Install required packages
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y git "$KERNEL_HEADERS_PKG" build-essential

# ---------------------------------------------------------------------------
# Clone or update the TAS5805M kernel driver repository
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$TAS5805M_DEST")"
if [ -d "$TAS5805M_DEST/.git" ]; then
    echo "[louder] Updating existing repository at $TAS5805M_DEST"
    git -C "$TAS5805M_DEST" pull
else
    echo "[louder] Cloning $TAS5805M_REPO → $TAS5805M_DEST"
    git clone "$TAS5805M_REPO" "$TAS5805M_DEST"
fi

# ---------------------------------------------------------------------------
# Build and install the kernel module, then compile the DT overlay
# ---------------------------------------------------------------------------
cd "$TAS5805M_DEST"
make all
make install
./compile-overlay.sh

# ---------------------------------------------------------------------------
# Helper: idempotent lineinfile (mirrors Ansible lineinfile module)
#   If a line matching REGEXP exists it is replaced; otherwise appended.
# ---------------------------------------------------------------------------
lineinfile() {
    local file="$1"
    local regexp="$2"
    local line="$3"
    if grep -qE "$regexp" "$file"; then
        sed -i -E "s|$regexp.*|$line|" "$file"
    else
        echo "$line" >> "$file"
    fi
}

# ---------------------------------------------------------------------------
# Patch /boot/firmware/config.txt
# ---------------------------------------------------------------------------
lineinfile "$CONFIG_PATH" "^dtoverlay=w5500"   "dtoverlay=w5500"
lineinfile "$CONFIG_PATH" "^dtoverlay=tas5805m" "dtoverlay=tas5805m,i2creg=${TAS5805M_I2C_ADDRESS}"

# Disable HDMI audio output (comment out if present; no-op if already absent)
sed -i -E "s|^(dtparam=audio=on)|#\1|"    "$CONFIG_PATH"
sed -i -E "s|^(dtoverlay=vc4-kms-v3d)|#\1|" "$CONFIG_PATH"

echo "[louder] Configuration written to $CONFIG_PATH"

# ---------------------------------------------------------------------------
# Reboot to apply hardware configuration changes
# ---------------------------------------------------------------------------
echo "[louder] Rebooting to apply changes..."
reboot
