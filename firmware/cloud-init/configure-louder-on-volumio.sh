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
CONFIG_PATH="/boot/config.txt"
DACS_JSON="/volumio/app/plugins/system_controller/i2s_dacs/dacs.json"

# ---------------------------------------------------------------------------
# Install required packages
# ---------------------------------------------------------------------------
apt update -y
apt install -y git raspberrypi-kernel-headers build-essential i2c-tools device-tree-compiler

# ---------------------------------------------------------------------------
# Install Volumio kernel build prerequisites (this step takes several minutes)
# ---------------------------------------------------------------------------
echo "[louder] Running 'volumio kernelsource' — this may take a while..."
# volumio kernelsource

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
# Fix kernel source directory permissions (required on Volumio before building)
# ---------------------------------------------------------------------------
echo "[louder] Fixing kernel source directory permissions..."
find /usr/src/rpi-linux -type d -exec chmod 755 {} \;

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
# Patch /boot/config.txt
# ---------------------------------------------------------------------------
# Volumio writes just "dtoverlay=tas58xx" (without parameters) when it applies
# a DAC setting, leaving "i2creg=0x2d" as an orphaned second line.
# Clean up any such split before applying the correct single-line overlay.
sed -i -E '/^dtoverlay=tas58xx[[:space:]]*$/d; /^,i2creg=/d' "$CONFIG_PATH"

lineinfile "$CONFIG_PATH" "^dtoverlay=tas58xx" "dtoverlay=tas58xx,i2creg=${TAS5805M_I2C_ADDRESS}"

# Disable HDMI audio output (comment out if present; no-op if already absent)
sed -i -E "s|^(dtparam=audio=on)|#\1|"    "$CONFIG_PATH"
sed -i -E "s|^(dtoverlay=vc4-kms-v3d)|#\1|" "$CONFIG_PATH"

echo "[louder] Configuration written to $CONFIG_PATH"

# ---------------------------------------------------------------------------
# Register Louder Raspberry as a selectable DAC in Volumio's DAC list
# ---------------------------------------------------------------------------
if [ -f "$DACS_JSON" ] && ! grep -q '"id":"louder-raspberry"' "$DACS_JSON"; then
    echo "[louder] Adding Louder Raspberry entry to $DACS_JSON..."
    python3 - <<'PYEOF'
import json

dacs_file = "/volumio/app/plugins/system_controller/i2s_dacs/dacs.json"
new_entry = {
    "id": "louder-raspberry",
    "name": "Louder Raspberry",
    "overlay": "tas58xx,i2creg=0x2d",
    "alsanum": "2",
    "alsacard": "LouderRaspberry",
    "mixer": "Master",
    "modules": "tas58xx",
    "script": "",
    "needsreboot": "yes"
}

with open(dacs_file, "r") as f:
    data = json.load(f)

daclist = data["devices"]
if not any(d.get("id") == "louder-raspberry" for d in daclist):
    daclist.insert(0, new_entry)

with open(dacs_file, "w") as f:
    json.dump(data, f, indent=2)

print("[louder] DAC entry added successfully")
PYEOF
else
    echo "[louder] DAC entry already present or $DACS_JSON not found, skipping"
fi

# ---------------------------------------------------------------------------
# Restart Volumio service to pick up the new DAC entry
# ---------------------------------------------------------------------------
echo "[louder] Restarting Volumio service..."
systemctl restart volumio.service

# ---------------------------------------------------------------------------
# Reboot to apply hardware configuration changes
# ---------------------------------------------------------------------------
echo "[louder] Please reboot to apply changes..."
#reboot