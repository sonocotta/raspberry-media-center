#!/bin/bash
# Installs the TAS58xx driver (Louder Raspberry) on Volumio for Raspberry Pi and
# adds the Louder boards to Volumio's DAC list.
#
# Usage, over SSH on the Volumio device (enable SSH at http://volumio.local/dev):
#   curl -sL https://raw.githubusercontent.com/sonocotta/raspberry-media-center/refs/heads/main/firmware/cloud-init/configure-louder-on-volumio.sh | sudo bash
#
# Then pick your board in Settings > Playback Options > DAC Model, save, and reboot.
# For the 2X and 2X Plus boards, also set Volume options > Mixer Type to Software.
#
# Run it again after every Volumio update. Updates change the kernel, and the
# driver has to be rebuilt for the new one.
#
# The build takes a few minutes on a Pi 4 or Pi 5 and much longer on a Pi Zero,
# downloads about 250 MB and needs about 2.5 GB of free space while it runs.
# Written for Volumio 4 (Debian Bookworm). On Volumio 3 (Debian Buster) a Pi 5
# isn't supported, and other Pis need working Buster package mirrors.
#
# Optional settings (put them after sudo, e.g. "... | sudo LOUDER_I2C_ADDRESS=0x2e bash"):
#   LOUDER_I2C_ADDRESS       I2C address for the "Louder Raspberry" (1X) board, e.g. 0x2e
#                            for early boards. Default 0x2d.
#   LOUDER_PLUS_I2C_ADDRESS  I2C address for the "Louder Raspberry Plus" board. Default 0x4c.
#                            Without these, a re-run keeps the address (and any other
#                            options) already on the board's overlay line in config.txt.
#   TAS58XX_REF              Driver branch, tag or commit to build. Default main.
#   LOUDER_WORK_DIR          Folder to build in. The script creates a "louder-build"
#                            folder there and removes it afterwards. Default /home/volumio.
#   KEEP_BUILD=1             Keep the build folder after a successful build.
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
# Empty means "not set": a re-run then keeps the address already in use.
LOUDER_I2C_ADDRESS="${LOUDER_I2C_ADDRESS:-}"
LOUDER_PLUS_I2C_ADDRESS="${LOUDER_PLUS_I2C_ADDRESS:-}"
# Absolute path: the module build runs make from inside the kernel tree.
WORK_DIR="$(realpath -m "${LOUDER_WORK_DIR:-/home/volumio}")"
BUILD_DIR="$WORK_DIR/louder-build"
BUILD_MARKER=".created-by-configure-louder-on-volumio"
KEEP_BUILD="${KEEP_BUILD:-0}"

RPI_FIRMWARE_RAW="https://raw.githubusercontent.com/raspberrypi/rpi-firmware"
RPI_LINUX_ARCHIVE="https://github.com/raspberrypi/linux/archive"
BOOT_DIR="/boot"
MODULES_ROOT="/lib/modules"
OS_RELEASE="/etc/os-release"
DT_MODEL="/proc/device-tree/model"
PROC_CONFIG="/proc/config.gz"
ETC_MODULES="/etc/modules"
DACS_JSON="/volumio/app/plugins/system_controller/i2s_dacs/dacs.json"
I2S_CONFIG="/data/configuration/system_controller/i2s_dacs/config.json"
ALSA_CONFIG="/data/configuration/audio_interface/alsa_controller/config.json"
MIN_FREE_MB=2500

