;;; Maprando Stats Screens
;;;
;;; nn_357

arch snes.cpu
lorom

;;; declarations

!bank_8b_free_space_start = $8bfac5
!bank_8b_free_space_end = $8bffff

!bank_df_free_space_start = $dfec32
!bank_df_free_space_end = $dffef0

!bank_ea_free_space_start = $eab300
!bank_ea_free_space_end = $eaffff

!stats_table_bank = $ea
!stats_screen_var = $7ef5a6
!stats_palette_upload = $7ef5a8

;;; vanilla hooks

org $8be7b5
  jsl setup_stats

org $8be7af
  lda.w #stats_handler                                                          ;} Cinematic function = stats_handler

;;; custom code

org !bank_8b_free_space_start
stats_handler:
  php
  rep #$30

  ; L / R newly pressed: toggle stars
  lda $8f
  and #$0030                      ; R = $0010, L = $0020
  beq .select
  lda $1a05
  eor #$0001
  sta $1a05

.select:
  ; SELECT newly pressed
  lda $8f
  and #$2000
  beq .done

  ; forced blank on
  sep #$20
  lda $51 : pha                   ; save the game's INIDISP mirror
  lda #$80 : sta $51 : sta $2100
  rep #$20

  ; one-time palette / digit upload
  lda.l !stats_palette_upload
  bne .screen
  jsl upload_stats_graphics
  lda #$0001
  sta.l !stats_palette_upload

.screen:
  jsl update_stats_screen         ; flips the screen variable and uploads that screen

  ; forced blank off
  sep #$20
  pla : sta $51 : sta $2100

.done:
  plp
  rts

org !bank_df_free_space_start

stats_palettes:
  dw $0000, $7FFF, $28C6 : rep 13 : dw $0000   ; 0 white
  dw $0000, $7DA4, $28C6 : rep 13 : dw $0000   ; 1 blue (Maridia, header)
  dw $0000, $023F, $28C6 : rep 13 : dw $0000   ; 2 orange (Tourian)
  dw $0000, $17E9, $28C6 : rep 13 : dw $0000   ; 3 green (Brinstar)
  dw $0000, $001D, $28C6 : rep 13 : dw $0000   ; 4 red (Norfair)
  dw $0000, $2717, $28C6 : rep 13 : dw $0000   ; 5 yellow (Wrecked Ship)
  dw $0000, $7C74, $28C6 : rep 13 : dw $0000   ; 6 purple (Crateria)
  dw $0000, $7FFF, $28C6 : rep 13 : dw $0000   ; 7 spare

digits_8x8_4bpp:
  db $00,$7E,$3C,$C3,$66,$99,$66,$99,$66,$99,$66,$99,$3C,$C3,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 0
  db $00,$3C,$18,$64,$38,$44,$18,$64,$18,$24,$18,$66,$3C,$42,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 1
  db $00,$7E,$3C,$C3,$66,$99,$06,$F9,$18,$67,$30,$CF,$7E,$81,$00,$FF
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 2
  db $00,$7E,$3C,$C3,$66,$99,$1C,$E3,$06,$F9,$66,$99,$3C,$C3,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 3
  db $00,$1E,$0C,$32,$1C,$63,$36,$C9,$7E,$81,$06,$F9,$06,$09,$00,$0F
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 4
  db $00,$FF,$7E,$81,$60,$9F,$7C,$83,$06,$F9,$66,$99,$3C,$C3,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 5
  db $00,$7E,$3C,$C2,$60,$9E,$7C,$83,$66,$99,$66,$99,$3C,$C3,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 6
  db $00,$FF,$7E,$81,$06,$F9,$0C,$33,$18,$26,$18,$24,$18,$24,$00,$3C
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 7
  db $00,$7E,$3C,$C3,$66,$99,$3C,$C3,$66,$99,$66,$99,$3C,$C3,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 8
  db $00,$7E,$3C,$C3,$66,$99,$66,$99,$3E,$C1,$06,$79,$3C,$43,$00,$7E
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 9

setup_stats:
  lda #$0001
  sta !stats_screen_var
  lda #$0000
  sta !stats_palette_upload
  jsl $80824f                                                         ; replaced code      
  rtl  
  
upload_stats_graphics:
  php
  rep #$30
  phx

  ; palettes -> CGRAM $00-$7F (direct DMA)
  sep #$20
  stz $2121
  lda #$00 : sta $4300
  lda #$22 : sta $4301
  ldx #stats_palettes : stx $4302
  lda.b #stats_palettes>>16 : sta $4304
  ldx #$0100 : stx $4305
  lda #$01 : sta $420B

  ; digits -> VRAM via the game's transfer queue
  rep #$30
  ldx $0330                       ; queue pointer

  ; entry 1: digits 0-6 -> VRAM word $4890
  lda #224                        ; 7 tiles * 32 bytes
  sta $D0,x
  lda #digits_8x8_4bpp
  sta $D2,x
  sep #$20
  lda.b #digits_8x8_4bpp>>16
  sta $D4,x
  rep #$20
  lda #$4890
  sta $D5,x

  ; entry 2: digits 7-9 -> VRAM word $4990
  lda #96                         ; 3 tiles * 32 bytes
  sta $D7,x
  lda #digits_8x8_4bpp+224
  sta $D9,x
  sep #$20
  lda.b #digits_8x8_4bpp>>16
  sta $DB,x
  rep #$20
  lda #$4990
  sta $DC,x

  txa
  clc
  adc #$000E                      ; advance pointer past 2 entries (2 * 7)
  sta $0330
  plx
  plp
  rtl
  
assert pc() <= !bank_df_free_space_end

org !bank_ea_free_space_start
stats_screen_table:
  rep 760 : dw $0000
stats_screen_table2:
  rep 760 : dw $0000
  
update_stats_screen:
    php
    rep #$30
    lda.l !stats_screen_var
    eor #$0001
    sta.l !stats_screen_var
    beq .screen0
    ldx #stats_screen_table2-stats_screen_table
    bra .go
.screen0:
    ldx #$0000
.go:
    phx                             ; table offset

    ; clear the tilemap with a blank tile
    sep #$20
    lda #$80 : sta $2115
    rep #$20
    ldx #$0000 : stx $2116
    sep #$20
    lda #$09 : sta $4300            ; fixed source, 2 registers
    lda #$18 : sta $4301
    ldx #blank_word : stx $4302
    lda.b #blank_word>>16 : sta $4304
    ldx #$1000 : stx $4305
    lda #$01 : sta $420B

    ; rows -> tilemap, one 64-byte transfer each (skips the item_idx word)
    rep #$30
    plx
    lda.l stats_screen_table,x      ; row count
    beq .done
    pha
    txa : clc : adc #stats_screen_table+2 : tax   ; first row address
    ldy #$0060                      ; VRAM word of tilemap row 3
    sep #$20
    lda #$01 : sta $4300
    lda #$18 : sta $4301
    lda #!stats_table_bank : sta $4304
    rep #$20
.row:
    sty $2116
    stx $4302
    lda #$0040 : sta $4305
    sep #$20
    lda #$01 : sta $420B
    rep #$20
    txa : clc : adc #66 : tax
    tya : clc : adc #$0020 : tay
    lda 1,s : dec : sta 1,s
    bne .row
    pla
.done:
    plp
    rtl

blank_word:
    dw $005A                        ; must match BLANK_TILE in Rust

assert pc() <= !bank_ea_free_space_end
