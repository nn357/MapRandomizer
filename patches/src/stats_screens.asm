;;; Maprando Stats Screens
;;;
;;; nn_357

arch snes.cpu
lorom

;;; declarations

incsrc "constants.asm"

!bank_8b_free_space_start = $8bfac5
!bank_8b_free_space_end = $8bfb2e

!bank_df_free_space_start = $dfec32
!bank_df_free_space_end = $dff241

!bank_ea_free_space_start = $eab300
!bank_ea_free_space_end = $eac7c6

!stats_table_bank = $ea
!collected_beams = $09a8
!collected_items = $1f5d
!stats_screen_var = $7ef5a6
!stats_palette_upload = $7ef5a8
!stats_game_finished = $7ef5aa

!nothing_item_total = $dfff0e     ; modified by patch.rs, defined in item_count.asm
!initial_item_bits  = $b5fe12     ; wrote by patch.rs
!settings_flags = $dfff05

;;; tiles with fixed palettes
!stats_percent = $1C7B ; tile 7B palette 7
!stats_slash   = $1C7C ; tile 7C palette 7
!stats_colon = $1C1E ; tile 1E palette 7
!stats_period = $1C1C ; tile 1C palette  7

;;; vanilla hooks


;org $8be7b5
;  jsl setup_stats

org $8be7af
  lda.w #stats_handler                                                          ;} Cinematic function = stats_handler

org $8CE12D                                                                     ;] see you next mission #delete
  dw end_of_game

org $91e5f0
  jml backup_items                                                        
  nop #2
org $91e5f6
backup_finished:
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
    lda !stats_game_finished
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
    jsl $808338                     ; wait for nmi (vblank is off so we have time for transfers to finish)
    ; forced blank off
    sep #$20
    pla : sta.b $51 : sta.w $2100

.done:
    plp
    rts

end_of_game:
    rep #$30
    pha
    lda #$0001
    sta.l !stats_game_finished
    pla
    jmp $9698

print "Bank $8b free space ends at: $", pc 
assert pc() <= !bank_8b_free_space_end

org !bank_df_free_space_start

stats_palettes:
  dw $0000, $02DF, $01D7, $00AC, $5A73, $41AD, $2D08, $1863, $0BB1, $0017, $319F, $7FFF, $7FFF, $48FB, $7FFF, $0000 ; CRE
  dw $0000, $7DA4, $28C6, $0BB1, $1EA9, $0145, $7FFF : rep 9 : dw $0000 ; 1 blue / Plasma
  dw $0000, $023F, $28C6, $72BC, $48FB, $1816, $7FFF : rep 9 : dw $0000 ; 2 orange / Wave
  dw $0000, $17E9, $28C6, $4A52, $72B2, $71C7, $4D03, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $7FFF, $0000 ; 3 green / Ice / Blue Booster
  dw $0000, $001D, $28C6, $34C5, $2882, $7F34, $7D00 : rep 9 : dw $0000 ; 4 red / X-Ray
  dw $0000, $2717, $28C6, $02DF, $5A73, $41AD, $2D08, $1863, $0BB1, $48FB, $0000, $0000, $7FFF, $44E5, $0000, $0000 ; 5 yellow (WS) / Morph / Speed
  dw $0000, $7C74, $28C6, $15A3, $5EBB, $3DB3, $292E, $1486, $0000, $4A52, $318C, $0000, $7FFF, $294A, $4631, $7FFF ; 6 purple (Crateria) / WJB
  dw $0000, $7FFF, $28C6 : rep 13 : dw $0000   ; 7 white

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
  db $00,$FF,$66,$99,$6C,$93,$18,$E7,$36,$C9,$66,$99,$00,$FF,$00,$00  
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; %
  db $00,$0F,$06,$19,$0C,$33,$18,$26,$18,$64,$30,$CC,$60,$98,$00,$F0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; /

ice_crystal_tile:
    db $3E,$22,$63,$49,$49,$08,$49,$08
    db $49,$08,$63,$49,$3E,$22,$00,$00
    db $1C,$00,$3E,$00,$7F,$08,$7F,$08
    db $7F,$08,$3E,$00,$1C,$00,$00,$00

plasma_crystal_tile:
    db $22,$00,$5D,$1C,$1E,$3E,$3E,$3C
    db $3C,$3C,$5D,$1C,$22,$00,$00,$00
    db $3E,$00,$7F,$1C,$73,$12,$5F,$1C
    db $53,$10,$73,$10,$3E,$00,$00,$00
    
