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
TOP_LEFT  = %0001 
TOP_RIGHT = %0010
BOT_LEFT  = %0100
BOT_RIGHT = %1000
.feature force_range
RefGridMinus1 = (RefGrid-1) & $ffff
RefGridPlus15 = (RefGrid+15) & $ffff

.code
.proc MainLoop
: jsr UpdateGrid
  lda IsPaused
  beq :-
  lda #0
  sta KeyRepeat
EditLoop:
  lda keydown
  and #KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT
  sta Temp
  lda keylast
  and #KEY_LEFT|KEY_DOWN|KEY_UP|KEY_RIGHT
  cmp Temp
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

  lda keydown
  and #KEY_LEFT
  beq :+
    lda keylast
    and #KEY_LEFT
    bne :+
      dec PlayerX
  :
  lda keydown
  and #KEY_DOWN
  beq :+
    lda keylast
    and #KEY_DOWN
    bne :+
      inc PlayerY
  :
  lda keydown
  and #KEY_UP
  beq :+
    lda keylast
    and #KEY_UP
    bne :+
      dec PlayerY
  :
  lda keydown
  and #KEY_RIGHT
  beq :+
    lda keylast
    and #KEY_RIGHT
    bne :+
      inc PlayerX
  :

  lda PlayerX
  and #31
  sta PlayerX

  lda PlayerY
  and #31
  sta PlayerY


  lda keylast
  eor #255
  and keydown
  and #KEY_UP|KEY_LEFT|KEY_DOWN|KEY_RIGHT
  sta Temp

  lda keydown
  and #KEY_A
  beq :+
    lda keylast
    and #KEY_A
    eor #KEY_A
    ora Temp
    beq :+
      lda PlayerX
      sta Temp+0
      lda PlayerY
      sta Temp+1
      jsr ToggleCell
      lda #1
      sta NeedRedrawGrid
  :

  lda keydown
  and #KEY_START
  beq :+
    lda keylast
    and #KEY_START
    bne :+
      lda #0
      sta IsPaused
  :

  lda keydown
  and #KEY_SELECT
  beq NoClear
    lda keylast
    and #KEY_SELECT
    bne NoClear
      lda #0
      tax
    : sta RefGrid,x
      inx
      bne :-
      lda #1
      sta NeedRedrawGrid
NoClear:

  jsr wait_vblank
  lda IsPaused
  jne EditLoop
  jmp MainLoop
.endproc

.proc ToggleCell ; Temp+0=X, Temp+1=Y
  XPos = Temp+0
  YPos = Temp+1  
  lda XPos
  lsr
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
MaskOn:
  .byt 1, 2, 4, 8
MaskOff:
  .byt <~1, <~2, <~4, <~8
.endproc

CellBirthTL:
  .byt 0,0,0,1,0,0,0,0,0
CellSurviveTL:
  .byt 0,0,1,1,0,0,0,0,0
CellBirthTR:
  .byt 0,0,0,2,0,0,0,0,0
CellSurviveTR:
  .byt 0,0,2,2,0,0,0,0,0
CellBirthBL:
  .byt 0,0,0,4,0,0,0,0,0
CellSurviveBL:
  .byt 0,0,4,4,0,0,0,0,0
CellBirthBR:
  .byt 0,0,0,8,0,0,0,0,0
CellSurviveBR:
  .byt 0,0,8,8,0,0,0,0,0

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
  lda RefGridMinus1,y
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
  lda RefGridMinus1,x
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
  lda RefGridMinus1,y
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
  lda RefGridMinus1,x
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
  lda RefGrid+15,y
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
  lda RefGrid+15,x
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
  lda RefGrid+15,y
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
  lda RefGrid+15,x
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
  lda RefGridMinus1,y
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
  lda RefGridMinus1,x
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
  lda RefGridPlus15,y
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
  lda RefGridPlus15,x
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
  lda RefGridMinus1,y
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
  lda RefGridMinus1,x
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
  lda RefGridPlus15,y
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
  lda RefGridPlus15,x
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

; copy new grid over old one
  ldx #0
: lda CurGrid,x
  sta RefGrid,x
  inx
  bne :-
  lda #1
  sta NeedRedrawGrid
  rts
.endproc
