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

.proc RunObjects
  ldx #0
: jsr LaunchA
  inx
  cpx #AObjectLen
  beq Exit
  jmp :-

LaunchA:
  lda #0
  sta NoBounceTouch
  lda AObjectF1,x
  and #31
  beq Exit
  asl
  tay

; push address
  lda AObjectTable+1,y
  pha
  lda AObjectTable+0,y
  pha
  rts

Exit:
  rts
.endproc

.proc EmptyObject
  rts
.endproc

.proc AObjectTable
  .raddr EmptyObject
  .raddr AObject_Spinner
  .raddr AObject_Cannon ; cannon 1
  .raddr AObject_Cannon ; cannon 2, shoots sneakers
  .raddr AObject_Burger1
  .raddr AObject_Burger1
  .raddr AObject_Burger1
  .raddr AObject_George
  .raddr AObject_King
  .raddr AObject_Mine
  .raddr AObject_Pickup ; powerup
  .raddr AObject_Pickup
  .raddr AObject_Pickup
  .raddr AObject_Pickup
  .raddr AObject_Shirt
  .raddr AObject_Bill
  .raddr AObject_MightyBurger

  ; padding
  .raddr AObject_Mine
  .raddr AObject_Mine
  .raddr AObject_Mine
  .raddr AObject_Mine
  .raddr AObject_Mine
.endproc

.enum
  AOBJECT_NONE
  AOBJECT_SPINNER
  AOBJECT_CANNON1 ; shoots burger1s
  AOBJECT_CANNON2
  AOBJECT_BURGER1 ; just drift until it hits something
  AOBJECT_BURGER2
  AOBJECT_BURGER3
  AOBJECT_GEORGE ; rides against stuff
  AOBJECT_KING
  AOBJECT_MINE
  AOBJECT_PICKUP_AMMO
  AOBJECT_PICKUP_HEALTH
  AOBJECT_PICKUP_SPEED
  AOBJECT_PICKUP_BOMB
  AOBJECT_DIRTY_SHIRT    ; gets cleaned by getting shot
  AOBJECT_BILL
  AOBJECT_MIGHTYBURGER
.endenum

ObjectIsEnemyTable:
  .byt 0
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 1
  .byt 0
  .byt 0
  .byt 0
  .byt 0
  .byt 0 ; shirt

.proc AObjectShoot
  pha
  lda AObjectPXH,x
  add #4
  sta GunX
  lda AObjectPYH,x
  add #4
  sta GunY
  pla
  jsr ShootFromXY
  rts
.endproc

.proc AObjectAimAtPlayer
  lda AObjectPXH,x
  sta 0
  lda AObjectPYH,x
  sta 1
  lda PlayerPXH
  sta 2
  lda PlayerPYH
  sta 3
  jmp getAngle
.endproc

.proc AObject_Spinner
  lda AObjectF2,x
  cmp #2
  bne NotTeleporting

  jsr huge_rand
  and #63
  sub #32
  add AObjectPXH,x
  sta AObjectPXH,x
  add #8
  pha

  jsr huge_rand
  and #63
  sub #32
  add AObjectPYH,x
  sta AObjectPYH,x
  add #8
  and #$f0
  sta 0
  pla
  lsr
  lsr
  lsr
  lsr
  ora 0
  tay
  lda LevelBuf,y
  bne :+
    lda #0
    sta AObjectF2,x
  :

  ldy #ADRAW_HMIRROR
  lda retraces
  and #8
  lsr
  lsr
  add #$74
  jmp AObjectDrawEx
NotTeleporting:
  lda retraces
  and #3
  bne :+
  jsr huge_rand
  and #%111
  bne :+
    jsr AObjectAimAtPlayer
    sta AObjectAngle,x
