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

.proc DecodeLevelData ; A=map number
  asl
  pha
  asl
  asl
  asl
  tay
  lda LevelAttributes+0,y
  sta EnemiesPool+0
  lda LevelAttributes+1,y
  sta EnemiesPool+1
  lda LevelAttributes+2,y
  sta EnemiesPool+2
  lda LevelAttributes+3,y
  sta EnemiesPool+3
  lda LevelAttributes+4,y
  sta LevelSpinShootSpeed
  lda LevelAttributes+5,y
  sta LevelSpinShootChance
  lda LevelAttributes+6,y
  sta LevelSpinShootRate
  lda LevelAttributes+7,y
  sta MaxScreenEnemies
  lda LevelAttributes+8,y
  sta LevelSpecialFlags
  lda LevelAttributes+9,y
  sta EnemiesLeftForNextLevelStart
  lda LevelAttributes+10,y
  sta Speedup
  pla
  tay
  lda LevelMapData+0,y
  sta 7
  lda LevelMapData+1,y
  sta 8
  lda EditMode
  beq CorrectMap
  rts
CorrectMap:

; clear out level chunks and level metatiles
  ldx #0
  txa
: sta LevelBuf,x
  inx
  bne :-

  tax
: sta LevelDataBuf,x
  inx
  cpx #12
  bne :-

; read information from map
  iny
  lda LevelMapData,y
  unpack LevelDataPoints+0, LevelDataPoints+1
  iny
  lda LevelMapData,y
  unpack LevelDataPoints+2, LevelDataPoints+3
  iny

  lda LevelDataPoints+0
  and #%0011
  asl ; *2
  asl ; *4
  asl ; *8
  asl ; *16
  asl ; *32
  asl ; *64
  add #32-16
  sta PlayerPXH

  lda LevelDataPoints+0
  and #%1100 ; *4
  asl ; *8
  asl ; *16
  add #32+(32-16)
  sta PlayerPYH

  ldx #0
  ldy #2
FillDataBuf:
  lda (7),y
  sta LevelDataBuf,x
  iny
  inx
  cpx #12
  bne FillDataBuf
.endproc
; don't put anything here
.proc LevelChunks2LevelBuf
ChunkNum = 0
TileLo = 1
TileHi = 2
NeedFlip = 3
LevelBufIndex = 4
LevelChunk = 5
; transfer 4x4 tiles to 16x16
  lda #0
  sta ChunkNum
ChunkLoop:
  lda ChunkNum
  jsr MakeLevelBufIndexFromChunk
  stx LevelBufIndex

  ldy ChunkNum
  lda LevelDataBuf,y
  sta LevelChunk
  and #%111111
  asl
  asl
  asl
  tay
ChunkRow:
  sty TempVal
  lda RandomLevelParts,y
  unpack TileHi, TileLo
  ldy TileLo
  lda MetaNybbleTable,y
  sta LevelBuf+0,x
  ldy TileHi
  lda MetaNybbleTable,y
  sta LevelBuf+1,x
  ldy TempVal
  lda RandomLevelParts+1,y
  unpack TileHi, TileLo
  ldy TileLo
  lda MetaNybbleTable,y
  sta LevelBuf+2,x
  ldy TileHi
  lda MetaNybbleTable,y
  sta LevelBuf+3,x

  lda LevelChunk
  and #LC_H
  beq :+
    lda LevelBuf+0,x
    pha
    lda LevelBuf+3,x
    sta LevelBuf+0,x
    pla
    sta LevelBuf+3,x

    lda LevelBuf+1,x
    pha
    lda LevelBuf+2,x
    sta LevelBuf+1,x
    pla
    sta LevelBuf+2,x
  :

  txa
  axs #<-16
  txa
  sub #32
  and #%110000
  beq ChunkRowExit
  ldy TempVal
  iny
  iny
  jmp ChunkRow
ChunkRowExit:

  lda LevelChunk
  and #LC_V
  beq NoVertFlip
    ldy #4
    ldx LevelBufIndex
  : lda LevelBuf+(16*0),x
    pha
    lda LevelBuf+(16*3),x
    sta LevelBuf+(16*0),x
    pla
    sta LevelBuf+(16*3),x

    lda LevelBuf+(16*1),x
    pha
    lda LevelBuf+(16*2),x
    sta LevelBuf+(16*1),x
    pla
    sta LevelBuf+(16*2),x
    inx
    dey
    bne :-
