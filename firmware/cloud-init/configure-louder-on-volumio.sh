#!/bin/bash
# Installs the TAS58xx driver (Louder Raspberry) on Volumio for Raspberry Pi and
# adds the Louder boards to Volumio's DAC list.
#
# Usage, over SSH on the Volumio device (enable SSH at http://volumio.local/dev):
#   curl -sL https://raw.githubusercontent.com/sonocotta/raspberry-media-center/refs/heads/main/firmware/cloud-init/configure-louder-on-volumio.sh | sudo bash
#
# Then pick your board in Settings > Playback Options > DAC Model, save, and reboot.
#
# Run it again after every Volumio update. Updates change the kernel, and the
# driver has to be rebuilt for the new one.
#
# The build takes a few minutes on a Pi 4 or Pi 5 and much longer on a Pi Zero,
# downloads about 250 MB and needs about 2.5 GB of free space while it runs.
#
# Optional settings (put them after sudo, e.g. "... | sudo LOUDER_I2C_ADDRESS=0x2e bash"):
#   LOUDER_I2C_ADDRESS  I2C address for the "Louder Raspberry" (1X) entry. Default 0x2d.
#                       Some early 1X boards answer on 0x2e instead.
#   TAS58XX_REF         Driver branch, tag or commit to build. Default main.
#   LOUDER_WORK_DIR     Where to download and build. Default /home/volumio/louder-build.
#   KEEP_BUILD=1        Keep the downloaded kernel source after a successful build.
#
# Why this doesn't use `volumio kernelsource`: on a Pi 4 that helper prepares the
# kernel with the v7 Module.symvers instead of v7l. Many of the kernel symbols this
# driver uses have different checksums between the two, so the kernel refuses to
# load the module. The helper also can't build for the 64-bit kernel a Pi 5 runs.
# This script fetches the kernel source and symbol versions that match the
# running kernel exactly.

set -euo pipefail

TAS58XX_REPO="https://github.com/sonocotta/tas5805m-driver-for-raspbian"
TAS58XX_REF="${TAS58XX_REF:-main}"
LOUDER_I2C_ADDRESS="${LOUDER_I2C_ADDRESS:-0x2d}"
WORK_DIR="${LOUDER_WORK_DIR:-/home/volumio/louder-build}"
KEEP_BUILD="${KEEP_BUILD:-0}"

RPI_FIRMWARE_RAW="https://raw.githubusercontent.com/raspberrypi/rpi-firmware"
RPI_LINUX_ARCHIVE="https://github.com/raspberrypi/linux/archive"
BOOT_DIR="/boot"
MODULES_ROOT="/lib/modules"
OS_RELEASE="/etc/os-release"
PROC_CONFIG="/proc/config.gz"
ETC_MODULES="/etc/modules"
DACS_JSON="/volumio/app/plugins/system_controller/i2s_dacs/dacs.json"
MIN_FREE_MB=2500