wave_crystal_tile:
    db $22,$00,$4D,$1C,$2E,$3E,$3E,$3E
    db $3E,$2A,$5D,$1C,$22,$00,$00,$00
    db $3E,$00,$73,$00,$7B,$2A,$6B,$2A
    db $7F,$2A,$77,$14,$3E,$00,$00,$00
    
xray_scope_tiles:
    ; Top-left ($89:8980)
    db $00,$00,$00,$01,$00,$02,$01,$03
    db $01,$04,$01,$05,$03,$0A,$01,$09
    db $00,$00,$01,$00,$03,$00,$02,$00
    db $07,$00,$06,$00,$0D,$00,$0E,$00

    ; Top-right ($89:89A0)
    db $00,$00,$00,$80,$00,$40,$80,$C0
    db $80,$20,$C0,$E0,$C0,$50,$80,$90
    db $00,$00,$80,$00,$C0,$00,$40,$00
    db $E0,$00,$20,$00,$B0,$00,$70,$00

morph_tiles:
    ; TL
    db $08,$00,$27,$00,$5F,$03,$3F,$08
    db $BF,$12,$7D,$25,$78,$28,$7D,$25
    db $0F,$0F,$3F,$3F,$7F,$7F,$7C,$7F
    db $F0,$FD,$F2,$FA,$E7,$F7,$E2,$FA
    ; TR
    db $20,$00,$C8,$00,$F4,$80,$F8,$20
    db $FA,$10,$FC,$08,$FC,$88,$FC,$08
    db $E0,$E0,$F8,$F8,$FC,$FC,$7C,$FC
    db $1E,$FE,$1E,$FE,$0E,$7E,$0E,$FE
    ; BL
    db $7F,$22,$7F,$20,$BF,$10,$3F,$08
    db $5F,$03,$27,$00,$08,$00,$00,$00
    db $E0,$FD,$F0,$FF,$F0,$FF,$7C,$7F
    db $7F,$7F,$3F,$3F,$0F,$0F,$00,$00
    ; BR
    db $FC,$08,$FC,$08,$FA,$10,$F8,$20
    db $F4,$80,$C8,$00,$20,$00,$00,$00
    db $0E,$FE,$1E,$FE,$1E,$FE,$7C,$FC
    db $FC,$FC,$F8,$F8,$E0,$E0,$00,$00
speed_tiles:
    ; TL
    db $38,$40,$3F,$FF,$44,$C0,$48,$C0
    db $D1,$40,$E7,$40,$DC,$40,$70,$40
    db $7F,$01,$FF,$00,$FC,$30,$F8,$20
    db $F1,$01,$E7,$07,$DD,$1F,$F7,$3F
    ; TR
    db $1C,$02,$FC,$FF,$1E,$03,$76,$03
    db $CF,$02,$1B,$02,$33,$02,$62,$02
    db $FE,$80,$FF,$00,$1F,$1C,$77,$7C
    db $CF,$FC,$1B,$F8,$33,$F0,$63,$E0
    ; BL
    db $40,$00,$F0,$40,$CC,$40,$C3,$40
    db $40,$C0,$40,$C0,$3F,$FF,$38,$40
    db $CC,$7F,$F0,$3F,$CC,$0F,$C3,$03
    db $C0,$00,$C0,$00,$FF,$00,$7F,$01
    ; BR
    db $42,$02,$63,$02,$33,$02,$1B,$02
    db $CE,$03,$36,$03,$FC,$FF,$1C,$02
    db $43,$C0,$63,$E0,$33,$F0,$1B,$F8
    db $CF,$FC,$37,$3C,$FF,$00,$FE,$80
bluebooster_tiles:
    ; TL
    db $00,$03,$01,$0E,$06,$39,$14,$63
    db $6C,$82,$1C,$63,$06,$19,$01,$06
    db $03,$00,$0F,$00,$3F,$00,$7F,$00
    db $FF,$00,$7F,$00,$1F,$00,$07,$00
    ; TR
    db $70,$80,$50,$84,$30,$88,$60,$10
    db $40,$30,$60,$10,$30,$88,$50,$84
    db $FE,$00,$FE,$04,$FE,$08,$FC,$10
    db $F8,$30,$FC,$10,$FE,$08,$FE,$04
    
