        Work-In-Progress Work Breakdown Schedule for Firefly SBC ROM/BIOS


DONE    1. Page Zero Skeleton

y           Defs for the IRQ handlers and vectors
y           Boot jump
            Define general memory layout

DONE    2. ROM-2-RAM Switcher

            Copy ROM to RAM on boot

        3. Initializations

y           General HW defs for board
y           Define & enable Stack
            Initialize basic board operational params like default serial console baud
            Boot console splash

        4. Boot Mode Switch Dispatcher

            Stubs for dispatch targets
            Read boot switches and transfer execution to mode-appropriate code

        5. Diagnostics Simple I/O Package

            Wrapper for hex LED output?
            Simple serial output

        6. Diagnostics

            RAM test, output to LEDs
            RAM test, output to serial console
            Serial Port tests
            RO/RI/RTS/CTS tests
            Baud & param changes w/ dummy text output
            Port A R/W
            Port B R/W
            PIO Tests
            Loopback
            Port A R/W
            Port B R/W

        7. Mode 2 IRQ I/O Package

        8. Machine Language Monitor

        9. Board Hardware Utilities

            Card format & copy

        10. Forth Interpeter

        11. CP/M loader