: lda retraces
  and LevelSpinShootRate
  bne :+
  jsr huge_rand
  and LevelSpinShootChance
  bne :+
    ldy AObjectAngle,x
    lda LevelSpinShootSpeed
    jsr AObjectShoot
  :

  jsr AObjectPlayerTouch
  jsr AObjectHurtPlayerIfTouched
  jsr AObjectGetShot
  jsr AObjectGetHurtFromShot
  lda #1
  jsr AObjectUpdateVelocity
  lda #0
  sta 0
  jsr AObjectCheckBounce
  lda 0
  beq :+
    jsr huge_rand
    lsr
    lsr
    and #7
    bne :+
      lda #2
      sta AObjectF2,x
  :
  jsr AObjectApplyVelocity
  ldy #ADRAW_HMIRROR
  lda retraces
  and #8
  lsr
  lsr
  add #$40
  jsr AObjectDrawEx
  rts
.endproc

.proc AObject_Cannon
  jsr AObjectPlayerTouch
  jsr AObjectHurtPlayerIfTouched
  jsr AObjectGetShot
  jsr AObjectGetHurtFromShot
  lda #6
  jsr AObjectUpdateVelocity
  jsr AObjectApplyVelocity

  ; shoot
  lda retraces
  and #63
  jne NoShoot
     jsr huge_rand
     lsr
     jcc NoShoot
       jsr AObjectAimAtPlayer
       sta 10
       txa
       pha
       jsr FindFreeAObjectX
       jcc NoShoot
       txa
       tay
       pla
       tax

       lda AObjectPXH,x
       sta AObjectPXH,y
       lda AObjectPYH,x
       sta AObjectPYH,y
       lda #0
       sta AObjectPXL,y
       sta AObjectPYL,y
       sta AObjectVXL,y
       sta AObjectVXH,y
       sta AObjectVYL,y
       sta AObjectVYH,y
       sta AObjectF2,y
       lda #1
       sta AObjectF3,y
       lda #30
       sta AObjectTimer,y
       lda #AOBJECT_BURGER2
       sta AObjectF1,y
       lda 10
       sta AObjectAngle,y
NoShoot:

  ldy #ADRAW_VMIRROR
  lda AObjectPXH,x
  bpl :+
    ldy #ADRAW_VMIRROR|ADRAW_HFLIP
: lda #$54
  jsr AObjectDrawEx
  rts
.endproc

MakeMightyBurger:
  lda #0
  sta AObjectF3,x
  lda #AOBJECT_MIGHTYBURGER
  sta AObjectF1,x
  rts

.proc AObject_Burger1
  lda AObjectF1,x
  sub #AOBJECT_BURGER1
  and #31
  sta 10
  jsr AObjectPlayerTouch
  jsr AObjectHurtPlayerIfTouched
  jsr AObjectGetShot
  lda LevelSpecialFlags
  and #LSF_BOSS
  beq :+
  bcs MakeMightyBurger
: jsr AObjectGetHurtFromShot
  ldy 10
  lda BaseSpeeds,y
  jsr AObjectUpdateVelocity
  jsr AObjectApplyVelocity
  lda 10
  asl
  asl
  add #$44
  jsr AObjectDraw
  lda 10
  cmp #1 ; burger shot from cannon
  bne :+
  jsr AObjectTimerTick
  rts
: cmp #2 ; fast, shooty burger
  bne :+
  lda retraces
  and #7
  bne :+
  jsr huge_rand
  and #7
  bne :+
  jsr AObjectAimAtPlayer
  tay
  lda LevelSpinShootSpeed
  jsr AObjectShoot
: rts
BaseSpeeds:
  .byt 6, 12, 10
.endproc

.proc AObject_Shirt
  jsr AObjectGetShot
  bcc :+
    lda AObjectF2,x
    bne :+
    lda #3
    sta AObjectF2,x
    lda #150
    sta AObjectTimer,x
: lda #6
  jsr AObjectUpdateVelocity
  jsr AObjectCheckBounce
  jsr AObjectApplyVelocity
 
  lda retraces
  lsr
  bcc :+
  inc AObjectTimer,x
  lda AObjectTimer,x
  cmp #180
  bne :+
    lda AObjectF2,x
    bne TurnToHealth    
    lda #0
    sta AObjectF1,x
    rts
