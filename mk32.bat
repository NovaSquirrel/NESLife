@echo off
ca65 32x32/life.s -o 32x32/life.o -l 32x32/life.lst
ld65 -C 32x32/nrom128.x 32x32/life.o -o 32life.nes
pause