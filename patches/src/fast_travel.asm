;; fast travel between map stations
;; nn_357

arch snes.cpu
lorom

!bank_82_free_space_start = $82BE5A
!bank_82_free_space_end = $82BF03

!bank_83_free_space_start = $83ba00
!bank_83_free_space_end = $83baff

!bank_df_free_space_start = $dfe3c2
!bank_df_free_space_end = $dffef0

!bank_84_free_space_start = $84F690
!bank_84_free_space_end = $84F6AF

!canwarp = $1f5d
!warp_pending = $1f5f 
!warp_area = $1f4b
!warp_busy = $1f4d 
!backup_area = $1F62

;;; Vanilla hooks

org $82DFA8             ; save map explored if elevator
    jsr save_flag_hook
    nop

org $82DFB9             ; load map explored if elevator
    jsr load_flag_hook
    nop
    
org $82dfcc
    jsl hook_inanimate_samus
    
org $8293B8             
    jmp warp_or_unpause

org $82943A
    jmp warp_text_hook_spring

org $848caa
    jmp map_activation_hook
    nop 
    nop
    
org $8290F2
    jsl warp_button_long   
    
org $829377 ;;;; Restore BG2 tilemap from pause menu
    rep #$30
    jsr clear_warp_flag
    
org $84B1A6
  nop #2

;; Custom Code

org !bank_82_free_space_start

warp_text_hook_spring:
    jml warp_text_hook
    
clear_warp_flag:
    stz !canwarp
    rts
    
warp_or_unpause:
    stz $0725
    lda !warp_pending
    beq .unpause

    ; Check if warp pointer is valid 
    lda !warp_area         ; Displayed map area
    asl
    tax
    lda.l warp_table,x     ; Door pointer from warp table
    beq .unpause           ; 0 = no warp, standard unpause

    ; --- WARP PATH ---
    stz !warp_pending
    stz !canwarp
    stz !warp_area
    sta $078d              ; Set door pointer
    tax
    lda.l $830003,x        ; direction byte of the door record
    and.w #$00FF
    cmp.w #$0005
    bne .type04
    lda.w #$0013           
    sta $0AF6
    lda.w #$008B
    sta $0AFA
    bra .placed
.type04:
    lda.w #$00EC           
    sta $0AF6
    lda.w #$008B
    sta $0AFA
.placed:
    lda.w #$0001
    sta !warp_busy
    lda.w #$E17D
    sta $099C
    lda.w #$0009
    sta $0998
    jmp $93c1
.unpause
    jmp $93BB
    
warp_button_hook:
jsl warp_button_long
rts
    
save_flag_hook:
    lda.l $830002,x
    pha
    lda !warp_busy
    beq .no
    pla
    ora.w #$0040
    rts
.no:
    pla
    rts

load_flag_hook:
    lda.l $830002,x
    pha
    lda !warp_busy
    beq .no
    stz !warp_busy      ; load is the last use, so clear it here
    lda $1f5b
    sta !backup_area    ; update backup_area 
    lda #$EB52             ; Samus drawing handler = default
    sta $0a5c
    pla
    ora.w #$0040
    rts
.no:
    pla
    rts
    
assert pc() <= !bank_82_free_space_end

org !bank_84_free_space_start
map_activation_hook:
    lda $1f5b
    sta !backup_area
    lda #$ffff
    sta !canwarp
    ply
    plx
    rts
assert pc() <= !bank_84_free_space_end



org !bank_df_free_space_start

warp_text_hook:
    pha
    phx
    phy
    ldx !canwarp
    beq .hide
    ldx $1F5B
    cpx !backup_area
    beq .hide
    lda.l $7ED908,x
    beq .hide
    ldx.w #$0000
    bra .draw
.hide:
    ldx.w #no_warp_tiles-warp_text_tiles
.draw:
    lda.b #$80
    sta $2115
    rep #$20
    lda.w #$38B7
    sta $2116
    ldy.w #$0008
.run:
    lda.l warp_text_tiles,x
    sta $2118
    inx
    inx
    dey
    bne .run
    lda.w #$389D
    sta $2116
    sep #$20
    ply
    plx
    pla
    plb
    plp
    rtl

warp_text_tiles:
    dw $300F,$30D6,$30C0,$30D1,$30CF,$300F,$30C1,$300F
no_warp_tiles:
    dw $3031,$3031,$3031,$3031,$3031,$3031,$3031,$3031
    
warp_button_long:           ; called from $A51E; PHP already on the stack
    php
    rep #$30
    pha
    lda $0727
    cmp.w #$0003                 ; map2equip_load_equip
    beq .clear
    cmp.w #$000D                 ; map2obj_load_obj
    bne .no_clear
.clear:
    jsr warp_text_clear          ; blank the WARP tiles (forced blank here)
.no_clear:
    pla
    plp
    jsl $8290ff             ; run the original main pause routine first
    php
    rep #$30
    lda $05e1
    bit.w #$8000            ; B newly pressed
    beq .done
    lda $0727               ; menu index 0 = map screen
    bne .done
    lda !canwarp            ; opened via map station
    beq .done
    ldx $1f5b
    cpx !backup_area        ; displayed area != current area
    beq .done
    lda.l $7ed908,x         ; displayed area's map collected
    and.w #$00ff
    beq .done
    txa
    asl
    tax
    lda.l warp_table,x         ; warp table entry, 0 = no warp
    beq .done
    lda $1f5b
    sta !warp_area
    lda.w #$0001
    sta !warp_pending
    lda #$ebf2             ; Samus drawing handler = RTS
    sta $0a5c
    lda.w #$0038            ; same select sound as start
    jsl $809049
    lda.w #$0001            ; same fade-out setup as start
    sta $0723
    sta $0725
    inc $0998               ; game state 10h
.done:
    plp
    rtl

warp_text_clear:
    php
    sep #$20
    lda.b #$80
    sta $2115                   ; same increment mode as the hook
    rep #$20
    lda.w #$38B7
    sta $2116                   ; same VRAM address as .draw
    lda.w #$3031                ; blank tile from no_warp_tiles
    sta $2118
    sta $2118
    sta $2118
    sta $2118
    sta $2118
    sta $2118
    sta $2118
    sta $2118                   ; 8 words, matching ldy #$0008
    plp
    rts

unpause_samus_hook:
    lda !warp_pending
    beq .skip
    jml $82a312
.skip
    lda #$000c
    jml $82a30e


hook_inanimate_samus:        ; replaces the JSL at $82:DFCC (same 4 bytes)
    lda !warp_busy
    bne .skip
    jml $908a00              ; vanilla RTL returns to the RTS at $DFD0
.skip:
    rtl
    
assert pc() <= !bank_df_free_space_end

; Pause menu tiles routine DMA transfer size bug fix.
; Vanilla code transfers too many bytes, destroying the BG2 tilemap.
; Correcting the DMA transfer size means the backup/restore BG2 pause hook isn't needed.
; Which also frees up the 4k block of ram used for the backup / restore.
; nn_357

;org $828ed2 ; Correct DMA transfer size $1000, [hud_expansion_opaque already fixes this, included for reference].
;  db $10

org $828d08 ; Back up BG2 tilemap for pause menu
  bra +
  nop
+                                                                   

;org $829377 ; Restore BG2 tilemap from pause menu
;  bra +
;  nop
;+

;;; warp pointer table

org !bank_83_free_space_start ;; (ba00)

warp_table:
    dw $0000,$0000,$0000,$0000,$0000,$0000
assert pc() <= !bank_83_free_space_end