;setup_stats:
;    php
;    rep #$20
;    pha
;    lda.w #$0001
;    sta.l !stats_screen_var
;    lda.w #$0000
;    sta.l !stats_palette_upload
;    pla
;    plp
;    jsl $80824f                     ; replaced code
;    rtl 
backup_items:
    lda $09A4
    sta !collected_items
    lda #$1009
    sta $09a6
    jml backup_finished

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
    
     ; entry 4: percent and mini slash -> VRAM word $47F0
    lda.w #64                       ; 2 tiles * 32 bytes
    sta.w $00E5,x
    lda.w #digits_8x8_4bpp+320
    sta.w $00E7,x
    sep #$20
    lda.b #digits_8x8_4bpp>>16
    sta.w $00E9,x
    rep #$20
    lda.w #$47B0
    sta.w $00EA,x

    txa
    clc
    adc.w #$001C                    ; advance pointer past 4 entries (4 * 7)
    sta.w $0330
    
    jsr upload_item_icons           ; add the icons to VRAM
    jsr upload_custom_tiles         ; use icons that have remapped palette indicies where appropriate.
    
    plx
    plp
    rtl
    
upload_item_icons:                  ; 16-bit A/X/Y
    ldy.w $0330
    ldx.w #$0000
.loop:
    lda.w #$0080 : sta.w $00D0,y
    lda.l .table,x : sta.w $00D2,y
    sep #$20
    lda.b #$89 : sta.w $00D4,y
    rep #$20
    lda.l .table+2,x : sta.w $00D5,y
    tya : clc : adc.w #$0007 : tay
    inx #4
    cpx.w #.table_end-.table
    bne .loop
    sty.w $0330
    rts

.table:  ; source, VRAM
    dw $8B00,$5800, $8C00,$5840, $8D00,$5880, $8F00,$58C0, $8E00,$5900
    dw $8700,$5940, $8000,$5980, $8200,$59C0, $9180,$5A00
    dw $8300,$5A40, $8100,$5A80, $8400,$5AC0, $8600,$5B00, $8500,$5B40
    dw $8800,$5B80, $8980,$5BC0, $8A00,$5C00, $9700,$5C40, $9600,$5C80
.table_end:
    
upload_custom_tiles:                ; 16-bit A/X/Y
    ldy.w $0330
    ldx.w #$0000
.loop:
    lda.w #$0020 : sta.w $00D0,y    ; one 4bpp tile
    lda.l .table,x : sta.w $00D2,y  ; source address
    lda.l .table+2,x : sta.w $00D4,y ; source bank (extra byte is overwritten next)
    lda.l .table+3,x : sta.w $00D5,y ; VRAM destination
    tya : clc : adc.w #$0007 : tay
    txa : clc : adc.w #$0005 : tax
    cpx.w #.table_end-.table
    bne .loop
    sty.w $0330
    rts

.table:  ; 24-bit source, VRAM
    dl ice_crystal_tile      : dw $5850
    dl wave_crystal_tile     : dw $5890
    dl plasma_crystal_tile   : dw $5910
    dl xray_scope_tiles      : dw $5BC0  ; top-left
    dl xray_scope_tiles+$20  : dw $5BD0  ; top-right  
    dl morph_tiles           : dw $5940
    dl morph_tiles+$20       : dw $5950
    dl morph_tiles+$40       : dw $5960
    dl morph_tiles+$60       : dw $5970  
    dl speed_tiles           : dw $5C00
    dl speed_tiles+$20       : dw $5C10
    dl speed_tiles+$40       : dw $5C20
    dl speed_tiles+$60       : dw $5C30    
    dl bluebooster_tiles     : dw $5C40
    dl bluebooster_tiles+$20 : dw $5C50
.table_end:

print "Bank $DF free space ends at: $", pc
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
    lda.l !stats_screen_var
    bne .report
    jsr stats_draw_times            ; X still points at screen 1's item list
    bra .queue
.report:
    jsr stats_draw_report
    jsr stats_draw_items
    jsr stats_draw_icons
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
    lda.w #!stats_colon : sta.w $0004,y
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
    lda.w #!stats_colon : sta.w $000A,y
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
    dw $1C89, $1C8A, $1C8B, $1C8C, $1C8D, $1C8E, $1C8F, $1C99, $1C9E, $1C9F ; palette 7
    
blank_word:
    dw $004F                        ; must match BLANK_TILE in Rust

