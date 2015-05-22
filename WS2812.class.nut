// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class WS2812 
{
	// This class uses SPI to emulate the WS2812s' one-wire protocol.
	// This requires one byte per bit to send data at 7.5 MHz via SPI.
	// These consts define the "waveform" to represent a zero or one
	
	static version = [1,0,1];

	static ZERO            = 0xC0;
	static ONE             = 0xF8;
	static BYTESPERPIXEL   = 24;

	// When instantiated, the WS2812 class will fill this array with blobs to
	// represent the waveforms to send the numbers 0 to 255. This allows the blobs to be
	// copied in directly, instead of being built for each pixel - which makes the class faster.
	
	_bits            = null;

	// Like bits, this blob holds the waveform to send the color [0,0,0], to clear pixels faster.
	
	_clearblob       = null;

	// Private variables passed into the constructor
	
	_spi             = null;  // imp SPI interface (pre-configured)
	_frameSize       = null;  // number of pixels per frame
	_frame           = null;  // a blob to hold the current frame

	// Parameters:
	//    spi          A configured spi (MSB_FIRST, 7.5MHz)
	//    frameSize    Number of Pixels per frame
	
	constructor(spiBus, frameSize) 
	{
		_spi = spiBus;
		_frameSize = frameSize;
		_frame = blob(_frameSize * BYTESPERPIXEL + 1);
		_frame[_frameSize * BYTESPERPIXEL] = 0;

		// Prepare the bits array and the clearblob blob
		
		_initialize();
		
		// Zero the LED array
		
		clearFrame();
		writeFrame();
	}

	// ------- PUBLIC FUNCTIONS -------

	// Sets a pixel in the frame buffer
	// but does not write it to the pixel strip
	// color is an array of the form [r, g, b]

	function writePixel(p, color) 
	{
		_frame.seek(p * BYTESPERPIXEL);

		// Red and green are swapped for some reason, so swizzle them back

		_frame.writeblob(_bits[color[1]]);
		_frame.writeblob(_bits[color[0]]);
		_frame.writeblob(_bits[color[2]]);
	}

	// Clears the frame buffer
	// but does not write it to the pixel strip

	function clearFrame() 
	{
		_frame.seek(0);
		for (local p = 0 ; p < _frameSize ; p++) _frame.writeblob(_clearblob);
	}

	// Writes the frame buffer to the pixel strip
	// ie - this function changes the pixel strip

	function writeFrame() 
	{
		_spi.write(_frame);
	}
	
	// ------ PRIVATE METHODS - DO NOT CALL DIRECTLY ------
	
	// Fill the array of representative 1-wire waveforms,
	// done by the constructor at instantiation
	
	function _initialize() 
	{
		// Fill the bits array first

		_bits = array(256);
		
		for (local i = 0; i < 256; i++) 
		{
			local valblob = blob(BYTESPERPIXEL / 3);
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

		// Now fill the clearblob
		
		_clearblob = blob(BYTESPERPIXEL);
		
		for (local j = 0 ; j < BYTESPERPIXEL ; j++) 
		{
			_clearblob.writen(ZERO, 'b');
		}
	}
}
