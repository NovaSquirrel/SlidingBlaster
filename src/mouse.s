.segment "CODE"
.if 0
;;
; @param X player number
.proc ReadMouse
  lda #1
  sta 1
  sta 2
  sta 3
:
  lda JOY1,x
  lsr a
  rol 1
  bcc :-
  lda mousedown,x
  eor #$FF
  and 1
  sta mousenew,x
  lda 1
  sta mousedown,x
:
  lda JOY1,x
  lsr a
  rol 2
  bcc :-
:
  lda JOY1,x
  lsr a
  rol 3
  bcc :-
  rts
.endproc
.endif

.proc MouseChangeSensitivity
  lda #1
  sta $4016
  lda $4016,x
  lda #0
  sta $4016
  rts
.endproc

.if 0
;;
; Checks for the signature of a Super NES Mouse, which is $x1
; on the second read report.
; Stores 0 for no mouse or 1-3 for mouse sensitivity 1/4, 1/2, 1
.proc DetectMice
crosshairDXLo = CursorVXL
crosshairDXHi = CursorVXH
crosshairDYLo = CursorVYL
crosshairDYHi = CursorVYH
crosshairXLo  = CursorPXL
crosshairXHi  = CursorPXH
crosshairYLo  = CursorPYL
crosshairYHi  = CursorPYH

  lda #0
  sta 4
  sta 5
  ldx #1
loop:
  jsr ReadMouse
  lda 1
  and #$0F
  cmp #1
  bne notMouse
  lda 2
  sta 4
  lda 3
  sta 5
  lda 1
  and #$30
  lsr a
  lsr a
  lsr a
  lsr a
  clc
  adc #1
  bne isMouse
notMouse:
  lda #0
isMouse:
  sta mouseEnabled,x
  dex
  bpl loop

  ; If a mouse is connected, 4 will have Y motion and 5 will have
  ; X motion
  
  lda 4
  bpl mouseNotDown
  eor #$7F
  clc
  adc #$01
mouseNotDown:
  clc
  adc crosshairYHi+0
  cmp #128
  bcs noClipTop
  lda #128
noClipTop:
  cmp #191
  bcc noClipBottom
  lda #191
noClipBottom:
  sta crosshairYHi+0

  lda 5
  bpl mouseNotLeft
  eor #$7F
  clc
  adc #$01
mouseNotLeft:
  clc
  adc crosshairXHi+0
  cmp #48
  bcs noClipLeft
  lda #48
noClipLeft:
  cmp #207
  bcc noClipRight
  lda #207
noClipRight:
  sta crosshairXHi+0
  rts
.endproc
.endif
