#!/bin/bash
# Configures Louder Raspberry Pi hardware (TAS5805M amplifier driver) — DietPi edition
# Mirrors playbooks/0-hardware/1-louder-raspberry-pi.yml
#
# Usage (cloud-init):
#   runcmd:
#     - curl -sL https://raw.githubusercontent.com/sonocotta/raspberry-media-center/refs/heads/main/firmware/cloud-init/configure-louder-diet-pi.sh | bash

set -euo pipefail

TAS5805M_REPO="https://github.com/sonocotta/tas5805m-driver-for-raspbian"
TAS5805M_DEST="/src/tas5805m-driver-for-raspbian"
TAS5805M_I2C_ADDRESS="0x2d"

# ---------------------------------------------------------------------------
# Detect the boot config path.
# Raspbian/Bookworm (and newer DietPi) mount the firmware partition at
# /boot/firmware; older DietPi images expose config.txt directly at /boot.
# ---------------------------------------------------------------------------
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_PATH="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_PATH="/boot/config.txt"
else
    echo "[louder] ERROR: Cannot locate config.txt (tried /boot/firmware/config.txt and /boot/config.txt)" >&2
    exit 1
fi
echo "[louder] Using boot config: $CONFIG_PATH"

# ---------------------------------------------------------------------------
# Detect the overlays directory (mirrors the config.txt detection above).
# Raspbian/Bookworm and newer DietPi: /boot/firmware/overlays/
# Older DietPi (boot mounted directly at /boot): /boot/overlays/
# ---------------------------------------------------------------------------
if [ -d "/boot/firmware/overlays" ]; then
    OVERLAYS_PATH="/boot/firmware/overlays"
elif [ -d "/boot/overlays" ]; then
    OVERLAYS_PATH="/boot/overlays"
else
    echo "[louder] ERROR: Cannot locate overlays directory" >&2
    exit 1
fi
echo "[louder] Using overlays directory: $OVERLAYS_PATH"

# ---------------------------------------------------------------------------
# Pin kernel headers to the currently running kernel version.
# Using the meta-package (linux-headers-rpi-v8) would install headers for the
# LATEST available kernel, which may differ from the running one.  The make
# step uses $(uname -r) to locate the build tree, so those newer headers are
# never found and the build fails.  Installing linux-headers-$(uname -r)
# guarantees the correct match without triggering an unwanted kernel upgrade.
# ---------------------------------------------------------------------------
KERNEL_HEADERS_PKG="linux-headers-$(uname -r)"
echo "[louder] Running kernel: $(uname -r) → headers package: $KERNEL_HEADERS_PKG"

# ---------------------------------------------------------------------------
# Install required packages
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y git "$KERNEL_HEADERS_PKG" build-essential i2c-tools

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
# Install dtc (device tree compiler) if not already present
# ---------------------------------------------------------------------------
apt-get install -y device-tree-compiler

# ---------------------------------------------------------------------------
# Build and install the kernel module, then compile the DT overlay
# compile-overlay.sh is hardcoded to /boot/overlays/ which does not exist on
# DietPi (the firmware partition is mounted at /boot/firmware/).  Run dtc
# directly with the detected OVERLAYS_PATH instead.
# ---------------------------------------------------------------------------
cd "$TAS5805M_DEST"
make all
make install
echo "[louder] Compiling DT overlays → $OVERLAYS_PATH"
dtc -I dts -O dtb -o "${OVERLAYS_PATH}/tas58xx.dtbo" tas58xx-overlay.dts
dtc -I dts -O dtb -W no-unit_address_vs_reg -W no-graph_child_address \
    -o "${OVERLAYS_PATH}/tas58xx-dual.dtbo" tas58xx-dual-overlay.dts

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
# Enable I2C interface
# DietPi ships dietpi-set_hardware which manages hardware interfaces without
# requiring raspi-config (which is not present on DietPi by default).
# ---------------------------------------------------------------------------
if command -v dietpi-set_hardware &>/dev/null; then
    dietpi-set_hardware i2c enable
else
    # Fallback: manually enable I2C in config.txt and ensure the kernel module loads
    echo "[louder] dietpi-set_hardware not found, enabling I2C manually"
    lineinfile "$CONFIG_PATH" "^#?dtparam=i2c_arm" "dtparam=i2c_arm=on"
    grep -qxF 'i2c-dev' /etc/modules || echo 'i2c-dev' >> /etc/modules
fi

# ---------------------------------------------------------------------------
# Patch boot config
# ---------------------------------------------------------------------------
lineinfile "$CONFIG_PATH" "^dtoverlay=tas58xx" "dtoverlay=tas58xx,i2creg=${TAS5805M_I2C_ADDRESS}"

# Disable HDMI audio output (comment out if present; no-op if already absent)
sed -i -E "s|^(dtparam=audio=on)|#\1|"    "$CONFIG_PATH"
sed -i -E "s|^(dtoverlay=vc4-kms-v3d)|#\1|" "$CONFIG_PATH"

echo "[louder] Configuration written to $CONFIG_PATH"

# ---------------------------------------------------------------------------
# Reboot to apply hardware configuration changes
# ---------------------------------------------------------------------------
echo "[louder] Please reboot to apply changes..."
#reboot