; Draws the mission report times as H:MM:SS.hh (HH from 10 hours)
; Needs DB = $7E. Clobbers A, X, Y
; Same $14 byte frame as stats_draw_times, plus $13 = hundredths
stats_draw_report:
    phd
    tsc : sec : sbc.w #$0014 : tcs : tcd
    stz $11                         ; table offset

.next:
    ldx $11
    lda.l stats_report_table,x      ; SRAM address, 0 = end
    bne .entry
    tsc : clc : adc.w #$0014 : tcs
    pld
    rts

.entry:
    tax
    lda.l $700000,x : sta $01       ; frame count
    lda.l $700002,x : sta $03
    ldx $11
    lda.l stats_report_table+2,x : tay
    inx #4
    stx $11

    jsr stats_frames_to_hundredths
    lda.w #100 : jsr stats_divide : sta $13   ; hundredths
    lda.w #60  : jsr stats_divide : sta $0D   ; seconds
    lda.w #60  : jsr stats_divide : sta $0F   ; minutes, $01 = hours

    ; cap at 99:59:59.99
    lda $03
    bne .cap
    lda $01
    cmp.w #100
    bcc .hours
.cap:
    lda.w #99 : sta $01 : sta $13
    lda.w #59 : sta $0D : sta $0F

.hours:
    lda $01
    cmp.w #10
    bcc .one_digit
    jsr stats_draw_two
    iny #4
    bra .rest
.one_digit:
    asl : tax
    lda.l stats_digits,x : sta.w $0000,y
    iny #2

.rest:
    lda.w #!stats_colon : sta.w $0000,y
    iny #2
    lda $0F : jsr stats_draw_two
    lda.w #!stats_colon : sta.w $0004,y
    tya : clc : adc.w #$0006 : tay
    lda $0D : jsr stats_draw_two
    lda.w #!stats_period : sta.w $0004,y
    tya : clc : adc.w #$0006 : tay
    lda $13 : jsr stats_draw_two
    jmp .next

stats_report_table:
    ;  SRAM time,         buffer address
    dw !stat_final_time,  $3116
    dw !stat_area0_time,  $3188     ; Crateria
    dw !stat_area1_time,  $31C8     ; Brinstar
    dw !stat_area2_time,  $3208     ; Norfair
    dw !stat_area3_time,  $31A8     ; Wrecked Ship
    dw !stat_area4_time,  $31E8     ; Maridia
    dw !stat_area5_time,  $3228     ; Tourian
    dw !stat_pause_time,  $329C
    dw $0000
    
; Needs DB = $7E and 16-bit A/X/Y. Clobbers A, X, Y
stats_draw_items:
    lda.l $8BE71B : tay             ; missiles
    lda.w $09C8 : jsr stats_quotient
    ldy.w #$352E : jsr stats_draw_count

    lda.l $8BE71D : tay             ; supers
    lda.w $09CC : jsr stats_quotient
    ldy.w #$356E : jsr stats_draw_count

    lda.l $8BE71F : tay             ; power bombs
    lda.w $09D0 : jsr stats_quotient
    ldy.w #$35AE : jsr stats_draw_count

    lda.l $8BE717 : tay             ; E tanks, including disabled
    lda.w $09C4 : sec : sbc.w #99 : jsr stats_quotient
    clc : adc.w !num_disabled_etanks
    ldy.w #$35EE : jsr stats_draw_count

    lda.l $8BE719 : tay             ; reserves
    lda.w $09D4 : jsr stats_quotient
    ldy.w #$362E : jsr stats_draw_count

    ; item collection
    ldx.w #$0000
    ldy.w #$0000                    ; Y = items collected
.byte:
    sep #$20
    lda.l !initial_item_bits,x
    eor.b #$FF
    and.l $7ED870,x
.bit:
    beq .next_byte
    lsr
    bcc .bit
    iny
    bra .bit
.next_byte:
    inx
    cpx.w #$0014
    bne .byte
    rep #$20

    tya
    ldy.w #$36AA
    jsr stats_draw_number

    lda.l !nothing_item_total
    bne .fraction
    lda.w #!stats_percent : sta.w $0000,y
    rts
.fraction:
    lda.w #!stats_slash : sta.w $0000,y
    iny #2
    lda.w #100
    sec : sbc.l !nothing_item_total
    jmp stats_draw_number

