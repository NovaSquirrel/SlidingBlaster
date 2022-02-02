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

.code
.proc MainLoop
forever:
  lda #OBJ_ON+BG_ON
  sta PPUMASK
  lda #1
  sta CrashDetect

  jsr wait_vblank
  jsr ReadJoy

  ; let player 2 join in
  lda keydown+1
  cmp #KEY_A+KEY_B
  bne :+
    lda PlayerEnabled+1
    bne :+
    lda PlayerHealth+0
    cmp #10
    bcc :+
      pha
      ldx #1
      jsr InitPlayer
      pla
      sub #5
      sta PlayerHealth+0
      lda #10
      sta PlayerHealth+1
      inc PlayerEnabled+1
      lda PlayerPXH
      sta PlayerPXH+1
      lda PlayerPYH
      sta PlayerPYH+1
      lda PlayerAngle
      add #16
      and #31
      sta PlayerAngle+1
      lda #0
      sta keynew+1
  :

  lda keydown ; pause routine
  ora keydown+1
  and #KEY_START
  beq NoPause
    lda keynew
    ora keynew+1
    and #KEY_START
    beq NoPause
      lda #0
      sta CrashDetect
      jsr stop_music
      jsr update_sound
      lda #BG_ON|OBJ_ON|1
      sta PPUMASK
:     jsr ReadJoy
      stx TempVal
      jsr update_sound
      ldx TempVal
      lda keydown
      ora keydown+1
      and #KEY_START
      bne :-
      ldx #15
    : jsr wait_vblank
      stx TempVal
      jsr update_sound
      ldx TempVal
      dex
      bne :-
:     jsr ReadJoy
      stx TempVal
      jsr update_sound
      ldx TempVal
      lda keydown
      ora keydown+1
      and #KEY_START
      beq :-
:     jsr ReadJoy
      lda keydown
      ora keydown+1
      and #KEY_START
      bne :-
      ldx #15
    : jsr wait_vblank
      dex
      bne :-
      lda #1
      sta music_playing
  NoPause:
;  lda #OBJ_ON+BG_ON+%11100000
;  sta PPUMASK

  lda CollectSoundDebounce
  beq :+
    dec CollectSoundDebounce
  :

  lda LevelMapNumber
  cmp #9
  bne NotBoss
  jsr BossStuff
NotBoss:

  lda retraces
  and #15
  bne :+
    inc retraces_16th
  :

  lda #1
  sta EnableNMIDraw
  sta DoControllerSwap
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr ClearOAM

  jsr update_sound
  jsr SpawnEnemies

  ldx #0
  jsr HandlePlayer
  jsr DispPlayer

  lda PlayerEnabled+1
  beq :+
  ldx #1
    jsr HandlePlayer
    jsr DispPlayer
  :

  jsr RunObjects
  lda NeedSound
  bmi :+
    jsr start_sound
    lda #<-1
    sta NeedSound
  :
  jsr RunBullets
  jsr RunExplosions

  jsr UpdateStatus

  ldx #0
MetaEditLoop:
  lda DelayedMetaEditType,x
  beq SkipMetaEdit
    lda retraces_16th
    cmp DelayedMetaEditTime,x
    bne SkipMetaEdit
    ldy DelayedMetaEditIndx,x
    lda DelayedMetaEditType,x
    bpl :+
      lda #0
  : jsr ChangeBlock
    lda #0
    sta DelayedMetaEditType,x
SkipMetaEdit:
  inx
  cpx #MaxDelayedMetaEdits
  bne MetaEditLoop

  lda LevelSpecialFlags
  and #LSF_DIRTY
  beq :+ ; not a dirty level
  lda LevelDirtyCount
  sta EnemiesLeftForNextLevel
:

  lda #0
  sta CrashDetect

  lda EnemiesLeftForNextLevel
  bne :+
  lda EditMode
  jne WonLevel
  inc LevelMapNumber
  jmp WonLevel
:

  lda PlayerHealth
  jeq PlayerDie

  jmp forever
.endproc

.proc ClearOAM
  lda #$f0
  ldx #0
