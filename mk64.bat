@echo off
ca65 64x32/life.s -o 64x32/life.o -l 64x32/life.lst
ld65 -C 64x32/nrom128.x 64x32/life.o -o 64life.nes
pause