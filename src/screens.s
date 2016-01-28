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

.proc StartMainMenu
  jsr init_sound
  lda #0
  sta CrashDetect
  sta EditMode
  sta DifficultyMode
  sta EasyMode
  sta DoControllerSwap
  sta EnableNMIDraw
  sta LevelNumber
  sta LevelMapNumber

  lda #0
  sta PPUMASK
  sta PPUSCROLL
  sta PPUSCROLL
  jsr ClearOAM

  lda #<TitleName
  ldx #>TitleName
  jsr CopyFromCHR
  lda #0
  sta 0
  lda #5
  sta 1
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  jsr PKB_unpackblk
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr wait_vblank

  lda #BG_ON | OBJ_ON
  sta PPUMASK
  jsr WaitForKey
  jsr wait_vblank

; if the mouse is plugged into player 1's slot, show mouse instructions
  lda mouseEnabled
  beq NoMouse
  lda #$23
  sta PPUADDR
  lda #$87
  sta PPUADDR
  ldx #18
  jsr PrintXSpaces
  lda #$23
  sta PPUADDR
  lda #$67
  sta PPUADDR
  ldx #18
  jsr PrintXSpaces

  lda #$23
  sta PPUADDR
  lda #$67+(3)
  sta PPUADDR
  PrintStringY MouseMenuHelp
  lda #$23
  sta PPUADDR
  lda #$87+(9)
  sta PPUADDR
  ldx #$17
  stx PPUDATA
  inx
  stx PPUDATA
NoMouse:
.endproc
; -- don't put anything here --
.proc StartMainMenu2
  ldy #MainMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda retraces
  beq :+
  ora #1
: sta r_seed

  lda MainMenuAddrs+1,x
  pha
  lda MainMenuAddrs+0,x
  pha
  rts
.endproc

MouseMenuHelp:
  .byt "Choose", $07, $08, "Next", 0

PrintXSpaces:
  lda #' '
: sta PPUDATA
  dex
  bne :-
  rts
.proc MainMenuAddrs
  .raddr NewGame
  .raddr NewGameEasy
  .raddr NewGameHard
  .raddr HelpAndConfig
  .raddr StartEditorFromMenu
  .raddr ShowCredits
.endproc

MenuData:
.proc MainMenuData
  .byt 6
  .ppuxy 0, 10, 19
  .byt "Normal Game",0
  .ppuxy 0, 10, 20
  .byt "Easier Game",0
  .ppuxy 0, 10, 21
  .byt "Harder Game",0
  .ppuxy 0, 10, 22
  .byt "Help/Config",0
  .ppuxy 0, 10, 23
  .byt "Level Edit",0
  .ppuxy 0, 10, 24
  .byt "Credits",0
.endproc

.proc RunChoiceMenu ; returns choice selected in A
CurChoice = 2  ; start at 2 and 3 because ReadJoy trashes 0 and 1
NumChoices = 3
  ldx MenuData,y
  stx NumChoices    ; keep number of choices for later
  jsr ClearMenuChoices

NewRow:
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  iny               ; also skips over zeroes when branched here
  dex
  bmi NoMoreRows
  lda MenuData,y
  sta PPUADDR
  iny
  lda MenuData,y
  sta PPUADDR
  iny
: lda MenuData,y
  beq NewRow
  sta PPUDATA
  iny
  jmp :-
NoMoreRows:
  jsr ClearOAM
  lda #0
  sta CurChoice

ChoiceLoop:
  jsr ReadJoy
  lda mouseEnabled
  beq :+
    lda keynew ; RL...... - ABssudlr
    pha
    asl
    and #KEY_A
    sta keynew
    pla
    asl
    rol
    rol
    rol
    and #KEY_DOWN
    ora keynew
    sta keynew
  :

  lda keynew
  and #KEY_UP
  beq :+
    dec CurChoice
    bpl :+
      lda NumChoices
      sta CurChoice
      dec CurChoice
  :

  lda keynew
  and #KEY_DOWN
  beq :+
    inc CurChoice
    lda CurChoice
    cmp NumChoices
    bcc :+
      lda #0
      sta CurChoice
  :

  lda #10*8-16
  sta OAM_XPOS+(4*0)
  lda CurChoice
  asl
  asl
  asl
  add #19*8-1
  sta OAM_YPOS+(4*0)
  lda #$1c
  sta OAM_TILE+(4*0)
  lda #0
  sta OAM_ATTR+(4*0)

  lda keynew
  and #KEY_A|KEY_START
  bne ChoiceSelected

  jsr wait_vblank
  jmp ChoiceLoop