TurnToHealth:
    lda #AOBJECT_PICKUP_HEALTH
    sta AObjectF1,x
    lda #160
    sta AObjectTimer,x
    rts
  :

  lda AObjectF2,x
  cmp #3
  beq :+
  lda #$78
  jsr AObjectDraw
  rts
: lda #$7c
  jsr AObjectDraw
  rts
.endproc

.proc AObject_George
Bumped = 0
  jsr AObjectPlayerTouch
  jsr AObjectHurtPlayerIfTouched
  jsr AObjectGetShot
  jsr AObjectGetHurtFromShot

  lda #8
  jsr AObjectUpdateVelocity
  lda #0
  sta Bumped
  jsr AObjectCheckBounce

  lda AObjectTimer,x
  beq :+
    dec AObjectTimer,x
    bne :+
      lda #0
      sta AObjectF2,x
      jsr huge_rand
      and #31
      sta AObjectAngle,x
  :

  lda Bumped
  beq :+
  lda AObjectF2,x
  bne :+
    jsr huge_rand
    and #1
    ora #4
    sta AObjectF2,x
    lda #90
    sta AObjectTimer,x
: jsr AObjectApplyVelocity

  lda AObjectF2,x
  cmp #4
  bne :+
    inc AObjectAngle,x
: lda AObjectF2,x
  cmp #5
  bne :+
    dec AObjectAngle,x
: lda AObjectAngle,x
  and #31
  sta AObjectAngle,x

  lda #$50
  jmp AObjectDraw
.endproc

.proc AObject_King
  jsr AObjectPlayerTouch
  jsr AObjectHurtPlayerIfTouched
  jsr AObjectGetShot
  jsr AObjectGetHurtFromShot
  lda retraces
  and #63
  cmp #32
  bcc :+
    and #31
    sta 0
    lda #31
    sub 0
  :
  cmp #0
  bne :++
    pha
    jsr huge_rand
    sta 0
    and #1
    sta AObjectF3,x
    lda 0
    and #%1100
    bne :+
    jsr AObjectAimAtPlayer
    tay
    lda LevelSpinShootSpeed
    jsr AObjectShoot
  : pla
  :
  jsr AObjectUpdateVelocity
  lda retraces
  and #3
  bne NoChangeAngle
  lda AObjectF3,x
  lsr
  pha
  bcc :+
  dec AObjectAngle,x
: pla
  bcs :+
  inc AObjectAngle,x
: lda AObjectAngle,x
  and #31
  sta AObjectAngle,x
NoChangeAngle:
  jsr AObjectCheckBounce
  jsr AObjectApplyVelocity
  lda #$58
  jmp AObjectDraw
.endproc

.proc AObject_Bill
;  jsr AObjectPlayerTouch
;  jsr AObjectHurtPlayerIfTouched
;  jsr AObjectGetShot
  lda #5
  jsr AObjectUpdateVelocity
  jsr AObjectApplyVelocity

  lda AObjectPXH,x
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda AObjectPYH,x
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  cmp #METATILE_BURGER1
  bcc :+
  cmp #METATILE_BURGER4+1
  bcs :+
    lda #0
    sta EnemiesLeftForNextLevel
  :


  lda retraces
  and #15
  bne :+
  jsr huge_rand
  and #15
  bne :+
  jsr AObjectAimAtPlayer
  sta AObjectAngle,x
:

  lda retraces
  and #7
  bne :+
  jsr huge_rand
  and #3
  bne :+
  pha
  ldy AObjectAngle,x
  lda AObjectPXH,x
  add #12-4
  sta GunX
  lda AObjectPYH,x
  add #16-4
  sta GunY
  pla
  lda #15
  jsr ShootFromXY
:

