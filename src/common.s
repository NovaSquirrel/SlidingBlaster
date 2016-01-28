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

.zeropage
r_seed: .res 1
randx: .res 1
randy: .res 1
randa: .res 1
.code

;http://codebase64.org/doku.php?id=base:two_very_fast_16bit_pseudo_random_generators_as_lfsr
.proc huge_rand
  jsr rand64k       ;Factors of 65535: 3 5 17 257
  jsr rand32k       ;Factors of 32767: 7 31 151 are independent and can be combined
;  lda random1+1        ;can be left out 
;  eor random2+1        ;if you dont use
;  tay                  ;y as suggested
  lda random1           ;mix up lowbytes of random1
  eor random2           ;and random2 to combine both 

  sta randa  
  stx randx
  sty randy
  jsr rand_8 
  eor randa
  ldx randx
  ldy randy
  rts
.endproc
 
;periode with 65535
;10+12+13+15
.proc rand64k
  lda random1+1
  asl
  asl
  eor random1+1
  asl
  eor random1+1
  asl
  asl
  eor random1+1
  asl
  rol random1         ;shift this left, "random" bit comes from low
  rol random1+1
  rts
.endproc
 
;periode with 32767
;13+14
.proc rand32k
  lda random2+1
  asl
  eor random2+1
  asl
  asl
  ror random2         ;shift this right, random bit comes from high - nicer when eor with random1
  rol random2+1
  rts
.endproc

.proc ReadJoy
  lda keydown
  sta keylast
  lda keydown+1
  sta keylast+1

  jsr ReadPads4

  lda $4030
  cmp #'M'
  bne NotTablet
  lda $4031
  and #%11000000
  sta keydown

  lda $4032
  sta CursorPXH
  lda $4033
  sta CursorPXH
  lda #0
  sta CursorPXL
  sta CursorPYL

  lda keylast
  eor #$FF
  and keydown
  sta keynew

  lda keylast+1
  eor #$FF
  and keydown+1
  sta keynew+1
  rts
NotTablet:

  ldx #1
fixupKeys:  
  lda #0
  sta mouseEnabled,x

  lda keydown,x
  bne NotMouse
    lda mousebyte2,x
    and #15
    cmp #1
    bne NotMouse

    lda #1
    sta mouseEnabled,x
    lda mousebyte2,x
    and #KEY_A | KEY_B
    sta keydown,x

    lda mousebyte2,x ; check speed
    and #%00110000
    lsr
    lsr
    lsr
    lsr
    cmp MouseSensitivity,x
    bne :+
      jsr MouseChangeSensitivity
    :

    lda #0
    sta CursorVYL,x
    sta CursorVXL,x

    lda mousebyte4,x
    bpl :+
    eor #$7F
    clc
    adc #1
  : sta CursorVXH,x

    lda mousebyte3,x
    bpl :+
    eor #$7F
    clc
    adc #1
  : sta CursorVYH,x
NotMouse:

;  lda DoControllerSwap
;  and ControllerSwap
;  beq :+
;    lda #1
;    sta mouseEnabled
;  :

  lda keylast,x         ; A = keys that were down last frame
  eor #$FF              ; A = keys that were up last frame
  and keydown,x         ; A = keys down now and up last frame
  sta keynew,x  
  dex
  bpl fixupKeys
  rts
.endproc

ReadPadsOnce:
  lda #1
  sta JOY1
  lda #0
  sta JOY1
ReadPadsByte:
  lda #1
  sta 0
  sta 1
  : lda JOY1
    and #$03
    cmp #1
    rol 0
    lda JOY2
    and #$03
    cmp #1
    rol 1
    bcc :-
  rts

.proc ReadPads4
  lda 0
  pha
  lda 1
  pha
  jsr ReadPadsOnce
  lda 0
  sta keydown
  lda 1
  sta keydown+1
  jsr ReadPadsByte
  lda 0
  sta mousebyte2
  lda 1
  sta mousebyte2+1
  jsr ReadPadsByte
  lda 0
  sta mousebyte3
  lda 1
  sta mousebyte3+1
  jsr ReadPadsByte
  lda 0
  sta mousebyte4
  lda 1
  sta mousebyte4+1
  pla
  sta 1
  pla
  sta 0

  lda DoControllerSwap
  and ControllerSwap
  beq NoSwap
  swapx keydown, keydown+1
  swapx mousebyte2, mousebyte2+1
  swapx mousebyte3, mousebyte3+1
  swapx mousebyte4, mousebyte4+1
NoSwap:
  rts
.endproc

.proc wait_vblank
  lda retraces
  loop:
    cmp retraces
    beq loop
  rts
.endproc

.proc PutHex
	pha
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	and #$0f
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	rts
hexdigits:	.byt "0123456789ABCDEF"
.endproc