log() { echo "[louder] $*"; }
die() { echo "[louder] ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------
check_system() {
    [ "$(id -u)" -eq 0 ] || die "Run this as root: curl -sL <script url> | sudo bash"
    # Volumio's Pi images report VOLUMIO_HARDWARE as pi, pi-kiosk, cm0, cm4 or cm5,
    # so check for Volumio and for a Raspberry Pi separately.
    grep -q '^VOLUMIO_HARDWARE=' "$OS_RELEASE" 2>/dev/null ||
        die "This script is for Volumio. On Raspberry Pi OS use configure-louder.sh."
    local model=""
    if [ -r "$DT_MODEL" ]; then
        model="$(tr -d '\0' <"$DT_MODEL")"
    fi
    [[ "$model" == "Raspberry Pi"* ]] ||
        die "This script is for Volumio on a Raspberry Pi, but this device reports '${model:-unknown model}'."
    DEBIAN_CODENAME="$(sed -n 's/^VERSION_CODENAME=//p' "$OS_RELEASE" | tr -d '"')"

    local address
    for address in "$LOUDER_I2C_ADDRESS" "$LOUDER_PLUS_I2C_ADDRESS"; do
        [ -z "$address" ] || [[ "$address" =~ ^0x[0-9a-fA-F]{2}$ ]] ||
            die "I2C addresses must look like 0x2d (got '$address')"
    done
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
        if [ "$DEBIAN_CODENAME" = buster ]; then
            die "Kernel $KREL is 64-bit, and Volumio 3 (Debian Buster) has no cross compiler to build for it. Update to Volumio 4 and run this script again."
        fi
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
    if ! apt-get update </dev/null; then
        if [ "$DEBIAN_CODENAME" = buster ]; then
            die "apt-get update failed. Volumio 3 is based on Debian Buster, whose Raspbian packages moved to legacy.raspbian.org. Update to Volumio 4, or point /etc/apt/sources.list at http://legacy.raspbian.org/raspbian/, then run this script again."
        fi
        die "apt-get update failed. Check the network connection and run this script again."
    fi
    apt-get install -y --no-install-recommends \
        build-essential bc bison flex libssl-dev curl ca-certificates xz-utils \
        device-tree-compiler i2c-tools kmod "${CROSS_PKGS[@]}" </dev/null
}

# Everything is downloaded and built in BUILD_DIR, which the script creates and
# marks. Only a folder with that mark is ever deleted.
remove_build_files() {
    [ -e "$BUILD_DIR" ] || return 0
    [ -e "$BUILD_DIR/$BUILD_MARKER" ] ||
        die "$BUILD_DIR exists but wasn't created by this script. Remove it, or set LOUDER_WORK_DIR to another folder."
    rm -rf "$BUILD_DIR"
}

check_disk_space() {
    # A failed run keeps its files for troubleshooting; don't count them.
    remove_build_files
    mkdir -p "$BUILD_DIR"
    touch "$BUILD_DIR/$BUILD_MARKER"
    local free_mb
    free_mb="$(df -Pm "$BUILD_DIR" | awk 'NR == 2 {print $4}')"
    [ "$free_mb" -ge "$MIN_FREE_MB" ] ||
        die "Need ${MIN_FREE_MB} MB free in $WORK_DIR but only ${free_mb} MB is available. Free up space, or set LOUDER_WORK_DIR to a folder with more space."
}

# ---------------------------------------------------------------------------
# Download and prepare the kernel source for building external modules
# ---------------------------------------------------------------------------
prepare_kernel() {
    KSRC="$BUILD_DIR/linux-$KREL"
    rm -rf "$KSRC"
    mkdir -p "$KSRC"

    log "Downloading kernel source (about 250 MB)..."
    curl -fL --retry 3 -o "$BUILD_DIR/linux.tar.gz" "$RPI_LINUX_ARCHIVE/$GIT_HASH.tar.gz" ||
        die "Can't download $RPI_LINUX_ARCHIVE/$GIT_HASH.tar.gz"
    log "Extracting kernel source..."
    tar -xzf "$BUILD_DIR/linux.tar.gz" -C "$KSRC" --strip-components=1
    rm -f "$BUILD_DIR/linux.tar.gz"

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
    DRV="$BUILD_DIR/tas5805m-driver-for-raspbian"
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
# Volumio settings. These run while Volumio is stopped.
#
# Volumio manages one overlay line in /boot/config.txt: the line directly below
# its banner. It rewrites that line only when you switch to a DAC with a
# different name. The earlier manual instructions had users add the tas58xx
# line by hand instead, usually under a copy of the banner and a commented-out
# line for the previous DAC, where Volumio doesn't manage it.
# ---------------------------------------------------------------------------
CONFIG_BANNER='#### Volumio i2s setting below: do not alter ####'

# Remove tas58xx lines that aren't directly below the banner, so the overlay
# isn't loaded twice, and banners left without an overlay line (with the
# commented-out lines below them). The line Volumio manages is kept.
# Sets HAND_ADDED_OVERLAY to the last removed overlay, so register_dacs can
# tell which board the old setup was for.
repair_config_txt() {
    HAND_ADDED_OVERLAY=""
    local config="$BOOT_DIR/config.txt"
    [ -f "$config" ] || return 0

    local result removed
    result="$(node - "$config" "$CONFIG_BANNER" <<'EOF'
const fs = require('fs');
const [file, BANNER] = process.argv.slice(2);
const lines = fs.readFileSync(file, 'utf8').split('\n');

const handAdded = (line, i) => /^\s*dtoverlay=tas58xx/.test(line) && lines[i - 1] !== BANNER;
const removedOverlays = lines.filter(handAdded).map((line) => line.trim().replace(/^dtoverlay=/, ''));
const kept = lines.filter((line, i) => !handAdded(line, i));
const out = [];
for (let i = 0; i < kept.length; i++) {
  if (kept[i] === BANNER && !/^dtoverlay=/.test(kept[i + 1] || '')) {
    while (/^#\s*dtoverlay=/.test(kept[i + 1] || '')) i++;
    continue;
  }
  out.push(kept[i]);
}
if (out.length !== lines.length) fs.writeFileSync(file, out.join('\n'));
console.log((lines.length - out.length) + '\t' + (removedOverlays.pop() || ''));
EOF
)"
    IFS=$'\t' read -r removed HAND_ADDED_OVERLAY <<<"$result"
    if [ "$removed" -gt 0 ]; then
        log "Removed $removed line(s) added to $config by hand under the old instructions"
    fi

    if grep -qE '^\s*dtoverlay=tas58xx' "$BOOT_DIR/userconfig.txt" 2>/dev/null; then
        log "WARNING: $BOOT_DIR/userconfig.txt also loads a tas58xx overlay. Remove that line,"
        log "         or the amplifier is set up twice once you pick a board in Volumio."
    fi
}

# The old DAC entry had "modules":"tas58xx". For Pi DACs Volumio expects that
# field to be empty: with a value it skips the overlay and rewrites /etc/modules
# with one letter per line, dropping i2c-dev.
repair_etc_modules() {
    [ -f "$ETC_MODULES" ] || return 0
    if grep -qxE '[[:alnum:]]' "$ETC_MODULES"; then
        log "Repairing $ETC_MODULES (removing single-letter lines left by the old DAC entry)"
        sed -i -E '/^[[:alnum:]]$/d' "$ETC_MODULES"
    fi
    if ! grep -qx 'i2c-dev' "$ETC_MODULES"; then
        # Start a new line if the file doesn't end with one
        if [ -n "$(tail -c 1 "$ETC_MODULES")" ]; then
            echo >>"$ETC_MODULES"
        fi
        echo 'i2c-dev' >>"$ETC_MODULES"
    fi
}

# ---------------------------------------------------------------------------
# Add the Louder boards to Volumio's DAC list (Settings > Playback Options),
# and bring an existing Louder setup up to date.
#
# alsacard is the ALSA card ID: the overlay label without dashes, cut to 15
# characters, so both overlays produce "LouderRaspberry".
# The 2X boards have two amplifiers with separate volume controls ("2.0 Digital"
# for the speakers, "0.1 Digital" for the subwoofer). There is no single control
# to name, and with an empty mixer Volumio picks the first control it finds,
# which is the subwoofer's. Users of those boards set Mixer Type to Software.
#
# If a Louder board is already selected, Volumio won't rewrite config.txt when
# it's picked again, so this writes the line itself, directly below the banner:
# - The line already in use (Volumio's, or one added by hand under the old
#   instructions) is kept with its address and options (eq_mode, firmware, ...).
#   Only an address set with LOUDER_I2C_ADDRESS / LOUDER_PLUS_I2C_ADDRESS
#   replaces the one on the line. Without a line, the board's default is used.
# - If that line is for a different board than the one selected (the old
#   instructions had one "Louder Raspberry" entry for every board), nothing is
#   written and the user is told which board to pick. Volumio then writes the
#   line itself, because the DAC name changes.
# - The old entry named the "Master" volume control, which the driver has since
#   renamed to "Digital Volume". A hardware mixer still set to another control
#   is switched to the board's mixer.
#
# Sets SELECTED_BOARD (a Louder board is selected and its line is up to date)
# or PICK_BOARD (the board the user should pick in Volumio).
# ---------------------------------------------------------------------------
register_dacs() {
    SELECTED_BOARD=""
    PICK_BOARD=""
    [ -f "$DACS_JSON" ] || die "Can't find Volumio's DAC list at $DACS_JSON"
    [ -f "$DACS_JSON.orig" ] || cp -p "$DACS_JSON" "$DACS_JSON.orig"

    local result
    result="$(node - "$DACS_JSON" "$I2S_CONFIG" "$ALSA_CONFIG" "$BOOT_DIR/config.txt" "$CONFIG_BANNER" \
        "${LOUDER_I2C_ADDRESS,,}" "${LOUDER_PLUS_I2C_ADDRESS,,}" "$HAND_ADDED_OVERLAY" <<'EOF'
const fs = require('fs');
const [dacsFile, i2sFile, alsaFile, configTxtFile, BANNER, address1x, addressPlus, handAdded] =
  process.argv.slice(2);

// An overlay is "name,key=value,..."
const parse = (overlay) => {
  const [name, ...rest] = overlay.split(',');
  const params = {};
  for (const part of rest) {
    const [key, value = ''] = part.split('=');
    params[key.trim()] = value.trim().toLowerCase();
  }
  return { name: name.trim(), params };
};
const withParam = (overlay, key, value) => {
  const parts = overlay.split(',');
  const i = parts.findIndex((part, n) => n > 0 && part.split('=')[0].trim() === key);
  if (i > 0) parts[i] = key + '=' + value;
  else parts.push(key + '=' + value);
  return parts.join(',');
};
// TAS5805M boards answer on 0x2c-0x2f, TAS5825M (Plus) boards on 0x4c-0x4f
const isPlusAddress = (address) => /^0x4[c-f]$/.test(address);
const boardOf = (overlay) => {
  const { name, params } = parse(overlay);
  if (name === 'tas58xx') {
    return isPlusAddress(params.i2creg || '0x2d') ? 'louder-raspberry-plus' : 'louder-raspberry';
  }
  if (name === 'tas58xx-dual') {
    return isPlusAddress(params.i2creg_primary || '0x2d') ? 'louder-raspberry-2x-plus' : 'louder-raspberry-2x';
  }
  return null;
};

const overlay1x = (address) => (address && address !== '0x2d' ? 'tas58xx,i2creg=' + address : 'tas58xx');
const overlayPlus = (address) => 'tas58xx,i2creg=' + (address || '0x4c');
const entry = (id, name, overlay, mixer) => ({
  id, name, overlay,
  alsanum: '2', alsacard: 'LouderRaspberry', mixer,
  modules: '', script: '', needsreboot: 'yes',
});
const entries = [
  entry('louder-raspberry', 'Louder Raspberry', overlay1x(address1x), 'Digital'),
  entry('louder-raspberry-plus', 'Louder Raspberry Plus', overlayPlus(addressPlus), 'Digital'),
  entry('louder-raspberry-2x', 'Louder Raspberry 2X', 'tas58xx-dual', ''),
  entry('louder-raspberry-2x-plus', 'Louder Raspberry 2X Plus',
        'tas58xx-dual,i2creg_primary=0x4c,i2creg_secondary=0x4d', ''),
];
const byId = (id) => entries.find((e) => e.id === id);
const readJson = (file) => {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { return null; }
};
const writeJson = (file, data) => fs.writeFileSync(file, JSON.stringify(data, null, 2));

let result = '';
const i2s = readJson(i2sFile);
const enabled = i2s && i2s.i2s_enabled && i2s.i2s_enabled.value === true;
const selected = enabled && i2s.i2s_dac && entries.find((e) => e.name === i2s.i2s_dac.value);

if (selected) {
  const escaped = (BANNER + '\n').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const managedRe = new RegExp(escaped + 'dtoverlay=(.*)\n');
  const configTxt = fs.readFileSync(configTxtFile, 'utf8');
  const match = configTxt.match(managedRe);
  const managed = match && boardOf(match[1]) ? match[1].trim() : '';
  const current = managed || (handAdded && boardOf(handAdded) ? handAdded : '');
  const currentBoard = current ? boardOf(current) : null;

  if (current && currentBoard !== selected.id) {
    result = ['pick', byId(currentBoard).name, selected.name].join('\t');
  } else {
    let overlay = current || selected.overlay;
    if (selected.id === 'louder-raspberry' && address1x) overlay = withParam(overlay, 'i2creg', address1x);
    if (selected.id === 'louder-raspberry-plus' && addressPlus) overlay = withParam(overlay, 'i2creg', addressPlus);
    // Keep the DAC entry on the address in use, so switching away and back keeps it
    const inUse = parse(overlay).params.i2creg;
    if (selected.id === 'louder-raspberry') selected.overlay = overlay1x(inUse);
    if (selected.id === 'louder-raspberry-plus') selected.overlay = overlayPlus(inUse);

    const line = BANNER + '\n' + 'dtoverlay=' + overlay + '\n';
    const newConfigTxt = match
      ? configTxt.replace(managedRe, line)
      : configTxt + (configTxt.endsWith('\n') ? '' : '\n') + '\n' + line;
    const changed = newConfigTxt !== configTxt;
    if (changed) fs.writeFileSync(configTxtFile, newConfigTxt);

    // Volumio stores an overlay DAC's overlay as i2s_id
    if (!i2s.i2s_id || i2s.i2s_id.value !== selected.overlay) {
      i2s.i2s_id = { type: 'string', value: selected.overlay };
      writeJson(i2sFile, i2s);
    }

    let oldMixer = '';
    const alsa = selected.mixer ? readJson(alsaFile) : null;
    if (alsa && alsa.mixer_type && alsa.mixer_type.value === 'Hardware' &&
        alsa.mixer && alsa.mixer.value !== selected.mixer) {
      oldMixer = alsa.mixer.value || '(none)';
      alsa.mixer.value = selected.mixer;
      writeJson(alsaFile, alsa);
    }
    result = ['selected', selected.name, changed ? 'updated' : 'unchanged', overlay, oldMixer].join('\t');
  }
}

// Add the entries at the top of the Raspberry Pi list, replacing older Louder entries
const data = JSON.parse(fs.readFileSync(dacsFile, 'utf8'));
const ids = new Set(entries.map((e) => e.id));
for (const group of data.devices) {
  group.data = group.data.filter((dac) => !ids.has(dac.id));
}
const pi = data.devices.find((group) => group.name === 'Raspberry PI');
if (!pi) {
  console.error('[louder] ERROR: no "Raspberry PI" section in ' + dacsFile);
  process.exit(1);
}
pi.data.unshift(...entries);
fs.writeFileSync(dacsFile, JSON.stringify(data, null, 2) + '\n');
console.log(result);
EOF
)"
    log "Added Louder Raspberry, Plus, 2X and 2X Plus to $DACS_JSON"

    local status board detail overlay old_mixer
    IFS=$'\t' read -r status board detail overlay old_mixer <<<"$result"
    case "$status" in
        selected)
            SELECTED_BOARD="$board"
            if [ "$detail" = updated ]; then
                log "$board is already selected in Volumio; set its line in $BOOT_DIR/config.txt to dtoverlay=$overlay"
            else
                log "$board is already selected in Volumio; its line in $BOOT_DIR/config.txt (dtoverlay=$overlay) is up to date"
            fi
            if [ -n "$old_mixer" ]; then
                log "Changed Volumio's hardware volume control from '$old_mixer' to 'Digital'"
            fi
            ;;
        pick)
            PICK_BOARD="$board"
            log "Your overlay line is for the $board board, but Volumio has $detail selected."
            ;;
    esac
}