log() { echo "[louder] $*"; }
die() { echo "[louder] ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------
check_system() {
    [ "$(id -u)" -eq 0 ] || die "Run this as root: curl -sL <script url> | sudo bash"
    grep -q 'VOLUMIO_HARDWARE="pi"' "$OS_RELEASE" 2>/dev/null ||
        die "This script is for Volumio on a Raspberry Pi. On Raspberry Pi OS use configure-louder.sh."
    [[ "$LOUDER_I2C_ADDRESS" =~ ^0x[0-9a-fA-F]{2}$ ]] ||
        die "LOUDER_I2C_ADDRESS must look like 0x2d (got '$LOUDER_I2C_ADDRESS')"
}

# ---------------------------------------------------------------------------
# Work out which kernel is running and how to build for it.
# Volumio installs Raspberry Pi kernels with rpi-update, so the kernel release
# ends in "+" and the suffix names the variant:
#   6.12.75+      Pi Zero / Pi 1           Module.symvers
#   6.12.75-v7+   Pi 2 / Pi 3 / Zero 2     Module7.symvers
#   6.12.75-v7l+  Pi 4 / Pi 400 / CM4      Module7l.symvers
#   6.12.75-v8+   64-bit kernel (Pi 5)     Module8.symvers
# ---------------------------------------------------------------------------
detect_kernel() {
    KREL="$(uname -r)"
    case "$KREL" in
        *-v8+)  KARCH=arm64; SYMVERS=Module8.symvers;  UNAME_STRING=uname_string8 ;;
        *-v7l+) KARCH=arm;   SYMVERS=Module7l.symvers; UNAME_STRING=uname_string7l ;;
        *-v7+)  KARCH=arm;   SYMVERS=Module7.symvers;  UNAME_STRING=uname_string7 ;;
        *-*)    die "Unsupported kernel $KREL. Expected a Volumio Raspberry Pi kernel such as 6.12.75-v7l+." ;;
        *+)     KARCH=arm;   SYMVERS=Module.symvers;   UNAME_STRING=uname_string ;;
        *)      die "Unsupported kernel $KREL. Expected a Volumio Raspberry Pi kernel such as 6.12.75-v7l+." ;;
    esac

    # Volumio's userland is 32-bit (armhf). A Pi 5 still boots a 64-bit kernel,
    # so modules for it have to be cross-compiled.
    local user_arch
    case "$(dpkg --print-architecture)" in
        armhf | armel) user_arch=arm ;;
        arm64)         user_arch=arm64 ;;
        *)             user_arch=other ;;
    esac

    CROSS_COMPILE=""
    CROSS_PKGS=()
    if [ "$user_arch" != "$KARCH" ]; then
        if [ "$KARCH" = arm64 ]; then
            CROSS_COMPILE=aarch64-linux-gnu-
            CROSS_PKGS=(gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu)
        else
            CROSS_COMPILE=arm-linux-gnueabihf-
            CROSS_PKGS=(gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf)
        fi
    fi

    MAKE_ARGS=(ARCH="$KARCH")
    if [ -n "$CROSS_COMPILE" ]; then
        MAKE_ARGS+=(CROSS_COMPILE="$CROSS_COMPILE")
    fi
    log "Running kernel: $KREL ($KARCH)${CROSS_COMPILE:+, cross-compiling with ${CROSS_COMPILE}gcc}"
}

# ---------------------------------------------------------------------------
# Find the kernel source commit for the running kernel.
# rpi-update records the rpi-firmware commit it installed in /boot/.firmware_revision.
# That commit's git_hash file names the matching raspberrypi/linux commit.
# ---------------------------------------------------------------------------
find_kernel_source() {
    FW_REV=""
    local rev_file
    for rev_file in "$BOOT_DIR/.firmware_revision_kernel" "$BOOT_DIR/.firmware_revision"; do
        if [ -s "$rev_file" ]; then
            FW_REV="$(tr -d '[:space:]' <"$rev_file")"
            break
        fi
    done
    [[ "$FW_REV" =~ ^[0-9a-f]{40}$ ]] ||
        die "Can't read the firmware revision from $BOOT_DIR/.firmware_revision, so the matching kernel source is unknown."

    local fw_url="$RPI_FIRMWARE_RAW/$FW_REV"
    local built running_build
    built="$(curl -fsSL "$fw_url/$UNAME_STRING")" ||
        die "Can't download $fw_url/$UNAME_STRING"
    # built looks like: "Linux version 6.12.75-v7l+ (dom@buildbot) (...) #1949 SMP Fri Mar  6 ..."
    running_build="$(uname -v | awk '{print $1}')"
    if [[ "$built" != *" $KREL "* || "$built" != *" $running_build "* ]]; then
        die "Firmware revision $FW_REV is for '${built%% (*}', but the running kernel is $KREL $running_build. Reboot after the last Volumio update and try again."
    fi

    GIT_HASH="$(curl -fsSL "$fw_url/git_hash" | tr -d '[:space:]')" ||
        die "Can't download $fw_url/git_hash"
    [[ "$GIT_HASH" =~ ^[0-9a-f]{40}$ ]] ||
        die "Unexpected kernel source hash '$GIT_HASH' from $fw_url/git_hash"
    log "Kernel source: raspberrypi/linux@$GIT_HASH (firmware $FW_REV)"
}

# ---------------------------------------------------------------------------
# Packages and disk space
# ---------------------------------------------------------------------------
install_packages() {
    log "Installing build tools..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update </dev/null
    apt-get install -y --no-install-recommends \
        build-essential bc bison flex libssl-dev curl ca-certificates xz-utils \
        device-tree-compiler i2c-tools kmod "${CROSS_PKGS[@]}" </dev/null
}

