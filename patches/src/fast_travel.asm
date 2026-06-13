;; super-metroid fast-travel
;; nn_357

arch snes.cpu
lorom

;; variable definitions

!warp_destination = $0362 ; vanilla unused upto 036f
!warp_flag = $0364
!warp_table = $B6F660

;; rom space definitions
!bank_b6_freespace_start = $B6F6B4 
!bank_b6_freespace_end = $B6FC00:

!bank_82_freespace_start = $82f404 ;;; $F404: Unused. Pre-instruction ;;;
!bank_82_freespace_end = $82f419

;; vanilla hooks.

org $829122 ; Handle pause menu L/R
  jsr fast_travel_check
  
org $80c43d ; ;;; $C437: Load from load station ;;;
  jml fast_travel_warp_code 
  nop
  nop
  
;; new code.

org !bank_82_freespace_start
fast_travel_check:
  jsr $a505 ; hijacked instruction 
  lda $8b
  cmp #$8000
  bne .skip
  jsl do_fast_travel
.skip
  rts

assert pc() <= !bank_82_freespace_end


org !bank_b6_freespace_start
do_fast_travel:
  lda $1f5b
  sta !warp_destination
  lda #$FFFF
  sta !warp_flag
  stz $0727    ; Reset pause menu index
  stz $0795    ; Reset door transition flags
  stz $0797    ;
  lda #$0000
  sta $7EC400  ; clear palette change numerator, in case of reload during fade-in/fade-out
  stz $05F5    ; enable sounds
  pea $f70d    ; $82f70e = rtl
  jml $82DDC7
  
  
fast_travel_warp_code:  
  lda #$0001
  sta $1e75
  lda !warp_flag
  beq .skip
; X = area * 14
  LDA !warp_destination
  ASL A
  STA $12
  ASL A
  CLC
  ADC $12
  ADC !warp_destination
  ASL A
  TAX

  ; Room pointer
  LDA.l !warp_table+$00,x
  STA $079B

  ; Door pointer
  LDA.l !warp_table+$02,x
  STA $078D

  ; Door BTS
  LDA.l !warp_table+$04,x
  STA $078F

  ; Layer 1 X position
  LDA.l !warp_table+$06,x
  STA $0911
  STA $091D

  ; Layer 1 Y position
  LDA.l !warp_table+$08,x
  STA $0915
  STA $091F

  ; Samus Y = table Y + layer1 Y
  LDA.l !warp_table+$0A,x
  CLC
  ADC $0915
  STA $0AFA
  STA $0B14

  ; Samus X = table X + layer1 X + $80
  LDA $0911
  CLC
  ADC #$0080
  ADC.l !warp_table+$0C,x
  STA $0AF6
  STA $0B10
  stz !warp_flag
  jml $80c49c
.skip
  jml $80c443
  print pc