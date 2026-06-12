;; fast-travel
;; nn_357

arch snes.cpu
lorom

!warp_table = $B6F660
!bank_b6_freespace_start = $B6F6B4 
!bank_b6_freespace_end = $B6FC00:

;; vanilla hooks.

org $829128 ; $82:9128 22 34 B9 82 JSL $82B934[$82:B934]  ; Handle map scroll arrows
  jsl fast_travel_check


org !bank_b6_freespace_start
fast_travel_check:
  jsl $82b934 ; Handle map scroll arrows [hijacked instruction]
  lda $8b    ; load newly pressed input // DOESNT WORK?
  cmp #$0001  ; B button pressed?
  bne .skip

  jsl $82be17 ; stop sounds
  jsr do_fast_travel
.skip
  rtl
  
do_fast_travel:

; idea
; if currently area has map station collected
; set game flag "warping"
; call unpause
; hook in maingameplay checks for warping and calls a room reload but with values in table at f660
 