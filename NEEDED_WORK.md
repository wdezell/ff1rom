# Needed Work
Roughly listed in order of priority.


----

##### Console Serial Port Abstraction
A byte (or bit) that designates which serial channel (A or B) is active console

----

##### Serial Channel Initialization Abstraction
A byte (or bit) that designates which serial channel (A or B) is target of an SIO configuration action

----

##### Mode 2 IRQ Console Input Handler
Console input will be received to a ring buffer via Mode 2 interrupt routines. Could (should?) make
selectable between Polled and IRQ-based.  Can be abstracted at CONIN.

----

##### BUTOA: 16-bit Unsigned Binary to ASCII Numerical String Conversion
Given 16-bit unsigned value in DE and a buffer in HL, convert to ASCII decimal digits.
Maybe some potential help here with BCD instructions.  Research.