check_disk_space() {
    mkdir -p "$WORK_DIR"
    local free_mb
    free_mb="$(df -Pm "$WORK_DIR" | awk 'NR == 2 {print $4}')"
    [ "$free_mb" -ge "$MIN_FREE_MB" ] ||
        die "Need ${MIN_FREE_MB} MB free in $WORK_DIR but only ${free_mb} MB is available. Set LOUDER_WORK_DIR to a location with more space."
}

# ---------------------------------------------------------------------------
# Download and prepare the kernel source for building external modules
# ---------------------------------------------------------------------------
prepare_kernel() {
    KSRC="$WORK_DIR/linux-$KREL"
    rm -rf "$KSRC"
    mkdir -p "$KSRC"

    log "Downloading kernel source (about 250 MB)..."
    curl -fL --retry 3 -o "$WORK_DIR/linux.tar.gz" "$RPI_LINUX_ARCHIVE/$GIT_HASH.tar.gz" ||
        die "Can't download $RPI_LINUX_ARCHIVE/$GIT_HASH.tar.gz"
    log "Extracting kernel source..."
    tar -xzf "$WORK_DIR/linux.tar.gz" -C "$KSRC" --strip-components=1
    rm -f "$WORK_DIR/linux.tar.gz"

    # Configuration of the running kernel (CONFIG_IKCONFIG is built as a module)
    modprobe configs 2>/dev/null || true
    [ -r "$PROC_CONFIG" ] ||
        die "Can't read $PROC_CONFIG to get the running kernel's configuration"
    zcat "$PROC_CONFIG" >"$KSRC/.config"

    # Symbol versions of the running kernel, so the module passes modversion checks
    curl -fsSL -o "$KSRC/Module.symvers" "$RPI_FIRMWARE_RAW/$FW_REV/$SYMVERS" ||
        die "Can't download $RPI_FIRMWARE_RAW/$FW_REV/$SYMVERS"

    log "Preparing kernel source..."
    make -s -C "$KSRC" "${MAKE_ARGS[@]}" olddefconfig </dev/null
    # LOCALVERSION=+ reproduces the "+" suffix that Raspberry Pi kernel builds carry.
    make -s -C "$KSRC" "${MAKE_ARGS[@]}" LOCALVERSION=+ -j"$(nproc)" modules_prepare </dev/null

    local src_release
    src_release="$(make -s -C "$KSRC" "${MAKE_ARGS[@]}" LOCALVERSION=+ kernelrelease </dev/null)"
    [ "$src_release" = "$KREL" ] ||
        die "Prepared kernel source is $src_release, but the running kernel is $KREL"
}

# ---------------------------------------------------------------------------
# Build and install the driver and its device tree overlays
# ---------------------------------------------------------------------------
build_driver() {
    DRV="$WORK_DIR/tas5805m-driver-for-raspbian"
    rm -rf "$DRV"
    mkdir -p "$DRV"

    log "Downloading driver ($TAS58XX_REF)..."
    curl -fsSL "$TAS58XX_REPO/archive/$TAS58XX_REF.tar.gz" | tar -xz -C "$DRV" --strip-components=1 ||
        die "Can't download $TAS58XX_REPO/archive/$TAS58XX_REF.tar.gz"

    log "Building driver..."
    make -C "$KSRC" "${MAKE_ARGS[@]}" M="$DRV" modules </dev/null

    local vermagic
    vermagic="$(modinfo -F vermagic "$DRV/tas58xx.ko")"
    [[ "$vermagic" == "$KREL "* ]] ||
        die "Built module is for '$vermagic', but the running kernel is $KREL"

    install -D -m 0644 "$DRV/tas58xx.ko" "$MODULES_ROOT/$KREL/kernel/sound/soc/codecs/snd-soc-tas58xx.ko"
    depmod -a "$KREL"
    log "Installed $MODULES_ROOT/$KREL/kernel/sound/soc/codecs/snd-soc-tas58xx.ko"
}

install_overlays() {
    local overlays_dir="$BOOT_DIR/overlays"
    [ -d "$overlays_dir" ] || die "Can't find $overlays_dir"

    dtc -q -I dts -O dtb -o "$overlays_dir/tas58xx.dtbo" "$DRV/tas58xx-overlay.dts"
    dtc -q -I dts -O dtb -W no-unit_address_vs_reg -W no-graph_child_address \
        -o "$overlays_dir/tas58xx-dual.dtbo" "$DRV/tas58xx-dual-overlay.dts"
    log "Installed tas58xx.dtbo and tas58xx-dual.dtbo in $overlays_dir"
}