; draw Billy Mays
  ldy OamPtr
  lda AObjectPXH,x
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*3),y
  sta OAM_XPOS+(4*6),y
  sta OAM_XPOS+(4*9),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*4),y
  sta OAM_XPOS+(4*7),y
  sta OAM_XPOS+(4*10),y
  add #8
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*5),y
  sta OAM_XPOS+(4*8),y
  sta OAM_XPOS+(4*11),y

  lda AObjectPYH,x
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*2),y
  add #8
  sta OAM_YPOS+(4*3),y
  sta OAM_YPOS+(4*4),y
  sta OAM_YPOS+(4*5),y
  add #8
  sta OAM_YPOS+(4*6),y
  sta OAM_YPOS+(4*7),y
  sta OAM_YPOS+(4*8),y
  add #8
  sta OAM_YPOS+(4*9),y
  sta OAM_YPOS+(4*10),y
  sta OAM_YPOS+(4*11),y

  stx 0
  ldx #$80
: txa
  sta OAM_TILE+(4*0),y
  lda #1
  sta OAM_ATTR+(4*0),y
  iny
  iny
  iny
  iny
  inx
  cpx #$80+12
  bne :-
  ldx 0

  sty OamPtr
  rts
.endproc

.proc MightyBurgerTouch
;  txa ; cut down on the number of collisions
;  sta 0
;  lda retraces
;  and #7
;  cmp 0
;  bne :+
;    rts
;  :
  ldy #0
  sty TempVal+2
ObjectLoop:
  stx 0
  cpy 0
  beq NotTouched

  lda AObjectF1,y
  cmp #AOBJECT_MIGHTYBURGER
  bne NotTouched

  lda AObjectPXH,y
  sta TouchLeftA
  lda AObjectPYH,y
  sta TouchTopA

  lda AObjectPXH,x
  sub #16
  sta TouchLeftB
  lda AObjectPYH,x
  sub #16
  sta TouchTopB

  lda #16
  sta TouchWidthA
  sta TouchHeightA
  lda #16*3
  sta TouchWidthB
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcc NotTouched
  inc TempVal+2
  lda TempVal+2
  cmp #3
  bcs Yes
NotTouched:
  iny
  cpy #AObjectLen
  bne ObjectLoop
  rts
Yes:
  ldy #0
: lda AObjectF1,y
  cmp #AOBJECT_MIGHTYBURGER
  bne :+
  lda #0
  sta AObjectF1,y
: iny
  cpy #AObjectLen
  bne :--

  lda AObjectPXH,x
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda AObjectPYH,x
  and #$f0
  ora 0
  sta 9
  add #1
  sta 10
  add #15
  sta 11
  add #1
  sta 12

  lda #METATILE_BURGER1
  ldy 9
  jsr ChangeBlock
  lda #METATILE_BURGER2
  ldy 10
  jsr ChangeBlock
  lda #METATILE_BURGER3
  ldy 11
  jsr ChangeBlock
  lda #METATILE_BURGER4
  ldy 12
  jsr ChangeBlock

  pla
  pla
  rts
.endproc

.proc AObject_MightyBurger
  inc NoBounceTouch
  jsr AObjectPlayerTouch
  bcc :+
  lda #0
  sta AObjectF3,x
: jsr AObjectGetShot
  bcc :+
  lda #15
  sta AObjectF3,x
  jsr AObjectAimAtPlayer
  sta AObjectAngle,x
:
  jsr MightyBurgerTouch
  lda AObjectF3,x
  beq :+
    dec AObjectF3,x
: jsr AObjectUpdateVelocity
  jsr AObjectCheckBounce
  jsr AObjectApplyVelocity
  lda #$48
  jmp AObjectDraw
.endproc

.proc AObject_Mine
  inc NoBounceTouch
  jsr AObjectPlayerTouch
  bcs AObjectExplode
  jsr AObjectGetShot
  bcs AObjectExplode
  lda #6
  jsr AObjectUpdateVelocity
  jsr AObjectCheckBounce
  jsr AObjectApplyVelocity
  lda #$5c
  jmp AObjectDraw
.endproc

.proc AObjectExplode
  lda AObjectPXH,x
  add #8
  sta 0
  lda AObjectPYH,x
  add #8
  sta 1
  lda #30
  jsr CreateExplosion
  lda #SOUND_EXPLODE1
  jsr start_sound
  lda #SOUND_EXPLODE2
  jsr start_sound
  lda #0
  sta AObjectF1,x
  rts
