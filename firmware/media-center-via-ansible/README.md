# Raspberry Pi Media Center — Ansible Playbooks

This repository provisions and manages a Raspberry Pi–based media center using Ansible. Playbooks are idempotent, use systemd services for long-running apps, and favor Python virtual environments where needed. Tasks are designed to run from any subfolder (VS Code tasks use ${workspaceFolder}/.venv).

- [Raspberry Pi Media Center — Ansible Playbooks](#raspberry-pi-media-center--ansible-playbooks)
  - [How it works (Ansible approach)](#how-it-works-ansible-approach)
  - [Repository layout](#repository-layout)
  - [Playbooks overview](#playbooks-overview)
    - [Hardware](#hardware)
    - [Core audio](#core-audio)
    - [Visualizers](#visualizers)
    - [Auxiliary](#auxiliary)
  - [Common variables (examples)](#common-variables-examples)
  - [Troubleshooting](#troubleshooting)
  - [Requirements](#requirements)
  - [Run examples](#run-examples)

## How it works (Ansible approach)

- Inventory: hosts are grouped under “raspberry” in hosts.yml.
- Privileges: most tasks require become: true (sudo).
- Idempotence: lineinfile/copy/file ensure repeatable runs without duplication.
- Services: systemd units are installed/updated and daemon-reloaded, then enabled.
- venvs: Python apps run in per-project virtualenvs under the app directory; pip in venv is used to avoid host Python conflicts.

Run any playbook:

- With VS Code task `1. apply without password,` or
- From a terminal:
```bash
source ./.venv/bin/activate
ansible-playbook -i hosts.yml playbooks/<playbook>.yml
```

## Repository layout

- playbooks/: Main playbooks
  - 0-hardware/: Device tree, overlays, GPIO, audio hardware configuration
  - 1-core/: Core audio services and media center functionality
  - 2-auxiliary/: Convenience, tmux, and demo helpers
  - 3-visual/: OLED / LED bar / TFT visualizers

## Playbooks overview

### Hardware

- playbooks/0-hardware/2-oled-hat.yml
- playbooks/0-hardware/2-tft-hat.yml
  - Ensures SPI is enabled (dtparam=spi=on) in /boot/config.txt and reboots if changed.

- playbooks/0-hardware/0-w5500-rotating-mac-fix.yml
  - Deploys files/w5500-overlay.dts, with a hard-coded MAC address, compiles it to DTBO with dtc, backs up /boot/overlays/w5500.dtbo, installs the custom DTBO, syncs, and reboots. More details [here](https://github.com/sonocotta/raspberry-media-center?tab=readme-ov-file#rotating-mac-address-on-the-w5500)

- playbooks/0-hardware/1-amped-raspberry-pi.yml
  - Audio hardware setup for [Amped Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/amped-raspberry-pi-hat/) and [Media Center](https://www.tindie.com/products/sonocotta/amped-raspberry-pi-media-center/). Ensures HiFiBerry overlay, manages mutually exclusive options:
    - use_w5500_overlay=true: adds dtoverlay=w5500 and disables `dac-enable-gpio` service.
    - use_w5500_overlay=false: removes dtoverlay=w5500 and enables `dac-enable-gpio` GPIO control.
  - Disables HDMI audio if requested, reboots, and prints `aplay -l`.
  
  Since W5500 uses GPIO8 (CS0) and some early designs use GPIO8 to enable DAC, you can use one or the other. At this moment HiFi-Berrt DAC overlay, which I reuse for Amped boards, do not support EN pin, thus `dac-enable-gpio` service was created to switch on DAC on start

- playbooks/0-hardware/1-hifi-raspberry-pi.yml
  - Audio hardware setup for [HiFi Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/hifi-raspberry-pi-hat/) and [HiFi Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/hifi-raspberry-pi-media-center/) configurations.

- playbooks/0-hardware/1-loud-raspberry-pi.yml
  - Audio hardware setup for [Loud Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/loud-raspberry-pi-hat/) and [Loud Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/loud-raspberry-pi-media-center/) configurations.

- playbooks/0-hardware/1-louder-raspberry-pi.yml
  - Audio hardware setup for [Louder Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/louder-raspberry-pi-hat/) and [Louder Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/louder-raspberry-pi-media-center/) configurations.

### Core audio

- playbooks/1-core/0-init.yml
  - System initialization playbook that updates apt cache and performs system upgrade if packages are older than 1 day.

- playbooks/1-core/2-pulseaudio.yml
  - Installs PulseAudio with system-wide configuration. Enables system mode, configures network access with IP ACL (127.0.0.1;192.168.0.0/23), adds zeroconf publishing, and creates systemd service. Ensures pulse user is in audio group.

- playbooks/1-core/3-librespot-raspberry.yml
  - Installs Raspotify (librespot for Raspberry Pi) by downloading and installing the latest ARM package. Provides Spotify Connect functionality.

- playbooks/1-core/4.0-snapserver.yml
  - Installs Snapcast server for multi-room audio synchronization. Configures TCP streams on ports 1716 (other) and 1706 (mopidy), enables web interface via snapweb, sets up Avahi service discovery, and configures listening on all network interfaces. Available at http://your-server-address:1704

- playbooks/1-core/4.1-snapclient.yml
  - Installs Snapcast client for receiving synchronized audio streams. Configures sound card device (default: "default") and sample format (48000:32:*). Variable `snapclient_device` can be customized for specific sound cards.

- playbooks/1-core/5-shairport-sync.yml
  - Installs Shairport Sync for Apple AirPlay compatibility. Enables the Raspberry Pi to receive audio streams from iOS devices and iTunes.

- playbooks/1-core/6-squeezelite.yml
  - Installs Squeezelite client for Logitech Media Server (LMS) compatibility. Configures to use system default audio output and enables/starts the service.

- playbooks/1-core/7-upnp-server.yml
  - Installs gmediarender UPnP renderer with GStreamer plugins for broad audio format support. Creates custom systemd service running as nobody user with audio group access. Enables UPnP/DLNA audio playback from compatible clients.

- playbooks/1-core/8.0-camilla-dsp-backend.yml
  - Installs CamillaDSP backend binary to /usr/local/bin, creates camilla system user, adds to audio, creates config/state under /etc/camilladsp (and defaults like loudness.yaml), installs/starts camilladsp.service (After=network-online.target sound.target). Available at http://your-server-address:1234
  - Optionally amends pulseaudio ordering if pulseaudio.service exists (safe no-op if not installed). Otherwise pulseaudio claim default ALSA device and Camilla fail to start.

- playbooks/1-core/8.1-camillagui-dsp-frontend.yml
  - Downloads the Camilla GUI backend bundle to /opt/camilladsp/camillagui_backend, fixes ownership, and installs camillagui.service that starts the packaged camillagui_backend executable (Requires camilladsp.service, After=network-online.target). Available at http://your-server-address:5005

### Visualizers

The actual code for those services is in the linked repo: https://github.com/sonocotta/raspberry-camilla-vu-meter

- playbooks/3-visual/8.2-camilla-ledbar-vu-meter.yml
  - Clones https://github.com/sonocotta/rpi-ws281x-camilla-vu-meter to /opt, creates venv, installs dependencies, and installs camilla-ledbar-vu-meter.service to run:
    - main.py --interval-ms 50 --ledbar --led-pin 12 --led-count 8 --led-end-colors

   <img width="864" height="658" alt="image" src="https://github.com/user-attachments/assets/3bb7696b-07f4-4b08-952c-2eeb38915ee8" />

- playbooks/3-visual/8.2-camilla-oled-vu-meter.yml
  - OLED visualizer variant. Enables SPI in config if needed, creates a venv in the repo, installs requirements (ensure Pillow build deps installed via apt), and runs main.py with --oled flags (mono/dual variants controlled by variables).

  <img width="1290" height="712" alt="image" src="https://github.com/user-attachments/assets/121504a8-163e-4632-a787-17fc9713d9bf" />


- playbooks/3-visual/8.2-camilla-tft-vu-meter.yml
  - TFT display visualizer variant for small TFT screens. Enables SPI interface, installs required packages including Pillow dependencies, fonts, and GPIO libraries. Clones the same repository and runs main.py with `--tft` flags. Supports both dual-channel and mono modes (controlled by `--tft-mono` flag). Requires CamillaDSP backend service.

  <img width="1328" height="675" alt="image" src="https://github.com/user-attachments/assets/1671d49f-3634-4e1f-93cf-327e557aaa8d" />

### Auxiliary

- playbooks/2-auxiliary/0-profile-tmux-autostart.yml
  - Installs tmux, creates a session script that avoids attaching when already attached elsewhere, and inserts an idempotent block into ~/.bash_profile to auto-attach on SSH login.

## Common variables (examples)

- use_w5500_overlay: true|false — choose between SPI W5500 overlay or GPIO control.
- gpio_set_on_boot: true|false — enable DAC via GPIO at boot when not using W5500.
- gpio_pin: numeric pin (e.g., 12 for PWM; 520 indicates board-specific mapping in comments).
- led_count / led_pin: LED bar length and control pin for LED visualizers.
- snapclient_device: Audio device for Snapcast client (default: "default", can be hw:CARD=sndrpihifiberry,DEV=0).
- display_tft_single: true|false — enable single channel mode for TFT visualizer (default: false for dual channel).

## Troubleshooting

- Check service logs:
  - journalctl -u camilladsp -e
  - journalctl -u camillagui -e
- If pip builds fail (e.g., Pillow), install required -dev packages:
  - libjpeg-dev zlib1g-dev libtiff5-dev libfreetype6-dev liblcms2-dev libwebp-dev libopenjp2-7-dev
- Ordering cycles: avoid mutual Requires/After between services; prefer Wants on only one side.

## Requirements

- Controller: Python 3 and a venv (.venv) containing Ansible.
- Targets: Raspberry Pi OS with Python 3, SSH access, and sudo privileges.

## Run examples

- System initialization:
  - ansible-playbook -i hosts.yml playbooks/1-core/0-init.yml
- PulseAudio setup:
  - ansible-playbook -i hosts.yml playbooks/1-core/2-pulseaudio.yml
- Spotify Connect (Raspotify):
  - ansible-playbook -i hosts.yml playbooks/1-core/3-librespot-raspberry.yml
- Multi-room audio (Snapcast server + client):
  - ansible-playbook -i hosts.yml playbooks/1-core/4.0-snapserver.yml
  - ansible-playbook -i hosts.yml playbooks/1-core/4.1-snapclient.yml
- CamillaDSP backend only:
  - ansible-playbook -i hosts.yml playbooks/1-core/8.0-camilla-dsp-backend.yml
- CamillaDSP backend + GUI:
  - ansible-playbook -i hosts.yml playbooks/1-core/8.0-camilla-dsp-backend.yml
  - ansible-playbook -i hosts.yml playbooks/1-core/8.1-camillagui-dsp-frontend.yml
- Visualizers:
  - ansible-playbook -i hosts.yml playbooks/3-visual/8.2-camilla-ledbar-vu-meter.yml
  - ansible-playbook -i hosts.yml playbooks/3-visual/8.2-camilla-oled-vu-meter.yml
  - ansible-playbook -i hosts.yml playbooks/3-visual/8.2-camilla-tft-vu-meter.yml
