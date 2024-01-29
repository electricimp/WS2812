# WS2812 4.0.1

This class allows the imp to drive WS2812 and WS2812B LEDs. The WS2812 is an all-in-one RGB LED with integrated shift register and constant-current driver. The parts are daisy-chained, and a proprietary one-wire protocol is used to send data to the chain of LEDs. Each pixel is individually addressable and this allows the part to be used for a wide range of effects animations.

Some example hardware that uses the WS2812 or WS2812B:

* [40 NeoPixel Matrix](http://www.adafruit.com/products/1430)
* [60 LED - 1m strip](http://www.adafruit.com/products/1138)
* [30 LED - 1m strip](http://www.adafruit.com/products/1376)
* [NeoPixel Stick](http://www.adafruit.com/products/1426)

The library also supports RGBW NeoPixels, such as [Ultra Bright 4 Watt RGBW NeoPixel LED](https://www.adafruit.com/product/5408).

**To add this library to your project, add** `#require "WS2812.class.nut:4.0.1"` **to the top of your device code.**

## Hardware

WS2812s require a 5V power supply and logic, and each pixel can draw up to 60mA when displaying white in full brightness, so be sure to size your power supply appropriately. Undersized power supplies (lower voltages and/or insufficient current) can cause glitches and/or failure to produce and light at all.

Because WS2812s require 5V logic, you will need to shift your logic level to 5V. A sample circuit can be found below using Adafruit’s [4-channel Bi-directional Logic Level Converter](http://www.adafruit.com/products/757).

![WS2812 Circuit](./circuit.png)

**Warning** We do not recommend using the imp005 with WS2812s. Unlike the imp001, imp002, imp003 and imp004m, the imp005 does not use DMA for SPI data transfers. Instead, each byte is written out individually, and this means there will always be a small gap between each byte. As a result, the LEDs may not work as expected.

## Class Usage

All public methods in the WS2812 class return `this`, allowing you to easily chain multiple commands together:

```squirrel
pixels
    .set(0, [255,0,0])
    .set(1, [0,255,0])
    .fill([0,0,255], 2, 4)
    .draw();
```

The above example is for RGB Neopixels. For RGBW LEDs, you would supply colors with four components, RBG plus White.

### Constructor: WS2812(*spi, numberOfPixels[, draw][, rgbw]*)

Instantiate the class with an imp SPI object and the number of pixels that are connected. The SPI object will be configured by the constructor.

An optional third parameter can be set to control whether the class will draw an empty frame on initialization. The default value is `true`.

An optional fourth parameter can be set to enable support for RGBW pixels. The default value is `false`.


#### Examples ####

```squirrel
#require "WS2812.class.nut:4.0.1"

// Select the SPI bus
spi <- hardware.spi257;

// Instantiate RGB LED array with 5 pixels
pixels <- WS2812(spi, 5);
```

```squirrel
#require "WS2812.class.nut:4.0.1"

// Select the SPI bus
spi <- hardware.spiEBCA;

// Instantiate RGBW array with 16 pixels
pixels <- WS2812(spi, 16, true, true);
```

## Class Methods

### set(*index, color*)

The `set()` method changes the color of a particular pixel in the frame buffer. The color is passed as an array of three integers between 0 and 255 representing `[red, green, blue]`. If the pixels are RGBW then the array has four integers, `[red, green, blue, white]`.

**Note** The `set()` method does not output the changes to the pixel strip. After setting up the frame, you must call `draw()` (see below) to output the frame to the strip.

#### Examples ####

```squirrel
// Set and draw an RGB pixel
pixels.set(0, [127,0,0]).draw();
```

```squirrel
// Set and draw an RGBW pixel
pixels.set(0, [255,0,0,10]).draw();
```

### fill(*color[, start][, end]*)

The `fill()` method sets all pixels in the specified range to the desired color. If no range is selected, the entire frame will be filled with the specified color. The color is passed as an array of three integers between 0 and 255 representing `[red, green, blue]`. If the pixels are RGBW then the array has four integers, `[red, green, blue, white]`.

**Note** The `fill()` method does not output the changes to the pixel strip. After setting up the frame, you must call `draw()` (see below) to output the frame to the strip.

#### Examples ####

```squirrel
// Turn all RGB LEDs off
pixels.fill([0,0,0]).draw();
```

```squirrel
// Set half the RGBW array red
// and the other half blue
pixels
    .fill([255,0,0,20], 0, 2)
    .fill([0,0,255,20], 3, 4)
    .draw();
```

### draw()

The `draw()` method draws writes the current frame to the pixel array (see examples above).

## License

The WS2812 class is licensed under the [MIT License](https://github.com/electricimp/ws2812/tree/master/LICENSE).
