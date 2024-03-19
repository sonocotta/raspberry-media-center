# Raspberry Pi Media Center

![Open Source Hardware](/images/open-source-hardware-logo.png)
![Open Source Software](/images/open-source-software-logo.png)

![DSC_0733](https://github.com/sonocotta/raspberry-media-center/assets/5459747/2a6729d0-b9ed-4b83-95d5-de66f2ad8bb1)

Raspberry Pi Media Center is a series of Raspberry Pi Zero based media center devices. They share a similar look, and compared to my earlier designs, they have a great-looking aluminum case.

## Motivation

I did few audio projects in the past, some using [ESP32](https://hackaday.io/project/173620-loud-esp), some using larger [Orange Pi](https://hackaday.io/project/191936-orange-pi-home-media-center) and [Raspberry Pi](https://hackaday.io/project/162373-orangepi-zero-pulse-music-server-using-i2s-dac) devices. Each has its pros and cons, and each iteration I'm trying to focus on the details that were working best for me, while actually using them. 

What is special about the Raspberry eco-system is of course its community support. Being a not-so-strong software developer, I often have to rely on the work that other people did and baked into the base Raspbian image. Attaching a DAC, Ethernet and IR reader is as simple as adding 3 lines into `config.txt` file

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

## Louder Raspberry Pi

This is still a work in progress. Spoiler alert: it uses TI TAS5805M DAC with dual amped output.

## Features

- [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC
- 2.1 VRMS Line level output
- -100 dB typical noise level
- Triple [LP5907](https://www.ti.com/lit/ds/symlink/lp5907.pdf) 3.3 V Ultra-Low-Noise LDO
- Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet
- 5V USB-C power adapter
- Mechanical dimensions (WxHxD): 88mm x 38mm x 100mm

## Board Pinout

### Audio

|       | I2S CLK | I2S DATA | I2S WS | 
|-------|---------|----------|--------|
| Raspberry Pi Zero | 18      | 21       | 19     | 

### Peripheral

|       | SPI CLK  |SPI MOSI| SPI MISO | LAN RES   | LAN CS   | LAN INT  |  WS2812 RGB LED |  RELAY EN | IR INPUT |
|-------|----------|--------|----------|-----------|-----------|-----------|---------|----------|----------|
| ESP32 |  11      |  10    |   9      |   24      | 8         | 25        |     12  |  7      | 23        |

## Software samples

You can use any distribution you like. The only change you need to make to enable hardware is to add 3 lines to the `/boot/config.txt`

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=hifiberry-dac
```

## Hardware

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0733 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/ba11555c-9e0c-47eb-b77e-4ac4b4ca1a99) | ![DSC_0739 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/b438fd68-108c-42b6-b3b1-4c2507fbd568)

Please visit [hardware](/hardware/) section for board schematics and PCB designs. Note that PCBs are shared as multi-layer PDFs as well as Gerber archives.

## Where to buy

You may support our work by ordering this product at Tindie (coming soon)
