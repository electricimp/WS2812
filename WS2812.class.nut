// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class WS2812 {
    // This class uses SPI to emulate the WS2812s' one-wire protocol.
    // This requires one byte per bit to send data at 7.5 MHz via SPI.
    // These consts define the "waveform" to represent a zero or one

    static version = [2,0,0];

    static ZERO            = 0xC0;
    static ONE             = 0xF8;
    static BYTES_PER_PIXEL   = 24;

    // When instantiated, the WS2812 class will fill this array with blobs to
    // represent the waveforms to send the numbers 0 to 255. This allows the blobs to be
    // copied in directly, instead of being built for each pixel - which makes the class faster.

    _bits            = null;

    // Private variables passed into the constructor

    _spi             = null;  // imp SPI interface (pre-configured)
    _frameSize       = null;  // number of pixels per frame
    _frame           = null;  // a blob to hold the current frame

    // Parameters:
    //    spi          A pre-configured SPI bus (MSB_FIRST, 7500)
    //    frameSize    Number of Pixels per frame

    constructor(spiBus, frameSize)
    {
        // spiBus must be configured
        _spi = spiBus;

        _frameSize = frameSize;
        _frame = blob(_frameSize * BYTES_PER_PIXEL + 1);
        _frame[_frameSize * BYTES_PER_PIXEL] = 0;

        // Fill the bits array first
        _bits = array(256);

        // Used in constructing the array
        local bytesPerColor = BYTES_PER_PIXEL / 3;

        for (local i = 0; i < 256; i++) {
            local valblob = blob(bytesPerColor);
            valblob.writen((i & 0x80) ? ONE:ZERO,'b');
            valblob.writen((i & 0x40) ? ONE:ZERO,'b');
            valblob.writen((i & 0x20) ? ONE:ZERO,'b');
            valblob.writen((i & 0x10) ? ONE:ZERO,'b');
            valblob.writen((i & 0x08) ? ONE:ZERO,'b');
            valblob.writen((i & 0x04) ? ONE:ZERO,'b');
            valblob.writen((i & 0x02) ? ONE:ZERO,'b');
            valblob.writen((i & 0x01) ? ONE:ZERO,'b');
            _bits[i] = valblob;
        }

        // Turn all pixels off
        fill([0,0,0]);
        draw();
    }

    // Sets a pixel in the buffer
    //   index - the index of the pixel (0 <= index < _frameSize)
    //   color - [r,g,b] (0 <= r,g,b <= 255)
    //
    // NOTE: set(index, color) replaces v1.x.x's writePixel(p, color) method
    function set(index, color) {
        assert(index >= 0 && index < _frameSize);
        assert(color[0] >= 0 && color[0] <= 255);
        assert(color[1] >= 0 && color[1] <= 255);
        assert(color[2] >= 0 && color[2] <= 255);

        _frame.seek(index * BYTES_PER_PIXEL);

        // Red and green are swapped for some reason, so swizzle them back
        _frame.writeblob(_bits[color[1]]);
        _frame.writeblob(_bits[color[0]]);
        _frame.writeblob(_bits[color[2]]);
    }


    // Sets the frame buffer (or a portion of the frame buffer)
    // to the specified color, but does not write it to the pixel strip
    //
    // NOTE: fill([0,0,0]) replaces v1.x.x's clear() method
    function fill(color, start=null, end=null) {
        // Set default values
        if (start == null) { start = 0; }
        if (end == null) { end = _frameSize - 1; }

        // Make sure we're not out of bounds
        assert(start >= 0 && start < _frameSize);
        assert(end >=0 && end < _frameSize)
        assert(color[0] >= 0 && color[0] <= 255);
        assert(color[1] >= 0 && color[1] <= 255);
        assert(color[2] >= 0 && color[2] <= 255);

        // Flip start & end if required
        if (start > end) {
            local temp = start;
            start = end;
            end = temp;
        }

        // Create a blob for the color
        local colorBlob = blob(BYTES_PER_PIXEL);
        colorBlob.writeblob(_bits[color[1]]);
        colorBlob.writeblob(_bits[color[0]]);
        colorBlob.writeblob(_bits[color[2]]);


        _frame.seek(start*BYTES_PER_PIXEL);
        for (local index = start ; index <= end ; index++) {
            _frame.writeblob(colorBlob);
        }
    }

    // Writes the frame to the pixel strip
    //
    // NOTE: draw() replaces v1.x.x's writeFrame() method
    function draw() {
        _spi.write(_frame);
    }
}