NoVertFlip:

  inc ChunkNum
  lda ChunkNum
  cmp #12
  jne ChunkLoop    

JustFinishLevel:
  rts

MakeLevelBufIndexFromChunk:
  pha
  ; make vertical offset
  and #%1100
  asl
  asl
  asl
  asl
  add #16*2
  sta TempVal
  ; make horizontal
  pla
  and #%11
  asl
  asl
  add TempVal
  tax
  rts
.endproc

.proc LevelMapData
  .addr Map1, Map2
  .addr Map3, Map4
  .addr Map5, Map6
  .addr Map7, Map8
  .addr Map9, Map10
  .addr Map10
Map1:
  .byt $01,$00
  .byt LC_EMPTY, LC_EMPTY, LC_AMMO_SQUARE, LC_EMPTY
  .byt LC_EMPTY, LC_SMALL_CORNER, LC_H|LC_CORNER_PLAIN, LC_EMPTY
  .byt LC_CORNER_PLAIN, LC_HORIZ_TUNNEL_BREAK, LC_HORIZ_SOLID_LINE, LC_MIDDLE_3BLOCKS
Map2:
  .byt $01,$00
  .byt LC_EMPTY, LC_SMALL_CORNER, LC_PLATFORM, LC_EMPTY
  .byt LC_EMPTY, LC_CORNER_PLAIN, LC_SMALL_CORNER, LC_H|LC_V|LC_CORNER_PLAIN
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_EMPTY, LC_H|LC_CORNER_PLAIN
Map3:
  .byt $01,$00
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_V|LC_CORNER_PLAIN, LC_EMPTY
  .byt LC_H|LC_V|LC_SMALL_CORNER, LC_RIGHT_TRIANGLE, LC_AMMO_SQUARE, LC_VERT_SOLID_LINE
  .byt LC_EMPTY, LC_V|LC_RIGHT_TRIANGLE, LC_H|LC_RIGHT_TRIANGLE, LC_VERT_SOLID_LINE
Map4:
  .byt $01,$00
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_AMMO_SQUARE, LC_EMPTY
  .byt LC_H|LC_VERT_SOLID_LINE, LC_RIGHT_TRIANGLE, LC_H|LC_CORNER_BREAKABLE, LC_EMPTY
  .byt LC_EMPTY, LC_HORIZ_SOLID_LINE, LC_AMMO_SQUARE, LC_EMPTY
Map5:
  .byt $05,$00
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_EMPTY, LC_H|LC_CORNER_WITHOUT_CORNER
  .byt LC_H|LC_VERT_SOLID_LINE, LC_SMALL_CORNER, LC_H|LC_CORNER_PLAIN, LC_V|LC_CORNER_WITHOUT_CORNER
  .byt LC_EMPTY, LC_EMPTY, LC_AMMO_SQUARE, LC_EMPTY
Map6:
  .byt $02,$00
  .byt LC_AMMO_SQUARE, LC_V|LC_HORIZ_SOLID_LINE, LC_AMMO_SQUARE, LC_EMPTY
  .byt LC_VERT_SOLID_LINE, LC_V|LC_CORNER_AMMO, LC_V|LC_H|LC_CORNER_AMMO, LC_EMPTY
  .byt LC_CORNER_WITHOUT_CORNER, LC_H|LC_CORNER_BREAKABLE, LC_AMMO_SQUARE, LC_EMPTY
Map7:
  .byt $01,$00
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_H|LC_VERT_SOLID_LINE, LC_EMPTY
  .byt LC_V|LC_H|LC_SMALL_CORNER, LC_HORIZ_SOLID_LINE, LC_H|LC_CORNER_PLAIN, LC_V|LC_HORIZ_SOLID_LINE
  .byt LC_CORNER_PLAIN, LC_SMALL_CORNER, LC_AMMO_SQUARE, LC_EMPTY
Map8:
  .byt $01,$00
  .byt LC_V|LC_CORNER_PLAIN, LC_AMMO_SQUARE, LC_EMPTY, LC_EMPTY
  .byt LC_V|LC_SMALL_CORNER, LC_RIGHT_TRIANGLE, LC_AMMO_SQUARE, LC_EMPTY
  .byt LC_EMPTY, LC_V|LC_H|LC_RIGHT_TRIANGLE, LC_CORNER_BREAKABLE, LC_EMPTY
