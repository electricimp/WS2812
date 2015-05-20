# WS2812 Class

This class allows the imp to drive WS2812 and WS2812B LEDs. The WS2812 is an all-in-one RGB LED with integrated shift register and constant-current driver. The parts are daisy-chained, and a proprietary one-wire protocol is used to send data to the chain of LEDs. Each pixel is individually addressable and this allows the part to be used for a wide range of effects animations.

Some example hardware that uses the WS2812 or WS2812B:

* [40 NeoPixel Matrix](http://www.adafruit.com/products/1430)
* [60 LED - 1m strip](http://www.adafruit.com/products/1138)
* [30 LED - 1m strip](http://www.adafruit.com/products/1376)
* [NeoPixel Stick](http://www.adafruit.com/products/1426)

**To add this library to your project, add** `#require "WS2812.class.nut:1.0.0"` **to the top of your device code**

## Hardware

WS2812s require a 5V power supply and logic, and each pixel can draw up to 60mA when displaying white in full brightness, so be sure to size your power supply appropriatly. Undersized power supplies (lower voltages and/or insufficent current) can cause glitches and/or failure to produce and light at all.

Because WS2812s require 5V logic, you will need to shift your logic level to 5V. A sample circuit can be found below using Adafruit’s [4-channel Bi-directional Logic Level Converter](http://www.adafruit.com/products/757):

![WS2812 Circuit](./circuit.png)

## Class Usage

### Constructor

Instantiate the class with a pre-configured SPI object and the number of pixels that are connected. The SPI object must be configured at 7500kHz and have the *MSB_FIRST* flag set:

```squirrel
// Configure the SPI bus

hardware.spi257.configure(MSB_FIRST, 7500)

// Instantiate an array of 8 WS2812s

pixels <- WS2812(hardware.spi257, 8)
```

### Class Methods

The WS2812 class keeps an internal frame that is only output to the pixel array when the **writeFrame()** method is called. As a result, changing the pixel strip takes two steps: writing values to the frame, and writing the frame to the SPI bus.

### writePixel(*pixelAddress*, *pixelColor*)

The **writePixel()** method changes the colour of a particular pixel in the frame buffer. However, this will not be written to the hardware until a call to **writeFrame()** is made. The method takes two parameters: the address of the WS2812 that you are changing (its position in the sequence of LEDs, an integer) and the color it should present. The color is passed as an array of three integers, one each for the red, green and blue components. Values range from 0 to 255.

```squirrel
// Change the colour of some pixels in the frame buffer

pixels.writePixel(0, [255, 0, 0])    // Write full red to the first pixel
pixels.writePixel(1, [127, 0, 0])    // Write half red to the second pixel
pixels.writePixel(2, [63, 0, 0])     // Write quarter red to the third pixel

// Write the frame buffer to the hardware

pixels.writeFrame()
```

### clearFrame()

The **clearFrame()** method will clear the frame buffer, ie. set ALL pixels to [0,0,0]). This will not be written to the hardware until a call to **writeFrame()** is made:

```squirrel
// Set all pixels to [0,0,0] in the frame buffer

pixels.clearFrame()

// Write the frame buffer to the hardware

pixels.writeFrame()
```

### writeFrame()

The **writeFrame()** method writes the internal frame buffer to the hardware *(see above examples)*.


## License

The WS2812 class is licensed under the [MIT License](./LICENSE).
