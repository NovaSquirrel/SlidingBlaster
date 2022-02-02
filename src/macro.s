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

.feature leading_dot_in_identifiers
.macpack generic
.macpack longbranch

; Meant to be an easy replacement for .repeat and .endrepeat
; when you're trying to save space. Uses a zeropage memory location
; instead of a register as a loop counter so as not to disturb any
; registers.
; Times - Number of times to loop ( may be a memory location )
; Free  - Free zeropage memory location to use
.macro .dj_loop Times, Free
  .scope
    DJ_Counter = Free
    lda Times
    sta Free
DJ_Label:
.endmacro
.macro .end_djl
  NextIndex:
    dec DJ_Counter
    jne DJ_Label
  .endscope
.endmacro


; Imitation of z80's djnz opcode.
; Can be on A, X, Y, or a zeropage memory location
; Label - Label to jump to
; Reg   - Counter register to use: A,X,Y or memory location
.macro djnz Label, Reg
  .if (.match({Reg}, a))
    sub #1
  .elseif (.match({Reg}, x))
    dex
  .elseif (.match({Reg}, y))
    dey
  .else
    dec var
  .endif
  bne Label
.endmacro


; Working with X,Y is much more fun than working with PPU addresses
; give it an X and Y position, as well as a nametable number (0-3),
; and if you want to save the address to a 16-bit zeropage address
; ( big endian ) you can give an additional argument.
; NT - Nametable number (0-3)
; PX - X position in tiles
; PY - Y position in tiles
; Var - Variable to store address in (optional)
.macro PositionXY NT, PX, PY, Var
	.scope
		t0 = $2000 + (NT * 1024)	; Nametable data starts at $2000 
		t1 = PX                 ; and each nametable is 1024 bytes in size
		t2 = PY * 32			; Nametable rows are 32 bytes large
		t3 = t0 + t1 + t2
        .ifblank Var
          lda #>t3
          sta $2006
          lda #<t3
          sta $2006
        .else
          lda #>t3
          sta Var+0
          lda #<t3
          sta Var+1
        .endif
	.endscope
.endmacro

.macro PutImmediateAtXY NT, PX, PY, Text
  PositionXY NT, PX, PY
  jsr PutStringImmediate
  .byt Text, 0
.endmacro


























.macro .nyb InpA, InpB		; Makes a .byt storing two 4 bit values
	.byt ( InpA<<4 ) | InpB
.endmacro

.macro .raddr This          ; like .addr but for making "RTS trick" tables with
 .addr This-1
.endmacro

; imaginary opcode section
.macro phx
  txa
  pha
.endmacro
.macro phy
  tya
  pha
.endmacro
.macro plx
  pla
  txa
.endmacro
.macro ply
  pla
  tya
.endmacro
.macro revsub Value       ; reverse subtraction
  eor #$FF
  sec
  adc Value
.endmacro
.macro neg                ; imitation of the z80 opcode NEG
  eor #$FF
  sec
  adc #0
.endmacro
.macro BackupRegs         ; backup all
	pha
	txa
	pha
	tya
	pha
.endmacro
.macro RestoreRegs        ; restore all
	pla
	tay
	pla
	tax
	pla
.endmacro
.macro lcp arg1, arg2    ; load then CMP
	lda arg1
	cmp arg2
.endmacro
.macro inw Addr          ; 16-bit increment
	.local Skip
	inc Addr
	bne Skip
	inc Addr+1
Skip:
.endmacro
.macro dew Addr          ; 16-bit decrement
	.local Skip
	inc Addr
	bne Skip
	inc Addr+1
Skip:
.endmacro







.macro btr Num, Here
.if .match({Num},"eq")
	beq Here
.elseif .match({Num},"ne")
	bne Here
.elseif .match({Num},"cs")
	bcs Here
.elseif .match({Num},"cc")
	bcc Here
.elseif .match({Num},"vs")
	bvs Here
.elseif .match({Num},"vc")
	bvc Here
.elseif .match({Num},"pl")
	bpl Here
.elseif .match({Num},"mi")
	bmi Here
.endif
.endmacro
.macro bfl Num, Here
.if .match({Num},"eq")
	beq Here
.elseif .match({Num},"ne")
	bne Here
.elseif .match({Num},"cs")
	bcs Here
.elseif .match({Num},"cc")
	bcc Here
.elseif .match({Num},"vs")
	bvs Here
.elseif .match({Num},"vc")
	bvc Here
.elseif .match({Num},"pl")
	bpl Here
.elseif .match({Num},"mi")
	bmi Here
.endif
.endmacro
