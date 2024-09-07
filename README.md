# WS2812B VHDL Controller

## Description
This repository contains a VHDL controller for the WS2812B addressable LED. The WS2812B is an RGB LED with an integrated controller, allowing each LED to be controlled individually in terms of brightness and color. It uses a single-wire communication protocol, which means that multiple LEDs can be chained together while still allowing independent control of each one. The data for each LED is passed from one LED to the next, enabling flexible and dynamic lighting effects.

### How the WS2812B Works
The WS2812B uses a 24-bit data protocol, where each LED requires 8 bits for red, 8 bits for green, and 8 bits for blue. Data is transmitted in a time-critical manner, where a series of high and low pulses are used to encode '0's and '1's. Each LED reads the first 24 bits of data and then forwards the remaining data to the next LED in the chain. The timing and order of bit shifts must be carefully managed to ensure proper operation.

## Tang Nano 20K
For testing the controller, the Tang Nano 20K development board was used. The Tang Nano 20K is a small FPGA board based on the Gowin GW2AR-18 FPGA, featuring 20K logic units. This board is a great choice for compact projects and comes with a variety of I/O options, including an onboard WS2812B LED.

![Pinout](https://github.com/user-attachments/assets/73a10015-f3d9-4272-a155-e7b096131272)

### Testing on the Tang Nano 20K
The Tang Nano 20K development board comes with a single WS2812B LED built into the board. To test the shifting of data across multiple LEDs, I added an additional WS2812B to the chain. This allowed me to validate the proper functioning of the VHDL controller in managing the bit shifts and data propagation through multiple LEDs.

## Features

- **bit_gen.vhd**: This file is responsible for transforming the data signals into the correct signal format required by the WS2812B LED. It handles the generation of the pulse signal to be transmitted to the LEDs, ensuring that the timing is precise and compatible with the WS2812B protocol. The component is already generalized, allowing it to handle any number of LEDs as needed.

- **ws2812b_top.vhd**: This file serves as the top-level module of the project. It connects the `bit_gen` component and manages the control logic for the WS2812B LEDs. You can modify this file to adapt the project to the specific number of LEDs in your application.

## Test

For testing, I used two WS2812B LEDs. To handle this, I created two separate signals, as can be seen in the `ws2812b_top.vhd` file. This setup allowed me to control each LED individually, demonstrating the ability of the controller to manage multiple LEDs in a chain.

![Test](https://github.com/user-attachments/assets/1b8eb264-1165-403e-bd5e-ba8df0833581)

## Warning

This project was developed with the timing specifications of the WS2812B in mind. However, if you plan to use the WS2812 LED (instead of the WS2812B), you will need to adjust the timing values inside the `bit_gen.vhd` file.

You can modify the timing constants as shown below:

```vhdl
-- Constantes de tempo (em ciclos de clock de 100 MHz)
constant T0H : integer := 40;  -- 0.40 µs
constant T1H : integer := 80;  -- 0.80 µs
constant T0L : integer := 85;  -- 0.85 µs
constant T1L : integer := 45;  -- 0.45 µs
```

## References
- [WS2812 Datasheet](https://cdn-shop.adafruit.com/datasheets/WS2812.pdf)
- [WS2812B Datasheet](https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf)
- [Tang Nano 20K Specifications](https://www.gowinsemi.com/en/product/detail/41)
