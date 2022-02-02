; Big City Sliding Blaster
;
; Copyright 2013-2014 NovaSquirrel
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

.enum
METATILE_EMPTY
METATILE_PLATFORM
METATILE_AMMO
METATILE_HEALTH
METATILE_SPEEDUP
METATILE_BURGER1
METATILE_BURGER2
METATILE_BURGER3
METATILE_BURGER4
; solid area
METATILE_SOLID
METATILE_BREAKABLE
METATILE_MINE
METATILE_DIRTY
;METATILE_GRASSY
.endenum
FirstSolidTop = METATILE_SOLID

.proc MetatileTiledata
  .byt $20,$20,$20,$20 ; empty
  .byt $88,$89,$20,$20 ; platform
  .byt $8a,$8b,$9a,$9b ; ammo
  .byt $8c,$8d,$9c,$9d ; health
  .byt $8e,$8f,$9e,$9f ; speedup
  .byt $b0,$b1,$b4,$b5 ; \
  .byt $b2,$b3,$b6,$b7 ; | burger
  .byt $b8,$b9,$bc,$bd ; |
  .byt $ba,$bb,$be,$bf ; /
  ; --- solid ---
  .byt $80,$81,$90,$91 ; solid
  .byt $82,$83,$92,$93 ; breakable
  .byt $84,$85,$94,$95 ; mine
  .byt $86,$87,$96,$97 ; dirty
;  .byt $dd,$df,$fd,$ff ; grassy
.endproc

.if 0 ; not needed yet
.proc MetatileBecomes
  .byt METATILE_EMPTY    ; empty
  .byt METATILE_PLATFORM ; platform
  .byt METATILE_AMMO     ; ammo
  .byt METATILE_HEALTH   ; health
  .byt METATILE_SPEEDUP  ; speedup
  .byt 
  ; --- solid ---
  .byt METATILE_SOLID     ; solid
  .byt METATILE_BREAKABLE ; breakable
  .byt METATILE_MINE      ; mine
  .byt METATILE_DIRTY     ; dirty
.endproc
.endif

.proc MetatileFlags ; why does this table exist
  .byt %00000000        ; empty
  .byt %00000000        ; platform
  .byt %00000000        ; ammo
  .byt %00000000        ; health
  .byt %00000000        ; speedup
  .byt 0,0,0,0          ; burger
  ; --- solid ---
  .byt %00000000        ; solid
  .byt %00000000        ; breakable
  .byt %00000000        ; mine
  .byt %00000000        ; dirty
.endproc

.proc RenderLevelBuf ; As seen in DABG and FHBG!
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  tax
: sta AttribMap,x
  inx
  cpx #64
  bne :-

  PositionXY 0,   0, 0
  tax
MoreObj:
  ; Draw the top half of the blocks on the current row
  .dj_loop #16, 0

    lda LevelBuf,x
    asl
    asl
    tay
    lda MetatileTiledata+0,y
    sta PPUDATA
    lda MetatileTiledata+1,y
    sta PPUDATA

    inx
  .end_djl

  ; Go back and step through that row again!
  ; ( the bottom half still needs drawn )

  txa
  axs #16

  ; Draw the bottom half of the current row
  .dj_loop #16, 0
    txa
    lda LevelBuf,x
;    pha
;    pha
;    tay
;    lda MetatileBecomes,y
;    sta LevelBuf,x

;    pla    ; get block number
    asl
    asl
    tay
    lda MetatileTiledata+2,y
    sta PPUDATA
    lda MetatileTiledata+3,y
    sta PPUDATA

;    pla    ; get block number
.if 0
    tay
    lda MetatileFlags,y
    pha
    txa
    tay
    pla
    and #3
    beq :+ ; optimization: if it's zero it's already correct
    ora #128
    jsr ChangeBlockColor
  :
.endif

    inx
  .end_djl
  cpx #256-16 ; skip last 64 bytes (attributes table)
  jne MoreObj

  ldx #0
: lda AttribMap,x
  sta PPUDATA
  inx
  cpx #64
  bne :-

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

.proc ChangeBlock ; A-New block, Y-Block index
  sty 1
  stx 2
  sta LevelBuf,y
  sty 0           ; we need Y later when we calculate the PPU address
  asl
  asl
  tax             ; will fetch tiles from MetatileTiledata
                  ; now find a slot to put the block update in
  ldy #0