ChoiceSelected:
  jsr ClearOAM
  lda CurChoice
  rts
.endproc

.proc ClearMenuChoices
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  PositionXY 0, 10, 19
  jsr PrintSpaces
  PositionXY 0, 10, 20
  jsr PrintSpaces
  PositionXY 0, 10, 21
  jsr PrintSpaces
  PositionXY 0, 10, 22
  jsr PrintSpaces
  PositionXY 0, 10, 23
  jsr PrintSpaces
  PositionXY 0, 10, 24
PrintSpaces:
  lda #' '
  .repeat 12
    sta PPUDATA
  .endrep
  rts
.endproc

.macro PositionPrintXY NT, XP, YP, String
  PositionXY NT, XP, YP
  jsr PutStringImmediate
  .byt String, 0
.endmacro

.proc WaitForKeyTimed
: jsr wait_vblank
  jsr ReadJoy
  dey
  beq :+
  lda keydown
  ora keydown+1
  beq :-
  lda keylast
  ora keylast+1
  bne :-
: rts

.endproc

.proc ShowCredits
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  PositionPrintXY 0, 8,4,  "Big City"
  PositionPrintXY 0, 9,5,  "Sliding Blaster"

  PositionPrintXY 0, 2,8,  "Nearly everything"
  PositionPrintXY 0, 3,9,  "by NovaSquirrel"
  PositionPrintXY 0, 3,10, "(NovaSquirrel.com)"

  PositionPrintXY 0, 2,12, "Sound, trig and cursor code"
  PositionPrintXY 0, 3,13, "and some sounds by Tepples"
  PositionPrintXY 0, 3,14, "(PinEight.com)"

  PositionPrintXY 0, 2,16, "Inspiration from Ballmaster2"

  PositionPrintXY 0, 2,21, "Press anything to continue"

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK
  jsr WaitForKey
  jmp StartMainMenu
.endproc

.proc HelpAndConfig
  ControlType1 = 10
  ControlType2 = 11

  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  PositionPrintXY 0, 8,4,  "Big City"
  PositionPrintXY 0, 9,5,  "Sliding Blaster"

  PositionXY  0, 2,8
  jsr PutStringImmediate
  .byt "Ammo: ", $8a, $8b, " Heal: ", $8c, $8d, " Speed: ", $8e, $8f, 0
  PositionXY  0, 8,9
  jsr PutStringImmediate
  .byt $9a, $9b, "       ", $9c, $9d, "        ", $9e, $9f, 0

  PositionPrintXY 0, 2,11, "B/Left button: Shoot"
  PositionPrintXY 0, 2,12, "A/Right button: Boost"

  PositionPrintXY 0, 2,14, "Shoot at enemies to proceed"
  PositionPrintXY 0, 2,15, "while avoiding getting hit."
  PositionPrintXY 0, 2,16, "Press both buttons to join"
  PositionPrintXY 0, 2,17, "in as player 2."

  PositionPrintXY 0, 2,19, "Control mode (Change: A/Right)"

  PositionPrintXY 0, 2,20, "Player 1:"
  PositionPrintXY 0, 2,21, "Player 2:"

  PositionPrintXY 0, 2,23, "P2 mouse for P1 (Select):"

  PositionPrintXY 0, 2,28, "Press B/Left to continue"


  lda #KEY_A|KEY_B|KEY_SELECT
  sta keydown
