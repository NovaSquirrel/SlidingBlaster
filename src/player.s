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

.proc SpeedAngle2Offset ; A = speed, Y = angle -> 0,1(X) 2,3(Y)
Angle = 4
Speed = 5
  sty Angle

  add Speedup
  add DifficultyMode
  adc DifficultyMode
  sta Speed

  lda CosineTable,y
  php
  bpl :+
  eor #255
  add #1
: ldy Speed
  jsr mul8
  sty 0
  sta 1

  plp
  bpl :+
  neg16 0
:

  ldy Angle
  lda SineTable,y
  php
  bpl :+
  eor #255
  add #1
: ldy Speed
  jsr mul8
  sty 2
  sta 3
  plp
  bpl :+
  neg16 2
:
  rts
.endproc

.proc HandlePlayer
  lda PlayerInvincible,x
  beq :+
    dec PlayerInvincible,x
  :

  lda mouseEnabled,x
  beq :+
    lda #0
    sta RacecarMode,x
  :

  cpx #1 ; disable player 2 if they run out of health
  bne :+
  lda PlayerHealth+1
  bne :+
    sta PlayerEnabled+1
    rts
  :

  ; give 1 ammo every 4 seconds the player is without any to make it a little easier
  lda PlayerAmmo,x
  beq :+
    lda #0
    sta PlayerTimeWithoutAmmo,x
  :

  lda PlayerAmmo,x
  bne :+
    inc PlayerTimeWithoutAmmo,x
    lda PlayerTimeWithoutAmmo,x
    cmp #240
    bcc :+
      inc PlayerAmmo,x
  :

  lda RacecarMode,x ; racecar mode has its own shoot angle
  bne :+
  lda PlayerPXH,x
  add #4
  sta 0
  lda PlayerPYH,x
  add #4
  sta 1
  lda CursorPXH,x
  sta 2
  lda CursorPYH,x
  sta 3
  jsr getAngle
  sta PlayerShootAngle,x
:

  lda RacecarMode,x
  jeq NotRacecar
  cmp #2
  jne NormalRacecar

  lda retraces ; slow it down some
  and #1
  bne ExitToNotCar

  ; simpler movement
  lda keydown,x
  and #15
  tay
  lda TargetAngles,y
  bmi ExitToNotCar   ; not a valid angle to target
  sta 0 ; target

  lda PlayerShootAngle,x
  sta 2
  sub 0
  bpl :+ ; absolute value
  eor #255
  add #1
: sta 1  ; abs(difference)
  beq ExitToNotCar  ; difference = 0? don't turn

  cmp #16 ; turning 180 degrees? random direction then
  bne :+
   lda PlayerShootAngle,x
   add #16
   sta PlayerShootAngle,x
;  jsr huge_rand
;  lsr
;  and #1
;  tay
;  lda OneMinusOne,y
;  add PlayerShootAngle,x
;  sta PlayerShootAngle,x
  jmp ExitToNotCar
:

  cmp #16
  bcs :+
  lda 2
  cmp 0
  bcc :+
  dec PlayerShootAngle,x
  jmp ExitToNotCar
:

  lda 1
  cmp #16
  bcc :+
  lda 2
  cmp 0
  bcs :+
  dec PlayerShootAngle,x
  jmp ExitToNotCar
:

  inc PlayerShootAngle,x
ExitToNotCar:
  lda PlayerShootAngle,x ; restrict to the range of 0-31
  and #31
  sta PlayerShootAngle,x
  jmp NotRacecar

TargetAngles: ;up, down, left, right
.byt <-1,  0, 16, <-1,  8,  4, 12, <-1
.byt 24, 28, 20, <-1, <-1, <-1, <-1, <-1
; OneMinusOne: .byt 1, -1

NormalRacecar:
  lda retraces
  and #1
  beq :++
  lda keydown,x
  and #KEY_LEFT
  beq :+
    dec PlayerShootAngle,x
: lda keydown,x
  and #KEY_RIGHT
  beq :+
    inc PlayerShootAngle,x
: lda keynew,x
  and #KEY_UP|KEY_DOWN
  beq :+
    lda PlayerShootAngle,x
    add #16
    sta PlayerShootAngle,x
: lda PlayerShootAngle,x
  and #31
  sta PlayerShootAngle,x
