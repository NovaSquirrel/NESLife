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

TOP_LEFT  = %0001 
TOP_RIGHT = %0010
BOT_LEFT  = %0100
BOT_RIGHT = %1000

.code
.proc LifeMainLoop
: jsr UpdateGrid
  lda IsPaused
  beq :-

  lda #0
  sta KeyRepeat
EditLoop:
  lda #NMI_LIFE
  sta WhichNMI

  lda keydown
  and #KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT
  sta 0
  lda keylast
  and #KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT
  cmp 0
  bne :+
    lda KeyRepeat
    cmp #16
    bcc NoRepeat
    lda retraces
    and #3
    bne NoRepeat
    lda keylast
    and #<~(KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT)
    sta keylast
  NoRepeat:
    lda KeyRepeat
    bmi DidRepeat
    inc KeyRepeat
    jmp DidRepeat
: lda #0
  sta KeyRepeat
DidRepeat:
  lda keylast
  eor #$FF
  and keydown
  sta keynew

  lda keynew
  and #KEY_LEFT
  beq :+
    dec PlayerX
: lda keynew
  and #KEY_DOWN
  beq :+
    inc PlayerY
: lda keynew
  and #KEY_UP
  beq :+
    dec PlayerY
: lda keynew
  and #KEY_RIGHT
  beq :+
    inc PlayerX
  :

  lda PlayerX
  and #63
  sta PlayerX

  lda PlayerY
  and #31
  sta PlayerY

  lda keylast
  eor #255
  and keynew
  and #KEY_UP|KEY_LEFT|KEY_DOWN|KEY_RIGHT
  sta Temp

  lda keynew
  and #KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT
  beq :+
    lda keydown
    and #KEY_A
    bne DoA
  :

  lda keynew
  and #KEY_A
  beq :+
DoA: lda PlayerX
     sta Temp+0
     lda PlayerY
     sta Temp+1
     jsr ToggleCell
     lda #1
     sta NeedRedrawGrid
     sta NeedRedrawGrid+1
     sta NeedRedrawGrid+2
  :

  lda keynew
  and #KEY_B
  jne ShowLifeMenu

  lda keynew
  and #KEY_START
  beq :+
    lda #0
    sta IsPaused
  :

  lda keynew
  and #KEY_SELECT
  beq NoClear
    lda #0
    tax
  : sta RefGrid,x
    sta RefGrid2,x
    inx
    bne :-
    lda #1
    sta NeedRedrawGrid
    sta NeedRedrawGrid+1
    sta NeedRedrawGrid+2
NoClear:

  jsr wait_vblank
  lda IsPaused
  jne EditLoop
  jmp LifeMainLoop
.endproc

.proc ToggleCell ; Temp+0=X, Temp+1=Y
  XPos = Temp+0
  YPos = Temp+1  
  lda XPos
  lsr
  and #15
  ; ....xxxx
  sta Temp+2
  lda YPos
  asl
  asl
  asl 
  and #%11110000
  ora Temp+2
  tax

  lda YPos
  and #1
  asl
  sta Temp+2
  lda XPos
  and #1
  ora Temp+2
  tay

  lda XPos
  and #32
  bne SecondGrid

  lda RefGrid,x
  and MaskOn,y
  php
  lda RefGrid,x
  and MaskOff,y
  sta RefGrid,x
  plp
  bne :+
    ora MaskOn,y
    sta RefGrid,x
  :
  rts
SecondGrid:
  lda RefGrid2,x
  and MaskOn,y
  php
  lda RefGrid2,x
  and MaskOff,y
  sta RefGrid2,x
  plp
  bne :+
    ora MaskOn,y
    sta RefGrid2,x
  :
  rts

MaskOn:
  .byt 1, 2, 4, 8
MaskOff:
  .byt <~1, <~2, <~4, <~8
.endproc

.proc ShowLifeMenu
  lda #NMI_SIMPLE
  sta WhichNMI
  jsr ReadJoy
  jsr wait_vblank
  lda #0
  sta PPUMASK

  lda #$20
  sta PPUADDR
  lda #$c0
  sta PPUADDR
  ldx #<(16*32)
  ldy #>(16*32)
  lda #' '
