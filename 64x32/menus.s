; NES Life
; Copyright (C) 2014 NovaSquirrel
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

GameSet_ChoiceRows:
.byt ChoiceRow_AppSelect - GameSet_ChoiceText
.byt ChoiceRow_LifeMenu - GameSet_ChoiceText
.byt ChoiceRow_LifeRuleset - GameSet_ChoiceText

GameSet_ChoiceText:
ChoiceRow_AppSelect:
.byt "Life, SFX Edit",0
ChoiceRow_LifeMenu:
.byt "Ruleset, Exit",0
ChoiceRow_LifeRuleset:
.byt "Life High Long Anti Morley +",0

.enum
  CHOICES_APPSELECT
  CHOICES_LIFEMENU
  CHOICES_LIFERULESET
.endenum

.proc GameSet_DisplayChoice ; A = screen row, X = choice of row, Y = initial choice ---> A = chosen option
ScreenRow = 4
RowStartsAt = 5
CurrentChoice = 6
NumChoices = 7
NameYPos = 8
SpritesYPos = 9
ChoiceList = Temp
  sta ScreenRow
  sty CurrentChoice
  txa
  pha

  jsr wait_vblank
  lda #0
  sta PPUMASK
  sta NumChoices

  jsr wait_vblank
  lda ScreenRow
  asl
  add #8

  pha
    pha
    asl
    asl
    asl
    sta SpritesYPos
    pla
  add #2
  jsr Mul32PPU1202
  jsr Put32Spaces
  pla
  sta NameYPos
  jsr Mul32PPU1202

; display row of text
  pla
  tax
  lda GameSet_ChoiceRows,x
  tax
  stx RowStartsAt
  stx ChoiceList
  ldy #1
WriteText:
  lda GameSet_ChoiceText,x
  beq EndText

  cmp #' ' ; note spaces in list
  bne :+
  pha
  inx
  txa
  dex
  sta ChoiceList,y
  inc NumChoices
  iny
  pla
: cmp #'_' ; change underscore to spaces
  bne :+
  lda #' '
:

  sta PPUDATA
  inx
  bne WriteText
EndText:
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #OBJ_ON|BG_ON
  sta PPUMASK

  lda #0
  sta CurrentChoice
; now let the user choose 
ChooseLoop:
  jsr ClearOAM

  ldx CurrentChoice
  lda ChoiceList,x
  tax
  ldy OamPtr
DrawLoop:
  lda #$12
  sta OAM_TILE+(4*0),y
  lda #OAM_PRIORITY | 3
  sta OAM_ATTR+(4*0),y
  txa
  sub ChoiceList
  asl
  asl
  asl
  add #$2*8
  sta OAM_XPOS+(4*0),y

  lda SpritesYPos
  sub #1
  sta OAM_YPOS+(4*0),y
  iny
  iny
  iny
  iny
  inx
  lda GameSet_ChoiceText,x
  beq :+
  cmp #' '
  beq :+
  cmp #','
  beq :+
  bne DrawLoop
:

  jsr ReadJoy

  lda keynew
  and #KEY_LEFT
  beq :+
    dec CurrentChoice
    bpl :+
      lda NumChoices
      sta CurrentChoice
  :

  lda keynew
  and #KEY_RIGHT
  beq :+
    inc CurrentChoice
    lda NumChoices
    cmp CurrentChoice
    bcs :+
      lda #0
      sta CurrentChoice
  :

  lda keynew
  and #KEY_A
  jne PickedOption

  lda keynew
  and #KEY_B
  beq :+
 ;   jsr ClearOAM
 ;   lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_0000
 ;   sta PPUCTRL
    clc
    rts
  :

  jsr wait_vblank
  jmp ChooseLoop

PickedOption:
  jsr ClearOAM
  jsr wait_vblank
  lda #0
  sta PPUMASK
  lda NameYPos
  jsr Mul32PPU1202

  ldx CurrentChoice
  lda ChoiceList,x
  tax
: lda GameSet_ChoiceText,x
  beq ExitPick
  cmp #' '
  beq ExitPick
  cmp #'_'
  bne :+
  lda #' '
: cmp #','
  beq ExitPick
  sta PPUDATA
  inx
  bne :--
ExitPick:

  jsr Put32Spaces

;  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_0000
;  sta PPUCTRL

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda CurrentChoice
  sec
  rts

Put32Spaces:
  ldx #32
PutXSpaces:
  lda #' '
: sta PPUDATA
  dex
  bne :-
  rts

Mul32PPU1202:
  Mul32_PPU 1, #$20, #2
  rts
.endproc