NotRacecar:

  ; mouse users don't have a select button, so let them
  ; press it anyway by holding the right mouse button for 3 seconds
  lda keydown,x
  and #KEY_A
  bne :+
    lda #0
    sta PlayerHoldR,x
  :

  lda keydown,x
  and #KEY_A
  beq :+
    lda mouseEnabled,x
    beq :+
      inc PlayerHoldR,x
      lda PlayerHoldR,x
      cmp #180
      beq DoSelect
  :

  lda keynew,x
  and #KEY_SELECT
  beq :+
DoSelect:
    lda EditMode
    beq NoStartEditor
    pla
    pla
    lda #0
    sta CrashDetect
    jmp StartEditorNormal
NoStartEditor:
    lda #0
    sta EnableNMIDraw
    pla
    pla
    lda #0
    sta CrashDetect
    inc LevelMapNumber
    jmp NewLevel
  :

  lda keynew,x
  and #KEY_A
  beq :+
    lda PlayerSpeedBurst,x
    bne :+
      lda PlayerShootAngle,x
      sta PlayerAngle,x
      lda #5
      sta PlayerSpeed,x
      asl
      sta PlayerSpeedBurst,x
      sta PlayerSpeedBurstRate,x

      ldy PlayerSpeedupTimer
      beq NoSpeedup
        lda #7
        sta PlayerSpeed,x
      NoSpeedup:

      lda #SOUND_BOOST
      jsr start_sound
 :

  lda PlayerSpeedBurst,x
  beq NoBoost
    dec PlayerSpeedBurst,x
    lda PlayerSpeedBurst,x
    bne NoBoost
      dec PlayerSpeed,x
      lda PlayerSpeed,x
      cmp #2
      beq NoBoost
      lda PlayerSpeedBurstRate,x
      sta PlayerSpeedBurst,x
  NoBoost:

.scope
VelXL = 0
VelXH = 1
VelYL = 2
VelYH = 3
CheckX = 4
CheckY = 5
Temp = 6
Bumped = 8
  lda #0
  sta Bumped

  ldy PlayerAngle,x
  lda PlayerSpeed,x
  jsr SpeedAngle2Offset

  lda PlayerPXH,x
  add VelXH
  bit VelXH
  bmi :+
    add #15
: sta CheckX

  lsr
  lsr
  lsr
  lsr
  sta Temp
  lda PlayerPYH,x
  add #8
  and #$f0
  ora Temp
  tay
  lda LevelBuf,y
  cmp #METATILE_SOLID
  bcc NoTouchH
    inc Bumped
    lda #16
    sub PlayerAngle,x
    bpl :+
    add #32
  : sta PlayerAngle,x
  NoTouchH:

  lda PlayerPYH,x
  add VelYH
  bit VelYH
  bmi :+
    add #15
: sta CheckY

  and #$f0
  sta Temp
  lda PlayerPXH,x
  add #8
  lsr
  lsr
  lsr
  lsr
  ora Temp
  tay
  lda LevelBuf,y
  cmp #METATILE_SOLID
  bcc NoTouchV
    inc Bumped
    lda PlayerAngle,x
    eor #255
    add #1
    and #31
    sta PlayerAngle,x
  NoTouchV:

; apply velocity
  lda PlayerPXL,x
  add VelXL
  sta PlayerPXL,x
  lda PlayerPXH,x
  adc VelXH
  sta PlayerPXH,x

  lda PlayerPYL,x
  add VelYL
  sta PlayerPYL,x
  lda PlayerPYH,x
  adc VelYH
  sta PlayerPYH,x

  lda Bumped
  beq :+
    lda PlayerBumpSoundTimer,x
    bne :+
      lda #16
      sta PlayerBumpSoundTimer,x
      lda #SOUND_BUMP
      jsr start_sound
  :
.endscope
  lda PlayerBumpSoundTimer,x
  beq :+
    dec PlayerBumpSoundTimer,x
  :

  lda PlayerSpeedupTimer,x
  beq :+
    dec PlayerSpeedupTimer,x
  :

  lda keynew,x
  beq :+
  sta PlayerPressedAnything,x
:

  lda PlayerPressedAnything,x
  jeq NoAmmoCheck