.endproc

; ---------------------------------------------------
.proc AObject_Poof
  jsr AObjectTimerTick
  rts
.endproc

.proc AObject_Pickup
  inc NoBounceTouch
  lda AObjectF1,x
  and #31
  sub #AOBJECT_PICKUP_AMMO
  sta 10

  jsr AObjectPlayerTouch
  jcs Remove

  ldy 10
  lda Images,y
  pha
  lda Flags,y
  tay
  pla
  jsr AObjectDrawEx
  jmp AObjectTimerTick
Images: .byt $20, $22, $24, $28, $30
Flags: .byt ADRAW_HMIRROR, ADRAW_HMIRROR, 0, 0, 0
Remove:
  lda #SOUND_COLLECT
  sta NeedSound
  lda #0
  sta AObjectF1,x
  lda 10
  asl
  tax
  lda PowerUpRoutines+1,x
  pha
  lda PowerUpRoutines+0,x
  pha
  ldy PlayerThatTouched
  rts
PowerUpRoutines:
  .raddr Ammo
  .raddr Health
  .raddr Speed
  .raddr Bomb
Ammo:
  lda PlayerAmmo,y
  add #5
  sta PlayerAmmo,y
  rts
Speed:
  lda #240
  sta PlayerSpeedupTimer,y
  rts
Health:
  lda PlayerHealth,y
  add #10
  cmp #40
  bcc :+
    lda #40
: sta PlayerHealth,y
  rts
Bomb:
;  lda #80
;  sta PlayerInvincible,y
  lda PlayerPXH,y
  sta 0
  lda PlayerPYH,y
  sta 1
  lda #20
  jmp CreateExplosion
.endproc

.proc AObjectTimerTick
  lda retraces
  lsr
  bcc Exit
  lda AObjectTimer,x
  beq Remove
  dec AObjectTimer,x
  beq Remove
  clc
Exit:
  rts
Remove:
  lda #0
  sta AObjectF1,x
  sec
  rts
.endproc

.proc rand_8_safe
  stx TempVal
  jsr rand_8
  ldx TempVal
  rts
.endproc

.proc AObjectHurtPlayerIfTouched
  bcc :+
  lda #3
  jsr HurtPlayer
: rts
.endproc

ADRAW_HMIRROR    = %00000001
ADRAW_VMIRROR    = %00000010
ADRAW_HFLIP      = %00000100

AObjectDraw:
  ldy #0
.proc AObjectDrawEx
Flags = 0
  pha
  sty Flags
  ldy OamPtr

  lda AObjectPYH,x
  sub #1
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  add #8
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*3),y

  pla
  sta OAM_TILE+(4*0),y
  add #1
  sta OAM_TILE+(4*2),y
  add #1
  sta OAM_TILE+(4*1),y
  add #1
  sta OAM_TILE+(4*3),y

  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y

  lda Flags
  and #ADRAW_HMIRROR
  beq :+
    lda OAM_TILE+(4*2),y
    sta OAM_TILE+(4*3),y
    lda OAM_TILE+(4*0),y
    sta OAM_TILE+(4*1),y

    lda #OAM_COLOR_1+OAM_XFLIP
    sta OAM_ATTR+(4*1),y
    sta OAM_ATTR+(4*3),y
    lda retraces      
  :

  lda AObjectPXH,x
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*2),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*3),y

  lda Flags
  and #ADRAW_VMIRROR
  beq :+
    lda OAM_TILE+(4*2),y
    sta OAM_TILE+(4*1),y
    sta OAM_TILE+(4*3),y
    lda OAM_TILE+(4*0),y
    sta OAM_TILE+(4*2),y
    lda #OAM_COLOR_1+OAM_YFLIP
    sta OAM_ATTR+(4*2),y
    sta OAM_ATTR+(4*3),y
  :

  lda Flags
  and #ADRAW_HFLIP
  beq :+
    lda OAM_TILE+(4*0),y
    pha
    lda OAM_TILE+(4*1),y
    sta OAM_TILE+(4*0),y
    pla
    sta OAM_TILE+(4*1),y

    lda OAM_TILE+(4*2),y
    pha
    lda OAM_TILE+(4*3),y
    sta OAM_TILE+(4*2),y
    pla
    sta OAM_TILE+(4*3),y

    lda #OAM_COLOR_1+OAM_XFLIP
    sta OAM_ATTR+(4*0),y
    sta OAM_ATTR+(4*1),y
    lda #OAM_COLOR_1+OAM_XFLIP+OAM_YFLIP
    sta OAM_ATTR+(4*2),y
    sta OAM_ATTR+(4*3),y
  :

  tya
  add #4*4
  sta OamPtr
