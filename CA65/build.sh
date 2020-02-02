#!/bin/bash

rm -f clck1637

echo Assembling
ca65 -l clck1637.lst -o clck1637.o clck1637.asm
ca65 -l tm1637py.lst -o tm1637py.o tm1637py.asm

echo Linking
ld65 clck1637.o -o clck1637 -C tm1637.lkr 
ld65 tm1637py.o -o tm1637py -C tm1637.lkr 

echo Cleaning
rm -f *.o

echo Checksumming
md5sum clck1637
md5sum tm1637py