Update:
  lda keydown
  ora keydown+1
  pha
  and #KEY_A
  beq :+
  PositionXY  0, 11,20
  ldx #0
  jsr FindSchemeIndex
  jsr PrintSchemeName

  PositionXY  0, 11,21
  ldx #1
  jsr FindSchemeIndex
  jsr PrintSchemeName
:
  pla 
  and #KEY_SELECT
  beq :+
  PositionXY  0, 28,23
  ldx ControllerSwap
  lda NoYesTable,x
  sta PPUDATA
:

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK

WaitMore:
  jsr wait_vblank
  jsr ReadJoy
  lda keynew+0
  ora keynew+1
  sta 1
  beq WaitMore
  and #KEY_SELECT
  beq :+
    lda ControllerSwap
    eor #1
    sta ControllerSwap
    jmp Update
  :

  ldx #0
  jsr TrySchemeChange
  ldx #1
  jsr TrySchemeChange

  lda keydown+0
  ora keydown+1
  sta 0
  and #KEY_A
  beq :+
    jsr wait_vblank
    jmp Update
  :

  lda 0
  and #KEY_B  
  jne StartMainMenu

  jmp WaitMore

TrySchemeChange:
  lda keydown,x
  and #KEY_A
  beq @Exit
  lda mouseEnabled,x
  bne @Mouse
  lda RacecarMode,x
  add #1
  cmp #3
  bne :+
  lda #0
: sta RacecarMode,x
  rts
@Mouse:
  inc MouseSensitivity,x
  lda MouseSensitivity,x
  cmp #3
  bne @Exit
  lda #0
  sta MouseSensitivity,x
@Exit:
  rts

PrintSchemeName:
  stx 1
  asl ; *2
  sta 0
  asl ; *4
  asl ; *8
  add 0
  tay
  ldx #10
: lda ControlSchemes,y
  sta PPUDATA
  iny
  dex
  bne :-
  ldx 1
  rts

FindSchemeIndex:
  lda mouseEnabled,x
  bne @Mouse
  lda RacecarMode,x
  rts
@Mouse:
  lda #0
  sta RacecarMode,x
  lda MouseSensitivity,x
  add #3
  rts

ControlSchemes:
  .byt "Cursor    "
  .byt "Spinning  "
  .byt "Simple    "
  .byt "Mouse Fast"
  .byt "Mouse Med."
  .byt "Mouse Slow"
NoYesTable:
  .byt "NY"
.endproc

.proc PreLevelScreen
; draw the base
  pha
  jsr init_sound
  jsr wait_vblank
  jsr ClearOAM
  lda #0
  sta PPUMASK
  ; change a pallete entry temporarily
  lda #$3f
  sta PPUADDR
  lda #$02
  sta PPUADDR
  lda #$36
  sta PPUDATA

  lda #<MaysScreen
  sta 0
  lda #>MaysScreen
  sta 1
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  jsr PKB_unpackblk
; add text
  pla
  asl
  tay
  lda BillyMessagePointers+0,y
  ldx BillyMessagePointers+1,y
  jsr CopyFromCHR
  lda #>$2148
  sta PPUADDR
  sta 1
  lda #<$2148
  sta PPUADDR
  sta 0
  inc 0 ; sloppy bugfix

  ldy #0
  sty 2 ; line counter
ReadChar:
  lda $500,x
  beq ExitChar
  inx
  cmp #10 ;\n
  bne NotNewline
  lda 0
  add #32
  sta 0
  lda 1
  adc #0
  sta 1

  inc 2
  lda 2
  cmp #4
  bne NoUnindent
  lda 0
  sub #4
  sta 0
NoUnindent:

  lda 1
  sta PPUADDR
  lda 0
  sta PPUADDR
  bne ReadChar
NotNewline:
  sta PPUDATA
  bne ReadChar
ExitChar:

; done drawing
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank

  lda #BG_ON | OBJ_ON
  sta PPUMASK

  ldx #30
: jsr wait_vblank
  dex
  bne :-

  jsr WaitForKey
  jsr wait_vblank
  ; change palette back
  lda #$3f
  sta PPUADDR
  lda #$02
  sta PPUADDR
  lda #$00
  sta PPUDATA
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