Map9:
  .byt $02,$00
  .byt LC_EMPTY, LC_V|LC_HORIZ_SOLID_LINE, LC_AMMO_SQUARE, LC_EMPTY
  .byt LC_V|LC_H|LC_RIGHT_TRIANGLE, LC_HORIZ_SOLID_LINE, LC_H|LC_CORNER_PLAIN, LC_HORIZ_SOLID_LINE
  .byt LC_EMPTY, LC_AMMO_SQUARE, LC_H|LC_V|LC_SMALL_CORNER, LC_V|LC_SMALL_CORNER
Map10:
  .byt $01,$00
  .byt LC_EMPTY, LC_EMPTY, LC_H|LC_SMALL_CORNER, LC_EMPTY
  .byt LC_HEALTH, LC_H|LC_SMALL_CORNER, LC_H|LC_SOLID_SQUARE, LC_EMPTY
  .byt LC_EMPTY, LC_V|LC_H|LC_SMALL_CORNER, LC_V|LC_SMALL_CORNER, LC_EMPTY
.endproc

.proc LevelAttributes
; enemy 1, enemy 2, enemy 3, enemy 4
; LevelSpinShootSpeed
; LevelSpinShootChance
; LevelSpinShootRate
; MaxScreenEnemies
; special stuff
; EnemiesLeftForNextLevel
; Speedup

; 1 start level
  .byt AOBJECT_SPINNER, AOBJECT_SPINNER, AOBJECT_SPINNER, AOBJECT_SPINNER
  .byt 8, %111, %1111, 4, 0, 20, 0, 0, 0, 0, 0, 0
; 2 introduce sliders
  .byt AOBJECT_BURGER1, AOBJECT_BURGER1, AOBJECT_SPINNER, AOBJECT_SPINNER
  .byt 8, %111, %1111, 4, 0, 20, 0, 0, 0, 0, 0, 0
; 3
  .byt AOBJECT_SPINNER, AOBJECT_GEORGE, AOBJECT_GEORGE, AOBJECT_GEORGE
  .byt 15, %111, %111, 6, 0, 20, 0, 0, 0, 0, 0, 0
; 4
  .byt AOBJECT_CANNON1, AOBJECT_SPINNER, AOBJECT_DIRTY_SHIRT, AOBJECT_MINE
  .byt 10, %111, %1111, 3, 0, 20, 0, 0, 0, 0, 0, 0
; 5 clean up the blocks with kaboom!
  .byt AOBJECT_SPINNER, AOBJECT_SPINNER, AOBJECT_SPINNER, AOBJECT_DIRTY_SHIRT
  .byt 8, %1111, %111, 4, LSF_DIRTY, 20, 0, 0, 0, 0, 0, 0
; 6 another kaboom level
  .byt AOBJECT_SPINNER, AOBJECT_SPINNER, AOBJECT_GEORGE, AOBJECT_GEORGE
  .byt 8, %111, %111, 4, LSF_DIRTY, 20, 0, 0, 0, 0, 0, 0
; 7
  .byt AOBJECT_KING, AOBJECT_KING, AOBJECT_BURGER1, AOBJECT_DIRTY_SHIRT
  .byt 8, %111, %111, 4, 0, 20, 0, 0, 0, 0, 0, 0
; 8
  .byt AOBJECT_BURGER3, AOBJECT_BURGER3, AOBJECT_BURGER3, AOBJECT_DIRTY_SHIRT
  .byt 8, %111, %111, 7, 0, 20, 0, 0, 0, 0, 0, 0
; 9
  .byt AOBJECT_KING, AOBJECT_KING, AOBJECT_KING, AOBJECT_KING
  .byt 8, %111, %111, 4, 0, 15, 4, 0, 0, 0, 0, 0
; 10 - boss
  .byt AOBJECT_BILL, AOBJECT_BILL, AOBJECT_BILL, AOBJECT_BILL
  .byt 8, %111, %111, 1, LSF_BOSS, 1, 0, 0, 0, 0, 0, 0
.endproc