.proc PutDecimal ; Prints with anywhere from 1 to 3 digits
   cmp #10 ; only one char
   bcs :+
     add #'0'    ; char is number+'0'
     sta PPUDATA
     rts
   :

   ; the hundreds digit if necessary
   cmp #200
   bcc LessThan200
   ldx #'2'
   stx PPUDATA
   sub #200
   jmp :+
LessThan200:
   cmp #100
   bcc :+
   ldx #'1'
   stx PPUDATA
   sub #100
:
   ldx #'0'    ; now calculate the tens digit
:  cmp #10
   bcc Finish
   sbc #10     ; carry will be set if this runs anyway
   inx
   jmp :-
Finish:
   stx PPUDATA ; display tens digit
   add #'0'
   sta PPUDATA ; display ones digit
   rts
.endproc
.proc ClearName
;Clear the nametable
  ldx #$20
  ldy #$00
  stx PPUADDR
  sty PPUADDR
  ldx #64
  ldy #4
  lda #' '
: sta PPUDATA
  inx
  bne :-
  dey
  bne :-
;Clear the attributes
  ldy #64
  lda #0
: dey
  bne :-
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

.proc WaitForKey
: jsr ReadJoy
  jsr wait_vblank
  lda keydown
  ora keydown+1
  bne :-

: jsr ReadJoy
  jsr wait_vblank
  lda keydown
  ora keydown+1
  beq :-
  lda keylast
  ora keylast+1
  bne :-
  rts
.endproc

.proc CopyFromCHR ; A: <address, X: >address - outputs to $500
  stx PPUADDR
  sta PPUADDR
  lda PPUDATA ; dummy read

  ldy #0      ; prepare destination address (always $500)
  sty 0
  lda #5
  sta 1

  ldx PPUDATA ; read size low
  lda PPUDATA ; read size high
  sta 2
  inc 2

Loop:
  lda PPUDATA
  sta (0),y
  iny
  bne :+      ; fix destination address if we roll over
    inc 1
  :
  dex
  cpx #<-1     ; fix size if we roll over
  bne :+
    lda 2
    beq Exit
    dec 2
    bmi Exit
  :
  bne Loop
Exit:
  rts
.endproc

.proc PutStringImmediate
	DPL = $02
	DPH = $03
	pla					; Get the low part of "return" address
                        ; (data start address)
	sta     DPL     
	pla 
	sta     DPH         ; Get the high part of "return" address
                        ; (data start address)
						; Note: actually we're pointing one short
PSINB:	ldy #1
	lda (DPL),y         ; Get the next string character
	inc DPL             ; update the pointer
	bne PSICHO          ; if not, we're pointing to next character
	inc DPH             ; account for page crossing
PSICHO:	ora #0          ; Set flags according to contents of 
                        ;    Accumulator
	beq     PSIX1       ; don't print the final NULL 
	sta PPUDATA         ; write it out
	jmp     PSINB       ; back around
PSIX1:	inc     DPL     ; 
	bne     PSIX2       ;
	inc     DPH         ; account for page crossing
PSIX2:	jmp     (DPL)   ; return to byte following final NULL
.endproc
.macro LoadPalette Addr
    lda #0
    sta PPUMASK
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-

	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-
.endmacro
.macro LoadNametable Addr
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	lda #<Addr
	sta 0
	lda #>Addr
	sta 1
	ldx #4
	ldy #0
:	lda ($0), y
	sta PPUDATA
	iny
	bne :-
	inc 1
	dex
	bne :-
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
.endmacro
.proc rand_8    ; From some site
  lda   r_seed  ; get seed
  and   #$B8    ; mask non feedback bits
                ; for maximal length run with 8 bits we need
                ; taps at b7, b5, b4 and b3
  ldx   #$05    ; bit count (shift top 5 bits)
  ldy   #$00    ; clear feedback count
F_loop:
  asl   A       ; shift bit into carry
  bcc   bit_clr ; branch if bit = 0

  iny           ; increment feedback count (b0 is XOR all the	
                ; shifted bits from A)
bit_clr:
  dex           ; decrement count
  bne   F_loop  ; loop if not all done
no_clr:
  tya           ; copy feedback count
  lsr   A       ; bit 0 into Cb
  lda   r_seed  ; get seed back
  rol   A       ; rotate carry into byte
  sta   r_seed  ; save number as next seed
  rts           ; done
.endproc

.proc BitSelect
 .byt %00000001
 .byt %00000010
 .byt %00000100
 .byt %00001000
 .byt %00010000
 .byt %00100000
 .byt %01000000
 .byt %10000000
.endproc
.proc BitCancel
 .byt %11111110
 .byt %11111101
 .byt %11111011
 .byt %11110111
 .byt %11101111
 .byt %11011111
 .byt %10111111
 .byt %01111111
.endproc

.macro PrintStringY String
.local Loop
.local Exit
  ldy #0
Loop:
  lda String,y
  beq Exit
  sta PPUDATA
  iny
  bne Loop
Exit:
.endmacro
