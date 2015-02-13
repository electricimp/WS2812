#Neopixel Class
This class allows the imp to drive WS2812 and WS2812B ["NeoPixel"](http://www.adafruit.com/products/1312) LEDs. The "Neopixel" is an all-in-one RGB LED with integrated shift register and constant-current driver. The parts are daisy-chained, and a proprietary one-wire protocol is used to send data to the chain of LEDs. Thus, each pixel is individually addressable, which allows the part to be used for a wide range of effects animations.

Some example hardware that uses the WS2812 or WS2812B:

* [40 RGB LED Pixel Matrix](http://www.adafruit.com/products/1430)
* [60 LED - 1m strip](http://www.adafruit.com/products/1138)
* [30 LED - 1m strip](http://www.adafruit.com/products/1376)
* [NeoPixel Stick](http://www.adafruit.com/products/1426)

# Hardware
NeoPixels require a 5V power supply and logic, and each pixel can draw up to 60mA when displaying white in full brightness, so bne sure to size your power supply appropriatly. Undersized power supplies (lower voltages and/or insufficent current) can cause glitches and/or failure to produce and light at all.

Because Nexpixels require 5V logic, you will need to shift your logic level to 5V. A sample circuit can be found below using Adafruit's [4-channel Bi-directional Logic Level Converter](http://www.adafruit.com/products/757):

![NeoPixel Circuit](./circuit.png)

# Usage

## Instantiating the class
Instantiate the NeoPixels class with a pre-configured SPI object (see example below), and the number of pixels that are connected. The SPI object must be configured at 7500 kHz, and have the MSB_FIRST flag set:

```
// configure the SPI bus
hardware.spi257.configure(MSB_FIRST, 7500);
// Instantiate an array of 8 NeoPixels
pixels <- NeoPixels(hardware.spi257, 8);
```

## Writing Pixels
The NeoPixels class keeps an internal frame that is only output to the pixel array when **.writeFrame()** is called. As a result, changing the pixel strip takes two steps: writing values to the frame, and writing the frame to the SPI bus.

### NeoPixel.writePixel(pixelID, [r,g,b])
The **writePixel** method changes the colour of a particular pixel in the frame buffer - this will not be written to the hardware until a call to **writeFrame()** is made:

```
// Change the colour of some pixels in the frame buffer
pixels.writePixel(0, [255, 0, 0]); // write full red to the first pixel
pixels.writePixel(1, [127, 0, 0]); // write half red to the second pixel
pixels.writePixel(2, [63, 0, 0]);  // write quarter red to the third pixel

// Write the frame buffer to the hardware
pixels.writeFrame();
```

### NeoPixels.clearFrame()
The **clearFrame** method will clear the frame buffer (set ALL pixels to [0,0,0]) - this will not be written to the hardware until a call to **writeFrame()** is made:
```
// Set all pixels to [0,0,0] in the frame buffer
pixels.clearFrame();
// Write the frame buffer to the hardware
pixels.writeFrame();
```

### NeoPixel.writeFrame()
The **writeFrame** method writes the internal frame buffer to the hardware (see above examples).


# License
The NeoPixel class is licensed under the [MIT License](./LICENSE).
