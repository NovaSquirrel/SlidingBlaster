; Big City Sliding Blaster
; Copyright (C) 2013-2014 NovaSquirrel
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

.proc StartEditorFromMenu
  lda #1
  sta EditMode
  sta EnemiesLeftForNextLevelStart
  lda #128
  sta CursorPXH
  sta CursorPYH
  sta DoControllerSwap

  ldx #0
  txa
: sta LevelBuf,x
  inx
  bne :-

  tax
: sta LevelDataBuf,x
  inx
  cpx #16 ; 4 extra to hit the points afterward
  bne :-
.endproc
.proc StartEditorNormal
  jsr ClearOAM
  jsr wait_vblank
  jsr init_sound
  lda #0
  sta PPUMASK
  sta PPUSCROLL
  sta PPUSCROLL
  sta LevelNumber
  sta LevelMapNumber
  jsr ClearName

  jsr LevelChunks2LevelBuf

  PositionPrintXY 0, 10,  4, "Level Studio"
  PositionPrintXY 0, 7,  8, "Setup -Play- Quit"

  PositionXY 0,  7,  9
  lda #16
  jsr PutBorderBar

  PositionXY 0,  7,  22
  lda #16|128
  jsr PutBorderBar

  ldx #0
  stx 0
  ldx #32
RenderView:
  ldy 0
  lda EditViewRowAddr+0,y
  sta PPUADDR
  lda EditViewRowAddr+1,y
  sta PPUADDR
  iny
  iny
  cpy #13*2
  beq ExitRender
  sty 0
  lda #$16
  sta PPUDATA
  pha
  .dj_loop #16, 1
    ldy LevelBuf,x
    lda LevelEditTileTable,y
    sta PPUDATA
    inx
  .end_djl
  pla
  sta PPUDATA

  jmp RenderView
ExitRender:

  jsr wait_vblank
  lda #OBJ_ON|BG_ON
  sta PPUMASK

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
.endproc
.proc EditorLoop
  jsr ClearOAM
  jsr ReadJoy
  jsr HandleDrawCursor

  lda keynew
  and #KEY_START
  beq :+
    lda #(15*8)+4
    sta CursorPXH
    lda #(8*8)+4
    sta CursorPYH
  :

  lda CursorPXH
  cmp #(8*8)
  bcc NotInLevel
  lda CursorPXH
  cmp #(24*8)
  bcs NotInLevel
  ; within level at least horizontally
  lda CursorPYH
  cmp #(10*8)
  jcc IsInMenuCheck
  lda CursorPYH
  cmp #(21*8)
  bcs NotInLevel

  lda CursorPXH
  sub #(8*8)
  jsr Div32
  sta 0
  lda CursorPYH
  sub #(10*8)
  jsr Div32
  sta 1

  lda CursorPXH
  sub #(8*8)
  and #%1100000
  add #(8*8)
  sta 0

  lda CursorPYH
  sub #(10*8)
  and #%1100000
  add #(10*8)
  sta 1

  lda 0
  sub #(8*8)
  lsr
  lsr
  lsr
  lsr
  lsr
  sta 15
  lda 1
  sub #(10*8)
  lsr
  lsr
  lsr
  ora 15
  sta 15

  lda CursorPXH
  sta EditorCursorXBackup
  lda CursorPYH
  sta EditorCursorYBackup

  lda keynew
  and #KEY_A
  jne EditorSelectChunk

  lda keynew
  and #KEY_B
  jne EditorRotateChunk

  lda #4
  sta 2
  sta 3
  jsr MakeHighlightRect
NotInLevel:

  jsr wait_vblank
  jmp EditorLoop

Div32:
  lsr
  lsr
  lsr
  lsr
  lsr
  rts

IsInMenuCheck:
  lda CursorPYH
  cmp #6*8
  jcc NotInLevel
  lda #5
  sta 2
  lda #1
  sta 3
  lda #8*8
  sta 1

  lda CursorPXH
  cmp #(7+5)*8
  bcc LeftHover
  cmp #20*8
  bcs RightHover

  ; "Play"
  lda #13*8
  sta 0
  inc 2
  jsr MakeHighlightRect
  lda keynew
  and #KEY_A
  jne EditorStartGame
  jmp NotInLevel