: lda BlockUpdateA1,y
  beq :+          ; empty slot found
  iny
  cpy #MaxNumBlockUpdates
  bne :-
  clc
  ldy 1
  ldx 2
  rts ;  no free slots
:
  lda MetatileTiledata+0,x
  sta BlockUpdateT1,y
  lda MetatileTiledata+1,x
  sta BlockUpdateT2,y
  lda MetatileTiledata+2,x
  sta BlockUpdateT3,y
  lda MetatileTiledata+3,x
  sta BlockUpdateT4,y

  tya
  tax

  lda 0           ; calculate PPU address now
  pha             ; starting with the top nybble
  lsr
  lsr
  alr #%111100    ; <- replacing "lsr, and #%11110"
  tay             ; index into PPURowAddr
  pla
  and #$0f        ; bottom nybble is the X index
  asl             ; multiply by two because blocks are 16 pixels wide
  sta 0
  lda PPURowAddrHi+0,y
  sta BlockUpdateA1,x
  lda PPURowAddrHi+1,y
  sta BlockUpdateB1,x

  lda PPURowAddrLo+0,y
  add 0
  sta BlockUpdateA2,x
  lda PPURowAddrLo+1,y
  add 0
  sta BlockUpdateB2,x
  sec             ; success
  ldy 1
  ldx 2
  rts
.endproc

PPURowAddrHi:
.repeat 30, I
  .byt >($2000+I*32)
.endrep
PPURowAddrLo:
.repeat 30, I
  .byt <($2000+I*32)
.endrep

.proc ChangeBlockColor ; A-New color (0 to 3), Y-Block index
                       ; http://wiki.nesdev.com/w/index.php/Attribute_table
  AttrIndexTemp = 4
  OnValue = 5
  SaveColor = 6
  SaveX = 7

  stx SaveX       ; level renderer uses X, so save it
  sta SaveColor
  and #3
  tax         ; save the particular color being used
  lda ValueMasks,x  ; start with it unshifted
  sta OnValue
  ; now determine how much to shift
  ldx #0      ; start at no shift
  tya
  lsr         ; odd X? move up one
  bcc :+
    inx
: tya
  and #$10 ;odd Y? move up two
  beq :+
    inx
    inx
  :

  lda OnValue
  and ShiftOnMasks,x
  sta OnValue

  ; Take the level buffer index and make it into an AttribMap index
  tya
  alr #$e0 ; Y half (discard last bit)
  lsr
  sta AttrIndexTemp
  tya
  alr #$e     ; X half (discard last bit)
  ora AttrIndexTemp
  tay

  lda AttribMap,y
  and ShiftOffMasks,x
  ora OnValue
  sta AttribMap,y
  sta OnValue
  ldx SaveX

  bit SaveColor
  bpl :+
    rts
  :
; Now locate a slot to queue the actual change
  ldx #0
: lda TileUpdateA1,x
  beq Found
  inx
  cpx #MaxNumTileUpdates
  bne :-
  clc ; failed
  rts
Found:

  lda OnValue
  sta TileUpdateT,x
  lda #$23
  sta TileUpdateA1,x
  tya
  add #$c0
  sta TileUpdateA2,x
  sec
  rts

ValueMasks:
  .byt %00000000
  .byt %01010101
  .byt %10101010
  .byt %11111111
ShiftOnMasks:
  .byt %00000011
  .byt %00001100
  .byt %00110000
  .byt %11000000
ShiftOffMasks:
  .byt %11111100
  .byt %11110011
  .byt %11001111
  .byt %00111111
.endproc

.proc IndexToBitmap ; Y = $yx -> Y = index, A = mask
  tya
  pha
  lsr
  lsr
  lsr
  sta TempVal+1
  pla
  and #7
  tay
  lda BitSelect,y
  ldy TempVal+1
  rts
.endproc

.proc AddDelayMetaEdit ; Y = $yx, A = type, 0 = time (destroys 1 and 2)
  sta 1
  sty 2
  ldy #0
: lda DelayedMetaEditType,y
  beq Found
  iny
  cpy #MaxDelayedMetaEdits
  bne :-
  ldy 2
  clc
  rts
Found:
  lda 0
  sta DelayedMetaEditTime,y
  lda 1
  sta DelayedMetaEditType,y
  lda 2
  sta DelayedMetaEditIndx,y
  ldy 2
  sec
  rts
.endproc
