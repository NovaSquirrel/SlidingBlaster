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

.proc InitPlayer
  lda #0
  sta PlayerPXL,x
  sta PlayerPYL,x
  sta PlayerAngle,x
  sta PlayerShootAngle,x
  sta PlayerSpeedBurst,x
  sta PlayerSpeedBurstRate,x
  sta PlayerInvincible,x
  sta PlayerHoldR,x
  sta PlayerSpeedupTimer,x
  sta PlayerBumpSoundTimer,x
  sta PlayerPressedAnything,x
  lda #2
  sta PlayerSpeed,x
  lda #15
  sta PlayerAmmo,x
  lda #25
  sta PlayerHealth,x
  rts
.endproc

NewGameEasy:
  inc EasyMode
  bne NewGame
NewGameHard:
  inc DifficultyMode
NewGame:
  lda retraces
  bne :+
    lda #1
: sta r_seed
.proc NewLevel
  jsr wait_vblank

  lda LevelMapNumber
  ldy EditMode
  bne :+
    jsr PreLevelScreen ; A still = LevelMapNumber
:
  lda LevelMapNumber
  cmp #10
  bne :+
    lda EditMode
    jeq StartMainMenu
  :

  lda #0
  sta PPUMASK
  sta LevelDirtyCount
.if 0
  lda #8
  sta LevelSpinShootSpeed
  lda #%111
  sta LevelSpinShootChance
  sta LevelSpinShootRate
.endif

  lda EditMode
  bne :+
  lda LevelMapNumber
  jsr DecodeLevelData
:

; make the blocks dirty if needed
  lda LevelSpecialFlags
  and #LSF_DIRTY
  beq NotDirty

  ldx #0
DirtyLoop:
  lda LevelBuf,x
  cmp #METATILE_SOLID
  bne DirtyLoopNext
  lda #METATILE_DIRTY
  sta LevelBuf,x
  inc LevelDirtyCount
DirtyLoopNext:
  inx
  bne DirtyLoop
NotDirty:
; 

  jsr RenderLevelBuf

  lda LevelMapNumber
  cmp #9
  bne NotBoss

  ldx #$a0
  PositionXY 0, 18, 14
  jsr Draw3
  PositionXY 0, 18, 15
  jsr Draw3
  PositionXY 0, 18, 16
  jsr Draw3
  PositionXY 0, 18, 17
  jsr Draw3
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jmp NotBoss

  Draw3:
    stx PPUDATA
    inx
    stx PPUDATA
    inx
    stx PPUDATA
    inx
    rts
NotBoss:

  jsr wait_vblank
  lda #OBJ_ON + BG_ON
  sta PPUMASK

  ldx #0
  jsr InitPlayer
  ldx #1
  jsr InitPlayer

  lda #10*8
  sta PlayerPXH
  sta PlayerPXH+1
  lda #7*8
  sta PlayerPYH
  sta PlayerPYH+1

  lda #16
  sta PlayerAngle+1

  lda #1
  sta PlayerEnabled

  lda EnemiesLeftForNextLevelStart
  sta EnemiesLeftForNextLevel

  lda #0
  tax
: sta BulletF,x
  inx
  cpx #BulletLen*10
  bne :-

  jsr init_sound
  lda #0
  jsr init_music

;  lda #4
;  sta MaxScreenEnemies

  lda #<-1
  sta NeedSound

  ldx #AObjectLen
  lda #0
: sta AObjectF1,x
  dex
  bpl :-

  lda random1
  eor retraces
  sta random1
  lda random2
  sub retraces
  sta random2

  ldx #0
  txa
: sta DelayedMetaEditType,x
  inx
  cpx #MaxDelayedMetaEdits
  bne :-

  jmp MainLoop
.endproc