: sta OAM_YPOS,x
  inx
  inx
  inx
  inx
  bne :-
  rts
.endproc

.proc UpdateStatus
; player 1 and other stuff
  ldy OamPtr
  lda #10
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*6),y
  sta OAM_YPOS+(4*7),y

  lda #20
  sta OAM_YPOS+(4*3),y
  sta OAM_YPOS+(4*4),y
  sta OAM_YPOS+(4*5),y

  lda #30
  sta OAM_YPOS+(4*6),y
  sta OAM_YPOS+(4*7),y

  lda #10
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*3),y

  lda #10+10
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*4),y

  lda #10+18
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*5),y

; enemies left
  lda #4+10
  sta OAM_XPOS+(4*6),y
  lda #4+18
  sta OAM_XPOS+(4*7),y

  lda #0
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y
  sta OAM_ATTR+(4*4),y
  sta OAM_ATTR+(4*5),y
  sta OAM_ATTR+(4*6),y
  sta OAM_ATTR+(4*7),y

  ; ammo symbol
  lda #$34
  sta OAM_TILE+(4*0),y


  ldx PlayerAmmo
  lda BCDTable,x
  pha
  lsr
  lsr
  lsr
  lsr
  add #$36
  sta OAM_TILE+(4*1),y
  pla
  and #15
  add #$36
  sta OAM_TILE+(4*2),y

  ; health symbol
  lda #$35
  sta OAM_TILE+(4*3),y

  ldx PlayerHealth
  lda BCDTable,x
  pha
  lsr
  lsr
  lsr
  lsr
  add #$36
  sta OAM_TILE+(4*4),y
  pla
  and #15
  add #$36
  sta OAM_TILE+(4*5),y

  ldx EnemiesLeftForNextLevel
  lda LevelDirtyCount ; if a dirty level, show that number instead
  beq :+
    tax
  :
  lda BCDTable,x
  pha
  lsr
  lsr
  lsr
  lsr
  add #$36
  sta OAM_TILE+(4*6),y
  pla
  and #15
  add #$36
  sta OAM_TILE+(4*7),y


  tya
  add #4*8
  sta OamPtr
  tay

; show player 2 stats
  lda PlayerEnabled+1
  bne :+
  rts
:

  ldx PlayerAmmo+1
  lda BCDTable,x
  pha
  lsr
  lsr
  lsr
  lsr
  add #$36
  sta OAM_TILE+(4*0),y
  pla
  and #15
  add #$36
  sta OAM_TILE+(4*1),y

  ldx PlayerHealth+1
  lda BCDTable,x
  pha
  lsr
  lsr
  lsr
  lsr
  add #$36
  sta OAM_TILE+(4*2),y
  pla
  and #15
  add #$36
  sta OAM_TILE+(4*3),y

  lda #10
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y
  lda #20
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*3),y

  lda #30+10
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*2),y
  lda #30+18
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*3),y

  lda #0
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y

  lda #10
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  lda #20
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*3),y

  tya
  add #4*4
  sta OamPtr
  rts
.endproc

.proc BCDTable
  .byt $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byt $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byt $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byt $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
.endproc

.proc BossStuff
XFrom = (19*8)+4
YFrom = (16*8)+4
  lda retraces
  beq :+
  rts
: lda #XFrom
  sta 0
  lda #YFrom
  sta 1
  lda PlayerPXH
  sta 2
  lda PlayerPYH
  sta 3
  jsr getAngle

  sta 10
  jsr FindFreeAObjectX
  jcc NoShoot

  lda #XFrom-4
  sta AObjectPXH,x
  lda #YFrom-4
  sta AObjectPYH,x
  lda #0
  sta AObjectPXL,x
  sta AObjectPYL,x
  sta AObjectVXL,x
  sta AObjectVXH,x
  sta AObjectVYL,x
  sta AObjectVYH,x
  sta AObjectF2,x
  lda #1
  sta AObjectF3,x
  lda #30
  sta AObjectTimer,x
  lda #AOBJECT_BURGER2
  sta AObjectF1,x
  lda 10
  sta AObjectAngle,x
NoShoot:
  rts
.endproc
