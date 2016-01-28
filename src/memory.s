.segment "ZEROPAGE"
NumPlayers = 2
  retraces: .res 1
  retraces_16th: .res 1
  keydown:  .res NumPlayers
  mousebyte2: .res NumPlayers
  mousebyte3: .res NumPlayers
  mousebyte4: .res NumPlayers
  keylast:  .res NumPlayers
  keynew:   .res NumPlayers
  mousedown:  .res NumPlayers
  mousenew:   .res NumPlayers
  mouseEnabled: .res NumPlayers
  MouseSensitivity: .res NumPlayers
  RacecarMode: .res NumPlayers
  CrashDetect: .res 1
  TwoPlayer: .res 1

  DifficultyMode: .res 1
  Speedup: .res 1

  PlayerThatTouched: .res 1
  EasyMode: .res 1

  PlayerPXH:   .res NumPlayers
  PlayerPXL:   .res NumPlayers
  PlayerPYH:   .res NumPlayers
  PlayerPYL:   .res NumPlayers
  PlayerAngle: .res NumPlayers
  PlayerShootAngle: .res NumPlayers
  PlayerSpeed:      .res NumPlayers
  PlayerControls:   .res NumPlayers
  PlayerSpeedBurst: .res NumPlayers
  PlayerSpeedBurstRate: .res NumPlayers
  .res NumPlayers
  PlayerAmmo: .res NumPlayers
  PlayerEnabled: .res NumPlayers
  PlayerInvincible: .res NumPlayers
  PlayerHoldR: .res NumPlayers
  PlayerBumpSoundTimer: .res NumPlayers
  PlayerSpeedupTimer: .res NumPlayers
  PlayerTimeWithoutAmmo: .res NumPlayers
  PlayerPressedAnything: .res NumPlayers

  LevelNumber: .res 1
  ControllerSwap: .res 1   ; whether or not to swap
  DoControllerSwap: .res 1 ; signals to ReadJoys to do the swapping if applicable
  CollectSoundDebounce: .res 1

  TempVal:     .res 4

  TouchRight:      .res 1
  TouchBottom:     .res 1
  TouchTopA:       .res 1
  TouchTopB:       .res 1
  TouchLeftA:      .res 1
  TouchLeftB:      .res 1
  TouchWidthA:     .res 1
  TouchWidthB:     .res 1
  TouchHeightA:    .res 1
  TouchHeightB:    .res 1

  MaxNumBlockUpdates = 4
  MaxNumTileUpdates  = 5
  BlockUpdateA1:   .res MaxNumBlockUpdates
  BlockUpdateA2:   .res MaxNumBlockUpdates
  BlockUpdateB1:   .res MaxNumBlockUpdates
  BlockUpdateB2:   .res MaxNumBlockUpdates
  BlockUpdateT1:   .res MaxNumBlockUpdates
  BlockUpdateT2:   .res MaxNumBlockUpdates
  BlockUpdateT3:   .res MaxNumBlockUpdates
  BlockUpdateT4:   .res MaxNumBlockUpdates

  TileUpdateA1:    .res MaxNumTileUpdates
  TileUpdateA2:    .res MaxNumTileUpdates
  TileUpdateT:     .res MaxNumTileUpdates

  TempSoundMem: .res 5

  MaxScreenEnemies: .res 1

.enum
  CONTROLLER_CURSOR
  CONTROLLER_ROTATE
  SNES_MOUSE_BA
  SNES_MOUSE_AB
.endenum
  random1:         .res 2
  random2:         .res 2
  EditMode:    .res 1

  CursorPXH:   .res NumPlayers
  CursorPXL:   .res NumPlayers
  CursorPYH:   .res NumPlayers
  CursorPYL:   .res NumPlayers

  CursorVXH:   .res NumPlayers
  CursorVXL:   .res NumPlayers
  CursorVYH:   .res NumPlayers
  CursorVYL:   .res NumPlayers
  OamPtr:      .res 1
  FlashColor:      .res 1
  EnableNMIDraw:   .res 1

  GunX: .res 1
  GunY: .res 1

  NeedSound: .res 1

  psg_sfx_state:    .res 32

; kinematics args
abl_vel = 0
abl_maxVel = 2
abl_brakeRate = 4
abl_accelRate = 5
abl_keys = 6

accelBrakeLimit: .res 1

.segment "BSS"
LevelDataBuf:
  .res 12
LevelDataPoints:
  .res 4

BulletLen = 15
  BulletF:     .res BulletLen ; eps.tttt
  BulletPXH:   .res BulletLen
  BulletPXL:   .res BulletLen
  BulletPYH:   .res BulletLen
  BulletPYL:   .res BulletLen
  BulletVXH:   .res BulletLen
  BulletVXL:   .res BulletLen
  BulletVYH:   .res BulletLen
  BulletVYL:   .res BulletLen
  BulletLife:  .res BulletLen

AObjectLen = 8 ; main objects
  AObjectF1:    .res AObjectLen ; hhhttttt - HP (7=8HP, 0=1HP), type
  AObjectF2:    .res AObjectLen ; ....ssss - state
  AObjectF3:    .res AObjectLen
  AObjectTimer: .res AObjectLen ; returns to state 0 when zero
  AObjectPXH:   .res AObjectLen
  AObjectPXL:   .res AObjectLen
  AObjectPYH:   .res AObjectLen
  AObjectPYL:   .res AObjectLen
  AObjectVXH:   .res AObjectLen
  AObjectVXL:   .res AObjectLen
  AObjectVYH:   .res AObjectLen
  AObjectVYL:   .res AObjectLen
  AObjectAngle: .res AObjectLen

.if 0
BObjectLen = 10 ; secondary objects
  BObjectF1:    .res BObjectLen ; ???ttttt - type
  BObjectF2:    .res BObjectLen
  BObjectPX:    .res BObjectLen
  BObjectPY:    .res BObjectLen
  BObjectTimer: .res BObjectLen
.endif

  EnemiesLeftForNextLevel: .res 1 ; actual counter
  EnemiesLeftForNextLevelStart: .res 1
  EnemiesPool: .res 4

  MaxExplosions = 3
  ExplosionPosX: .res MaxExplosions
  ExplosionPosY: .res MaxExplosions
  ExplosionSize: .res MaxExplosions
  ExplosionTime: .res MaxExplosions

  MaxDelayedMetaEdits = 16
  DelayedMetaEditIndx: .res MaxDelayedMetaEdits
  DelayedMetaEditTime: .res MaxDelayedMetaEdits
  DelayedMetaEditType: .res MaxDelayedMetaEdits

  EditorCursorXBackup: .res 1
  EditorCursorYBackup: .res 1

  LevelMapNumber: .res 1

  LevelSpinShootSpeed: .res 1
  LevelSpinShootChance: .res 1
  LevelSpinShootRate: .res 1

  LevelSpecialFlags: .res 1
.enum
  LSF_DIRTY = 1
  LSF_BOSS = 2
.endenum

  LevelDirtyCount: .res 1
  MightyPuttyLeft: .res 1

  soundBSS:        .res 64
  NoBounceTouch: .res 1 ; don't automatically bounce when colliding, for powerups

  PlayerHealth: .res NumPlayers

  LevelBuf = $700
  BulletMap = LevelBuf - 64
  AttribMap = BulletMap - 64
  CollectMap = AttribMap - 32
