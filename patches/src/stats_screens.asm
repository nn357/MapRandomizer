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
    lda.b $8F
    and.w #$0030                    ; R = $0010, L = $0020
    beq .select
    lda.w $1A05
    eor.w #$0001
    sta.w $1A05

.select:
    ; SELECT newly pressed
    lda.b $8F
    and.w #$2000
    beq .done

    ; forced blank on
    sep #$20
    lda #$01                        ; hide bg2 (screw attack logo)
    sta $69
    lda.b $51 : pha                 ; save the game's INIDISP mirror
    lda.b #$80 : sta.b $51 : sta.w $2100
    rep #$20
    ; reset bg scroll
    lda #$0000
    sta $1997
    
    ; one-time palette / digit upload
    lda.l !stats_palette_upload
    bne .screen
    jsl upload_stats_graphics
    lda.w #$0001
    sta.l !stats_palette_upload

.screen:
    jsl update_stats_screen         ; flips the screen variable and uploads that screen

    ; forced blank off
    sep #$20
    pla : sta.b $51 : sta.w $2100

.done:
    plp
    rts

print pc
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
    php
    rep #$20
    pha
    lda.w #$0001
    sta.l !stats_screen_var
    lda.w #$0000
    sta.l !stats_palette_upload
    pla
    plp
    jsl $80824f                     ; replaced code
    rtl 
  
upload_stats_graphics:
    php
    rep #$30
    phx
    phb
    pea $7E7E : plb : plb           ; DB = $7E

    ; palettes -> game's CGRAM buffer $7E:C000 (sent to CGRAM by the NMI every frame)
    ldx.w #$0000
.pal:
    lda.l stats_palettes,x
    sta.w $C000,x
    inx : inx
    cpx.w #$0100
    bne .pal

    plb                             ; back to the caller's data bank

    ; digits -> VRAM via the game's transfer queue
    ldx.w $0330                     ; queue pointer

    ; entry 1: digits 0-6 -> VRAM word $4890
    lda.w #224                      ; 7 tiles * 32 bytes
    sta.w $00D0,x
    lda.w #digits_8x8_4bpp
    sta.w $00D2,x
    sep #$20
    lda.b #digits_8x8_4bpp>>16
    sta.w $00D4,x
    rep #$20
    lda.w #$4890
    sta.w $00D5,x

    ; entry 2: digit 7 -> VRAM word $4990
    lda.w #32                       ; 1 tile * 32 bytes
    sta.w $00D7,x
    lda.w #digits_8x8_4bpp+224
    sta.w $00D9,x
    sep #$20
    lda.b #digits_8x8_4bpp>>16
    sta.w $00DB,x
    rep #$20
    lda.w #$4990
    sta.w $00DC,x

    ; entry 3: digits 8-9 -> VRAM word $49E0
    lda.w #64                       ; 2 tiles * 32 bytes
    sta.w $00DE,x
    lda.w #digits_8x8_4bpp+256
    sta.w $00E0,x
    sep #$20
    lda.b #digits_8x8_4bpp>>16
    sta.w $00E2,x
    rep #$20
    lda.w #$49E0
    sta.w $00E3,x

    txa
    clc
    adc.w #$0015                    ; advance pointer past 3 entries (3 * 7)
    sta.w $0330

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
    phb
    pea $7E7E : plb : plb           ; DB = $7E, so sta.w hits the buffer

    lda.l !stats_screen_var
    eor.w #$0001
    sta.l !stats_screen_var
    beq .screen0
    ldx.w #stats_screen_table2-stats_screen_table
    bra .go
.screen0:
    ldx.w #$0000
.go:
    ; clear buffer rows 0-25 with the blank tile
    lda.l blank_word
    ldy.w #$0000
.clr:
    sta.w $3000,y
    iny : iny
    cpy.w #$0680
    bne .clr

    ; copy rows into the buffer, starting at tilemap row 3
    lda.l stats_screen_table,x      ; row count
    beq .queue
    pha
    txa : clc : adc.w #stats_screen_table+2 : tax
    ldy.w #$30C0                    ; $3000 + row 3 * $40
.row:
    lda.w #$0020
    pha                             ; word counter
.word:
    lda.l !stats_table_bank<<16,x
    sta.w $0000,y
    inx : inx
    iny : iny
    lda 1,s : dec : sta 1,s
    bne .word
    pla
    inx : inx                       ; skip the item_idx word
    lda 1,s : dec : sta 1,s
    bne .row
    pla

.queue:
    plb
    ; the game's own entry covers buffer bytes $0000-$04DF, so queue the
    ; rest (rows 19-25) to VRAM word $4C00 + $270 = $4E70
    ldx.w $0330
    lda.w #$01A0 : sta.w $00D0,x
    lda.w #$34E0 : sta.w $00D2,x
    sep #$20
    lda.b #$7E : sta.w $00D4,x
    rep #$20
    lda.w #$4E70 : sta.w $00D5,x
    txa : clc : adc.w #$0007 : sta.w $0330
    plp
    rtl

blank_word:
    dw $004F                        ; must match BLANK_TILE in Rust
print pc
assert pc() <= !bank_ea_free_space_end