MaysScreen:
 .incbin "mays.pkb"

; $1f

BillyMessagePointers:
  .addr BillyMessage1
  .addr BillyMessage2
  .addr BillyMessage3
  .addr BillyMessage4
  .addr BillyMessage5
  .addr BillyMessage6
  .addr BillyMessage7
  .addr BillyMessage8
  .addr BillyMessage9
  .addr BillyMessage10
  .addr BillyMessage11
.segment "CHR_DATA"
BillyMessage1:
  .word BillyMessage2-BillyMessage1
  .byt "THE BIG CITY SLIDER",10
  .byt "STATION HAS BEEN",10
  .byt "STOLEN AND IT IS",10
  .byt "BEING USED TO MAKE",10
  .byt "ALL SORTS OF BAD GUYS.",10,10
  .byt "DEFEAT 20 PER LEVEL TO",10
  .byt "REACH ",34,"EVIL BILLY",34, " SO",10
  .byt "YOU CAN TAKE BACK THE",10
  .byt "BIG CITY SLIDER STATION!",0
BillyMessage2:
  .word BillyMessage3-BillyMessage2
  .byt "WELL DONE! THERE",10
  .byt "ARE 10 LEVELS IN",10
  .byt "TOTAL. COMPLETE ALL",10
  .byt "OF THEM AND WIN.",10
  .byt "DO IT FOR BILLY!",10
  .byt 10,"THIS IS KIND OF LIKE THE",10
  .byt "MOVIE ", 34,"BIG CITY SLIDERS",10
  .byt "ATTACK YOUR FAMILY",34,0
BillyMessage3:
  .word BillyMessage4-BillyMessage3
  .byt "PLAYER 2 CAN PRESS",10
  .byt "A+B TO JOIN IN, BUT",10
  .byt "PLAYER 1 GIVES UP",10
  .byt "SOME HEALTH",10,10
  .byt "THESE VOLCANOES ARE",10
  .byt "CRAZY! WATCH OUT!",0
BillyMessage4:
  .word BillyMessage5-BillyMessage4
  .byt "WATCH OUT FOR MINES!",10
  .byt "SHOOT DIRTY SHIRTS!",10
  .byt "THEY DROP HEALTH",10
  .byt "RECOVERY ITEMS",0
BillyMessage5:
  .word BillyMessage6-BillyMessage5
  .byt "THIS LEVEL IS DIRTY",10
  .byt "SO SHOOT THE BLOCKS",10
  .byt "AND CLEAN THEM ALL!",0
BillyMessage6:
  .word BillyMessage7-BillyMessage6
  .byt "IF I HAD TO DO IT",10
  .byt "ALL OVER AGAIN, I",10
  .byt "WOULD STILL DO IT",10
  .byt "ALL OVER AGAIN",0
BillyMessage7:
  .word BillyMessage8-BillyMessage7
  .byt "I HOPE YOU CAN AIM",10
  .byt "AT FAST TARGETS!",10,10
  .byt "THIS COULD BE HARD",0
BillyMessage8:
  .word BillyMessage9-BillyMessage8
  .byt "YOU ARE GETTING",10
  .byt "CLOSER! I CAN SMELL",10
  .byt "ALL THE DELICIOUS",10
  .byt "SLIDERS!!",0
BillyMessage9:
  .word BillyMessage10-BillyMessage9
  .byt "THE FAST ENEMIES",10
  .byt "ARE BACK, AND YOU",10
  .byt "ARE FAST TOO!",0
BillyMessage10:
  .word BillyMessage11-BillyMessage10
  .byt "MIGHTY PUTTY MANY",10
  .byt "SLIDERS TOGETHER!",10
  .byt "THIS IS JUST DUMB",10
  .byt "ENOUGH TO WORK!",10,10
  .byt "UNITE 4 TOGETHER, SHOOT",10
  .byt "ONE TO DRAW IT CLOSER TO",10
  .byt "YOU THEN DRAW THE BOSS",10
  .byt "TOWARDS IT! GREAT PLAN",0
