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

.proc ShootFromXY ; GunX=X, GunY=Y, A=Speed and flags, Y=Angle
Speed = 0
Angle = 1
  sta Speed
  sty Angle

  ldy #0
: lda BulletF,y
  beq FoundSlot
  iny
  cpy #BulletLen
  bne :-
  clc
  rts

FoundSlot:
  lda #0
  sta BulletPXL,y
  sta BulletPYL,y
  lda GunX
  add #4
  sta BulletPXH,y
  lda GunY
  add #4
  sta BulletPYH,y
  lda #%10000001
  sta BulletF,y
  tya
  pha
  lda Speed
  ldy Angle
  jsr SpeedAngle2Offset
  pla
  tay
  lda 0
  sta BulletVXL,y
  lda 1
  sta BulletVXH,y
  lda 2
  sta BulletVYL,y
  lda 3
  sta BulletVYH,y
  lda #70
  sta BulletLife,y
  sec
  rts
.endproc

.proc RunBullets
CurBullet = 10
  lda #0
  sta CurBullet ; current bullet counter

  tax   ; clear bullet map out first
: sta BulletMap+0,x
  sta BulletMap+8,x
  sta BulletMap+16,x
  sta BulletMap+24,x
  sta BulletMap+32,x
  sta BulletMap+40,x
  sta BulletMap+48,x
  sta BulletMap+56,x
  inx
  cpx #8
  bne :-

  ldy OamPtr

BulletLoop:
  ldx CurBullet
  lda BulletF,x
  jpl SkipBullet

  lda BulletPXL,x
  add BulletVXL,x
  sta BulletPXL,x
  lda BulletPXH,x
  adc BulletVXH,x
  sta BulletPXH,x

  lda BulletPYL,x
  add BulletVYL,x
  sta BulletPYL,x
  lda BulletPYH,x
  adc BulletVYH,x
  sta BulletPYH,x

  sty TempVal+1
  ; write to bullet map: 00yyyxxx
  lda BulletPYH,x
  lsr
  lsr
  and #%111000
  sta 1 ; Y is used for both versions
  lda BulletPXH,x
  alr #%11100000
  sta 2
  lsr ; ALR already takes care of the first shift
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y
  lda 2
  add #7
  and #%01110000
  cmp 2
  bne :+ ; most of the time the second write isn't needed, so avoid it when possible
  lsr ; / 32 pixels (right side)
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y
:
; now do the bottom half to be extra sure
  lda BulletPYH,x
  add #7
  lsr
  lsr
  and #%111000
  sta 1
  lda BulletPXH,x
  add #4
  lsr ; / 32 pixels (bottom
  lsr
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y

  ; check against level stuff
  lda BulletPXH,x
  add #4
  lsr
  lsr
  lsr
  lsr
  sta 1
  lda BulletPYH,x
  and #$f0
  ora 1
  tay
  lda LevelBuf,y
  sta 1
  cmp #METATILE_SOLID
  bcc NoBounce

  lda BulletF,x
  pha
  lda #0
  sta BulletF,x
  pla
  and #%01000000
  beq NoBounce ; enemy bullets won't affect anything

  lda 1
  cmp #METATILE_BREAKABLE
  bne NotBreakable
    lda #METATILE_EMPTY
    jsr ChangeBlock
    jmp NoBounce
;    lda retraces
;    add #10
;    sta 0
;    lda #METATILE_BREAKABLE
;    jsr AddDelayMetaEdit
NotBreakable:
  cmp #METATILE_DIRTY
  bne NotDirty
    lda #METATILE_SOLID
    jsr ChangeBlock
    dec LevelDirtyCount
NotDirty:
NoBounce:

  ldy TempVal+1

  lda BulletPYH,x
  sta OAM_YPOS+(4*0),y
  lda #0
  sta OAM_ATTR+(4*0),y
  lda BulletF,x        ; if second biggest bit is off, it's an enemy bullet and set color accordingly
  and #%01000000
  bne :+
    lda #1
    sta OAM_ATTR+(4*0),y
: lda #$1e
  sta OAM_TILE+(4*0),y
  lda BulletPXH,x
  sta OAM_XPOS+(4*0),y

  dec BulletLife,x
  bne :+
    lda #0
    sta BulletF,x
  :

  .repeat 4
    iny
  .endrep
SkipBullet:
  inc CurBullet
  lda CurBullet
  cmp #BulletLen
  jne BulletLoop

  lda #0
  sta OAM_YPOS+(4*0),y
  sta OAM_ATTR+(4*0),y
  sta OAM_TILE+(4*0),y
  sta OAM_XPOS+(4*0),y

  sty OamPtr
  rts
.endproc

.proc FindFreeBulletY ; carry set = success?
  pha
  ldy #0
: lda BulletF,y
  bpl Found
  iny
  cpy #BulletLen
  bne :-
NotFound:
  pla
  clc
  rts
Found:
  lda #0
  sta BulletVYH,y
  sec
  pla
  rts
.endproc
