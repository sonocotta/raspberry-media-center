# Raspberry Pi Media Center

![Open Source Hardware](/images/open-source-hardware-logo.png)
![Open Source Software](/images/open-source-software-logo.png)
<a href="https://www.tindie.com/stores/sonocotta/?ref=offsite_badges&utm_source=sellers_andrey-malyshenko&utm_medium=badges&utm_campaign=badge_medium"><img src="https://d2ss6ovg47m0r5.cloudfront.net/badges/tindie-mediums.png" alt="I sell on Tindie" width="150" height="78"></a>
<br />
[![Dev Chat](https://img.shields.io/discord/1233306441469657140?logo=discord&label=discord&style=flat-square)](https://discord.gg/PtnaAaQMpS)


![DSC_0005](https://github.com/sonocotta/raspberry-media-center/assets/5459747/37bf52d2-3fde-4fbb-b98e-35fb1b48ebe4)

Raspberry Pi Media Center is a series of Raspberry Pi Zero-based media center devices. They share a similar look, and compared to my earlier designs, they have a great-looking aluminum case.

## Table of Contents

- [Raspberry Pi Media Center](#raspberry-pi-media-center)
  - [Table of Contents](#table-of-contents)
  - [Motivation](#motivation)
  - [Raspberry Pi HiFi](#raspberry-pi-hifi)
  - [Loud Raspberry Pi](#loud-raspberry-pi)
  - [Louder Raspberry Pi](#louder-raspberry-pi)
  - [Features](#features)
  - [Board Pinout](#board-pinout)
    - [Audio](#audio)
    - [Peripheral](#peripheral)
    - [Peripheral (Louder)](#peripheral-louder)
  - [Software](#software)
    - [DAC Configuration - HiFi Raspberry Pi](#dac-configuration---hifi-raspberry-pi)
    - [DAC Configuration - HiFi Raspberry Pi](#dac-configuration---hifi-raspberry-pi-1)
    - [DAC Configuration - Louder Raspberry Pi](#dac-configuration---louder-raspberry-pi)
    - [Bare OS Options](#bare-os-options)
    - [Bare OS + Standard client services](#bare-os--standard-client-services)
    - [Third-party Media Software](#third-party-media-software)
  - [Hardware](#hardware)
    - [HiFi Raspberry Pi](#hifi-raspberry-pi)
    - [Loud Raspberry Pi](#loud-raspberry-pi-1)
    - [Louder Raspberry Pi](#louder-raspberry-pi-1)
    - [Power considerations](#power-considerations)
      - [Hifi and Loud Raspberry](#hifi-and-loud-raspberry)
      - [Louder Raspberry](#louder-raspberry)
      - [Serial and USB-PD](#serial-and-usb-pd)
  - [Demo](#demo)
  - [Where to buy](#where-to-buy)
  - [Press mentions](#press-mentions)

## Motivation

I did few audio projects in the past, some using [ESP32](https://hackaday.io/project/173620-loud-esp), some using larger [Orange Pi](https://hackaday.io/project/191936-orange-pi-home-media-center) and [Raspberry Pi](https://hackaday.io/project/162373-orangepi-zero-pulse-music-server-using-i2s-dac) devices. Each has its pros and cons, and with each iteration, I'm trying to focus on the details that were working best for me, while actually using them. 

What is special about the Raspberry eco-system is of course its community support. Being a not-so-strong software developer, I often have to rely on the work that other people did and baked into the base Raspbian image. Attaching a DAC, Ethernet, and IR reader is as simple as adding 3 lines into the `config.txt` file

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=hifiberry-dac
```

All the device tree definitions, kernel drivers, and dependency packages are already in place, believe it or not. 

Sure, compared to the ESP32 platform it is not as lightweight. It requires more power, it takes some time to boot. But when it comes to rapid development, there is nothing like the Raspberry Pi.

## Raspberry Pi HiFi

Raspberry Pi HiFi is a first-in-line product that uses the legendary PCM5100 series DAC with supreme audio quality. It exposes line-level output that you can plug into a stereo amplifier. Spend as much as you need on the external amp to deliver the sound you like (personally I prefer late 80's audio gear).

![DSC_0727](https://github.com/sonocotta/raspberry-media-center/assets/5459747/029e5175-1ee1-4876-8ba3-91d49730c29f)

## Loud Raspberry Pi

Loud Raspberry Pi uses a dual MAX98357 HiFi DAC with a built-in highly efficient D-class amp to deliver 3 to 5W of music power directly to your speakers. It is not too loud, but also very simple to use and fun to play with. It powers from a standard USB-C power source, like a phone charger, etc.

![DSC_0013](https://github.com/sonocotta/raspberry-media-center/assets/5459747/a998abe0-6069-443d-b7e2-b12694eca55d)

## Louder Raspberry Pi

Louder Raspberry Pi is a top-of-the-range model that uses a modern highly capable TAS5805M DAC and is aimed to be paired with medium-to-large speaker systems. With 25W per channel stereo output, it packs a punch and can easily enliven living quarters or dorm rooms. It is highly efficient, but much more demanding for power when cranked, therefore it uses USB-C Power Delivery to pull up to 65W from the wall power adapter. It can be used both with Wi-Fi and Ethernet (to make sure bad Wi-Fi would not interrupt the stream)

![DSC_0008](https://github.com/sonocotta/raspberry-media-center/assets/5459747/8dc35e18-1663-4a5e-8cae-7efb642978d4)

## Features

|                               | HiFi Raspberry                                                                                                      | Loud Raspberry                                                                                       | Louder Raspberry                                                                         |
|-------------------------------|---------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| Image                         |      ![DSC_0733 (copy 1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/990da9e7-b8fd-400c-b818-cb9352fd10a3) | ![DSC_0008](https://github.com/sonocotta/raspberry-media-center/assets/5459747/8846389c-f06c-4c36-88a7-63c0c789e944) |  ![DSC_0011-copy](https://github.com/sonocotta/raspberry-media-center/assets/5459747/fbedd926-8ff9-4f8a-8948-a3f96b013a6f) |
| DAC                           | [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC                                                    | Dual I2S DAC [MAX98357](https://www.analog.com/en/products/max98357a.html) with built in D-Class amp | Stereo I2S DAC [TAS5805M](https://www.ti.com/product/TAS5805M) with built in D-Class amp |
| Output                        | 2.1 VRMS Line level output <br/> -100 dB typical noise level                                                        | 2x 3W (8Ω);   2x 5W (4Ω)                                 | 2x 22W (8Ω, 1% THD+N); 2x 32W (4Ω, 1% THD+N)                                                                                      |
| RGB LED                       | yes                                                                                                                 | yes                                                                                                  | yes                                                                                      |
| External relay driver         | yes                                                                                                                 | no                                                                                                   | yes                                                                                       |
| Ethernet                      | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                                              | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                               | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                   |
| Powers from                   | 5V USB-C power adapter (up to 1 A)<br/>Triple [LP5907](https://www.ti.com/lit/ds/symlink/lp5907.pdf) 3.3 V Ultra-Low-Noise LDO | 5V USB-C power adapter (up to 3 A)                                                                          | 65W USB-C PD power adapter (25W/45W with limited power)                                                             |
| Mechanical dimensions (WxHxD) | 88mm x 38mm x 100mm                                                                                                 | 88mm x 38mm x 100mm                                                                                  | 88mm x 38mm x 100mm                                                                      |

## Board Pinout

### Audio

|       | I2S CLK | I2S DATA | I2S WS | MAX98357A EN (Loud only)
|-------|---------|----------|--------|--------|
| Raspberry Pi Zero (BCM) | 18      | 21       | 19     |   4

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

### DAC Configuration - HiFi Raspberry Pi

As simple as HiFi model, just add 3 lines to the `/boot/config.txt`

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=max98357a-overlay
```

### DAC Configuration - Louder Raspberry Pi

TAS5805M DAC is not supported by default Raspbian distribution, therefore some work needs to be done to enable it. [Linked repo](https://github.com/sonocotta/tas5805m-for-raspbian-paspberry-pi-zero) contains code and instruction on how to configure it. It will take you 5 minutes and one reboot.

### Bare OS Options

With the bare OS you're in full control of what to install and configure. IT is totally up to your use case. 

|          | Raspbian                       | DietPi                             | PostmarketOS                               |
|----------|--------------------------------|------------------------------------|--------------------------------------------|
| Link     | [link](https://www.raspbian.org/)      | [link](https://dietpi.com/#download)       | [link](https://wiki.postmarketos.org/wiki/Devices) |
| Code     | [link](https://github.com/raspberrypi) | [link](https://github.com/MichaIng/DietPi) | [link](https://github.com/postmarketOS)            |
| Based on | Debian                         | Debian                             | Alpine                                     |
| Type     | Bare OS                        | Base OS                            | Bare OS                                    |

### Bare OS + Standard client services

This is a work in progress and the idea is to have a bare minimum OS (be it Raspbian, DietPi, or Armbian) and install the most used client services via the Ansible playbook. I will add more details, as soon as I have working samples, but planned things to add are

- [ ] Spotify Connect
- [ ] Apple Airplay
- [ ] Mpd
- [ ] Network Pulsesink
- [ ] UPNP sink
- [ ] Snapcast client
- [ ] Slimproto client
- [ ] Basic UI with configuration

This will allow to integrate into existing media sources with Home Assistant, LMS, or Mopidy instance, including multi-room sync.

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

## Hardware

Please visit the [hardware](/hardware/) section for board schematics and PCB designs. Note that PCBs are shared as multi-layer PDFs as well as Gerber archives.

### HiFi Raspberry Pi

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0733 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/ba11555c-9e0c-47eb-b77e-4ac4b4ca1a99) | ![DSC_0739 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/b438fd68-108c-42b6-b3b1-4c2507fbd568)

### Loud Raspberry Pi

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0008_small JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/7c939831-95e4-467d-874e-b2a65ba0960c) | ![DSC_0016_small JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/999abf17-8c0b-464a-b1b0-50d00ee8cb4b)

### Louder Raspberry Pi

| Front | Back | PCB |
|---|---|---|
|![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0011-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/913adcb9-b5fe-4ffa-b443-bdbba04693bc) | ![DSC_0004-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/adebf060-a3bd-45b9-8474-9397e695b0d7)

### Power considerations

#### Hifi and Loud Raspberry

According to the manufacturer Raspberry Pi Zero requires at least 1 Amp of 5V line, and each of the Loud Raspberry DAC needs at least 1 Amp extra. With the total budget requirement of 3 Amps, it is within specs for a non-PD USB-C 5V power line. I've decided not to use USB-PD for The Loud model. Just make sure your power adapter is capable of 3 Amps (or keep a reasonable volume if it is not).

HiFi Raspberry barely uses extra power compared to what the Raspberry Pi Zero board itself needs. No special requirements are there.

#### Louder Raspberry

For Louder Raspberry, it is clearly not an option. You'd need a PD-enabled power adapter to run the board. Ideally, you should supply a 20V 3.25 Amp capable power source, common for modern laptops (Dell, HP, and Lenovo all tested and work perfectly). However, pretty much any 9V/12V/20V PD-enabled power adapter will work, most typically phone chargers with a quick charge option. The smallest of the family is a 25W model, which is plenty enough for both Raspberry Pi and DAC.

The interesting part was all the phone and laptop chargers I used for the test (around five different makes of each), sounded great, with no hissing, no popping. (Apart from the Apple ones, they didn’t work. Likely they have Apple-specific PD protocol). This is probably because modern devices have become so noise-sensitive that manufacturers have been forced to do good work on noise levels.

Tested and perfectly working models are (others may be available)

| Model   | Image   |
|-------------------------------|---------------------------------|
| [65W USB-C Lenovo ThinkPad Laptop Charger Replacement Power Adapter](https://www.aliexpress.com/item/1005005994445557.html)  | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/27614db3-de35-4054-8450-9845a09f6381)
| [65W 45W 20V 3.25A Type-C PD Laptop Charger](https://www.aliexpress.com/item/1005006086701848.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/266a9bed-dde5-4869-aa31-84176b0a6608)
| [120W Gan Type-C PD Charger](https://www.aliexpress.com/item/1005006806666186.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/f42d4c8c-879b-494c-ac18-dd18ace322e7)
| [45W Type-C PD Mobile Phone Wall Adapter](https://www.aliexpress.com/item/1005006713008533.html) | ![image](https://github.com/sonocotta/orange-pi-media-center/assets/5459747/110bb6f9-7014-4dfc-8fd8-3bc99b269e9c)

#### Serial and USB-PD

One caveat is that, since Raspberry Pi requires 5V to run and the input voltage is in the range of 5 to 20 volts, I failed to find a step-down converter that (a) supports this wide input range and (b) can run in no-dropout mode (meaning keep 5V output on 5V input). If you know one, please let me know. But at this moment **you have to supply more than 5V over USB (meaning 9V in PD standards) to start the Raspberry**.

Now, you have USB power delivery and the Serial on the same bus, how should this work then? When you're developing, you may not require the full power of the DAC, and it will happily work with 5V input (limited to something like 5W of music power per channel). you just supply 5V to the Raspberry using a micro-USB cable, while USB-C will power the DAC with 5V and give you a Serial console at the same time

![image](https://github.com/sonocotta/raspberry-media-center/assets/5459747/05784784-128f-443f-b0fc-9a4ee6f2eae1)

## Demo

[![Loud Raspberry Pi Media Center audio test](http://img.youtube.com/vi/PloeejWgDLs/0.jpg)](http://www.youtube.com/watch?v=PloeejWgDLs "Loud Raspberry Pi Media Center audio test")

## Where to buy

You may support our work by ordering this product at Tindie
- [HiFi Raspberry Pi](https://www.tindie.com/products/sonocotta/raspberry-pi-media-center/)
- [Loud Raspberry](https://www.tindie.com/products/sonocotta/loud-raspberry-pi-media-center/)
- [Louder Raspberry Pi](https://www.tindie.com/products/sonocotta/louder-raspberry-pi-media-center/) 

## Press mentions

- [Louder Raspberry Pi is an open-source home media center that is powered by Raspberry Pi Zero and a TI TAS5805M DAC](https://www.cnx-software.com/2024/04/22/louder-raspberry-pi-open-source-home-media-center-raspberry-pi-zero-2-w-ti-tas5805m-dac/)
- [Sonocotta's Raspberry Pi Media Center Is a Sleek Compact Streaming Box for Your Hi-Fi Setup](https://www.hackster.io/news/sonocotta-s-raspberry-pi-media-center-is-a-sleek-compact-streaming-box-for-your-hi-fi-setup-460d2170c156)
- [Open Hi-Fi Devices Developed Through The Raspberry Pi Media Center Project](https://www.gamingdeputy.com/open-hi-fi-devices-developed-through-the-raspberry-pi-media-center-project/)
