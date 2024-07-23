pots  dc.l      0
      dc.l      0
      dc.w      0

      dc.l      0
      dc.l      0
      dc.w      0
      dc.l      -1

POT_ENTRY_SIZE = 4+4+2

; a0 = pointer to pot
pot_addPot:
      lea.l     pots,a6

      cmp.l     #0,(a6)
      bne.s     .next
.add:
      move.l    a0,(a6)                          ; set pointer
      move.l    58(a0),4(a6)                     ; set idle animation
      move.w    #0,8(a6)                         ;clear animation offset
      rts
.next:
      adda.l    #POT_ENTRY_SIZE,a6
      cmp.l     #-1,(a6)
      beq       .done
      cmp.l     #0,(a6)
      beq.s     .add
      bra.s     .next
.done
      rts



pot_update:  
      lea.l     pots,a6
.loop:
      cmp.l     #-1,(a6)
      beq       .allDone
      cmp.l     #0,(a6)
      beq       .next

      add.w     #2,8(a6)                         ; pot_animation_offset
      moveq     #0,d0
      move.w    8(a6),d0

      move.l    4(a6),a0
      adda.l    d0,a0
      cmp.w     #-1,(a0)
      bne.s     .done
      move.w    #0,8(a6)

.done:

      lea.l     joystick1_button_automatic,a0    ; shoot?
      cmp.w     #1,(a0)
      bne       .shoot_done

      move.l    (a6),a2
      move.l    player_current,a3
      move.l    62(a2),a1                        ; set fire animation
      move.l    4(a6),d0                         ;  compare with current animation pointer
      cmp.l     a1,d0
      beq.s     .skipOffsetReset
      move.w    0,8(a6)
.skipOffsetReset: 
      move.l    a1,4(a6)                         ; update animation pointer 

      add.w     #1,34(a2)
      move.w    34(a2),d0
					
      cmp.w     32(a2),d0                        ; firerate check
      bne       .bullet_done                     ; no shoot this time
      move.w    #0,34(a2)					
      moveq     #0,d5                            ; set bullet type
      move.l    28(a2),a4  
  				
.bullet_loop:
      move.w    (a3),d3                          ;x pos of enemy as start x
      add.w     virtualscreen_xPosition,d3
      add.w     (a2),d3
                        
      move.w    2(a3),d4                         ;y pos of enemy as start y                          
      add.w     virtualscreen_yPosition,d4
      add.w     2(a2),d4

      move.l    (a4)+,a2                         ; pointer to first bullet
					
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
					
      jsr       bullet_create
      tst.l     (a4)                             ; has this enemy more bullets?
      beq       .bullet_done                     ; done
      move.l    (a6),a2                          ; restore pot pointer
      bra       .bullet_loop
.bullet_done:
      ;rts
      bra.s     .next

.shoot_done:
      move.l    (a6),a1
      move.l    58(a1),a1
      move.l    4(a6),d0
      cmp.l     a1,d0
      beq.s     .skipOffset
      move.w    0,8(a6)
.skipOffset: 
      move.l    a1,4(a6) 

.next:
      adda.l    #POT_ENTRY_SIZE,a6
      bra       .loop
.allDone
      rts


pot_draw:
      move.l    player_current,a4
      lea.l     pots,a6
      moveq     #-2,d4
.loop:
      cmp.l     #-1,(a6)
      beq       .done
      cmp.l     #0,(a6)
      beq.s     .next

      moveq     #0,d0
      move.l    (a6),a0

      move.w    2(a4),d0
      add.w     2(a0),d0
      add.w     #44,d0
      move.l    d4,a0                            ; pot 
      ;sub.w     virtualscreen_yPosition,d0
                ;a0 pointer to object
                ;d0 y-sort value
      jsr       sprite_addPointer

.next: 
      adda.l    #POT_ENTRY_SIZE,a6
      moveq     #-3,d4
      bra       .loop
.done:
      rts

pot_draw_old:
	;get player position 
      lea.l     pots,a6
      move.l    player_current,a4
      lea.l     copper_sprite_setup+32,a3

.loop:
      cmp.l     #-1,(a6)
      beq       .done
      cmp.l     #0,(a6)
      beq.s     .next
      move.l    (a6),a0 
      moveq     #0,d4                                             
      move.w    (a4),d4                          ; load x pos
      add.w     (a0),d4                          ; add  x offset

      lsr.w     #1,d4                            ; amiga correction
      add.w     #57+8,d4
   
      moveq     #0,d5
      move.w    2(a4),d5                         ; load y pos

      add.w     2(a0),d5                         ;add       y offset

      add.w     #44,d5                           ; amiga correct y?

      move.w    d5,d6
      add.w     6(a0),d6                         ; add pot height
	
	
	;set sprite:
    
      moveq     #0,d2
      move.l    4(a6),a2                         ; animation pointer
      move.w    8(a6),d2                         ; animation offset
      adda.l    d2,a2
      move.w    (a2),d2
                       
     
      move.l    8(a0),a1                         ; load image pointer
    
      add.l     d2,a1	
      move.b    d4,1(a1)                         ; set x pos
      move.b    d5,(a1)                          ; set y pos
      move.b    d6,2(a1)                         ; set y pos + height
	
             ; set pointer in copper list (a3)       
      move.l    a1,d1                            ; move sprite address into d1
      move.w    d1,6(a3)                         ; transfer sprite address high to copper
      swap      d1                               ; swap
      move.w    d1,2(a3)                         ; transfer sprite address low to copper
      adda.l    #8,a3                            ; next pointer

      move.l    8(a0),a1 
      add.w     66(a0),a1                        ;add pot size

      add.l     d2,a1
      move.b    d4,1(a1)                         ; set x pos
      move.b    d5,(a1)                          ; set y pos
      move.b    d6,2(a1)                         ; set y pos + height
      move.l    a1,d1                            ; move sprite address into d1
      move.w    d1,6(a3)                         ; transfer sprite address high to copper
      swap      d1                               ; swap
      move.w    d1,2(a3)                         ; transfer sprite address low to copper
      adda.l    #8,a3                            ; next pointer
.next:
      adda.l    #POT_ENTRY_SIZE,a6
      bra       .loop
.done:
      rts