LeftHover: ; "Setup"
  lda #7*8
  sta 0
  jsr MakeHighlightRect
  lda keynew
  and #KEY_A
  jne StartLevelSettings
  jmp NotInLevel
RightHover: ; "Quit"
  lda #20*8
  sta 0
  dec 2
  jsr MakeHighlightRect
  lda keynew
  and #KEY_A
  jne StartMainMenu
  jmp NotInLevel
.endproc

.proc EditorStartGame
  lda #1
  sta EditMode
  jmp NewGame
.endproc

.proc EditorRotateChunk
  ldx 15
  lda LevelDataBuf,x
  add #%01000000
  sta LevelDataBuf,x
  jmp StartEditorNormal
.endproc

.proc EditorSelectChunk
  LevelPartsIndex = 3   ; index into the metatiles making up the 4x4 chunks
  LevelChunksNum = 4
  RowToRender = 5

  ldx 15
  lda LevelDataBuf,x
  and #%111111
  ldy #5
  jsr div8
  ; Y = remainder, A = result
  sta 2
  sty 3

  lda 2
  ldy #40
  jsr mul8
  tya
  add #(3*8)+16
  sta CursorPYH
  lda 3
  ldy #40
  jsr mul8
  tya
  add #(4*8)+15
  sta CursorPXH

  jsr wait_vblank
  lda #0
  sta PPUMASK
  sta RowToRender
  sta LevelChunksNum
  jsr ClearName

  PositionXY 0,  0,  3
RenderLoop:
  ldx #4
  jsr PrintXSpaces
  jsr DrawChunkRow
  jsr DrawChunkRow
  jsr DrawChunkRow
  jsr DrawChunkRow
  jsr DrawChunkRow
  ldx #3
  jsr PrintXSpaces
  lda LevelChunksNum
  sub #5
  sta LevelChunksNum
  inc RowToRender
  lda RowToRender
  cmp #20
  beq Done
  and #3
  cmp #0
  bne :+
    lda LevelChunksNum
    add #5
    sta LevelChunksNum
    ldx #32
    jsr PrintXSpaces
: jmp RenderLoop
Done:

  jsr wait_vblank
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #OBJ_ON|BG_ON
  sta PPUMASK

; ------------------------------
SelectLoop:
  jsr ClearOAM
  jsr ReadJoy
  jsr HandleDrawCursor

  lda CursorPXH
  cmp #(4*8)
  bcc NotInSelect
  lda CursorPXH
  cmp #(27*8)
  bcs NotInSelect
  lda CursorPYH
  cmp #(3*8)
  bcc NotInSelect
  lda CursorPYH
  cmp #(26*8)
  bcs NotInSelect

  lda CursorPXH
  sub #(4*8)
  ldy #40
  jsr div8
  sta 13
  ldy #40
  jsr mul8
  tya
  add #(4*8)
  pha

  lda CursorPYH
  sub #(3*8)
  ldy #40
  jsr div8
  sta 14
  ldy #40
  jsr mul8
  tya
  add #(3*8)
  pha

  pla
  sta 1
  pla
  sta 0
  lda #4
  sta 2
  sta 3
  jsr MakeHighlightRect

  lda keynew
  and #KEY_A
  beq NotInSelect
    lda 14
    asl
    asl
    add 14
    add 13
    ldx 15
    sta LevelDataBuf,x
    lda EditorCursorXBackup
    sta CursorPXH
    lda EditorCursorYBackup
    sta CursorPYH
    jmp StartEditorNormal
NotInSelect:

  jsr wait_vblank
  jmp SelectLoop

DrawChunkRow:
  lda LevelChunksNum
  asl
  asl
  asl
  sta 0
  lda RowToRender
  and #3
  asl
  ora 0
  tax
  lda RandomLevelParts+0,x
  jsr DrawChunk2Bytes
  lda RandomLevelParts+1,x
  jsr DrawChunk2Bytes
  lda #' '
  sta PPUDATA
  inc LevelChunksNum
  rts
