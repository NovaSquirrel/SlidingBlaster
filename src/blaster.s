; Double Action Blaster Guys
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

;.setcpu "6502X"
.include "ns_nes.s" ; handy macros and defines
.include "common.s" ; handy routines
.include "memory.s"
.include "main.s"
.include "player.s"
.include "newgame.s"
.include "math.s"
.include "bullet.s"
.include "mouse.s"
.include "object.s"
.include "explosion.s"
.include "musicseq.h"
.include "sound.s"
.include "music.s"
.include "meta.s"
.include "level.s"
.include "musicseq.s"
.include "unpkb.s"
.include "screens.s"
.include "edit.s"

.segment "INESHDR"
  .byt "NES", $1A
  .byt 1     ; PRG in 16kb units
  .byt 1     ; CHR in 8kb units
  .byt 0     ; horizontal mirroring
  .byt %1000 ; NES 2.0
  .byt 0     ; extra mapper bits
  .byt 0     ; extra PRG/CHR bits
  .byt $00   ; no PRG RAM
  .byt $00   ; no CHR RAM
  .byt 0     ; NTSC (PAL works but no speed adjustments are made)
  .byt 0     ; regular PPU

.segment "VECTORS"
  .addr nmi, reset, irq
.segment "CODE"

.proc reset
  lda #0		; Turn off PPU
  sta PPUCTRL
  sta PPUMASK
  sei
  ldx #$FF	; Set up stack pointer
  txs		; Wait for PPU to stabilize

: lda PPUSTATUS
  bpl :-
: lda PPUSTATUS
  bpl :-

  inx
  txa
: sta $000,x
  sta $100,x 
;  sta $200,x
  sta $300,x 
  sta $400,x 
  sta $500,x 
  sta $600,x 
  sta $700,x 
  inx
  bne :-

  lda #0
  sta SND_CHN
	
  lda #50
  sta PlayerPXH
  sta PlayerPYH
  lda #0
  sta PlayerPXL
  sta PlayerPYL

  lda #$69
  sta r_seed
  lda #$5a
  sta random1+0
  lda #$a5
  sta random1+1
  lda #$53
  sta random2+0
  lda #$76
  sta random2+1

  lda #100
  sta CursorPXH
  sta CursorPYH

  lda #$21
  sta FlashColor

  jsr ClearName
	
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR

  ldx #0
: lda #$01 ;2c for cyan sky
  sta PPUDATA
  lda #$0f
  sta PPUDATA
  lda PaletteTable1,x
  sta PPUDATA
  lda PaletteTable2,x
  sta PPUDATA
  inx
  cpx #8
  bne :-

  lda #VBLANK_NMI | NT_2000 | BG_0000 | OBJ_1000
  sta PPUCTRL
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK

  lda #2
  sta RacecarMode+0
  sta RacecarMode+1

  sei
  jmp StartMainMenu
.endproc

PaletteTable1:
  .byt $00, $12, $2a, $28
  .byt $21, $16, $2a, $28
PaletteTable2:
  .byt $30, $30, $30, $30
  .byt $30, $37, $30, $30

.proc Crashed
;  lda #SOUND_MONEY
;  jsr start_sound
  jmp MainLoop
.endproc

.proc nmi
  pha
  inc retraces
  lda #0
  sta OAMADDR
  sta OamPtr
  lda #2
  sta OAM_DMA

  ; crash recovery
  lda CrashDetect
  beq :+
    inc CrashDetect
    lda CrashDetect
    cmp #4
    bcc :+
      pla
      pla
      pla
      ldx #255
      txs
      jmp Crashed
  :

  lda EnableNMIDraw
  bne :+
    pla
    rti
: dec EnableNMIDraw

  lda #$3f
  sta PPUADDR
  lda #$1e
  sta PPUADDR
  lda FlashColor
  sta PPUDATA
  lda retraces
  and #1
  beq :+
  lda FlashColor
  add #1
  sta FlashColor
  cmp #$2c
  bne :+
    lda #$21
    sta FlashColor
: lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

 .repeat 5, I ; change if the max number of tile changes per frame is changed
    lda TileUpdateA1+I
    beq :+
      sta PPUADDR
      lda TileUpdateA2+I
      sta PPUADDR
      lda TileUpdateT+I
      sta PPUDATA
      lda #0
      sta TileUpdateA1+I
    :
 .endrep
 .repeat 4, I ; change if the max number of metatile changes per frame is changed
    lda BlockUpdateA1+I
    beq :+
      sta PPUADDR
      lda BlockUpdateA2+I
      sta PPUADDR
      lda BlockUpdateT1+I
      sta PPUDATA
      lda BlockUpdateT2+I
      sta PPUDATA

      lda BlockUpdateB1+I
      sta PPUADDR
      lda BlockUpdateB2+I
      sta PPUADDR
      lda BlockUpdateT3+I
      sta PPUDATA
      lda BlockUpdateT4+I
      sta PPUDATA
      lda #0
      sta BlockUpdateA1+I
    :
  .endrep

  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

  pla
  rti
.endproc

.proc irq
  rti
.endproc
 
.segment "CHR"
.incbin "ascii.chr", 0, $1900

.segment "CHR_DATA"
TitleName:
.addr EndTitle-TitleName
.incbin "title.pkb"
EndTitle:
.segment "CODE"
