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
	  
      ;add.w     #2,8(a6)                         ; pot_animation_offset
      moveq     #0,d0
      move.w    8(a6),d0

      move.l    4(a6),a0
      adda.l    d0,a0
      cmp.w     #-1,(a0)
      bne.s     .done
      move.w    #0,8(a6)

.done:

      lea.l     joystick1_button,a0    ; shoot?
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
      rts
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
	;get player position 
      lea.l     pots,a6
      move.l    player_current,a4


.loop:
      cmp.l     #-1,(a6)
      beq       .done
      cmp.l     #0,(a6)
      beq.s     .next
      move.l    (a6),a5

	  moveq     #0,d0
	  move.l 8(a5),a0		;  pointer to sprite
	  
	  move.l 4(a6),a3		; load animation  pointer
	  move.w 8(a6),d0		; add animation offset
	  add.l  d0,a3
	  move.w (a3),d0
	  
	  adda.l d0,a0	  
   
	  
	  moveq #0,d1
	  moveq #0,d2
	  moveq #0,d3
	  moveq #0,d6	
	  
      move.w    (a4),d0                          ; load x pos
      add.w     (a5),d0                          ; add  x offset
  
      move.w    2(a4),d1                         ; load y pos
      add.w     2(a5),d1                         ;add       y offset

	  move.w    14(a5),d2
      move.w    12(a5),d3                         ; set pot height-1
	  move.w 	26(a5),d6
	
	  ;move.w #$0070,$ff8240

	 
		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=chunk(2*4)*2(width in words) 

	jsr screen_drawObject
.next:
      adda.l    #POT_ENTRY_SIZE,a6
      bra       .loop
.done:
      rts

	  
	  