; check for ammo
  lda PlayerPXH,x
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda PlayerPYH,x
  and #$f0
  ora 0
  jsr CheckTouchTile

  lda PlayerPXH,x
  add #15
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda PlayerPYH,x
  and #$f0
  ora 0
  jsr CheckTouchTile

  lda PlayerPXH,x
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda PlayerPYH,x
  add #15
  and #$f0
  ora 0
  jsr CheckTouchTile

  lda PlayerPXH,x
  add #15
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda PlayerPYH,x
  add #15
  and #$f0
  ora 0
  jsr CheckTouchTile
NoAmmoCheck:

  ldy PlayerShootAngle,x
  lda CosineTable,y
  cmp #80
  ror
  cmp #80
  ror
  add PlayerPXH,x
  sta GunX
  lda SineTable,y
  cmp #80
  ror
  cmp #80
  ror
  add PlayerPYH,x
  sta GunY

  lda keynew,x
  and #KEY_B
  beq NoShoot
    lda PlayerAmmo,x
    beq NoShoot
    dec PlayerAmmo,x
    ldy PlayerShootAngle,x
    lda #8
    jsr ShootFromXY
    bcc NoShoot
    lda BulletF,y
    ora #%11000000
    sta BulletF,y
    lda #SOUND_SHOOT
    jsr start_sound
NoShoot:

  jsr PlayerGetShot
  bcc :+
    txa
    tay
    lda #3
    jsr HurtPlayer
  :

  lda RacecarMode,x
  jeq HandleCursor
  rts

CheckTouchTile:
  tay
  lda LevelBuf,y
  cmp #METATILE_AMMO
  bne NotAmmo
    lda #METATILE_EMPTY
    jsr ChangeBlock
    lda retraces_16th
    add #40
    sta 0
    lda #METATILE_AMMO
    jsr AddDelayMetaEdit

    lda #30
    sta 0 ; limit
    lda EasyMode
    beq :+
      lda #99
      sta 0
    :

    lda PlayerAmmo,x
    add #5
    sta PlayerAmmo,x
    cmp 0
    bcc :+
      lda 0
      sta PlayerAmmo,x
    :
  SoundEffectWithDebounce:
    lda CollectSoundDebounce
    bne NotHealth
    lda #SOUND_COLLECT
    sta NeedSound
    lda #15
    sta CollectSoundDebounce
    rts
  NotAmmo:
  cmp #METATILE_HEALTH
  bne NotHealth
    lda #METATILE_EMPTY
    jsr ChangeBlock
    lda retraces_16th
    add #90
    sta 0
    lda #METATILE_HEALTH
    jsr AddDelayMetaEdit

    lda PlayerHealth,x
    add #5
    sta PlayerHealth,x
    cmp #50
    bcc :+
      lda #50
      sta PlayerHealth,x
    :
    jmp SoundEffectWithDebounce
  NotHealth:
  rts
.endproc

.proc DispPlayer
  lda PlayerInvincible,x
  beq :+
  lda retraces
  lsr
  bcc :+
  rts
:
  ldy OamPtr

  lda PlayerPYH,x
  sub #1
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*4),y
  add #8
  sta OAM_YPOS+(4*3),y
  sta OAM_YPOS+(4*5),y

  cpx #1
  beq NormalTiles
  lda #8
  sta OAM_TILE+(4*2),y
  lda #9
  sta OAM_TILE+(4*3),y
  lda #10
  sta OAM_TILE+(4*4),y
  lda #11
  sta OAM_TILE+(4*5),y
  bne :+
NormalTiles:
  lda #0
  sta OAM_TILE+(4*2),y
  lda #1
  sta OAM_TILE+(4*3),y
  lda #2
  sta OAM_TILE+(4*4),y
  lda #3
  sta OAM_TILE+(4*5),y
:

  lda #0
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y
  sta OAM_ATTR+(4*4),y
  sta OAM_ATTR+(4*5),y

  lda PlayerPXH,x
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*3),y
  add #8
  sta OAM_XPOS+(4*4),y
  sta OAM_XPOS+(4*5),y

  lda CursorPXH,x
  sta OAM_XPOS+(4*0),y
  lda CursorPYH,x
  sub #1
  sta OAM_YPOS+(4*0),y
  txa
  sta OAM_ATTR+(4*0),y
  lda #$1c
  sta OAM_TILE+(4*0),y

  lda RacecarMode,x ; no cursor in racecar mode
  beq :+
    lda #<-16
    sta OAM_YPOS+(4*0),y
  :

  lda GunX
  add #4
  sta OAM_XPOS+(4*1),y
  lda GunY
  add #3
  sta OAM_YPOS+(4*1),y
  txa
  sta OAM_ATTR+(4*1),y
  lda #$1d
  sta OAM_TILE+(4*1),y

  tya
  add #6*4
  sta OamPtr
  rts
