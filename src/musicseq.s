.enum
  SOUND_BOOST
  SOUND_SNARE2
  SOUND_KICK2
  SOUND_HIHAT
  SOUND_SHOOT
  SOUND_ENEMYHURT
  SOUND_YOUHURT
  SOUND_COLLECT
  SOUND_SPRING
  SOUND_SNARE
  SOUND_KICK
  SOUND_EXPLODE1
  SOUND_EXPLODE2
  SOUND_ENEMYHURT2
  SOUND_MONEY
  SOUND_BUMP
.endenum

psg_sound_table: ; address, (channel?), length in words
  .addr playerboost_snd
  .byt 0, 10
  .addr snare2_snd
  .byt 8, 2
  .addr kick2_snd
  .byt 8, 4
  .addr hihat_snd
  .byt 12, 2
  .addr youshoot_snd
  .byt 0, 6
  .addr enemyhurt_snd
  .byt 0, 10
  .addr youhurt_snd
  .byt 0, 10

  .addr collect_snd
  .byt 0, 10
  .addr spring_snd
  .byt 0, 20
  .addr snare_snd
  .byt 12, 7

  .addr kick_snd
  .byt 12, 3

  .addr boom1_snd ; explosion sounds taken from Thwaite
  .byt 16+0, 15
  .addr boom2_snd
  .byt 48+12, 16

  .addr enemyhurt2_snd
  .byt 0, 10
  .addr money_snd
  .byt 0, 10
  .addr bump_snd
  .byt 0, 5

; alternating duty/volume and pitch bytes
playerboost_snd:
  .byt $4f, $20, $48, $21
  .byt $4f, $22, $48, $23
  .byt $4f, $24, $48, $25
  .byt $4f, $26, $48, $27
  .byt $4f, $28, $48, $29

bump_snd:
  .byt $0f, $24, $0f, $23
  .byt $0f, $22, $0f, $21
  .byt $0f, $20

spring_snd:
  .byt $4f, $20, $4f, $21
  .byt $4f, $20, $4f, $21
  .byt $4f, $22, $4f, $23
  .byt $4f, $22, $4f, $23
  .byt $4f, $24, $4f, $25
  .byt $4f, $24, $4f, $25
  .byt $4f, $26, $4f, $27
  .byt $4f, $26, $4f, $27
  .byt $4f, $28, $4f, $29
  .byt $4f, $28, $4f, $29

youshoot_snd:
  .byt $8f, $20, $8f, $21
  .byt $8f, $22, $8f, $23
  .byt $8f, $22, $8f, $21

enemyhurt_snd:
  .byt $4f, $20, $4f, $21
  .byt $40, $22, $40, $23
  .byt $4f, $24, $4f, $2f
  .byt $4f, $26, $4f, $2f
  .byt $4f, $28, $4f, $2f

youhurt_snd:
  .byt $4f, $10, $4f, $11
  .byt $40, $12, $40, $13
  .byt $4f, $14, $4f, $1f
  .byt $4f, $16, $4f, $1f
  .byt $4f, $18, $4f, $1f

collect_snd:
  .byt $4f, $20, $4f, $21
  .byt $40, $22, $40, $23
  .byt $4f, $24, $4f, $2f
  .byt $40, $26, $40, $2f
  .byt $4f, $28, $4f, $2f

enemyhurt2_snd:
  .byt $4f, $20, $4f, $18
  .byt $4f, $10, $4f, $16
  .byt $4f, $20, $4f, $14
  .byt $4f, $10, $4f, $12
  .byt $4f, $20, $4f, $10

money_snd:
  .byt $4f, $20, $4f, $20
  .byt $40, $20, $40, $20
  .byt $4f, $23, $4f, $23
  .byt $40, $26, $40, $26
  .byt $4f, $26, $4f, $27

snare2_snd:
  .byt $8F, $26, $8F, $25
kick2_snd:
  .byt $8F, $1F, $8F, $1B, $8F, $18, $82, $15
hihat_snd:
  .byt $06, $03, $04, $83
snare_snd:
  .byt $0A, 085, $08, $84, $06, $04
  .byt $04, $84, $03, $04, $02, $04, $01, $04
kick_snd:
  .byt $08,$04,$08,$0E,$04,$0E
  .byt $05,$0E,$04,$0E,$03,$0E,$02,$0E,$01,$0E

boom1_snd:
  .byt $8F, $12, $4F, $0F, $8E, $0C
  .byt $0E, $0E, $8D, $0C, $4C, $0A
  .byt $8B, $0B, $0A, $09, $89, $06
  .byt $48, $08, $87, $07, $06, $05
  .byt $84, $06, $42, $04, $81, $03
boom2_snd:
  .byt $0F, $0E
  .byt $0E, $0D
  .byt $0D, $0E
  .byt $0C, $0E
  .byt $0B, $0E
  .byt $0A, $0F
  .byt $09, $0E
  .byt $08, $0E
  .byt $07, $0F
  .byt $06, $0E
  .byt $05, $0F
  .byt $04, $0E
  .byt $03, $0F
  .byt $02, $0E, $01, $0F, $01, $0F

; Each drum consists of one or two sound effects.
drumSFX:
  .byt 10, 2
  .byt 1,  9
  .byt 3, <-1