.enum
  LC_EMPTY
  LC_MIDDLE_4BLOCKS
  LC_VERT_TUNNEL_BREAK
  LC_HORIZ_TUNNEL_BREAK
  LC_CORNER_BREAK
  LC_PLATFORM
  LC_PLATFORM_GAP
  LC_RIGHT_TRIANGLE
  LC_CORNER_BREAKABLE
  LC_CORNER_AMMO
  LC_CORNER_PLAIN
  LC_VERT_SOLID_LINE
  LC_HORIZ_SOLID_LINE
  LC_SOLID_FULL
  LC_AMMO_SQUARE
  LC_VERT_BREAK_LINE
  LC_HORIZ_BREAK_LINE
  LC_SMALL_CORNER
  LC_CORNER_WITHOUT_CORNER
  LC_MIDDLE_3BLOCKS
  LC_SOLID_SQUARE
  LC_HEALTH
.endenum
LC_H = %01000000
LC_V = %10000000

; ---How chunks correspond to LevelBuf blocks:--- 
; ................
; ................
; 0000111122223333
; 0000111122223333
; 0000111122223333
; 0000111122223333
; 4444555566667777
; 4444555566667777
; 4444555566667777
; 4444555566667777
; 88889999aaaabbbb
; 88889999aaaabbbb
; 88889999aaaabbbb
; 88889999aaaabbbb
; ................

MetaNybbleTable:
  .byt METATILE_EMPTY, METATILE_SOLID, METATILE_BREAKABLE, METATILE_MINE, METATILE_PLATFORM, METATILE_DIRTY, METATILE_AMMO, METATILE_HEALTH

.enum
  NYB_EMPTY
  NYB_SOLID
  NYB_BREAK
  NYB_MINE
  NYB_PLATF
  NYB_DIRTY
  NYB_AMMO
  NYB_HEALTH
.endenum

.proc RandomLevelParts
; 0 EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 1 MIDDLE_4BLOCKS
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 2 VERT_TUNNEL_BREAK
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_BREAK
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_BREAK
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_SOLID
; 3 HORIZ_TUNNEL_BREAK
  .byt (NYB_SOLID<<4)+NYB_BREAK,(NYB_BREAK<<4)+NYB_SOLID
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 4 CORNER_BREAK
  .byt (NYB_EMPTY<<4)+NYB_SOLID,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_SOLID,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_BREAK<<4)+NYB_BREAK,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_BREAK<<4)+NYB_BREAK,(NYB_EMPTY<<4)+NYB_EMPTY
; 5 PLATFORM
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_PLATF<<4)+NYB_PLATF,(NYB_PLATF<<4)+NYB_PLATF
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 6 PLATFORM_GAP
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_AMMO, (NYB_AMMO<<4) +NYB_EMPTY
  .byt (NYB_PLATF<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_PLATF
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 7 RIGHT_TRIANGLE
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 8 CORNER_BREAKABLE
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_BREAK<<4)+NYB_BREAK
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_BREAK<<4)+NYB_BREAK
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 9 CORNER_AMMO
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_AMMO<<4) +NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 10 CORNER_PLAIN
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 11 VERT_SOLID_LINE
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 12 HORIZ_SOLID_LINE
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 13 SOLID_FULL
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 14 AMMO_SQUARE
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_AMMO, (NYB_AMMO <<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_AMMO, (NYB_AMMO <<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 15 VERT_BREAK_LINE
  .byt (NYB_BREAK<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_BREAK<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_BREAK<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_BREAK<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 16 HORIZ_BREAK_LINE
  .byt (NYB_BREAK<<4)+NYB_BREAK,(NYB_BREAK<<4)+NYB_BREAK
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 17 SMALL_CORNER
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_AMMO <<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_AMMO, (NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_EMPTY<<4)+NYB_EMPTY
; 18 CORNER_WITHOUT_CORNER
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_BREAK<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 19 MIDDLE_3BLOCKS
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_SOLID<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 20 SOLID_SQUARE
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_SOLID
  .byt (NYB_SOLID<<4)+NYB_SOLID,(NYB_SOLID<<4)+NYB_SOLID
; 21 HEALTH
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_HEALTH,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_HEALTH<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 22
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 23
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
; 24
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
  .byt (NYB_EMPTY<<4)+NYB_EMPTY,(NYB_EMPTY<<4)+NYB_EMPTY
.endproc