.endproc

.proc PlayerGetShot
  lda PlayerPYH,x
  add #8
  lsr
  lsr
  and #%111000
  sta TempVal
  lda PlayerPXH,x
  add #4
  lsr ; / 32 pixels
  lsr
  lsr
  lsr
  lsr
  ora TempVal
  tay
  lda BulletMap,y
  beq Exit

  ldy #0
BulletLoop:
  lda BulletF,y
  and #%10000000
  cmp #%10000000 ;enabled bullets only
  bne SkipBullet

  lda BulletPXH,y
  sta TouchLeftA
  lda BulletPYH,y
  sta TouchTopA

  lda PlayerPXH,x
  sta TouchLeftB
  lda PlayerPYH,x
  sta TouchTopB

  lda #8
  sta TouchWidthA
  sta TouchHeightA
  asl
  sta TouchWidthB
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcs ShotHit
SkipBullet:
  iny
  cpy #BulletLen
  bne BulletLoop
Exit:
  clc
  rts
ShotHit:
  lda #0
  sta BulletF,y
  sec
  rts
.endproc

CROSSHAIR_ACCEL_NTSC = 40
CROSSHAIR_MAX_VEL_NTSC = 4*256

.proc HandleCursor
crosshairDXLo = CursorVXL
crosshairDXHi = CursorVXH
crosshairDYLo = CursorVYL
crosshairDYHi = CursorVYH
crosshairXLo  = CursorPXL
crosshairXHi  = CursorPXH
crosshairYLo  = CursorPYL
crosshairYHi  = CursorPYH
cur_keys = keydown
  lda mouseEnabled,x
  bne noAdjustSpeed
  lda #<CROSSHAIR_MAX_VEL_NTSC
  sta abl_maxVel
  lda #>CROSSHAIR_MAX_VEL_NTSC
  sta abl_maxVel+1
  lda #CROSSHAIR_ACCEL_NTSC
  sta abl_accelRate
  asl a
  asl a
  sta abl_brakeRate

  lda crosshairDXLo,x
  sta abl_vel
  lda crosshairDXHi,x
  sta abl_vel+1
  lda cur_keys,x
  sta abl_keys
  jsr DoAccelBrakeLimit
  lda abl_vel
  sta crosshairDXLo,x
  lda abl_vel+1
  sta crosshairDXHi,x

  lda crosshairDYLo,x
  sta abl_vel
  lda crosshairDYHi,x
  sta abl_vel+1
  lda cur_keys,x
  lsr a
  lsr a
  sta abl_keys
  jsr DoAccelBrakeLimit
  lda abl_vel
  sta crosshairDYLo,x
  lda abl_vel+1
  sta crosshairDYHi,x
noAdjustSpeed:
  
  clc
  lda crosshairDXLo,x
  adc crosshairXLo,x
  sta crosshairXLo,x
  lda crosshairDXHi,x
  adc crosshairXHi,x
  sta crosshairXHi,x
  ; the carry should match the sign of the velocity
  ; if it doesn't, there was a wrap
.if 1
  ror a
  eor crosshairDXHi,x
  bpl notWrappedX
  eor crosshairDXHi,x
  asl a
  jmp limitX
notWrappedX:
  lda crosshairXHi,x
  cmp #$F8
  bcs limitX
  cmp #$08
  bcs noLimitX
limitX:
  lda #0
  sta crosshairDXLo,x
  sta crosshairDXHi,x
  sta crosshairXLo,x
  lda #$08
  bcc noLimitX
  lda #$F8
noLimitX:
.endif
  sta crosshairXHi,x

  clc
  lda crosshairDYLo,x
  adc crosshairYLo,x
  sta crosshairYLo,x
  lda crosshairDYHi,x
  adc crosshairYHi,x
  sta crosshairYHi,x
  ; the carry should match the sign of the velocity
  ; if it doesn't, there was a wrap
.if 1
  ror a
  eor crosshairDYHi,x
  bpl notWrappedY
  eor crosshairDYHi,x
  asl a
  jmp limitY