: sta PPUDATA
  dex
  bne :-
  dey
  bne :-

  jsr ClearOAM
  jsr wait_vblank

FirstChoice:
  lda #0
  ldx #CHOICES_LIFEMENU
  jsr GameSet_DisplayChoice
  jcc Cancel
  jne NotRuleset
    lda #1
    ldx #CHOICES_LIFERULESET
    jsr GameSet_DisplayChoice
    jcc FirstChoice
    cmp #5
    beq :+
      jsr CopyRuleTable
      jmp Cancel
    :
      XPos = Temp+10
      YPos = Temp+11
      TempY = Temp+12
      jsr wait_vblank
      PositionXY 0,  2,  12
      lda #'B'
      sta PPUDATA
      PositionXY 0,  2,  13
      lda #'S'
      sta PPUDATA
      PositionXY 0,  3,  14
      jsr PutStringImmediate
      .byt "012345678",0
      lda #0
      sta PPUSCROLL
      sta PPUSCROLL
      sta XPos
      sta YPos
      tax
    : sta 0,x
      inx
      cpx #18
      bne :-
      jsr wait_vblank
      lda #OBJ_ON|BG_ON
      sta PPUMASK
    RuleChangeLoop:
      jsr wait_vblank
      jsr ReadJoy
      lda keynew
      and #KEY_A
      beq :+
        lda YPos
        asl
        asl
        asl
        sta TempY
        asl TempY
        asl TempY
        add YPos
        add XPos
        tax
        lda 0,x
        eor #1
        sta 0,x
        tay
        lda #$21
        sta PPUADDR
        lda #$83
        add XPos
        add TempY
        sta PPUADDR
        lda SpacePlus,y
        sta PPUDATA
        lda #0
        sta PPUSCROLL
        sta PPUSCROLL
      :
      lda keynew
      and #KEY_LEFT
      beq :+
        dec XPos
        bpl :+
          lda #8
          sta XPos
      :
      lda keynew
      and #KEY_RIGHT
      beq :+
        inc XPos
        lda XPos
        cmp #9
        bne :+
          lda #0
          sta XPos
      :
      lda keynew
      and #KEY_UP|KEY_DOWN
      beq :+
        lda YPos
        eor #1
        sta YPos
      :
      lda keynew
      and #KEY_B
      jne Cancel

      lda keynew
      and #KEY_START
      beq NoStartCustomRule
        ldx #0
      : lda 0,x
        sta CellBirthTL,x
        asl
        sta CellBirthTR,x
        asl
        sta CellBirthBL,x
        asl
        sta CellBirthBR,x
        inx
        cpx #18
        bne :-
        jmp Cancel
      NoStartCustomRule:

      lda YPos
      asl
      asl
      asl
      add #12*8-1
      sta OAM_YPOS
      lda #$12
      sta OAM_TILE
      lda #OAM_PRIORITY
      sta OAM_ATTR
      lda XPos
      asl
      asl
      asl
      add #3*8
      sta OAM_XPOS
      jmp RuleChangeLoop
  NotRuleset:
  cmp #1 ; Exit
  bne :+
    jmp (ResetVector)
  :

Cancel:
  jsr ClearOAM
  jsr wait_vblank
  jsr ReadJoy
  lda #OBJ_ON|BG_ON
  sta PPUMASK
  lda #1
  sta NeedRedrawGrid+0
  sta NeedRedrawGrid+1
  sta NeedRedrawGrid+2
  jmp LifeMainLoop::EditLoop

SpacePlus:
  .byt " +"
.endproc

RuleLife: ;B3/S23
  .byt 0,0,0,1,0,0,0,0,0
  .byt 0,0,1,1,0,0,0,0,0
RuleHighLife: ;B36/S23
  .byt 0,0,0,1,0,0,1,0,0
  .byt 0,0,1,1,0,0,0,0,0
RuleLongLife: ;B345/S5
  .byt 0,0,0,1,1,1,0,0,0
  .byt 0,0,0,0,0,1,0,0,0
RuleAntiLife: ;B0123478/S01234678
  .byt 1,1,1,1,1,0,0,1,1
  .byt 1,1,1,1,1,0,1,1,1
RuleMorley: ;B368/S245
  .byt 0,0,0,1,0,0,1,0,1
  .byt 0,0,1,0,1,1,0,0,0