.if 0
  lda GunX
  add #4
  sta OAM_XPOS+(4*4),y
  lda GunY
  add #3
  sta OAM_YPOS+(4*4),y
  txa
  sta OAM_ATTR+(4*4),y
  lda #$1d
  sta OAM_TILE+(4*4),y
.endif
  rts
.endproc

.if 0
.proc BObjectDraw
  pha
  ldy OamPtr

  lda BObjectPY,x
  sub #1
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  add #8
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*3),y

  pla
  sta OAM_TILE+(4*0),y
  add #1
  sta OAM_TILE+(4*2),y
  add #1
  sta OAM_TILE+(4*1),y
  add #1
  sta OAM_TILE+(4*3),y

  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y

  lda BObjectPX,x
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*2),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*3),y
  tya
  add #4*4
  sta OamPtr
  rts
.endproc
.endif

.if 0
AObjectUpdateVelocityIfNeeded:
  pha
  lda AObjectVXH,x
  ora AObjectVYH,x
  ora AObjectVXL,x
  ora AObjectVYL,x
  beq :+
  lda AObjectLastAngle
  cmp AObjectAngle,x
  bne :+
  pla
  rts
: pla
.endif
.proc AObjectUpdateVelocity ; A = speed
  ldy AObjectAngle,x
  jsr SpeedAngle2Offset ; A = speed, Y = angle -> 0,1(X) 2,3(Y)
  lda 0
  sta AObjectVXL,x
  lda 1
  sta AObjectVXH,x
  lda 2
  sta AObjectVYL,x
  lda 3
  sta AObjectVYH,x
  rts
.endproc

.proc AObjectCheckBounce
Bumped = 0
Temp = 1
CheckX = 2
CheckY = 3
  lda AObjectVXH,x
  bmi :+
    add #15
: add AObjectPXH,x
  sta CheckX

  lsr
  lsr
  lsr
  lsr
  sta Temp
  lda AObjectPYH,x
  add #8
  and #$f0
  ora Temp
  tay
  lda LevelBuf,y
  cmp #METATILE_SOLID
  bcc NoTouchH
    inc Bumped
    lda #16
    sub AObjectAngle,x
    bpl :+
    add #32
  : sta AObjectAngle,x
  NoTouchH:
; ---------------------
  lda AObjectVYH,x
  bmi :+
    add #15
: add AObjectPYH,x
  sta CheckY

  and #$f0
  sta Temp
  lda AObjectPXH,x
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
    lda AObjectAngle,x
    eor #255
    add #1
    and #31
    sta AObjectAngle,x
  NoTouchV:
  rts
.endproc

.proc AObjectApplyVelocity
  lda AObjectPXL,x
  add AObjectVXL,x
  sta AObjectPXL,x
  lda AObjectPXH,x
  adc AObjectVXH,x
  sta AObjectPXH,x

  lda AObjectPYL,x
  add AObjectVYL,x
  sta AObjectPYL,x
  lda AObjectPYH,x
  adc AObjectVYH,x
  sta AObjectPYH,x
  rts
.endproc

.proc AObjectGetShot
  lda AObjectPYH,x
  add #8
  lsr
  lsr
  and #%111000
  sta TempVal
  lda AObjectPXH,x
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
  and #%11000000
  cmp #%11000000 ;enabled, player-made bullets only
  bne SkipBullet

  lda BulletPXH,y
  sta TouchLeftA
  lda BulletPYH,y
  sta TouchTopA

  lda AObjectPXH,x
  sta TouchLeftB
  lda AObjectPYH,x
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