notWrappedY:
  lda crosshairYHi,x
  cmp #$E0
  bcs limitY
  cmp #$8
  bcs noLimitY
limitY:
  lda #0
  sta crosshairDYLo,x
  sta crosshairDYHi,x
  sta crosshairYLo,x
  lda #$8
  bcc noLimitY
  lda #$E0
noLimitY:
.endif
  sta crosshairYHi,x
  
  rts
.endproc

.proc DoAccelBrakeLimit
  lsr abl_keys
  bcc notAccelRight

  ; if traveling to left, brake instead
  lda abl_vel+1
  bmi notAccelRight
  
  ; Case 1: nonnegative velocity, accelerating positive
  clc
  lda abl_accelRate
  adc abl_vel
  sta abl_vel
  lda #0
  adc abl_vel+1
  sta abl_vel+1
  
  ; clamp maximum velocity
  lda abl_vel
  cmp abl_maxVel
  lda abl_vel+1
  sbc abl_maxVel+1
  bcc notOverPosLimit
  lda abl_maxVel
  sta abl_vel
  lda abl_maxVel+1
  sta abl_vel+1
notOverPosLimit:
  rts
notAccelRight:

  lsr abl_keys
  bcc notAccelLeft
  ; if traveling to right, brake instead
  lda abl_vel+1
  bmi isAccelLeft
  ora abl_vel
  bne notAccelLeft
isAccelLeft:

  ; Case 2: nonpositive velocity, accelerating negative
  ;sec  ; already guaranteed set from bcc statement above
  lda abl_accelRate
  eor #$FF
  adc abl_vel
  sta abl_vel
  lda #$FF
  adc abl_vel+1
  sta abl_vel+1

  ; clamp maximum velocity
  clc
  lda abl_maxVel
  adc abl_vel
  lda abl_maxVel+1
  adc abl_vel+1
  bcs notUnderNegLimit
  sec
  lda #0
  sbc abl_maxVel
  sta abl_vel
  lda #0
  sbc abl_maxVel+1
  sta abl_vel+1
notUnderNegLimit:
  rts
notAccelLeft:

  lda abl_vel+1
  bmi brakeNegVel
  
  ; Case 3: Velocity > 0 and brake
  sec
  lda abl_vel
  sbc abl_brakeRate
  sta abl_vel
  lda abl_vel+1
  sbc #0
  bcs notZeroVelocity
zeroVelocity:
  lda #0
  sta abl_vel
notZeroVelocity:
  sta abl_vel+1
  rts

brakeNegVel:
  ; Case 4: Velocity < 0 and brake
  clc
  lda abl_vel
  adc abl_brakeRate
  sta abl_vel
  lda abl_vel+1
  adc #0
  bcs zeroVelocity
  sta abl_vel+1
  rts
.endproc

.proc ChkTouchGeneric
  jsr :+
  swapa TouchLeftA,   TouchLeftB
  swapa TouchTopA,    TouchTopB
  swapa TouchWidthA,  TouchWidthB
  swapa TouchHeightA, TouchHeightB
  jsr :+
  clc ; no collision
  rts
: lda TouchLeftB
  add TouchWidthB
  sta TouchRight
  lda TouchTopB
  add TouchHeightB
  sta TouchBottom

  lda TouchLeftA
  cmp TouchLeftB
  bcc :+

  lda TouchLeftA
  cmp TouchRight
  bcs :+

  lda TouchTopA
  cmp TouchTopB
  bcc :+

  lda TouchTopA
  cmp TouchBottom
  bcs :+
  pla
  pla
  sec ; collision detected
: rts
.endproc

.proc HurtPlayer ; A=amount, Y=player
;  add DifficultyMode
  pha
  lda PlayerInvincible,y
  bne NoHurt
  sty TempVal+1
  stx TempVal+2
  lda #SOUND_YOUHURT
  jsr start_sound
  ldx TempVal+2
  ldy TempVal+1
  lda #80
  sta PlayerInvincible,y
  pla
  add DifficultyMode
  sta TempVal+1
  lda PlayerHealth,y
  sub TempVal+1
  sta PlayerHealth,y
  bmi :+
  rts
: lda #0
  sta PlayerHealth,y
  rts
NoHurt:
  pla
  rts
.endproc
