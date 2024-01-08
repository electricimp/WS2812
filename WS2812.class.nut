// Copyright (c) 2015-19 Electric Imp
// Copyright (c) 2020-24 KORE Wireless
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class WS2812 {

    static VERSION = "4.0.0";

    // Imp usage warning
    static ERROR_IMP_005 = "Use of the imp005 module with the WS2812 library is not advisable.";

    // This class uses SPI to emulate the WS2812s' one-wire protocol.
    // The ideal speed for WS2812 LEDs is 6400 MHz via SPI.

    // The closest imp001 & imp002 supported SPI datarate is 7500 MHz
    // imp004m supported SPI datarate is 6000 MHz
    // imp005 supported SPI datarate is 6400 MHz
    // These constants define the "waveform" to represent a zero or one
    static ZERO                     = 0xC0;
    static ONE                      = 0xF8;
    static BYTES_PER_PIXEL          = 24;
    // FROM 4.0.0
    static BYTES_PER_PIXEL_W        = 32;

    // The closest imp003 supported SPI datarate is 9 MHz.
    // These constants define the "waveform" to represent a zero-zero, zero-one, one-zero, one-one.
    static ZERO_ZERO                = "\xE0\x0E\x00";
    static ZERO_ONE                 = "\xE0\x0F\xC0";
    static ONE_ZERO                 = "\xFC\x0E\x00";
    static ONE_ONE                  = "\xFC\x0F\xC0";
    static IMP3_BYTES_PER_PIXEL     = 36;
    // FROM 4.0.0
    static IMP3_BYTES_PER_PIXEL_W   = 48;

    // The WS2812 class will fill this array with blobs to represent
    // the waveforms to send the numbers 0 to 255. This allows the
    // blobs to be copied in directly, instead of being built for each pixel.
    // NOTE From 3.0.1, these are generated as required. To reduce memory impact
    static _bits                    = array(256, null);

    // Private variables passed into the constructor
    _spi                            = null;     // imp SPI interface
    _frameSize                      = null;     // number of pixels per frame
    _frame                          = null;     // a blob to hold the current frame
    _bytesPerPixel                  = null;     // number of bytes per pixel
    // FROM 3.0.1
    _makeBitPattern                 = null;     // Function to generate patterns
    // FROM 4.0.0
    _useRGBW                        = null;     // Are we using RGBW strings?

    // Parameters:
    //    spi          A SPI bus
    //    frameSize    Number of Pixels per frame
    //    _draw        Whether or not to initially draw a blank frame
    //    _rgbw        Whether or not the pixels are RGBS (instead of RGB)
    constructor(spiBus, frameSize, _draw = true, _rgbw = false) {
        // FROM 4.0.0
        // Are we using RGBW pixels?
        _useRGBW = _rgbw;

        local impType = _getImpType();
        _configureSPI(spiBus, impType, _useRGBW);

        // FROM 3.0.1
        if (impType == 3) {
            _makeBitPattern = _makeBitPattern003;
        } else {
            _makeBitPattern = _makeBitPatternDefault;
        }

        // NOTE `bytes_per_pixel` set by `_configureSPI()`
        _frameSize = frameSize;
        _frame = blob(_frameSize * _bytesPerPixel + 1);
        _frame[_frameSize * _bytesPerPixel] = 0;

        // Clear the pixel buffer
        fill([0,0,0,0]);

        // Output the pixels if required
        if (_draw) this.draw();
    }

    // Sets a pixel in the buffer
    //   index - the index of the pixel (0 <= index < _frameSize)
    //   color - [r,g,b] (0 <= r,g,b <= 255), or [r,g,b,a] with an alpha (RGBW)
    //
    // NOTE: set(index, color) replaces v1.x.x's writePixel(p, color) method
    function set(index, color) {
        index = _checkRange(index);
        color = _checkColorRange(color);

        _frame.seek(index * _bytesPerPixel);

        // Create a blob for the color
        // Red and green are swapped for some reason, so swizzle them back
        _frame.writeblob(_getBitPattern(color[1]));
        _frame.writeblob(_getBitPattern(color[0]));
        _frame.writeblob(_getBitPattern(color[2]));
        // FROM 4.0.0
        if (_useRGBW) _frame.writeblob(_getBitPattern(color.len() >= 4 ? color[3] : 0));

        return this;
    }

    // Sets the frame buffer (or a portion of the frame buffer)
    // to the specified color, but does not write it to the pixel strip
    //
    // NOTE: fill([0,0,0]) replaces v1.x.x's clear() method
    function fill(color, start=0, end=null) {
        // We can't default to _frameSize -1, so we
        // default to null and set to _frameSize - 1
        if (end == null) end = _frameSize - 1;

        // Make sure we're not out of bounds
        start = _checkRange(start);
        end = _checkRange(end);
        color = _checkColorRange(color);

        // Flip start & end if required
        if (start > end) {
            local temp = start;
            start = end;
            end = temp;
        }

        // Create a blob for the color
        // Red and green are swapped for some reason, so swizzle them back
        local colorBlob = blob(_bytesPerPixel);
        colorBlob.writeblob(_getBitPattern(color[1]));
        colorBlob.writeblob(_getBitPattern(color[0]));
        colorBlob.writeblob(_getBitPattern(color[2]));
        // FROM 4.0.0
        if (_useRGBW) colorBlob.writeblob(_getBitPattern(color.len() >= 4 ? color[3] : 0));

        // Write the color blob to each pixel in the fill
        _frame.seek(start * _bytesPerPixel);
        for (local index = start ; index <= end ; index++) {
            _frame.writeblob(colorBlob);
        }

        return this;
    }

    // Writes the frame to the pixel strip
    //
    // NOTE: draw() replaces v1.x.x's writeFrame() method
    function draw() {
        _spi.write(_frame);
        return this;
    }

    // Private functions
    // --------------------------------------------------

    function _checkRange(index) {
        if (index < 0) index = 0;
        if (index >= _frameSize) index = _frameSize - 1;
        return index;
    }

    function _checkColorRange(colors) {
        foreach(idx, color in colors) {
            if (color < 0) colors[idx] = 0;
            if (color > 255) colors[idx] = 255;
        }

        return colors;
    }

    function _getImpType() {
        local env = imp.environment();
        if (env == ENVIRONMENT_CARD) {
            return 1;
        }

        if (env == ENVIRONMENT_MODULE) {
            return hardware.getdeviceid().slice(0,1).tointeger();
        }
    }

    function _configureSPI(spiBus, impType, rgbw) {
        _spi = spiBus;
        switch (impType) {
            case 1:
                // Same as 002 config
            case 2:
                _bytesPerPixel = rgbw ? BYTES_PER_PIXEL_W : BYTES_PER_PIXEL;
                _spi.configure(MSB_FIRST | SIMPLEX_TX | NO_SCLK, 7500);
                break;
            case 3:
                _bytesPerPixel = rgbw ? IMP3_BYTES_PER_PIXEL_W : IMP3_BYTES_PER_PIXEL;
                _spi.configure(MSB_FIRST | SIMPLEX_TX | NO_SCLK, 9000);
                break;
            case 4:
                _bytesPerPixel = rgbw ? BYTES_PER_PIXEL_W : BYTES_PER_PIXEL;
                _spi.configure(MSB_FIRST | SIMPLEX_TX | NO_SCLK, 6000);
                break;
            case 5:
                // Log imp005 warning
                server.error(ERROR_IMP_005);
                _bytesPerPixel = rgbw ? BYTES_PER_PIXEL_W : BYTES_PER_PIXEL;
                // Note: to see the actual rate log actualRate
                // Passing in 6000 actually sets datarate to 6400
                local actualRate = _spi.configure(MSB_FIRST | SIMPLEX_TX | NO_SCLK, 6000);
                // server.log(actual Rate)
                break;
        }
    }

    // FROM 3.0.1
    // @rlipscome's lazy cache `_bits` fix
    function _getBitPattern(i) {
        if (_bits[i] != null) return _bits[i];
        _bits[i] = _makeBitPattern(i);
        return _bits[i];
    }

    function _makeBitPattern003(i) {
        local bytesPerColor = _bytesPerPixel / (_useRGBW ? 4 : 3);
        local valblob = blob(bytesPerColor);
        valblob.writestring(_getNumber((i / 64) % 4));
        valblob.writestring(_getNumber((i / 16) % 4));
        valblob.writestring(_getNumber((i / 4) % 4));
        valblob.writestring(_getNumber(i % 4));
        return valblob;
    }

    function _makeBitPatternDefault(i) {
        local bytesPerColor = _bytesPerPixel / (_useRGBW ? 4 : 3);
        local valblob = blob(bytesPerColor);
        valblob.writen((i & 0x80) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x40) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x20) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x10) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x08) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x04) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x02) ? ONE : ZERO, 'b');
        valblob.writen((i & 0x01) ? ONE : ZERO, 'b');
        return valblob;
    }

    function _getNumber(num) {
        if(num == 0) return ZERO_ZERO;
        if(num == 1) return ZERO_ONE;
        if(num == 2) return ONE_ZERO;
        if(num == 3) return ONE_ONE;
    }
}