; A = dividend, Y = divisor (not 0). Out: A = quotient
; Subtraction, because tank divisors can be over 255
stats_quotient:
    phy
    ldx.w #$0000
.loop:
    cmp $01,s
    bcc .done
    sbc $01,s
    inx
    bra .loop
.done:
    ply
    txa
    rts

; right-aligned in two tiles, capped at 99
stats_draw_count:
    cmp.w #100
    bcc .draw
    lda.w #99
.draw:
    jmp stats_draw_lead

; A = 0-100, left-aligned. Out: Y = next tile
stats_draw_number:
    cmp.w #100
    bcc .below
    lda.l stats_digits+2 : sta.w $0000,y
    lda.l stats_digits   : sta.w $0002,y : sta.w $0004,y
    iny #6
    rts
.below:
    cmp.w #10
    bcc .one
    jsr stats_draw_two
    iny #4
    rts
.one:
    asl : tax
    lda.l stats_digits,x : sta.w $0000,y
    iny #2
    rts

stats_draw_icons:                   ; DB = $7E, 16-bit A/X/Y
    ldx.w #$0000
.loop:
    jsr stats_draw_icon
    txa : clc : adc.w #14 : tax
    cpx.w #stats_icon_table_speed_entry-stats_icon_table
    bne .loop

    ; X = Speed Booster entry; Spark Booster is the one after it
    lda.l !settings_flags
    and.w #$0002
    beq .last
    txa : clc : adc.w #14 : tax
.last:
    jmp stats_draw_icon

; X = offset into stats_icon_table. Preserves X, clobbers A and Y
stats_draw_icon:
    lda.l stats_icon_table,x : tay
    lda.w $0000,y
    and.l stats_icon_table+2,x
    beq .done
    lda.l stats_icon_table+4,x : tay
    lda.l stats_icon_table+6,x  : sta.w $0000,y
    lda.l stats_icon_table+8,x  : sta.w $0002,y
    lda.l stats_icon_table+10,x : sta.w $0040,y
    lda.l stats_icon_table+12,x : sta.w $0042,y
.done:
    rts

stats_icon_table:
    ;  flags address,   mask,  buffer, TL,    TR,    BL,    BR
    ; top row
    dw !collected_beams, $1000, $3386, $0180, $0181, $0182, $0183  ; Charge
    dw !collected_beams, $0002, $338C, $0184, $0D85, $0186, $0187  ; Ice
    dw !collected_beams, $0001, $3392, $0188, $0989, $018A, $018B  ; Wave
    dw !collected_beams, $0004, $3398, $018C, $018D, $018E, $018F  ; Spazer
    dw !collected_beams, $0008, $339E, $0190, $0591, $0192, $0193  ; Plasma
    dw !collected_items, $0004, $33A4, $1594, $1595, $1596, $1597  ; Morph
    dw !collected_items, $1000, $33AA, $0198, $0199, $019A, $019B  ; Bombs
    dw !collected_items, $0002, $33B0, $019C, $019D, $019E, $019F  ; Spring Ball
    dw !collected_items, $0400, $33B6, $19A0, $19A1, $19A2, $19A3  ; Wall Jump
    ; bottom row
    dw !collected_items, $0001, $3446, $01A4, $01A5, $01A6, $01A7  ; Varia
    dw !collected_items, $0020, $344C, $01A8, $01A9, $01AA, $01AB  ; Gravity
    dw !collected_items, $0100, $3452, $01AC, $01AD, $01AE, $01AF  ; Hi-Jump
    dw !collected_items, $0200, $3458, $01B0, $01B1, $01B2, $01B3  ; Space Jump
    dw !collected_items, $0008, $345E, $01B4, $01B5, $01B6, $01B7  ; Screw Attack
    dw !collected_items, $4000, $3464, $01B8, $01B9, $01BA, $01BB  ; Grapple
    dw !collected_items, $8000, $346A, $11BC, $11BD, $01BE, $01BF  ; X-Ray
    dw !collected_items, $0040, $3476, $0DC4, $0DC5, $01C6, $01C7  ; Blue Booster
.speed_entry:
    dw !collected_items, $2000, $3470, $15C0, $15C1, $15C2, $15C3  ; Speed Booster
    dw !collected_items, $0080, $3470, $01C8, $01C9, $01CA, $01CB  ; Spark Booster

print "Bank $EA free space ends at: $", pc 
assert pc() <= !bank_ea_free_space_end
