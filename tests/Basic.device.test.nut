/**
 * WS2812 Library test cases
 * Tests below will turn LED's on and off in color patterns
 * To confirm the hardware is running correctly you must check
 * the color patterns on the LEDs attached to the test devices.
 *
 * Test Farm Hardware : WS2812 LED tail, Imp001, Imp003, Imp005
 */

 class BasicTestCase extends ImpTestCase {

    static NUM_LEDS = 5;

    _leds = null;

    function setUp() {
        local env = imp.environment();
        local spi = null;
        if (env == ENVIRONMENT_CARD) {
            spi = hardware.spi257;
        }
        if (env == ENVIRONMENT_MODULE) {
            local type = hardware.getdeviceid().slice(0,1).tointeger();
            if (type == 3) spi = hardware.spiEBCA;
            if (type == 5) spi = hardware.spi0;
        }
        _leds = WS2812(spi, NUM_LEDS);
    }

    function testSetEachLEDtoRed() {
        local red = [100, 0, 0];
        local off = [0, 0, 0];

        for (local i = 0; i < 5; i++) {
            _leds.set(i, red).draw();
            this.info("Setting LED " + i + " to red.");
            imp.sleep(3);
            _leds.set(i, off).draw();
            this.info("Using set to turn off LED " + i + ".");
        }

        this.assertTrue(true);
    }

    function testFillLEDs2Green3Blue() {
        local green = [0, 100, 0];
        local blue = [0, 0, 100];
        local off = [0, 0, 0];

        _leds.fill(green, 0, 1).draw();
        this.info("Filling LEDs 0&1 to green.");

        _leds.fill(blue, 2, 4).draw();
        this.info("Filling LEDs 2-4 to blue.");

        imp.sleep(7);
        _leds.fill(off).draw();
        this.info("Using fill to turn off LEDs.");

        this.assertTrue(true);
    }

    function tearDown() {
        // Clean up the test
        _leds = null;
    }

 }