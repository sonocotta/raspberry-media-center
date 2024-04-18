# Raspberry Pi Media Center

![Open Source Hardware](/images/open-source-hardware-logo.png)
![Open Source Software](/images/open-source-software-logo.png)

![DSC_0015](https://github.com/sonocotta/raspberry-media-center/assets/5459747/a7240800-ea4e-4be0-8ec3-488d34f0cbdf)

Raspberry Pi Media Center is a series of Raspberry Pi Zero based media center devices. They share a similar look, and compared to my earlier designs, they have a great-looking aluminum case.

## Motivation

I did few audio projects in the past, some using [ESP32](https://hackaday.io/project/173620-loud-esp), some using larger [Orange Pi](https://hackaday.io/project/191936-orange-pi-home-media-center) and [Raspberry Pi](https://hackaday.io/project/162373-orangepi-zero-pulse-music-server-using-i2s-dac) devices. Each has its pros and cons, and with each iteration I'm trying to focus on the details that were working best for me, while actually using them. 

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

Work in progress. Spoiler alert, it uses dual MAX98357 DACs with a built-in amp. It is not too loud, but also very simple to use and fun to play with.

## Louder Raspberry Pi

Louder Raspberry Pi is a top-of-the-range model that uses a modern highly capable TAS5805M DAC and is aimed to be paired with medium-to-large speaker systems. With 25W per channel stereo output, it packs a punch and can easily enliven living quarters or dorm rooms. It is highly efficient, but much more demanding for power when cranked, therefore it uses USB-C Power Delivery to pull up to 65W from the wall power adapter. It can be used both with Wi-Fi and Ethernet (to make sure bad Wi-Fi would not interrupt the stream)

![DSC_0008](https://github.com/sonocotta/raspberry-media-center/assets/5459747/8dc35e18-1663-4a5e-8cae-7efb642978d4)

## Features

|                               | HiFi Raspberry                                                                                                      | Loud Raspberry                                                                                       | Louder Raspberry                                                                         |
|-------------------------------|---------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| Image                         |      ![DSC_0733 (copy 1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/990da9e7-b8fd-400c-b818-cb9352fd10a3) | WIP |  ![DSC_0011-copy](https://github.com/sonocotta/raspberry-media-center/assets/5459747/fbedd926-8ff9-4f8a-8948-a3f96b013a6f) |
| DAC                           | [PCM5100A](https://www.ti.com/product/PCM5100A) 32bit Stereo DAC                                                    | Dual I2S DAC [MAX98357](https://www.analog.com/en/products/max98357a.html) with built in D-Class amp | Stereo I2S DAC [TAS5805M](https://www.ti.com/product/TAS5805M) with built in D-Class amp |
| Output                        | 2.1 VRMS Line level output <br/> -100 dB typical noise level                                                        | 2x 3W                                                                                                | 2x 22W at 20V over USB-PD                                                                |
| IR reader                     | yes                                                                                                                 | yes                                                                                                  | yes                                                                                      |
| RGB LED                       | yes                                                                                                                 | yes                                                                                                  | yes                                                                                      |
| External relay driver         | yes                                                                                                                 | no                                                                                                   | yes                                                                                       |
| Ethernet                      | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                                              | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                               | Wiznet [W5500](https://www.wiznet.io/product-item/w5500/) SPI Ethernet                   |
| Powers from                   | 5V USB-C power adapter <br/>Triple [LP5907](https://www.ti.com/lit/ds/symlink/lp5907.pdf) 3.3 V Ultra-Low-Noise LDO | 25W USB-C PD power adapter                                                                           | 65W USB-C PD power adapter                                                               |
| Mechanical dimensions (WxHxD) | 88mm x 38mm x 100mm                                                                                                 | 88mm x 38mm x 100mm                                                                                  | 88mm x 38mm x 100mm                                                                      |

## Board Pinout

### Audio

|       | I2S CLK | I2S DATA | I2S WS | 
|-------|---------|----------|--------|
| Raspberry Pi Zero (BCM) | 18      | 21       | 19     | 

### Peripheral

|       | SPI CLK  |SPI MOSI| SPI MISO | LAN RES   | LAN CS   | LAN INT  |  WS2812 RGB LED |  RELAY EN | IR INPUT |
|-------|----------|--------|----------|-----------|-----------|-----------|---------|----------|----------|
| Raspberry Pi Zero (BCM) |  11      |  10    |   9      |   24      | 8         | 25        |     12  |  7      | 23        |

### Peripheral (Louder)

|       | I2C CLK | I2C DATA | DAC PWDN | DAC FAULT | PD POWER GOOD 
|-------|---------|----------|--------|--------|--------|
| Raspberry Pi Zero (BCM) | 3      | 2       | 4     |   26  |   16


## Software samples

### HiFi and Loud Raspberry Pi

You can use any distribution you like. The only change you need to make to enable hardware is to add 3 lines to the `/boot/config.txt`

```
dtoverlay=gpio-ir,gpio_pin=23
dtoverlay=w5500
dtoverlay=hifiberry-dac
```

### Louder Raspberry Pi

TAS5805M DAC is not supported by default Raspbian distribution, therefore some work needs to be done to enable it. [Linked repo](https://github.com/sonocotta/tas5805m-for-raspbian-paspberry-pi-zero) contains code and instruction on how to configure it. It will take you 5 minutes and one reboot.

## Hardware

### HiFi Raspberry Pi

| Front | Back | PCB |
|---|---|---|
| ![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0733 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/ba11555c-9e0c-47eb-b77e-4ac4b4ca1a99) | ![DSC_0739 (copy 1) JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/b438fd68-108c-42b6-b3b1-4c2507fbd568)

### Louder Raspberry Pi

| Front | Back | PCB |
|---|---|---|
|![DSC_0730 (copy 1) JPG-mh (1)](https://github.com/sonocotta/raspberry-media-center/assets/5459747/c281dab2-9842-4760-be31-8ad52d836f4d) | ![DSC_0011-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/913adcb9-b5fe-4ffa-b443-bdbba04693bc) | ![DSC_0004-copy JPG-mh](https://github.com/sonocotta/raspberry-media-center/assets/5459747/adebf060-a3bd-45b9-8474-9397e695b0d7)

Please visit [hardware](/hardware/) section for board schematics and PCB designs. Note that PCBs are shared as multi-layer PDFs as well as Gerber archives.

## Where to buy

You may support our work by ordering this product at Tindie
- [HiFi Raspberry Pi](https://www.tindie.com/products/sonocotta/raspberry-pi-media-center/)
- Louder Raspberry Pi (coming soon)
