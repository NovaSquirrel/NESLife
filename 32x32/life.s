; NES Life
; Copyright (C) 2013 NovaSquirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

.setcpu "6502X"
.include "ns_nes.s" ; handy macros and defines
.include "common.s" ; handy routines

.include "memory.s"
.include "main.s"

.segment "INESHDR"
  .byt "NES", $1A
  .byt 1 ; PRG in 16kb units
  .byt 1 ; CHR in 16kb units
  .byt 1 ; vertical mirroring
  .byt 0
.segment "VECTORS"
  .addr nmi, reset, irq
.segment "CODE"

.proc reset
  lda #0		; Turn off PPU
  sta PPUCTRL
  sta PPUMASK
  sei
  ldx #$FF	; Set up stack pointer
  txs		; Wait for PPU to stabilize

: lda PPUSTATUS
  bpl :-
: lda PPUSTATUS
  bpl :-

  lda #0
  ldx #0
: sta $000,x
  sta $100,x 
  sta $200,x 
  sta $300,x 
  sta $400,x 
  sta $500,x 
  sta $600,x 
  sta $700,x 
  inx
  bne :-
  sta OAM_DMA

  lda #0
  sta SND_CHN
	
  lda #0
  sta PlayerX
  sta PlayerY

  lda #1
  sta r_seed

  lda #0
  sta PPUMASK

  jsr ClearName

  PositionXY 0,  6,  2
  jsr PutStringImmediate	
  .byt "Conway's Life for NES",0

  PositionXY 0,  9,  3
  jsr PutStringImmediate	
  .byt "by NovaSquirrel",0

  PositionXY 0,  7,  5
  lda #16
  jsr PutCheckeredBar

  PositionXY 0,  7,  22
  lda #16|128
  jsr PutCheckeredBar

  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR

  ldx #8
: lda #$2a
  sta PPUDATA
  lda #$0f
  sta PPUDATA
  lda #$00
  sta PPUDATA
  lda #$30
  sta PPUDATA
  dex
  bne :-

  lda #VRAM_DOWN
  sta PPUCTRL

  PositionXY 0,  7,  6
  ldx #16
  lda #$87
: sta PPUDATA
  dex
  bne :-

  PositionXY 0,  24,  6
  ldx #16
  lda #$87
: sta PPUDATA
  dex
  bne :-

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_0000
  sta PPUCTRL

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  lda #BG_ON + OBJ_ON
  sta PPUMASK

  ; make a glider
  lda #%0010
  sta RefGrid+$25
  lda #%0100
  sta RefGrid+$26
  lda #%0011
  sta RefGrid+$35
  lda #%0001
  sta RefGrid+$36

  sei
;    jsr WaitForKey
  lda retraces
  sta r_seed 

  jmp MainLoop
.endproc
.proc nmi
  pha
  txa
  pha
  tya
  pha
  inc retraces

  lda #0
  sta OAMADDR
  lda PlayerY
  asl
  asl
  add #48 - 2 - 1
  sta OAMDATA
  lda #$10
  sta OAMDATA
  lda #0
  sta OAMDATA
  lda PlayerX
  asl
  asl
  add #64 - 2
  sta OAMDATA

  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx IsPaused
  lda BGColors,x
  sta PPUDATA

  lda NeedRedrawGrid
  jeq NoRedraw
  .repeat 16, I
    lda #>($2000 + (6+I)*32 + 8)
    sta PPUADDR
    lda #<($2000 + (6+I)*32 + 8)
    sta PPUADDR
    .repeat 16, J
      lda RefGrid+J+(I*16)
      sta PPUDATA
    .endrep
  .endrep
  lda #0
  sta NeedRedrawGrid
NoRedraw:

  lda #0
  sta PPUADDR
  sta PPUADDR

  jsr ReadJoy
  lda keydown
  and #~KEY_START
  beq :+
    lda #1
    sta IsPaused
  :

  pla
  tay
  pla
  tax
  pla
  rti
BGColors:
  .byt $2a, $28
.endproc

.proc irq
  rti
.endproc

.proc PutCheckeredBar
  sta Temp
  and #31
  tax

  lda #$81
  bit Temp    ; choose top or bottom set of corners
  bpl :+
  lda #$84
: pha
  sta PPUDATA

  lda #$82
: sta PPUDATA
  dex
  bne :-

  pla
  add #2
  sta PPUDATA
  rts
.endproc

.segment "CHR"
.incbin "ascii.chr"