# Back up config.txt once per run, before any change, and keep the backup only
# if something changed. (Plain cp: /boot is FAT and can't keep ownership.)
update_volumio_settings() {
    local config="$BOOT_DIR/config.txt" backup="$BOOT_DIR/config.txt.louder-backup"
    [ -f "$config" ] && cp "$config" "$backup.new"

    repair_config_txt
    repair_etc_modules
    register_dacs

    if [ -f "$backup.new" ]; then
        if cmp -s "$config" "$backup.new"; then
            rm -f "$backup.new"
        else
            mv -f "$backup.new" "$backup"
            log "Saved the previous $config as $backup"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Start Volumio again if it was stopped. Remove the build folder after a
# successful run; keep it after a failure.
# ---------------------------------------------------------------------------
cleanup() {
    local rc=$?
    if [ "${VOLUMIO_STOPPED:-0}" = 1 ]; then
        systemctl start volumio.service || true
    fi
    if [ "$rc" -ne 0 ]; then
        echo "[louder] Build files kept in $BUILD_DIR for troubleshooting" >&2
    elif [ "$KEEP_BUILD" != 1 ]; then
        remove_build_files
    fi
}

mixer_note() {
    log "2X and 2X Plus only: under Volume options, set Mixer Type to Software,"
    log "or the volume slider only changes the subwoofer."
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

    log "Stopping Volumio while its settings are updated..."
    systemctl stop volumio.service
    VOLUMIO_STOPPED=1
    update_volumio_settings
    log "Starting Volumio..."
    systemctl start volumio.service
    VOLUMIO_STOPPED=0

    if [ -n "$SELECTED_BOARD" ]; then
        log "Done. Reboot to load the driver: sudo reboot"
        case "$SELECTED_BOARD" in *2X*) mixer_note ;; esac
    else
        log "Done. Next steps:"
        log "  1. In Volumio, open Settings > Playback Options and turn on I2S DAC."
        if [ -n "$PICK_BOARD" ]; then
            log "  2. Under DAC Model, pick $PICK_BOARD."
        else
            log "  2. Under DAC Model, pick your board: Louder Raspberry, Louder Raspberry Plus,"
            log "     Louder Raspberry 2X or Louder Raspberry 2X Plus."
        fi
        log "  3. Save and reboot when asked."
        case "$PICK_BOARD" in "" | *2X*) mixer_note ;; esac
    fi
    log "Run this script again after each Volumio update."
}

# Everything runs from main so the whole script is read before anything executes
# (safe with curl | bash).
main "$@"