.proc AObjectGetHurtFromShot
  bcc :+
  lda AObjectF1,x
  and #%11100000
  beq Killed
  sub #%00100000
  ora AObjectF1,x
  sta AObjectF1,x
  lda #SOUND_ENEMYHURT2
  sta NeedSound
: rts

Killed:
  lda #0
  sta AObjectF1,x

  lda EnemiesLeftForNextLevel
  beq :+
  dec EnemiesLeftForNextLevel
:

  jsr huge_rand
  and #7
  cmp #4
  bcs :+
    add #AOBJECT_PICKUP_AMMO
    sta AObjectF1,x
    lda #160
    sta AObjectTimer,x
    lda EasyMode
    beq :+
      lda #AOBJECT_PICKUP_HEALTH
      sta AObjectF1,x
  :

  lda #SOUND_ENEMYHURT
  sta NeedSound
  pla
  pla
  rts
.endproc

.proc AObjectPlayerTouch
  ldy #0
PlayerLoop:
  lda PlayerEnabled,y
  beq NotTouched

  lda PlayerPXH,y
  sta TouchLeftA
  lda PlayerPYH,y
  sta TouchTopA

  lda AObjectPXH,x
  sta TouchLeftB
  lda AObjectPYH,x
  sta TouchTopB

  lda #16
  sta TouchWidthB
  sta TouchWidthA
  sta TouchHeightA
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcc NotTouched

  lda NoBounceTouch
  bne NoBounce
  jsr huge_rand
  lsr
  and #7
  add AObjectAngle,x
  add #16-8
  and #31
  sta AObjectAngle,x

  lda PlayerInvincible,y
  beq :+
    clc
    rts
  :

  jsr huge_rand
  lsr
  and #7
  add PlayerAngle,y
  add #16-8
  and #31
  sta PlayerAngle,y
  sty PlayerThatTouched
NoBounce:

  sec
  rts
NotTouched:
  iny
  cpy #NumPlayers
  bne PlayerLoop
  clc
  rts
.endproc

.proc SpawnEnemies
  lda retraces
  and #63
  bne Exit
  ldx #0
  lda #0
  sta 0
: lda AObjectF1,x
  cmp #1
  lda #0
  adc 0
  sta 0
  inx
  cpx #AObjectLen
  bne :-

  ; need more enemies?
  lda 0
  cmp MaxScreenEnemies
  bcc :+
Exit:
  rts
: ; make new enemy

  jsr FindFreeAObjectX
  bcs :+
  rts
:
  jsr huge_rand ; pick an angle
  and #31
  sta 0
  tay
  lda CosineTable,y
  asl
  add #128-8
  sta AObjectPXH,x
  lda SineTable,y
  asl
  add #128-8
  sta AObjectPYH,x
  lda #0
  sta AObjectPXL,x
  sta AObjectPYL,x
  sta AObjectVXL,x
  sta AObjectVXH,x
  sta AObjectVYL,x
  sta AObjectVYH,x
  sta AObjectF2,x
  sta AObjectF3,x
  sta AObjectTimer,x

  jsr huge_rand
  lsr
  lsr
  and #3
  tay
  lda EnemiesPool,y
;  lda #AOBJECT_SPINNER ;AOBJECT_CANNON1
  sta AObjectF1,x

  lda 0
  add #16
  and #31
  sta AObjectAngle,x
  rts
.endproc

.proc FindFreeAObjectX ; carry = success
  pha
  ldx #0
: lda AObjectF1,x
  beq Found
  inx
  cpx #AObjectLen
  bne :-
NotFound:
  pla
  clc
  rts
Found:
  pla
  sec
  rts
.endproc

.if 0
.proc FindFreeBObjectX ; carry = success
  pha
  ldx #0
: lda BObjectF1,x
  beq Found
  inx
  cpx #BObjectLen
  bne :-
NotFound:
  pla
  clc
  rts
Found:
  pla
  sec
  rts
.endproc
.endif