# ---------------------------------------------------------------------------
# Earlier instructions used a DAC entry with "modules":"tas58xx". For Pi DACs
# Volumio expects that field to be empty: with a value it skips writing the
# overlay to config.txt and instead rewrites /etc/modules with one letter per
# line, dropping i2c-dev. Undo that if it happened.
# ---------------------------------------------------------------------------
repair_etc_modules() {
    [ -f "$ETC_MODULES" ] || return 0
    if grep -qxE '[[:alnum:]]' "$ETC_MODULES"; then
        log "Repairing $ETC_MODULES (removing single-letter lines left by the old DAC entry)"
        sed -i -E '/^[[:alnum:]]$/d' "$ETC_MODULES"
    fi
    grep -qx 'i2c-dev' "$ETC_MODULES" || echo 'i2c-dev' >>"$ETC_MODULES"
}

# ---------------------------------------------------------------------------
# Add the Louder boards to Volumio's DAC list (Settings > Playback Options).
# Volumio writes the overlay line to /boot/config.txt when a board is selected.
# alsacard is the ALSA card ID: the overlay label without dashes, cut to 15
# characters, so both overlays produce "LouderRaspberry".
# The 2X board has two amplifiers with separate volume controls, so it uses
# Volumio's software volume.
# ---------------------------------------------------------------------------
register_dacs() {
    [ -f "$DACS_JSON" ] || die "Can't find Volumio's DAC list at $DACS_JSON"
    [ -f "$DACS_JSON.orig" ] || cp -p "$DACS_JSON" "$DACS_JSON.orig"

    local overlay_1x="tas58xx"
    if [ "${LOUDER_I2C_ADDRESS,,}" != "0x2d" ]; then
        overlay_1x="tas58xx,i2creg=${LOUDER_I2C_ADDRESS,,}"
    fi

    node - "$DACS_JSON" "$overlay_1x" <<'EOF'
const fs = require('fs');
const [file, overlay1x] = process.argv.slice(2);

const entry = (id, name, overlay, mixer) => ({
  id, name, overlay,
  alsanum: '2', alsacard: 'LouderRaspberry', mixer,
  modules: '', script: '', needsreboot: 'yes',
});
const entries = [
  entry('louder-raspberry', 'Louder Raspberry', overlay1x, 'Digital'),
  entry('louder-raspberry-plus', 'Louder Raspberry Plus', 'tas58xx,i2creg=0x4c', 'Digital'),
  entry('louder-raspberry-2x', 'Louder Raspberry 2X', 'tas58xx-dual', ''),
];

const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const ids = new Set(entries.map((e) => e.id));
for (const group of data.devices) {
  group.data = group.data.filter((dac) => !ids.has(dac.id));
}
const pi = data.devices.find((group) => group.name === 'Raspberry PI');
if (!pi) {
  console.error('[louder] ERROR: no "Raspberry PI" section in ' + file);
  process.exit(1);
}
pi.data.unshift(...entries);
fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
EOF
    log "Added Louder Raspberry, Louder Raspberry Plus and Louder Raspberry 2X to $DACS_JSON"
}

# ---------------------------------------------------------------------------
# Remove downloads after a successful run; keep them after a failure.
# ---------------------------------------------------------------------------
cleanup() {
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "[louder] Build files kept in $WORK_DIR for troubleshooting" >&2
    elif [ "$KEEP_BUILD" != 1 ]; then
        rm -rf "$WORK_DIR/linux-${KREL:-}" "$WORK_DIR/linux.tar.gz" "$WORK_DIR/tas5805m-driver-for-raspbian"
        rmdir "$WORK_DIR" 2>/dev/null || true
    fi
}

main() {
    check_system
    detect_kernel
    find_kernel_source
    install_packages
    check_disk_space
    trap cleanup EXIT
    prepare_kernel
    build_driver
    install_overlays
    repair_etc_modules
    register_dacs

    log "Restarting Volumio..."
    systemctl restart volumio.service

    log "Done. Next steps:"
    log "  1. In Volumio, open Settings > Playback Options and turn on I2S DAC."
    log "  2. Under DAC Model, pick Louder Raspberry, Louder Raspberry Plus or Louder Raspberry 2X."
    log "  3. Save and reboot when asked."
    log "Run this script again after each Volumio update."
}

# Everything runs from main so the whole script is read before anything executes
# (safe with curl | bash).
main "$@"
