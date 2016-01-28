MEMORY {
  ZP:     start = $10, size = $f0, type = rw;
  # use first $10 zeropage locations as locals
  HEADER: start = $7f00, size = $0010, type = ro, file = %O, fill = yes, fillval = $00;
  RAM:    start = $0300, size = $0500, type = rw;
  PRG0:   start = $c000, size = $4000, type = ro, file = %O, fill = yes, fillval = $FF;
  CHR0:   start = $0000, size = $1900;
  CHR1:   start = $1900, size = $700, fillval = $00, fill = yes;
}

SEGMENTS {
  INESHDR:  load = HEADER, type = ro, align = $10;
  ZEROPAGE: load = ZP, type = zp;
  BSS:      load = RAM, type = bss, define = yes, align = $100;
  CODE:     load = PRG0, type = ro;
  RODATA:   load = PRG0, type = ro, align = $100;
  DMC:      load = PRG0, type = ro, align = $40, optional = yes;
  VECTORS:  load = PRG0, type = ro, start = $FFFA;
  CHR:      load = CHR0, type = ro;
  CHR_DATA: load = CHR1, type = ro, optional = yes;
}

FILES {
  %O: format = bin;
}

