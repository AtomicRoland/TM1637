#TM1637 DISPLAY DRIVER ROUTINES FOR 6502 CPU

The TM1637 is a nice IC for driving up to six 7-segment displays. However, the documentation that comes with it is the most lousy datasheet I have ever seen. Either I don't understand the English language not enough or the author does not. Also the timing diagrams are not very clear. 

Luckily I found a few routines on the internet that address this controller with a Raspberry Pi from a Python script. It was quite easy to translate this python script to 6502 assembly. I did this on my Acorn Atom with SALFAA2.6 and later I converted it to CA65. The assembly can easy be ported to other cpu's like the Z80 and 6809 as well because I use many short and simple subroutines.

I have written two versions:

TM1637PY
--------
This is a generic driver that you can assemble (by default to $700 but in the linker file you can change this as needed) and it provides a few basic functions:

jsr $700 -> initialize the 6522 VIA and the TM1637 controller
jsr $703 -> send data to the TM1637 controller *
jsr $706 -> clears the display
jsr $709 -> set brightness (Accumulator holds new value from 0 .. 7)
jsr $70C -> turn double point on (Accu = $80) or off (Accu = $00) **

* The data send to the display must be stored somewhere in the zero page:
  ZP-address+0: first (left-most) digit
  ZP-address+1: second digit
  ZP-address+2: third digit
  ZP-address+3: fourth digit (right-most)
  The digits must have a value between 0 and $0F otherwise the display result is undefined.

** The double point is activated on the next write (show) of the display

This driver does not provide any functions for reading the keys attached to the TM1637.


CLCK1637
--------
This is an expanded version of the driver and it provides routines to read a real time clock and display the time or date to the display. This version is more platform specific and it's written for my FPGAtom (a.k.a. Atom2k18) which has a simple real time clock in the FPGA. So you basically need a real time clock or an equivalent running in pure software. Reading of the clock is quite easy to adjust when you look at the source.
An extra feature of this program is that when the SHIFT and CTRL key are both pressed the date is displayed.

Assembly
========
There are two versions of each program. One is written in SALFAA2.6 and can be assembled directly on an Acorn Atom. The other version is written in CA65 and can be assembled by running build.sh.

Credits, copyright and warranty
===============================
Credits also go to Richart IJzermans (https://raspberrytips.nl/tm1637-4-digit-led-display-raspberry-pi/) for his Python script. 
You may use the programs TM1637PY and CLCK1637 for personal, educational and commercial for free. There is no warranty on these programs; you can use them as-is and at your own risk. I can not be held responsible for any loss of data or income, neither for any personal injury.
