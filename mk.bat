@echo off
ca65 src/blaster.s -o src/blaster.o -l src/blaster.lst
ld65 -C src/nrom128.x src/blaster.o -o blaster.nes
pause