BillyMessage11:
  .word BillyMessageEnd-BillyMessage11
  .byt "YOU DID IT! YOU",10
  .byt "STOPPED EVIL BILLY",10
  .byt "AND BROUGHT THE BIG",10
  .byt "CITY SLIDER STATION",10
  .byt "BACK! GOOD JOB!!!!",10,10
  .byt "YOU ARE INVITED FOR BIG",10
  .byt "CITY SLIDERS AT MY HOUSE",10
  .byt "FOR YOUR GOOD DEEDS :D",0
BillyMessageEnd:
.code

.proc PlayerDie
  jsr init_sound
  ldy #0
  sty EnableNMIDraw

  jsr wait_vblank
  jsr ClearOAM

  lda #BG_ON|OBJ_ON|INT_RED|LIGHTGRAY
  sta PPUMASK

  lda PlayerPXH,x
  add #8
  sta 0
  lda PlayerPYH,x
  add #8
  sta 1
  lda #60
  jsr CreateExplosion
  lda #SOUND_EXPLODE1
  jsr start_sound
  lda #SOUND_EXPLODE2
  jsr start_sound

  lda #80
  sta 15
: jsr wait_vblank
  jsr ClearOAM
  jsr RunObjects
  jsr RunBullets
  jsr RunExplosions
  jsr update_sound
  dec 15
  bne :-

  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  jsr ClearOAM
  lda EditMode
  jne StartEditorNormal

  PositionPrintXY 0, 8,14,  "Retry? B/Left:No"
  PositionPrintXY 0, 8+7,15, "A/Right:Yes"
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK

: jsr WaitForKey
  lda keydown
  and #KEY_A
  bne Retry

  lda keydown
  and #KEY_B
  bne Quit
  beq :-

Retry:
  jmp NewLevel
Quit:
  lda EditMode
  jne StartEditorNormal
  jmp StartMainMenu
.endproc

.proc WonLevel
  lda #80
  sta 15

  ldx #0
  stx CrashDetect
  txa
: sta LevelBuf,x
  inx
  bne :-
WonLevelLoop:
  jsr wait_vblank
  jsr ClearOAM
  jsr ReadJoy
  ldx #0
  stx OamPtr
;  jsr HandlePlayer
  jsr DispPlayer

  ldx OamPtr
  lda PlayerPXH
  sub #8
  sta OAM_XPOS+(4*0),x
  add #8
  sta OAM_XPOS+(4*1),x
  add #8
  sta OAM_XPOS+(4*2),x
  add #8
  sta OAM_XPOS+(4*3),x

  lda retraces
  and #15
  tay
  lda PlayerPYH
  sub #24
  sta 0
  add WavyTable+0,y
  sta OAM_YPOS+(4*0),x
  lda 0
  add WavyTable+1,y
  sta OAM_YPOS+(4*1),x
  lda 0
  add WavyTable+2,y
  sta OAM_YPOS+(4*2),x
  lda 0
  add WavyTable+3,y
  sta OAM_YPOS+(4*3),x

  lda #$2c
  sta OAM_TILE+(4*0),x
  lda #$2d
  sta OAM_TILE+(4*1),x
  lda #$2e
  sta OAM_TILE+(4*2),x
  lda #$2f
  sta OAM_TILE+(4*3),x
  lda #0
  sta OAM_ATTR+(4*0),x
  sta OAM_ATTR+(4*1),x
  sta OAM_ATTR+(4*2),x
  sta OAM_ATTR+(4*3),x
  ; updating OamPtr doesn't matter because this is all we're drawing

  jsr update_sound
  dec 15
  jne WonLevelLoop
  lda EditMode
  jne StartEditorNormal
  jmp NewLevel

WavyTable:
  .byt 0, 0, 1, 3, 6, 8, 9, 9
  .byt 9, 9, 8, 6, 3 ,1, 0, 0
  .byt 0, 0, 1, 3, 6, 8, 9, 9
  .byt 9, 9, 8, 6, 3 ,1, 0, 0
.endproc
