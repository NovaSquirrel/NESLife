; NES Life
;
; Copyright 2014 NovaSquirrel
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

.setcpu "6502X"
.include "ns_nes.s" ; handy macros and defines
.include "common.s" ; handy routines

.include "memory.s"
.include "main.s"
.include "menus.s"

.segment "INESHDR"
  .byt "NES", $1A
  .byt 1 ; PRG in 16kb units
  .byt 1 ; CHR in 16kb units
  .byt 1 ; vertical mirroring
  .byt 0
.segment "VECTORS"
  .addr nmi
ResetVector:
  .addr reset, irq
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

  lda #1
  sta r_seed
  sta PlayerX
  sta PlayerY

.if 0
  ldx #0
: lda InitCellBirthTL,x
  sta CellBirthTL,x
  inx
  cpx #9*8
  bne :-
.endif
  lda #0 ; Life
  jsr CopyRuleTable

  lda #0
  sta PPUMASK

  jsr ClearName

  PositionXY 0,  6,  3
  jsr PutStringImmediate
  .byt "Conway's Life for NES",0

  PositionXY 0,  9,  4
  jsr PutStringImmediate
  .byt "by NovaSquirrel",0

  PositionXY 0,  4,  23
  jsr PutStringImmediate
  .byt "A:Toggle, Start:Go/Stop",0

  PositionXY 0,  4,  24
  jsr PutStringImmediate
  .byt "Select:Clear    B:Menu",0

.if 0
  PositionXY 0,  7,  5
  lda #16
  jsr PutCheckeredBar

  PositionXY 0,  7,  22
  lda #16|128
  jsr PutCheckeredBar
.endif

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

.if 0
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
.endif

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

  jmp LifeMainLoop
.endproc

.enum
  NMI_LIFE
  NMI_SIMPLE
.endenum

.proc nmi
  pha
  txa
  pha
  tya
  pha
  inc retraces
  lda WhichNMI
  beq LifeNMI
  lda #0
  sta OAMADDR
  lda #2
  sta OAM_DMA
  pla
  tay
  pla
  tax
  pla
  rti
LifeNMI:
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
  add #<-2 ;64 - 2
  sta OAMDATA

  lda ShowSecondCursor
  beq :+
    lda PlayerY2
    asl
    asl
    add #48 - 2 - 1
    sta OAMDATA
    lda #$10
    sta OAMDATA
    lda #0
    sta OAMDATA
    lda PlayerX2
    asl
    asl
    add #<-2 ;64 - 2
    sta OAMDATA
  :
  lda ShowSecondCursor
  bne :+
    lda #<-16
    sta OAMDATA
    sta OAMDATA
    sta OAMDATA
    sta OAMDATA
  :

  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx IsPaused
  lda BGColors,x
  sta PPUDATA

  lda NeedRedrawGrid
  jeq NoRedraw
  .repeat 14, I
    lda #>($2000 + (6+I)*32)
    sta PPUADDR
    lda #<($2000 + (6+I)*32)
    sta PPUADDR
    .repeat 16, J
      lda RefGrid+J+(I*16)
      sta PPUDATA
    .endrep
  .endrep
  lsr NeedRedrawGrid
  jmp NoRedraw3 ; don't try to redraw both in one frame
NoRedraw:

  lda NeedRedrawGrid2
  jeq NoRedraw2
  .repeat 14, I
    lda #>($2000 + (6+I)*32 + 16)
    sta PPUADDR
    lda #<($2000 + (6+I)*32 + 16)
    sta PPUADDR
    .repeat 16, J
      lda RefGrid2+J+(I*16)
      sta PPUDATA
    .endrep
  .endrep
  lsr NeedRedrawGrid2
  jmp NoRedraw3
NoRedraw2:

  lda NeedRedrawGrid3
  jeq NoRedraw3
  .repeat 2, I
    lda #>($2000 + (6+I+14)*32)
    sta PPUADDR
    lda #<($2000 + (6+I+14)*32)
    sta PPUADDR
    .repeat 16, J
      lda RefGrid+J+((I+14)*16)
      sta PPUDATA
    .endrep
    .repeat 16, J
      lda RefGrid2+J+((I+14)*16)
      sta PPUDATA
    .endrep
  .endrep
  lsr NeedRedrawGrid3
NoRedraw3:

  lda #0
  sta PPUADDR
  sta PPUADDR

  jsr ReadJoy
  lda keydown
  and #<~KEY_START
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

.if 0
NewL = $fe

GosperRLE:
  .byt $ff
; 24bo22bobo$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o$2o8bo3bob2o4b
; obo$10bo5bo7bo$11bo3bo$12b2o$23bo$24b2o$23b2o7$24b2o$24b2o3bo$28bobo$
; 29bobo$31bo$31b2o!
.endif

.segment "CHR"
.incbin "ascii.chr"
