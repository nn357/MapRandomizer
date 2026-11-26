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
  rep $39C : dw $0000
stats_screen_table2:
  rep $39C : dw $0000
  
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
    ldy.w #$0000
.copy:
    lda.l stats_screen_table,x      ; X = 0 or the second table's offset
    sta.w $3000,y
    inx : inx
    iny : iny
    cpy.w #$0700
    bne .copy
    jsr stats_draw_times
.queue:
    plb
    ldx.w $0330
    lda.w #$0220 : sta.w $00D0,x
    lda.w #$34E0 : sta.w $00D2,x
    sep #$20
    lda.b #$7E : sta.w $00D4,x
    rep #$20
    lda.w #$4E70 : sta.w $00D5,x
    txa : clc : adc.w #$0007 : sta.w $0330
    plp
    rtl
; Clobbers A, X, Y
;
; Scratch is a $14 byte stack frame used as direct page:
;   $01-$04  frame count, then hundredths, then the running quotient
;   $05-$0C  64-bit product ($0C is reused as the divisor)
;   $0D      seconds
;   $0F      minutes
;   $11      pointer to the next item index

stats_draw_times:
    phd
    tsc : sec : sbc.w #$0014 : tcs : tcd
    stx $11
    ldy.w #$302C                    ; buffer row 0, column 22

.row:
    ldx $11
    inx : inx
    stx $11
    lda.l stats_screen_table-2,x    ; item index for this row
    cmp.w #$FFFF
    beq .next

    asl : asl : tax                 ; 4 bytes per time
    lda.l $7EFE06,x : sta $01
    lda.l $7EFE08,x : sta $03
    ora $01
    beq .next                       ; not collected: leave blank

    jsr stats_frames_to_hundredths

    lda.w #100 : jsr stats_divide   ; drop the hundredths
    lda.w #60  : jsr stats_divide : sta $0D
    lda.w #60  : jsr stats_divide : sta $0F

    ; cap hours at 99
    lda $03
    bne .cap
    lda $01
    cmp.w #100
    bcc .draw
.cap:
    lda.w #99 : sta $01

.draw:
    jsr stats_draw_time

.next:
    tya : clc : adc.w #$0040 : tay
    cpy.w #$302C+(28*$40)
    bne .row

    tsc : clc : adc.w #$0014 : tcs
    pld
    rts

; hundredths = (frames * $01A9F711) >> 24, the same math as the credits
macro stats_mul(f, k, pos)
    sep #$20
    lda.b $01+<f> : sta.l $004202
    lda.b #<k>    : sta.l $004203
    rep #$20
    ldx.w #<pos>
    jsr stats_add_product
endmacro

stats_frames_to_hundredths:
    stz $05 : stz $07 : stz $09 : stz $0B

    %stats_mul(0, $11, 0) : %stats_mul(1, $11, 1) : %stats_mul(2, $11, 2) : %stats_mul(3, $11, 3)
    %stats_mul(0, $F7, 1) : %stats_mul(1, $F7, 2) : %stats_mul(2, $F7, 3) : %stats_mul(3, $F7, 4)
    %stats_mul(0, $A9, 2) : %stats_mul(1, $A9, 3) : %stats_mul(2, $A9, 4) : %stats_mul(3, $A9, 5)
    %stats_mul(0, $01, 3) : %stats_mul(1, $01, 4) : %stats_mul(2, $01, 5) : %stats_mul(3, $01, 6)

    lda $08 : sta $01
    lda $0A : sta $03
    rts

; add the hardware product into the 64-bit total at byte position X
stats_add_product:
    lda.l $004216
    clc : adc $05,x : sta $05,x
    bcc .done
.carry:
    inx : inx
    inc $05,x
    beq .carry
.done:
    rts

; 32-bit / 8-bit, in place at $01-$04. In: A = divisor. Out: A = remainder
stats_divide:
    sep #$20
    sta $0C
    lda.b #$00                      ; running remainder
    ldx.w #$0003
.byte:
    sta.l $004205
    lda $01,x : sta.l $004204
    lda $0C   : sta.l $004206
    nop : nop : nop : nop : nop : nop : nop : nop
    lda.l $004214 : sta $01,x
    lda.l $004216
    dex
    bpl .byte
    rep #$20
    and.w #$00FF
    rts

; Y = buffer address of column 22. Layout: HH:MM:SS
stats_draw_time:
    lda $01
    beq .no_hours

    jsr stats_draw_lead             ; hours
    lda.w #$001E : sta.w $0004,y
    phy
    tya : clc : adc.w #$0006 : tay
    lda $0F : jsr stats_draw_two    ; minutes, keeps leading zero
    ply
    bra .seconds

.no_hours:
    phy
    tya : clc : adc.w #$0006 : tay
    lda $0F : jsr stats_draw_two   ; minutes, with leading zero, use draw_lead to remove the leading zero.
    ply

.seconds:
    lda.w #$001E : sta.w $000A,y
    phy
    tya : clc : adc.w #$000C : tay
    lda $0D : jsr stats_draw_two
    ply
    rts

; A = 0-99. Out: $4214 = tens, $4216 = ones, A = tens (Z set if zero)
stats_split:
    sta.l $004204
    sep #$20
    lda.b #10 : sta.l $004206
    rep #$20
    nop : nop : nop : nop : nop : nop : nop : nop
    lda.l $004214
    rts

stats_draw_two:
    jsr stats_split
    asl : tax
    lda.l stats_digits,x : sta.w $0000,y
    bra stats_draw_ones

stats_draw_lead:
    jsr stats_split
    beq stats_draw_ones             ; tens is zero: leave it blank
    asl : tax
    lda.l stats_digits,x : sta.w $0000,y

stats_draw_ones:
    lda.l $004216
    asl : tax
    lda.l stats_digits,x : sta.w $0002,y
    rts

stats_digits:
    dw $0089, $008A, $008B, $008C, $008D, $008E, $008F, $0099, $009E, $009F
    
blank_word:
    dw $004F                        ; must match BLANK_TILE in Rust
print pc
assert pc() <= !bank_ea_free_space_end
