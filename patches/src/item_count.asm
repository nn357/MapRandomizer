; Modify plms to increase a new collected items variable upon item collection.
; address is automatically saved / loaded to the save file
;
; overwrites unused routine $848821 set the boss bits [[Y]]
;
; $09ee contains number of collected items.
;
; credits % is displayed as a fraction if every item isn't placed.
; nn_357 / StagShot

; !escape_seed = $dfff04        ; overwritten in patch.rs
!starting_items_count = $dfff10 ; overwritten in patch.rs, also referenced in new_game.asm
!unplaced_total = $dfff0e       ; overwritten by patch.rs, contains the sum of 'nothing'
!item_count = $09ee

org !unplaced_total
  dw $0000
  
; org !escape_seed
  ; db $00

org $848821 ;;; $8821: Unused. Instruction - set the boss bits [[Y]] ;;; New routine - Update sum of items collected. preserves [A] unnecessary?
item_count:
  pha
  lda !item_count
  inc
  sta !item_count
  iny
  iny
  pla
  rts
assert pc() <= $84882D

;; $88B0: Instruction - pick up beam [[Y]] and display message box [[Y] + 2] ;;;
org $8488F0
  jmp item_count
assert pc() <= $8488f3

;;; $88F3: Instruction - pick up equipment [[Y]] and display message box [[Y] + 2] ;;;
org $848917
  jmp item_count
assert pc() <= $84891a

;;; $891A: Instruction - pick up equipment [[Y]], add grapple to HUD and display grapple message box ;;;
org $84893e
  jmp item_count
assert pc() <= $848941

;;; $8941: Instruction - pick up equipment [[Y]], add x-ray to HUD and display x-ray message box ;;;
org $848965
  jmp item_count
assert pc() <= $848968

;;; $8968: Instruction - collect [[Y]] health energy tank ;;;
org $848983
  jmp item_count
assert pc() <= $848986


;;; $8986: Instruction - collect [[Y]] health reserve tank ;;;
org $8489a6
  jmp item_count
assert pc() <= $8489a9

;;; $89A9: Instruction - collect [[Y]] ammo missile tank ;;;
org $8489cf
  jmp item_count
assert pc() <= $8489d2

;;; $89D2: Instruction - collect [[Y]] ammo super missile tank ;;;
org $8489f8
  jmp item_count
assert pc() <= $8489fb

;;; $89FB: Instruction - collect [[Y]] ammo power bomb tank ;;;
org $848a21
  jmp item_count
assert pc() <= $848a24

;;; $E627: Instruction - draw item percentage count ;;;

org $8be627
  php
  phb
  phk
  plb
  rep #$30
  phx
  phy
  lda !unplaced_total         ; everything placed?
  beq .check_100
  cmp !starting_items_count   ; nothing count = same as starting items? (seed has starting items / escape seed)
  beq .check_100

  bra .fractional             ; seed has more nothings than starting items (desolate / small map / stop item placement)

.check_100:
  lda !item_count
  cmp #$0064
  bne .not_100
.is_100  
  lda $e745                    ; 100% completion
  sta $7e339c
  lda $e747
  sta $7e33dc
  lda $e741
  sta $7e339e
  lda $e743
  sta $7e33de
  lda $e741
  sta $7e33a0
  lda $e743
  sta $7e33e0
  bra .percent_symbol

.not_100
  ldx #$0002
  jsr .digit2
  bra .percent_symbol

.fractional
  jsl load_fractional_tiles   ; transfer custom '/' tile to VRAM
  lda #$0064
  sec
  sbc !unplaced_total
  beq .is_100                  ; if you set enough starting items / higher difficulty nothing will be placed, this can result in a xx/00, in which case just display 100%.
  sta $14                

  lda !item_count        
  ldx #$0000
  jsr .digit2

  lda $14                 
  ldx #$0006
  jsr .digit2

  lda #$3888                  ; add custom '/' tile to tilemap
  sta $7e33a0             
  lda #$3898
  sta $7e33e0
  bra .finished

.percent_symbol
  lda #$386a
  sta $7e33a2
  lda #$387a
  sta $7e33e2
.finished
  ply
  plx
  plb
  plp
  rts

.digit2
  sta $4204
  sep #$20
  lda #$0A
  sta $4206
  nop #6
  rep #$20
  lda $4214
  asl a
  asl a
  tay
  lda $e741,y
  sta $7e339c,x
  lda $e743,y
  sta $7e33dc,x
  lda $4216
  asl a
  asl a
  tay
  lda $e741,y
  sta $7e339e,x
  lda $e743,y
  sta $7e33de,x
  rts

assert pc() <= $8be741      ; Tilemap values for decimal digits:

;8BE6ED

org $dfe212

load_fractional_tiles:

    php
    sep #$30
WaitVB:
    lda $4212
    and #$80
    beq WaitVB

    lda #$80                ; top_slash → $4880
    sta $2115
    lda #$80
    sta $2116
    lda #$48
    sta $2117

    lda #$01
    sta $4300
    lda #$18
    sta $4301
    lda.b #top_slash
    sta $4302
    lda.b #top_slash>>8
    sta $4303
    lda #$DF
    sta $4304
    lda #$20
    sta $4305
    stz $4306
    lda #$01
    sta $420B

    lda #$80                  ; bottom_slash → $4980
    sta $2116
    lda #$49
    sta $2117

    lda.b #bottom_slash
    sta $4302
    lda.b #bottom_slash>>8
    sta $4303
    lda #$20
    sta $4305
    stz $4306
    lda #$01
    sta $420B
    
    plp
    rtl

top_slash:
  db $00, $07, $02, $0D, $06, $09, $06, $09 
  db $0C, $13, $0C, $32, $18, $26, $18, $24
  db $00, $00, $00, $00, $00, $00, $00, $00
  db $00, $00, $00, $00, $00, $00, $00, $00

; db $00,$00,$00,$00,$00,$00,$00,$00
; db $00,$0F,$06,$19,$0C,$33,$18,$26
; db $00,$00,$00,$00,$00,$00,$00,$00
; db $00,$00,$00,$00,$00,$00,$00,$00
     
bottom_slash:
  db $18, $64, $30, $4C, $30, $C8, $60, $98 
  db $60, $90, $40, $B0, $00, $E0, $00, $00
  db $00, $00, $00, $00, $00, $00, $00, $00
  db $00, $00, $00, $00, $00, $00, $00, $00

; db $18,$64,$30,$CC,$60,$98,$00,$F0
; db $00,$00,$00,$00,$00,$00,$00,$00
; db $00,$00,$00,$00,$00,$00,$00,$00
; db $00,$00,$00,$00,$00,$00,$00,$00

assert pc() <= $dfe2b4