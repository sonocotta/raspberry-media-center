# Raspberry Pi Media Center and Hats

![Open Source Hardware](/images/open-source-hardware-logo.png)
![Open Source Software](/images/open-source-software-logo.png)
<a href="https://www.tindie.com/stores/sonocotta/?ref=offsite_badges&utm_source=sellers_andrey-malyshenko&utm_medium=badges&utm_campaign=badge_medium"><img src="https://d2ss6ovg47m0r5.cloudfront.net/badges/tindie-mediums.png" alt="I sell on Tindie" width="150" height="78"></a>
<br />
[![Dev Chat](https://img.shields.io/discord/1233306441469657140?logo=discord&label=discord&style=flat-square)](https://discord.gg/PtnaAaQMpS)


![DSC_0005](https://github.com/sonocotta/raspberry-media-center/assets/5459747/37bf52d2-3fde-4fbb-b98e-35fb1b48ebe4)

Raspberry Pi Media Center and Hats are a series of Raspberry Pi Zero-based media center devices. They share a similar look, and compared to my earlier designs, they have a great-looking aluminum case.

![DSC_0081](https://github.com/user-attachments/assets/be6897be-4f40-46ab-b77b-3659a681ff39)

Raspberry Pi Media Center Hats are cost-effective versions of the above devices, sharing the same DACs and similar schematics, but being able to pair with any Raspberry Pi boards. 

## Table of Contents

- [Raspberry Pi Media Center and Hats](#raspberry-pi-media-center-and-hats)
  - [Table of Contents](#table-of-contents)
  - [Motivation](#motivation)
  - [Raspberry Pi HiFi and Hat](#raspberry-pi-hifi-and-hat)
  - [Raspberry Pi HiFi Plus](#raspberry-pi-hifi-plus)
  - [Loud Raspberry Pi and Hat](#loud-raspberry-pi-and-hat)
  - [Louder Raspberry Pi and Hat](#louder-raspberry-pi-and-hat)
  - [Features](#features)
  - [Board Pinout](#board-pinout)
    - [Audio](#audio)
    - [Peripheral](#peripheral)
    - [Peripheral (Louder)](#peripheral-louder)
  - [Software](#software)
    - [DAC Configuration - HiFi Raspberry Pi](#dac-configuration---hifi-raspberry-pi)
    - [DAC Configuration - Loud Raspberry Pi](#dac-configuration---loud-raspberry-pi)
    - [DAC Configuration - Louder Raspberry Pi](#dac-configuration---louder-raspberry-pi)
    - [Bare OS Options](#bare-os-options)
    - [Bare OS + Standard client services (Ansible short overview)](#bare-os--standard-client-services-ansible-short-overview)
    - [Third-party Media Software](#third-party-media-software)
    - [Volumio](#volumio)
    - [Rotating MAC address on the W5500](#rotating-mac-address-on-the-w5500)
    - [TAS5805M DSP Capabilities](#tas5805m-dsp-capabilities)
    - [TAS5805M DAC I2C address changes](#tas5805m-dac-i2c-address-changes)
  - [Hardware](#hardware)
    - [HiFi Raspberry Pi](#hifi-raspberry-pi)
    - [HiFi Raspberry Hat](#hifi-raspberry-hat)
    - [HiFi-Plus Raspberry Hat](#hifi-plus-raspberry-hat)
    - [Loud Raspberry Pi](#loud-raspberry-pi)
    - [Loud Raspberry Hat](#loud-raspberry-hat)
    - [Louder Raspberry Pi](#louder-raspberry-pi)
    - [Louder Raspberry Hat](#louder-raspberry-hat)
    - [Power considerations](#power-considerations)
      - [Hifi and Loud Raspberry](#hifi-and-loud-raspberry)
      - [Louder Raspberry](#louder-raspberry)
      - [Serial and USB-PD](#serial-and-usb-pd)
    - [Relay Driver](#relay-driver)
    - [IR reader](#ir-reader)
    - [RGB Led](#rgb-led)
    - [Raspberry Pi 5 note](#raspberry-pi-5-note)
  - [Demo](#demo)
  - [Where to buy](#where-to-buy)
  - [Press mentions](#press-mentions)

## Motivation

I did few audio projects in the past, some using [ESP32](https://hackaday.io/project/173620-loud-esp), some using larger [Orange Pi](https://hackaday.io/project/191936-orange-pi-home-media-center) and [Raspberry Pi](https://hackaday.io/project/162373-orangepi-zero-pulse-music-server-using-i2s-dac) devices. Each has its pros and cons, and with each iteration, I'm trying to focus on the details that were working best for me, while actually using those devices at home. 

What is special about the Raspberry eco-system is of course its community support. Being a not-so-strong software developer, I often have to rely on the work that other people did and baked into the base Raspbian image. Attaching a DAC, Ethernet, and IR reader is as simple as adding 3 lines into the `config.txt` file, which is a bit of magic really

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=hifiberry-dac
```

All the device tree definitions, kernel drivers, and dependency packages are already in place, believe it or not. 

Sure, compared to the ESP32 platform it is not as lightweight. It requires more power, it takes some time to boot. But when it comes to rapid development, there is nothing like the Raspberry Pi.

## Raspberry Pi HiFi and Hat

![DSC_0727](https://github.com/sonocotta/raspberry-media-center/assets/5459747/029e5175-1ee1-4876-8ba3-91d49730c29f)

Raspberry Pi HiFi Media Center is a first-in-line product that uses the legendary PCM5100 series DAC with supreme audio quality. It exposes line-level output that you can plug into a stereo amplifier. Analog power comes through an Ultra-low-noise LDO, making sure no interference from Raspberry come through to your speakers. Spend as much as you need on the external amp to deliver the sound you like (personally I prefer late 80's audio gear).

![DSC_0038](https://github.com/user-attachments/assets/76359180-4787-443a-87aa-93235105e661)

Raspberry Pi HiFi Hat is the same DAC and power circuitry **times two** in a Hat shape. You can use it with any Raspberry Pi board, not only Zero. Raspberry Pi 5 users can use both outputs independently, while other Pis will produce the same audio on both outputs.

## Raspberry Pi HiFi Plus 

The PCM5100 HiFi DAC combined together with a highly efficient TPA3110D2 D-class amplifier. Times two (again, why not?). It brings all the best from the HiFi model and adds an onboard amp to form a complete solution that can be paired with speakers directly. It uses an external power source to feed hungry amps and host Pi using an onboard drop-down converter. Raspberry Pi 5 users can use both outputs independently, older boards will produce the same audio in parallel. Boards use 4-layer PCBs to ensure good signal protection to keep that noise low. Both amps can be shut down using GPIO pins, so you can be sure the speakers will be dead quiet when they are not in use.  

![DSC_0054](https://github.com/user-attachments/assets/1d4c9496-945c-4937-913f-c07db443e347)

The Media Center version of the HiFi-Plus model is in the ideation stage. I see it to be a little more than just the same DAC on the boxed shape. The benefit of having DAC and AMP separated is the ability to fiddle with the audio in the middle, so I'm looking to implement volume and tone controls available on the front panel, as well as a tone correction button. I'm thinking of pumping the visual with the LED matrix or small OLED screen, which requires mastering certain mechanical tasks. Long story short, this is a work in progress. 

## Loud Raspberry Pi and Hat

![DSC_0013](https://github.com/sonocotta/raspberry-media-center/assets/5459747/a998abe0-6069-443d-b7e2-b12694eca55d)

Loud Raspberry Pi Media Center uses a dual MAX98357 HiFi DAC with a built-in highly efficient D-class amp to deliver 3 to 5W of music power directly to your speakers. It is not too loud, but also very simple to use and fun to play with. When DAC is not in use, it goes into shutdown mode, making sure no hissing will keep you up at night. It powers from a standard USB-C power source, like a phone charger, etc.

![DSC_0043](https://github.com/user-attachments/assets/5768a8c6-20bf-4841-bc8a-936c5d4e96a8)

Loud Raspberry Pi Hat is the same DAC and audio circuitry, again times two (because why not?). You can use it with any Raspberry Pi, while Raspberry Pi 5 users can use both pairs of speakers independently, while other Pis will produce the same audio on both ends. Hat will pull the juice from the Pi's 5V line, or power the Pi itself using screw connectors, so you can make sure enough power is delivered to both boards.

## Louder Raspberry Pi and Hat

![DSC_0008](https://github.com/sonocotta/raspberry-media-center/assets/5459747/8dc35e18-1663-4a5e-8cae-7efb642978d4)

Louder Raspberry Pi Media Center is a top-of-the-range model that uses a modern highly capable TAS5805M DAC and is aimed to be paired with medium-to-large speaker systems. With 25W per channel stereo output, it packs a punch and can easily enliven living quarters or dorm rooms. It is highly efficient, but much more demanding for power when cranked, therefore it uses USB-C Power Delivery to pull up to 65W from the wall power adapter. It can be used both with Wi-Fi and Ethernet (to make sure bad Wi-Fi would not interrupt the stream)

![DSC_0075](https://github.com/user-attachments/assets/05402627-2729-4a22-9f8c-58b8a5e4abcf)

Louder Raspberry Pi Hat drops the USB-PD in favor of an external power supply up to 28V (opposed to 20V over PD) and has a step-down converter onboard to deliver 5V to the Pi, so you need only a single power source for everything. Otherwise, it delivers audio through the same highly capable DAC, capable of driving large speakers or tearing apart small ones

## Features

|  | HiFi Raspberry Media Center | HiFi Raspberry Hat | HiFi-Plus Raspberry Hat | Loud Raspberry Media Center | Loud Raspberry Hat | Louder Raspberry Media Center | Louder Raspberry Hat |
|---|---|---|---|---|---|---|---|
| Image | ![DSC_0733 (copy 1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/990da9e7-b8fd-400c-b818-cb9352fd10a3) | ![DSC_0022](https://github.com/user-attachments/assets/529c8179-702b-4a8e-b789-2e27cf373e4a) | ![DSC_0046](https://github.com/user-attachments/assets/20f83b94-3b65-4430-a84d-bf31d79a499e) | ![DSC_0008](https://github.com/sonocotta/raspberry-media-center/assets/5459747/8846389c-f06c-4c36-88a7-63c0c789e944) | ![DSC_0023](https://github.com/user-attachments/assets/e82fb430-cd7a-44ed-9659-32136250b471) | ![DSC_0011-copy](https://github.com/sonocotta/raspberry-media-center/assets/5459747/fbedd926-8ff9-4f8a-8948-a3f96b013a6f) | ![DSC_0062](https://github.com/user-attachments/assets/82718e9e-f36c-4f4c-ba08-e4726fd38f84) |
| DAC | Single [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC | Dual [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC | Dual [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC working with <br /> [TPA3110D2](https://www.ti.com/product/TPA3110D2) D-Class amp | Dual I2S DAC [MAX98357](https://www.analog.com/en/products/max98357a.html) with built in D-Class amp | Quadruple I2S DAC [MAX98357](https://www.analog.com/en/products/max98357a.html) with built in D-Class amp | Stereo I2S DAC [TAS5805M](https://www.ti.com/product/TAS5805M) with built in D-Class amp | Stereo I2S DAC [TAS5805M](https://www.ti.com/product/TAS5805M) with built in D-Class amp |
| Output | 2.1 VRMS Line level output  -100 dB typical noise level | 2x 2.1 VRMS Line level output  -100 dB typical noise level | 4x 25W (8Ω, 1% THD+N) at 22V; 4x 22W (4Ω, 1% THD+N) at 16V <br /> 2x 40W (4Ω, 1% THD+N) at 20V | 2x 3W (8Ω);   2x 5W (4Ω) | 4x 3W (8Ω);   4x 5W (4Ω) | 2x 22W (8Ω, 1% THD+N); 2x 32W (4Ω, 1% THD+N) at 20V <br /> 1x 45W (4Ω, 1% THD+N) at 20V  | 2x 32W (8Ω, 1% THD+N) at 24V <br /> 1x 55W (4Ω, 1% THD+N) at 24V  |
| RGB LED | yes | none | none | yes | none | yes | none |
| IR input | yes | header only | none | yes | none | yes | header only |
| External relay driver | yes | none | none | no | none | yes | none |
| Onboard Serial Bridge | yes | none | none | yes | none | yes | none |
| Ethernet | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet | none | none | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet | none | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet | none |
| Powers from | 5V USB-C power adapter (up to 1 A)<br/> Triple [LP5907](https://www.ti.com/lit/ds/symlink/lp5907.pdf) 3.3 V Ultra-Low-Noise LDO | 5V from the host<br/> 5x [LP5907](https://www.ti.com/lit/ds/symlink/lp5907.pdf) 3.3 V Ultra-Low-Noise LDO | 8..26V from external source<br />powering host (up to 3A cont.) | 5V USB-C power adapter (up to 3 A) | 5V from the host (up to 4A)<br/> or 5V from screw connector (powering host) | 65W USB-C PD power adapter (25W/45W with limited power) | 7..28V from external source<br />powering host (up to 3A cont.) |
| Mechanical dimensions (WxHxD) | 88mm x 38mm x 100mm | 65mm x 30mm x 15mm | 70mm x 61mm x 20mm | 88mm x 38mm x 100mm | 65mm x 30mm x 20mm | 88mm x 38mm x 100mm | 65mm x 56mm x 20mm |

## Board Pinout

### Audio

|                    | I2S CLK | I2S DATA           | I2S WS | MAX98357A EN, Loud Media Center | MAX98357A EN, Loud Hat | TPA3110 EN, HiFi-Plus Hat
|--------------------|---------|--------------------|--------|--------|--------|--------|
| Raspberry Pi Zero  | 18      | 21                 | 19     |   4    |   5,6  |   5,6
| Raspberry Pi 2,3,4 | 18      | 21                 | 19     |   4    |   5,6  |   5,6
| Raspberry Pi 5     | 18      | 21, 23, 25, 27     | 19     |   4    |   5,6  |   5,6


### Peripheral 

|       | SPI CLK  |SPI MOSI| SPI MISO | LAN RES   | LAN CS   | LAN INT  |  WS2812 RGB LED |  RELAY EN | IR INPUT |
|-------|----------|--------|----------|-----------|-----------|-----------|---------|----------|----------|
| Raspberry Pi Zero (BCM) |  11      |  10    |   9      |   24      | 8         | 25        |     12  |  7      | 23        |

### Peripheral (Louder)

|       | I2C CLK | I2C DATA | DAC PWDN | DAC FAULT | PD POWER GOOD 
|-------|---------|----------|--------|--------|--------|
| Raspberry Pi Zero (BCM) | 3      | 2       | 4     |   26  |   16


## Software

Being a Raspberry Pi software selection is a vast space for experimentation. First things first, for any OS you need to configure DAC. Then we talk about different OS options.

### DAC Configuration - HiFi Raspberry Pi

You can use any distribution you like. The only change you need to make to enable hardware is to add 3 lines to the `/boot/config.txt`

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=hifiberry-dac
```

### DAC Configuration - Loud Raspberry Pi

As simple as the HiFi model, just add 3 lines to the `/boot/config.txt`

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
# pin 4 for Media center, pins 5,6 for Hat
dtoverlay=max98357a,sdmode-pin=4

```

### DAC Configuration - Louder Raspberry Pi

TAS5805M DAC is not supported by default Raspbian distribution, therefore some work needs to be done to enable it. [Linked repo](https://github.com/sonocotta/tas5805m-for-raspbian-paspberry-pi-zero) contains code and instructions on how to configure it. It will take you 5 minutes and one reboot.

### Bare OS Options

With the bare OS you're in full control of what to install and configure. It is totally up to your use case. 

|          | Raspbian                       | DietPi                             | PostmarketOS                               |
|----------|--------------------------------|------------------------------------|--------------------------------------------|
| Link     | [link](https://www.raspbian.org/)      | [link](https://dietpi.com/#download)       | [link](https://wiki.postmarketos.org/wiki/Devices) |
| Code     | [link](https://github.com/raspberrypi) | [link](https://github.com/MichaIng/DietPi) | [link](https://github.com/postmarketOS)            |
| Based on | Debian                         | Debian                             | Alpine                                     |
| Type     | Bare OS                        | Base OS                            | Bare OS                                    |

### Bare OS + Standard client services (Ansible short overview)

A minimal Raspberry Pi OS can be provisioned with the most-used media features via Ansible playbooks in this repo. Current functionality includes:

- Hardware setup: HiFi/Loud/Louder/Amped DAC configuration, optional W5500 SPI Ethernet overlay, HDMI audio disable, OLED/TFT enable, rotating-MAC fix for W5500.
- Core audio services:
  - PulseAudio (system-wide, network sink)
  - Spotify Connect (Raspotify/librespot)
  - Snapcast server and client (multi-room sync)
  - Apple AirPlay (Shairport Sync)
  - Logitech Media Server client (Squeezelite)
  - UPnP/DLNA renderer (gmediarender)
- DSP: CamillaDSP backend plus CamillaGUI frontend.
- Visualizers: LED bar, OLED, and TFT CamillaDSP VU meters.
- Convenience: tmux auto-attach profile, base init/updates.

Full details, requirements, and run steps are documented here:
- See the detailed guide: [Ansible Playbooks README](./firmware/media-center-via-ansible/README.md)

This setup integrates cleanly with Home Assistant, LMS, Mopidy, and other sources, including multi-room synchronization via Snapcast.

### Third-party Media Software

|  | HifiBerry OS | PiCorePlayer | MupiBox | Mopidy | Volumio | Moode | Balena Audio |
|---|---|---|---|---|---|---|---|
| Link | [link](https://www.hifiberry.com/hifiberryos) | [link](https://www.picoreplayer.org/) | [link](https://mupibox.de/anleitungen/installationsanleitung/einfache-installation/) | [link](https://mopidy.com/) | [link](https://volumio.com/get-started/) | [link](https://moodeaudio.org/) | [link](https://balena.io/) |
| Code | [link](https://github.com/hifiberry/hifiberry-os) | [link](https://github.com/piCorePlayer) | [link](https://github.com/splitti/MuPiBox?tab=readme-ov-file) | [link](https://github.com/mopidy/mopidy) | [link](https://github.com/volumio) | [link](https://github.com/moode-player) | [link](https://github.com/balena-io) |
| Based on | Debian | Tiny Core Linux | DietPi | Debian | Debian | Debian | Balena |
| Type | OS + Services | OS + Services | OS + Services | Services only | OS + Services | OS + Services | OS + Services |
| Remote management | No | No | No | No | No | No | Yes |
| **SW support** |  |  |  |  |  |  |  |
| **UI/UX features** |  |  |  |  |  |  |  |
| Web UI | Yes | Yes | Yes | Yes | Yes | Yes |  |
| Mobile App/UI | Yes | Yes |  | Yes | Yes | Yes |  |
| IR Remote | ? | Yes | ? | ? | ? | ? | Custom |
| **Server features** |  |  |  |  |  |  |  |
| LMS server |  | Yes | ? | No | ? | ? | ? |
| Local library | Yes |  | Yes | Yes | Yes | Yes |  |
| Radio providers | Yes | Yes |  | Yes | Yes | Yes |  |
| Snapcast server | ? | ? | ? | ? | ? | ? | Yes |
| **Client features** |  |  |  |  |  |  |  |
| LMS Client/Squeezelite | Yes | Yes | ? | No | Yes | Yes | ? |
| Airplay | Yes | Yes | ? | No | Yes | Yes | Yes |
| Spotify | Yes | Yes | Yes | No | Yes | Yes | Yes |
| Snapcast client (HA) | Yes | ? | ? | ? | ? | ? | Yes |
| Pulseaudio sink | ? | ? | ? | ? | ? | ? | Yes |
| UPNP/DLNA client |  | Yes |  |  | Yes | Yes |  |
| MPD |  |  |  |  |  | Yes |  |

### Volumio

[Volumio](https://volumio.com/get-started/) is a great piece of software, extremely popular with media center devices like Raspberry Media Center. 

With HiFi Raspberry and Loud Raspberry, things are fairly simple. Those DACs are supported out of the box. Select `HiFiBerry DAC` and `Adafruit MAX98357` in the DAC Model settings accordingly. Optionally, you may also create a `/boot/userconfig.txt` file and add the following config to enable W5500 Ethernet
```
[all]
dtoverlay=w5500
```

For Louder Raspberry, you'd need to perform a few more steps to configure a custom DAC.

<details>
  <summary>Setup instructions</summary>

First, get access to the terminal either from USB-Serial or from SSH. To enter the Serial terminal you'd need to add this line to `/boot/volumioconfig.txt`
```
enable_uart=1
```
You can enable SSH at [volumio.local/dev](http://volumio.local/dev) and log in using user `volumio` and password `volumio`

We're about to build kernel modules, so we need to install a few dependencies first (all commands going forward are running on the target host, ie Raspberry Pi)

```
sudo apt update && sudo apt install git raspberrypi-kernel-headers build-essential -y
```

Assuming you're in, first install build prerequisites (this will take a while, grab a coffee)
```
volumio kernelsource
```

Next, pull the DAC driver from the GitHub
```
cd ~
git clone https://github.com/sonocotta/tas5805m-for-raspbian-paspberry-pi-zero
cd tas5805m-for-raspbian-paspberry-pi-zero
```

Build kernel driver
```
cd /usr/src/rpi-linux && sudo find . -type d -exec chmod 755 {} \;  # no idea why permissions are not right, but this should fix it
cd ~/tas5805m-for-raspbian-paspberry-pi-zero
make all
```
If all goes well you should see no errors in the console
```
make -C /lib/modules/6.1.77+/build M=/home/volumio/dev/tas5805m-for-raspbian-paspberry-pi-zero modules
make[1]: Entering directory '/usr/src/rpi-linux'
  CC [M]  /home/volumio/dev/tas5805m-for-raspbian-paspberry-pi-zero/tas5805m.o
  MODPOST /home/volumio/dev/tas5805m-for-raspbian-paspberry-pi-zero/Module.symvers
  CC [M]  /home/volumio/dev/tas5805m-for-raspbian-paspberry-pi-zero/tas5805m.mod.o
  LD [M]  /home/volumio/dev/tas5805m-for-raspbian-paspberry-pi-zero/tas5805m.ko
make[1]: Leaving directory '/usr/src/rpi-linux'
```

Copy over kernel drivers to filesystem
```
sudo make install
```

Now let's compile and copy device tree
```
sudo apt install device-tree-compiler -y
sudo ./compile-overlay.sh
```

Next, we need to update the Volumio settings. Navigate to `/volumio/app/plugins/system_controller/i2s_dacs/dacs.json` file and add this line as the first choice in the Raspberry PI section
```
{"id":"louder-raspberry","name":"Louder Raspberry","overlay":"tas5805m,i2creg=0x2d","alsanum":"2","alsacard":"LouderRaspberry","mixer":"Master","modules":"tas5805m","script":"","needsreboot":"yes"},
```
![image](https://github.com/sonocotta/raspberry-media-center/assets/5459747/fdc339ac-3382-4a62-b817-cde6c5b81145)

Restart the Volumio service 

```
sudo systemctl restart volumio.service
```

Now you should be able to select Louder Raspberry in the DAC list, which will restart the Raspberry

![image](https://github.com/sonocotta/raspberry-media-center/assets/5459747/32c4cfeb-9b0b-4580-9f74-4d01c7ff4fa1)

At this stage it is not changing DT overlay automatically, I need to figure out why, but for now let's add it manually to the end of the `/boot/config.txt` file
```
#### Volumio i2s setting below: do not alter ####
dtoverlay=tas5805m,i2creg=0x2d
```

After reboot, you should be able to see new sound card via `aplay -l`
```
card 2: LouderRaspberry [Louder-Raspberry], device 0: bcm2835-i2s-tas5805m-amplifier tas5805m-amplifier-0 [bcm2835-i2s-tas5805m-amplifier tas5805m-amplifier-0] ^F Forward
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

Volumio will start playing using the right DAC on its own. Congratulations!

</details>

### Rotating MAC address on the W5500

On some systems W5500 driver will rotatre the chip's MAC address on each boot, which is quite annoying if you're binding DHCP server to them. There is a manual fix that can help with that

- Downloaded the [w5500 overlay](https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/w5500-overlay.dts) file
- uncomment this line and change the MAC to your liking //				local-mac-address = [aa bb cc dd ee ff];
- save the file as w5500-overlay-custom.dts
- create the binary with the following command: `dtc -I dts -O dtb -o w5500-custom.dtbo w5500-overlay-custom.dts`
- backup the original w5500.dtbo: `sudo mv /boot/overlays/w5500.dtbo /boot/overlays/w5500.dtboBACKUP`
- move the new .dtbo into the overlays directory: `sudo cp w5500-custom.dtbo /boot/overlays/w5500.dtbo`
- reboot and ip a will report the new MAC address

### TAS5805M DSP Capabilities

TAS5805M DAC (and his big brother TAS5825M) has quite a sophisticated DSP inside, which is mostly undiscovered by the community at the moment. Documentation of it is scarce. The only reasonable way to use it is to obtain a TI PurePath license and Hardware Development kit ($250 if you find it). This should allow the following skills

- 2.0, 1.1, 2.1, 0.1, and pretty much any other speaker configuration
- Loudness correction (or Tone correction)
- Soft clipping
- Individual EQ (16 of them I think)
- True mono and other routing configurations
- And many more

<details>
  <summary>PurePath screenshots</summary>

![image](https://github.com/user-attachments/assets/277d3901-87d8-4c73-84d0-7e2d697c300c)
![image](https://github.com/user-attachments/assets/9275106c-5fd4-49df-88fd-f44e654f4d70)
![image](https://github.com/user-attachments/assets/f919b864-0c3f-4e39-8409-f3199c799f02)
![image](https://github.com/user-attachments/assets/d8976520-b60d-4ca5-9a11-9e7a752d1c03)

</details>

I'm planning to dive deep into the topic (whenever I have time, haha) and provide optional settings for the most common configurations. This is a work in progress with no deadline set.

### TAS5805M DAC I2C address changes

While most of the boards come with an I2C address consistent with the driver's default value, some boards might appear on the 1-bit off address. It happens partially because I accidentally put a resistor with the wrong value on the 'address set' pin on one of the early batches, partially because of some other unknown quirks (it was once reported on the modern board). It seems that when TAS5805M reports an unexpected address, it sticks to it, so it is easy to fix.

The indication of that is when `journalctl` spits out errors about I2C communication failure. In that case, one can confirm the address issue by running the `i2cdetect -y 1` command. 

| config.txt | i2cdetect | journactl -k |
|------------|-----------|--------------|
| `dtoverlay=tas5805m,i2creg=0x2e` | <img width="374" height="142" alt="image" src="https://github.com/user-attachments/assets/e506a526-c56e-4d59-aa97-23d0d428d0c5" /> | <img width="669" height="164" alt="image" src="https://github.com/user-attachments/assets/4dcc8a87-dcf7-4690-94fc-27333c5bb771" />

In the picture above device is found on the `0x2d` address, while the driver hooks up to the `0x2e` address, indicated by the `UU` mark. In that case, the address needs to be changed in the `/boot/firmware/config.txt` file to reflect the actual address. The correct picture would look like below

| config.txt | i2cdetect | journactl -k |
|------------|-----------|--------------|
| `dtoverlay=tas5805m,i2creg=0x2d` | <img width="415" height="143" alt="image" src="https://github.com/user-attachments/assets/6e573494-fcdc-4757-bcc5-b0de835b7385" /> | <img width="678" height="158" alt="image" src="https://github.com/user-attachments/assets/53594da6-a387-42b9-ae68-6b4ceb95dbc0" /> |

On the Louder 2X Hat, though, the driver only hooks up to the _master_ DAC, which drives satellite speakers, the _slave_ DAC configuration is handled within driver code. So the expected output from the `i2cdetect` command is `UU` mark on the master DAC and `0x2x` mark on the slave DAC

```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- UU 2e --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- —
```

## Hardware

Please visit the [hardware](/hardware/) section for board schematics and PCB designs. Note that PCBs are shared as multi-layer PDFs as well as Gerber archives.

### HiFi Raspberry Pi

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0733 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/ba11555c-9e0c-47eb-b77e-4ac4b4ca1a99) | ![DSC_0739 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/b438fd68-108c-42b6-b3b1-4c2507fbd568)

### HiFi Raspberry Hat

| Image |
|-------|
| ![image](https://github.com/user-attachments/assets/20753c79-cd01-4ef0-9c34-f24b8fe19cf4)

### HiFi-Plus Raspberry Hat

| Image |
|-------|
| ![image](https://github.com/user-attachments/assets/3c01a8b5-6dec-4063-921b-70df68d4b005)

### Loud Raspberry Pi

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0008_small JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/7c939831-95e4-467d-874e-b2a65ba0960c) | ![DSC_0016_small JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/999abf17-8c0b-464a-b1b0-50d00ee8cb4b)

### Loud Raspberry Hat

| Image |
|-------|
| ![image](https://github.com/user-attachments/assets/81ecd4dd-5fe1-41eb-aed7-153bf5b99cf8)

### Louder Raspberry Pi

| Front | Back | PCB |
|---|---|---|
|![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0011-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/913adcb9-b5fe-4ffa-b443-bdbba04693bc) | ![DSC_0004-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/adebf060-a3bd-45b9-8474-9397e695b0d7)

### Louder Raspberry Hat

| Image |
|-------|
| ![image](https://github.com/user-attachments/assets/4ac30e1b-8d07-4bda-a3ee-99d91c4dc1e9)

### Power considerations

#### Hifi and Loud Raspberry

According to the manufacturer, Raspberry Pi Zero requires at least 1 Amp of 5V line, and each of the Loud Raspberry DAC needs at least 1 Amp extra. With the total budget requirement of 3 Amps, it is within specs for a non-PD USB-C 5V power line. I've decided not to use USB-PD for The Loud model. Just make sure your power adapter is capable of 3 Amps (or keep a reasonable volume if it is not).

HiFi Raspberry barely uses extra power compared to what the Raspberry Pi Zero board itself needs. No special requirements are there.

#### Louder Raspberry

For Louder Raspberry, it is clearly not an option. You'd need a PD-enabled power adapter to run the board. Ideally, you should supply a 20V 3.25 Amp capable power source, common for modern laptops (Dell, HP, and Lenovo all tested and work perfectly). However, pretty much any 9V/12V/20V PD-enabled power adapter will work, most typically phone chargers with a quick charge option. The smallest of the family is a 25W model, which is plenty enough for both Raspberry Pi and DAC.

The interesting part was all the phone and laptop chargers I used for the test (around five different makes of each), sounded great, with no hissing, no popping. (Apart from the Apple ones, they didn’t work. Likely they have Apple-specific PD protocol). This is probably because modern devices have become so noise-sensitive that manufacturers have been forced to do good work on noise levels.

<details>
  <summary>Tested and perfectly working models are (others may be available)</summary>

| Model   | Image   |
|-------------------------------|---------------------------------|
| [65W USB-C Lenovo ThinkPad Laptop Charger Replacement Power Adapter](https://www.aliexpress.com/item/1005005994445557.html)  | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/27614db3-de35-4054-8450-9845a09f6381)
| [65W 45W 20V 3.25A Type-C PD Laptop Charger](https://www.aliexpress.com/item/1005006086701848.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/266a9bed-dde5-4869-aa31-84176b0a6608)
| [120W Gan Type-C PD Charger](https://www.aliexpress.com/item/1005006806666186.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/f42d4c8c-879b-494c-ac18-dd18ace322e7)
| [45W Type-C PD Mobile Phone Wall Adapter](https://www.aliexpress.com/item/1005006713008533.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/110bb6f9-7014-4dfc-8fd8-3bc99b269e9c)

</details>

#### Serial and USB-PD

One caveat is that, since Raspberry Pi requires 5V to run and the input voltage is in the range of 5 to 20 volts, I failed to find a step-down converter that (a) supports this wide input range and (b) can run in no-dropout mode (meaning keep 5V output on 5V input). If you know one, please let me know. But at this moment **you have to supply more than 5V over USB (meaning 9V in PD standards) to start the Raspberry**.

Now, you have USB power delivery and the Serial on the same bus, how should this work then? When you're developing, you may not require the full power of the DAC, and it will happily work with 5V input (limited to something like 5W of music power per channel). you just supply 5V to the Raspberry using a micro-USB cable, while USB-C will power the DAC with 5V and give you a Serial console at the same time

![image](https://github.com/sonocotta/raspberry-media-center/assets/5459747/05784784-128f-443f-b0fc-9a4ee6f2eae1)

### Relay Driver

HiFi version of the Raspberry Media Center has an internal driver for the external relay. It has a back-facing diode to shunt any coil-inducted currents. Driver is an open-drain output with the following states

| Driver Pin State (IO7)  | Output state  | Relay connected between OUT and +5V |
|---|---|---|
| Floating (pulled low with 100K resistor) or <br/> LOW | High impedance | INACTIVE (switched OFF)
| HIGH | Pulled to GND | ACTIVE (switched ON)

Schematics:

![image](https://github.com/sonocotta/raspberry-media-center/assets/5459747/4b81a844-ba2f-48d4-a5e8-0c9e91e6573d)

External relay can be connected directly between OUT and +5V pins (1st and 3rd pins, mid pin being GND)

### IR reader

<details>
  <summary>Setup instructions</summary>
  
Start by configuring IR device-tree overlay in the `/boot/config.txt` file

```
# Enable IR reader on GPIO23
dtoverlay=gpio-ir,gpio_pin=23
```

After reboot, you should be able to see `/dev/lirc0` device

```
$ ls -al /dev/lirc0 
crw-rw---- 1 root video 251, 0 Jun 17 21:51 /dev/lirc0

```

There are multiple ways you can capture IR signals using `/dev/lirc0` device, one of them is to use `lirc` utilities by installing them via 

```
$ sudo apt install lirc -y
```

Next, we need to pull the remote configuration or create new one by training `lirc`. First path is much easier, you may find your remote in the library [here](https://sourceforge.net/p/lirc-remotes/code/ci/master/tree/remotes/). Pull it into lirc config by running

```
$ cd /etc/lirc/lircd.conf.d/ 
$ sudo wget -O aa59-00741a.lircd.conf https://sourceforge.net/p/lirc-remotes/code/ci/master/tree/remotes/samsung/aa59-00741a.lircd.conf?format=raw
$ sudo service lircd restart
```

To be sure, I've updated also `/etc/lirc/lirc_options.conf` changing 2 lines
```
driver          = default
device          = /dev/lirc0
```

Next, capture incoming IR codes by running 

```
$ irw
00000000e0e0e01f 00 KEY_VOLUMEUP Samsung_TV
00000000e0e0e01f 01 KEY_VOLUMEUP Samsung_TV
00000000e0e0e01f 00 KEY_VOLUMEUP Samsung_TV
00000000e0e0d02f 00 KEY_VOLUMEDOWN Samsung_TV
00000000e0e0d02f 01 KEY_VOLUMEDOWN Samsung_TV
```

### RGB Led

The tested method of controlling RGB LED is to use [rpi_ws281x](https://github.com/jgarff/rpi_ws281x) library, available as [rpi-ws281x-python](https://github.com/rpi-ws281x/rpi-ws281x-python/tree/master) module. You can install it with `pip`. This library uses PWN capabilities of the GPIO and does not require any specific device tree configuration. The only configuration that you'd need in any of the [provided examples](https://github.com/rpi-ws281x/rpi-ws281x-python/tree/master/examples) is below

```
# LED strip configuration:
LED_COUNT = 1         
LED_PIN = 12          
LED_FREQ_HZ = 800000  
LED_DMA = 10          
LED_BRIGHTNESS = 255  
LED_INVERT = False    
LED_CHANNEL = 0       
```

Unfortunately, this library uses direct access to memory, so you need to run it as `root`. 

</details>

### Raspberry Pi 5 note

Raspberry Pi 5 is the first one that allows driving multiple I2S data lines using the same interface. What it means in practice is that while all older Pis have just 3 I2S lines (CLK, WS, DATA), Pi5 supports up to 4 Data lines (CLK, WS, D0, D1, D2, D3), capable of driving 4 independent audio interfaces. 

All Raspberry Pi hats have experimental support for alternative data lines. You need to short some solder bridge to use it, though. In theory, it allows for configuring Hats to use different pins and stack them together to create 4 individual stereo interfaces (8 channels in total) using the same device.  

| HiFi Hat | HiFi-Plus Hat | Loud Hat |
|----------|----------|----------|
| ![image](https://github.com/user-attachments/assets/3c126719-d0ca-40b3-92d4-5b542fd0c335) | ![image](https://github.com/user-attachments/assets/496798fa-75e0-4205-bcec-b438e2711599) | ![image](https://github.com/user-attachments/assets/cbbade50-5d49-4a8b-954c-81f5a1c80550)

The configuration value that allows this is quite simply

```
dtoverlay=hifiberry-dac8x
```

## Demo

[![Loud Raspberry Pi Media Center audio test](http://img.youtube.com/vi/PloeejWgDLs/0.jpg)](http://www.youtube.com/watch?v=PloeejWgDLs "Loud Raspberry Pi Media Center audio test")

## Where to buy

You may support our work by ordering this product at Tindie
- [HiFi Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/raspberry-pi-media-center/)
- [HiFi Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/hifi-raspberry-pi-hat/)
- HiFi-Plus Raspberry Pi Hat - coming soon...
- [Loud Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/loud-raspberry-pi-media-center/)
- [Loud Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/loud-raspberry-pi-hat/)
- [Louder Raspberry Pi Media Center](https://www.tindie.com/products/sonocotta/louder-raspberry-pi-media-center/)
- [Louder Raspberry Pi Hat](https://www.tindie.com/products/sonocotta/louder-raspberry-pi-hat/)

## Press mentions

- [Louder Raspberry Pi is an open-source home media center that is powered by Raspberry Pi Zero and a TI TAS5805M DAC](https://www.cnx-software.com/2024/04/22/louder-raspberry-pi-open-source-home-media-center-raspberry-pi-zero-2-w-ti-tas5805m-dac/)
- [Sonocotta's Raspberry Pi Media Center Is a Sleek Compact Streaming Box for Your Hi-Fi Setup](https://www.hackster.io/news/sonocotta-s-raspberry-pi-media-center-is-a-sleek-compact-streaming-box-for-your-hi-fi-setup-460d2170c156)
- [Open Hi-Fi Devices Developed Through The Raspberry Pi Media Center Project](https://www.gamingdeputy.com/open-hi-fi-devices-developed-through-the-raspberry-pi-media-center-project/)