KICK  = 0*8
SNARE = 1*8
CLHAT = 2*8

instrumentTable:
  ; first byte: initial duty (0/4/8/c) and volume (1-F)
  ; second byte: volume decrease every 16 frames
  ; third byte:
  ; bit 7: cut note if half a row remains
  .byt $88, 0, $00, 0  ; bass
  .byt $47, 4, $00, 0  ; piano
  .byt $86, 1, $00, 0  ; bell between rounds
  .byt $87, 2, $00, 0  ; xylo long
  .byt $87, 6, $00, 0  ; xylo short
  .byt $05, 0, $00, 0  ; distant horn blat
  .byt $88, 4, $00, 0  ; xylo medium

songTable:
  .addr oxi_mood

.enum
  PATT_OXI_DRUMS
  PATT_oxi_SQA1
  PATT_oxi_SQA2
  PATT_oxi_SQA3
  PATT_oxi_SQA4
  PATT_oxi_SQA5
  PATT_oxi_SQB1
  PATT_oxi_SQB2
  PATT_oxi_SQB3
  PATT_NOTHING
.endenum

musicPatternTable:
  .addr oxi_drums, oxi_sqA1, oxi_sqA2, oxi_sqA3, oxi_sqA4, oxi_sqA5, oxi_sqB1, oxi_sqB2,oxi_sqB3, oxi_nothing

oxi_mood:
  setTempo 510
  segno
  playPatSq1 PATT_NOTHING, 27, 1
  playPatSq2 PATT_NOTHING, 27, 1
  playPatNoise PATT_OXI_DRUMS, 0, 0
  waitRows 64
  playPatSq1 PATT_oxi_SQA1, 27, 1
  waitRows 32
  playPatSq1 PATT_oxi_SQA2, 27, 1
  waitRows 32
  playPatSq1 PATT_oxi_SQA1, 27, 1
  playPatSq2 PATT_oxi_SQB1, 27, 4
  waitRows 32
  playPatSq1 PATT_oxi_SQA3, 27, 1
  waitRows 32
;  playPatSq1 PATT_NOTHING, 27, 1
;  playPatSq2 PATT_oxi_SQB3, 27, 4
;  waitRows 32 ;64
  playPatSq1 PATT_oxi_SQA4, 27, 1
  playPatSq2 PATT_oxi_SQB2, 27, 4
  waitRows 32
  playPatSq1 PATT_oxi_SQA5, 27, 1
  waitRows 32
  dalSegno

oxi_sqA1:
  .byt N_F|D_4, N_F|D_4, N_G|D_4, REST|D_8, N_C, N_F, N_A|D_4, N_D|D_4, N_F|D_4
  .byt N_C|D_8, N_C|D_8
oxi_sqA2:
  .byt N_F|D_4, N_F|D_4, N_G|D_4, REST|D_8, N_C, N_F, N_A|D_4
  .byt N_C|D_8, N_D|D_8, N_E|D_8, N_D|D_8, N_E|D_8, N_F|D_8
oxi_sqA3:
  .byt N_F|D_4, N_F|D_4, N_G|D_4, REST|D_8, N_C, N_F, N_A|D_4
  .byt N_C, N_CS, N_D, N_DS, N_F|D_8, N_G|D_8, N_A|D_8, N_CH|D_8

oxi_sqA4:
  .byt N_F|D_4, N_F|D_4, N_G|D_4, REST|D_4
  .byt N_C|D_4, N_C|D_4, N_D|D_4, REST|D_4
oxi_sqA5:
  .byt N_F|D_4, N_F|D_4, N_G|D_4
  .byt N_G|D_8, N_A|D_8, N_C|D_4, N_C|D_4, N_C|D_4, N_C|D_4

oxi_sqB1:
  .byt N_C|D_8, N_F|D_8, N_C|D_8, N_F|D_8
  .byt N_E|D_8, N_G|D_8, N_E|D_8, N_G|D_8
  .byt N_C|D_8, N_E|D_8, N_C|D_8, N_E|D_8
  .byt N_D|D_8, N_G|D_8, N_D|D_8, N_G|D_8
  .byt 255
oxi_sqB3:
.if 0
  .byt N_C, N_C, N_F|D_8, N_C|D_8, N_F|D_8
  .byt N_E, N_E, N_G|D_8, N_E|D_8, N_G|D_8
  .byt N_C, N_C, N_E|D_8, N_C|D_8, N_E|D_8
  .byt N_D, N_D, N_G|D_8, N_D|D_8, N_G|D_8
  .byt 255
.endif

oxi_sqB2:
  .byt N_C, N_C|D_8, N_D|D_8, N_C|D_8
  .byt N_C, N_C|D_8, N_C|D_8, N_D|D_8, N_C|D_8
  .byt 255

oxi_nothing:
  .byt REST|D_2
  .byt 255

oxi_drums:
  .byt KICK|D_8, CLHAT|D_8, SNARE|D_8, CLHAT|D_8, KICK|D_8
  .byt REST, KICK, SNARE|D_8, CLHAT|D_8

  .byt KICK|D_8, CLHAT|D_8, SNARE|D_8, CLHAT|D_8, KICK|D_8
  .byt REST, KICK, SNARE|D_8, CLHAT, KICK
  .byt 255