.proc CopyRuleTable ; A=table to copy
  sta 0
  asl
  asl
  asl
  add 0 ;*9
  asl ;*18
  tax
  ldy #0
: lda RuleLife,x
  sta CellBirthTL,y
  asl
  sta CellBirthTR,y
  asl
  sta CellBirthBL,y
  asl
  sta CellBirthBR,y
  inx
  iny
  cpy #18
  bne :-

  rts
.endproc


.macro addneighbor Side
  and #Side
  beq :+
    inc Neighbors
  :
.endmacro

.proc UpdateCellRegular
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid-1,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid+1,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid-1,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid+1,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid,y
  sta CurGrid,y
  rts
.endproc

.proc UpdateCellLeftEdge
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid2+15,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2+15,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid+1,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2+15,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2+15,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid+1,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid,y
  sta CurGrid,y
  rts
.endproc

.proc UpdateCellRightEdge
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid-1,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2-15,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2-15,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid-1,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid,y
  sta CurGrid,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid2-15,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2-15,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid,y
  sta CurGrid,y
  rts
.endproc

; ---------------------------------------------------

.proc UpdateCellRegular2
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid2-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2-1,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid2,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2+1,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2-1,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid2+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2+1,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid2,y
  sta CurGrid2,y
  rts
.endproc

.proc UpdateCellLeftEdge2
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid+15,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid+15,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid2,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2+1,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid+15,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid+15,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid2+1,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2+1,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid2,y
  sta CurGrid2,y
  rts
.endproc

.proc UpdateCellRightEdge2
; find neighbors (top left)
  lda #0
  sta Neighbors
  lda RefGrid2-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2,y
  tax
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  txa
  addneighbor TOP_RIGHT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid2-1,x
  addneighbor BOT_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthTL,x
  sta CurGrid2,y

; find neighbors (top right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid-15,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #16
  lda RefGrid2,x
  pha
  addneighbor BOT_LEFT
  pla
  addneighbor BOT_RIGHT
  lda RefGrid-15,x
  addneighbor BOT_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #TOP_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthTR,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom left)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  lda RefGrid2-1,y
  tax
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_RIGHT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid2-1,x
  addneighbor TOP_RIGHT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_LEFT
  beq :+
    txa
    axs #<-9
: lda CellBirthBL,x
  ora CurGrid2,y
  sta CurGrid2,y

; find neighbors (bottom right)
  lda #0
  sta Neighbors
  lda RefGrid2,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor TOP_RIGHT
  txa
  addneighbor BOT_LEFT
  lda RefGrid-15,y
  tax
  addneighbor TOP_LEFT
  txa
  addneighbor BOT_LEFT
  tya
  tax
  axs #<-16
  lda RefGrid2,x
  pha
  addneighbor TOP_LEFT
  pla
  addneighbor TOP_RIGHT
  lda RefGrid-15,x
  addneighbor TOP_LEFT
; use neighbor count
  ldx Neighbors
  lda RefGrid2,y
  and #BOT_RIGHT
  beq :+
    txa
    axs #<-9
: lda CellBirthBR,x
  ora CurGrid2,y
  sta CurGrid2,y
  rts
.endproc

.proc UpdateGrid
  lda #0
  sta RowCount

  ldy #0
RowLoop:
  jsr UpdateCellLeftEdge
  iny
  .repeat 14
    jsr UpdateCellRegular
    iny
  .endrep
  jsr UpdateCellRightEdge
  iny
  inc RowCount
  lda RowCount
  cmp #16
  bne RowLoop

; ----------------------------------------
  ldy #0
RowLoop2:
  jsr UpdateCellLeftEdge2
  iny
  .repeat 14
    jsr UpdateCellRegular2
    iny
  .endrep
  jsr UpdateCellRightEdge2
  iny
  inc RowCount
  lda RowCount
  cmp #32
  bne RowLoop2

; copy new grid over old one
  ldx #0
: lda CurGrid,x
  sta RefGrid,x
  lda CurGrid2,x
  sta RefGrid2,x
  inx
  bne :-
  lda #1
  sta NeedRedrawGrid+0
  sta NeedRedrawGrid+1
  sta NeedRedrawGrid+2
  rts
.endproc
