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

        // Prepare the bits array and the clearblob blob

        _initialize();

        // Zero the LED array

        fill([0,0,0]);
        draw();
    }

    // ------- PUBLIC FUNCTIONS -------

    // Sets a pixel in the buffer
    //   p - the pixel (0 <= p < _frameSize)
    //   color - [r,g,b] (0 <= r,g,b <= 255)
    function set(p, color) {
        assert(p >= 0);
        assert(p < _frameSize);

        _frame.seek(p * BYTES_PER_PIXEL);

        // Red and green are swapped for some reason, so swizzle them back
        _frame.writeblob(_bits[color[1]]);
        _frame.writeblob(_bits[color[0]]);
        _frame.writeblob(_bits[color[2]]);
    }


    // Clears the frame buffer
    // but does not write it to the pixel strip
    function fill(color, start=null, end=null) {
        // Set default values
        if (start == null) { start = 0; }
        if (end == null) { end = _frameSize - 1; }

        // Make sure we're not out of bounds
        assert(start >= 0 && start < _frameSize);
        assert(end >=0 && end < _frameSize)

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
        for (local p = start ; p <= end ; p++) _frame.writeblob(colorBlob);
    }

    // Writes the frame to the pixel strip
    function draw() {
        _spi.write(_frame);
    }

    //-------------------- PRIVATE METHODS --------------------//

    // Fill the array of representative 1-wire waveforms,
    // done by the constructor at instantiation

    function _initialize() {
        // Fill the bits array first

        _bits = array(256);

        for (local i = 0; i < 256; i++) {
            local valblob = blob(BYTES_PER_PIXEL / 3);
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
    }
}