DrawChunk2Bytes:
  unpack 0,1
  ldy 1
  lda MetaNybbleTable,y
  tay
  lda LevelEditTileTable,y
  sta PPUDATA
  ldy 0
  lda MetaNybbleTable,y
  tay
  lda LevelEditTileTable,y
  sta PPUDATA
  rts
.endproc

.proc HandleDrawCursor
  ldx #0
  jsr HandleCursor

  ldy #0
  lda CursorPXH,x
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y
  lda CursorPYH,x
  sub #1
  sta OAM_YPOS+(4*0),y
  add #8
  sta OAM_YPOS+(4*1),y
  txa
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  lda #$16
  sta OAM_TILE+(4*0),y
  lda #$17
  sta OAM_TILE+(4*1),y
  ldy #8
  sty OamPtr
  rts
.endproc

.proc MakeHighlightRect
XPos   = 0 ; pixels
YPos   = 1
Width  = 2 ; tiles
Height = 3
XPos2  = 4 ; pixels
Attrib = 5

  lda retraces
  lsr
  lda #0
  ror
  ora #1
  sta Attrib

  dec YPos
  ldy OamPtr
RowLoop:
  lda XPos
  sta XPos2

  ldx Width
ColLoop:
  lda XPos2
  sta OAM_XPOS+(4*0),y
  add #8
  sta XPos2
  lda YPos
  sta OAM_YPOS+(4*0),y
  lda Attrib
  sta OAM_ATTR+(4*0),y
  lda #$15
  sta OAM_TILE+(4*0),y
  iny
  iny
  iny
  iny
  dex
  bne ColLoop

  lda YPos
  add #8
  sta YPos
  dec Height
  bne RowLoop

  sty OamPtr
  rts
.endproc

.proc PutBorderBar
  sta 1
  and #31
  tax

  lda #$10
  bit 1    ; choose top or bottom set of corners
  bpl :+
  lda #$13
: pha
  sta PPUDATA

  lda #$11
: sta PPUDATA
  dex
  bne :-

  pla
  add #2
  sta PPUDATA
  rts
.endproc

.proc EditViewRowAddr
  .repeat 12, I
    .ppuxy 0, 7, (I+10)
  .endrep
.endproc

.proc LevelEditTileTable
  .byt $f0, $f4, $f5, $f5, $f5, $f5, $f5, $f5, $f5, $f1, $f2, $f3
.endproc

.proc div8 ; see also mul8
num = 0   ; <-- also result
denom = 1
  sta num
  sty denom
  lda #$00
  ldx #$07
  clc
: rol num
  rol
  cmp denom
  bcc :+
  sbc denom
: dex
  bpl :--
  rol num
  tay
  lda num
  rts
.endproc

.proc StartLevelSettings
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  jsr ClearOAM

  PositionPrintXY 0, 7,  8, "Level to imitate:"
  PositionPrintXY 0, 10,  12, "1 2 3 4 5"
  PositionPrintXY 0, 10,  14, "6 7 8 9 10"

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr wait_vblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
Loop:
  jsr wait_vblank
  jsr ClearOAM
  jsr ReadJoy
  jsr HandleDrawCursor

  lda keynew
  and #KEY_B
  jne StartEditorNormal

  lda CursorPXH
  cmp #8*10
  bcc :+
  cmp #8*20
  bcs :+
  lda CursorPYH
  cmp #8*12
  bcc :+
  lda CursorPYH
  cmp #8*15
  bcs :+
    lda CursorPXH
    and #<~15
    sta 0
    lda CursorPYH
    and #<~15
    sta 1
    lda #2
    sta 2
    lsr
    sta 3
    jsr MakeHighlightRect
    lda keynew
    and #KEY_A
    beq :+
      lda CursorPXH
      sub #8*10
      lsr
      lsr
      lsr
      lsr
      sta 0
      ldy CursorPYH
      cpy #8*14
      bcc NoAdd5
      add #5
      sta 0
   NoAdd5:
      jsr DecodeLevelData
      jmp StartEditorNormal
  :
  jmp Loop
.endproc
