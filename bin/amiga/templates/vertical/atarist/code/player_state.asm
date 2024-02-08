player_animation_jump_left dc.w PLAYER_TABLE_ENTRY_SIZE,-1
player_animation_jump_right dc.w PLAYER_TABLE_ENTRY_SIZE,-1
player_animation_jump dc.w PLAYER_TABLE_ENTRY_SIZE,-1

player_animation_left	dc.w 0,PLAYER_TABLE_ENTRY_SIZE,PLAYER_TABLE_ENTRY_SIZE*2,-1
player_animation_idle	dc.w PLAYER_TABLE_ENTRY_SIZE*1,-1
player_animation_right	dc.w 0,0,PLAYER_TABLE_ENTRY_SIZE,PLAYER_TABLE_ENTRY_SIZE,PLAYER_TABLE_ENTRY_SIZE*2,PLAYER_TABLE_ENTRY_SIZE*2,-1

player_animation_falling_right	dc.w PLAYER_TABLE_ENTRY_SIZE,-1
player_animation_falling		dc.w PLAYER_TABLE_ENTRY_SIZE,-1
player_animation_falling_left	dc.w PLAYER_TABLE_ENTRY_SIZE,-1

player_animation_down_left	dc.w PLAYER_TABLE_ENTRY_SIZE,-1

player_path_up   	dc.w 8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,-1
player_path_down 	dc.w 1,1,2,2,3,3,4,4,5,5,-1
player_path_pointer dc.w 0

;player_animation_down_right	dc.w PLAYER_TABLE_ENTRY_SIZE,-1
;player_animation_up	dc.w PLAYER_TABLE_ENTRY_SIZE*0,-1

;player_animation_down	dc.w PLAYER_TABLE_ENTRY_SIZE,-1
;player_animation_up_left	dc.w PLAYER_TABLE_ENTRY_SIZE,-1
;player_animation_up_right	dc.w PLAYER_TABLE_ENTRY_SIZE,-1


                          
player_update:			
			  bsr p_checkStates

			  move.l     player_current,a2
			  cmp.w     #PLAYER_BOUNDERY_X0,(a2)
			  bge       .spu_noLeft
			  move.w old_player_pos_x,(a2)
.spu_noLeft:

			  cmp.w     #PLAYER_BOUNDERY_X1,(a2)
			  ble       .spu_noRight
			  move.w old_player_pos_x,(a2)
.spu_noRight:
			  cmp.w     #PLAYER_BOUNDERY_Y0,2(a2)
			  bge       .spu_noUp
			  move.w old_player_pos_y,2(a2)
.spu_noUp:
			  cmp.w     #PLAYER_BOUNDERY_Y1,2(a2)
			  ble       .spu_noDown
			  move.w old_player_pos_y,2(a2)
.spu_noDown
				rts



p_checkStates:
						move.l    player_current,a2
                        move.w    screen_scroll_speed_x,d0                          ; scrolling has always to apply
                        add.w     d0,(a2)
                        move.w    screen_scroll_speed_y,d0
                        add.w     d0,2(a2)

						move.w    (a2),old_player_pos_x                             ; save values before change
                        move.w    2(a2),old_player_pos_y
						
					    move.l    player_animation_current,d0
						lea.l 	  player_animation_idle,a0
						cmp.l     a0,d0
						beq       p_checkStateIdle
						lea.l 	  player_animation_left,a0
						cmp.l     a0,d0
						beq       p_checkStateLeft	
						lea.l 	  player_animation_right,a0
						cmp.l     a0,d0
						beq       p_checkStateRight	
						
						lea.l 	  player_animation_falling,a0
						cmp.l     a0,d0
						beq       p_checkStateFalling	

						lea.l 	  player_animation_falling_right,a0
						cmp.l     a0,d0
						beq       p_checkStateFallingRight	

						lea.l 	  player_animation_falling_left,a0
						cmp.l     a0,d0
						beq       p_checkStateFallingLeft	
						lea.l 	  player_animation_jump,a0
						cmp.l     a0,d0
						beq       p_checkStateJump	

						lea.l 	  player_animation_jump_right,a0
						cmp.l     a0,d0
						beq       p_checkStateJumpRight	

						lea.l 	  player_animation_jump_left,a0
						cmp.l     a0,d0
						beq       p_checkStateJumpLeft	
						;bsr p_transactionIdle
						rts

p_checkStateIdle:			;move.l   player_animation_idle,player_animation_current		; set State
						; check falling
						; check joy
						;move.w #$00700,$ff8240
						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    56(a2),d0
						move.w    54(a2),d1
						bsr collision_checkTilesByDir
						
						tst  d0
						bge  .continue_state
						bsr p_transactionFalling
.continue_state
						lea.l     joystick1_up,a0		; check Jump
                        tst.b     (a0)
                        beq       .check_noJump
						
                        lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq       .check_noJumpLeft
						bsr p_transactionJumpLeft
						bra .check_done
.check_noJumpLeft:			
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       .check_jump
						bsr p_transactionRight
						bra .check_done	
.check_jump:
						bsr p_transactionJump
						bra .check_done

.check_noJump:
                        lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq       .check_noLeft
						bsr p_transactionLeft
						bra .check_done
.check_noLeft:			
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       .check_done
						bsr p_transactionRight
	
.check_done:
						rts


p_transactionLeft:		
						lea.l     player_animation_left,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts


p_transactionRight:		
						lea.l     player_animation_right,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts

p_transactionIdle:		
						lea.l     player_animation_idle,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts

p_transactionFalling:		
						lea.l     player_animation_falling,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts

p_transactionFallingLeft:		
						lea.l     player_animation_falling_left,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts

p_transactionFallingRight:		
						lea.l     player_animation_falling_right,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						rts

p_transactionJump:		
						lea.l     player_animation_jump,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						move.w #0,player_path_pointer
						rts

p_transactionJumpRight:		
						lea.l     player_animation_jump_right,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						move.w #0,player_path_pointer
						rts

p_transactionJumpLeft:		
						lea.l     player_animation_jump_left,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						move.w #0,player_path_pointer
						rts


p_transactionJumpContinue:		
						lea.l     player_animation_jump,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
						
						rts

p_transactionJumpRightContinue:		
						lea.l     player_animation_jump_right,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
					
						rts

p_transactionJumpLeftContinue:		
						lea.l     player_animation_jump_left,a6
						move.l a6,player_animation_current 
						move.w #0,player_animation_counter 
					
						rts


p_checkStateLeft:
						move.l    player_current,a2
						sub.w     #PLAYER_SPEED,(a2)
						bsr p_continueAnimation
						; check coll left
						
						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0
						move.w    54(a2),d1
						addq.w #1,d1 ; correct to avoid permanently falling 
						bsr collision_checkTilesByDir
						
						tst  d0
						bge  .continue_state
						bsr p_transactionFalling
						rts
.continue_state
						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0				; left up
						move.w    54(a2),d1
						sub.w #2,d1 ; correction to avoid permant collision
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll1
						move.w old_player_pos_x,(a2)
						bsr p_transactionIdle
						bra .check_Done
						
												
.no_coll1:

						lea.l     joystick1_up,a0		; check Jump
                        tst.b     (a0)
                        beq       .check_noJump
						
                        lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq       .check_noJumpLeft
						bsr p_transactionJumpLeft
						bra .check_done
.check_noJumpLeft:			
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       .check_jump
						bsr p_transactionJumpRight
						bra .check_done	
.check_jump:
						bsr p_transactionJump
						bra .check_done

.check_noJump:
		
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       .check_left
						bsr p_transactionRight

.check_left
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne       .check_done
						bsr p_transactionIdle
	
.check_done:
						rts

p_checkStateRight:
						move.l    player_current,a2
						add.w     #PLAYER_SPEED,(a2)
						bsr p_continueAnimation
						; check coll left
						moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0 ;w
						move.w    54(a2),d1 ;h
						addq.w #1,d1 ; correct to avoid permanently falling 
						bsr collision_checkTilesByDir
						
						tst  d0
						bge  .continue_state
						bsr p_transactionFalling
						bra .check_done

.continue_state
						
						moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0				; right up
						move.w    54(a2),d1
						sub.w #2,d1 ; correction to avoid permant collision
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll1
						move.w old_player_pos_x,(a2)
						bsr p_transactionIdle
						bra .check_Done
.no_coll1:

						lea.l     joystick1_up,a0		; check Jump
                        tst.b     (a0)
                        beq       .check_noJump
						
                        lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq       .check_noJumpLeft
						bsr p_transactionJumpLeft
						bra .check_done
.check_noJumpLeft:			
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       .check_jump
						bsr p_transactionJumpRight
						bra .check_done	
.check_jump:
						bsr p_transactionJump
						bra .check_done

.check_noJump:
                        lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq       .check_right
						bsr p_transactionLeft
.check_right
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       .check_done
						bsr p_transactionIdle
.check_done:
						rts


GRAVITY = 4
p_checkStateFalling:
						;move.w #$0070,$ff8240
						move.l    player_current,a2
						add.w     #GRAVITY,2(a2)	

						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0	; x
						move.w    54(a2),d1	; h
						bsr collision_checkTilesByDir
						
						tst  d0
						blt  .no_coll0
						
						sub.w d0,2(a2)		; correction for collision with ground
						bra p_transactionIdle

.no_coll0:				moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0	;w
						move.w    54(a2),d1	;h
						bsr collision_checkTilesByDir
						
						tst  d0
						blt  .continue_state
						
						moveq #0,d0				; only right col -> only falling?
						moveq #0,d1
						move.w    52(a2),d0	;w
						sub.w     #PLAYER_SPEED,d0
						move.w    54(a2),d1	;h
						bsr collision_checkTilesByDir
						tst  d0
						blt  .noCollGround	; no coll
						
						bra p_transactionIdle ; coll -> idle
.noCollGround:
						;move.w #$0070,$ff8240
						bra p_transactionFalling 

.continue_state
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne        p_transactionFallingLeft
						
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       p_transactionFallingRight						
.checkDone:
						rts

p_checkStateFallingRight:
						;move.w #$0070,$ff8240
						move.l    player_current,a2
						add.w     #GRAVITY,2(a2)	
						add.w     #PLAYER_SPEED,(a2)

						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0 ;w
						move.w    54(a2),d1 ;h
						bsr collision_checkTilesByDir
						
						tst  d0
						blt  .continue_state   ; still falling right
						
						; is coll 
						move.w    52(a2),d0 ;w
						move.w    54(a2),d1 ;h
						sub.w 	  #PLAYER_SPEED,d1   ; old x pos	
						bsr collision_checkTilesByDir	

						tst  d0
						blt  .continue_falling	; coll but falling is ok					
						
						move.w old_player_pos_x,(a2)
						sub.w d0,2(a2)		; correction for collision with ground
						bsr p_transactionIdle
						;move.w #$0700,$ff8240
						bra .checkDone
						
.continue_falling:
						move.w old_player_pos_x,(a2) ; correct x
						bsr p_transactionFalling
						bra .checkDone
						
						;swap d0
						;sub.w d0,(a2)		; correction for collision with right 
.continue_state
						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0 ; x
						move.w    54(a2),d1 ; h
						bsr collision_checkTilesByDir
						tst  d0
						blt  .no_coll
						sub.w d0,2(a2)		; correction for collision with ground
						bsr p_transactionIdle
						
						bra .checkDone
.no_coll:						
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne        p_transactionFallingLeft
						
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       p_transactionFallingRight
						bsr p_transactionFalling
.checkDone:
						rts


p_checkStateFallingLeft:
						;move.w #$0070,$ff8240
						move.l    player_current,a2
						add.w     #GRAVITY,2(a2)	
						add.w     #-PLAYER_SPEED,(a2)

						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0
						move.w    54(a2),d1
						bsr collision_checkTilesByDir
						
						tst  d0
						blt  .continue_state
						move.w old_player_pos_x,(a2)
						bra p_transactionFalling
						
.continue_state
						
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne        p_transactionFallingLeft
						
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       p_transactionFallingRight
						bsr p_transactionFalling
.checkDone:
						rts


p_continueAnimation:
						move.l 	  player_animation_current,a0
						lea       player_animation_counter,a1
						moveq  #0,d1
						move.w (a1),d1
						adda.l d1,a0
						move.w (a0),player_animation_offset
						
						add.w  #2,(a1)

						cmp.w  #-1,2(a0)
						bne.s .skip
						move.w #0,player_animation_counter
.skip:
						rts



p_checkStateJump:
						;move.w #$0070,$ff8240
						move.l    player_current,a2

						lea player_path_up,a3
						moveq #0,d0
						move.w player_path_pointer,d0
						adda.l d0,a3
						move.w (a3),d0
						sub.w     d0,2(a2)	
						add.w #2,player_path_pointer

						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0				; left up
						move.w    50(a2),d1
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll0
						bsr p_transactionFalling
						bra .checkDone
.no_coll0:
						moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0				; right up
						move.w    50(a2),d1
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll1
						bsr p_transactionFalling
						bra .checkDone
.no_coll1:
						cmp.w  #-1,2(a3)
						bne.s 	.continue_state
						bsr p_transactionFalling
						bra .checkDone
.continue_state
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne        p_transactionJumpLeftContinue
						
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       p_transactionJumpRightContinue						
.checkDone:
						rts


p_checkStateJumpRight:
						;move.w #$0070,$ff8240
						move.l    player_current,a2
						lea player_path_up,a3
						moveq #0,d0
						move.w player_path_pointer,d0
						adda.l d0,a3
						move.w (a3),d0
						sub.w     d0,2(a2)	
						add.w #2,player_path_pointer
						add.w #PLAYER_SPEED,(a2)

						bsr p_continueAnimation

						moveq #0,d0
						moveq #0,d1
						move.w    52(a2),d0				; right up
						move.w    50(a2),d1
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll1
						bsr p_transactionFalling
						bra .checkDone

.no_coll1:
						cmp.w  #-1,2(a3)
						bne.s 	.continue_state
						bsr p_transactionFalling
						bra .checkDone


.continue_state
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        bne        p_transactionJumpLeftContinue
						
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        beq       p_transactionJumpContinue						
.checkDone:
						rts



p_checkStateJumpLeft:
						;move.w #$0070,$ff8240
						move.l    player_current,a2
						lea player_path_up,a3
						moveq #0,d0
						move.w player_path_pointer,d0
						adda.l d0,a3
						move.w (a3),d0
						sub.w     d0,2(a2)	
						add.w #2,player_path_pointer
						sub.w #PLAYER_SPEED,(a2)

						moveq #0,d0
						moveq #0,d1
						move.w    48(a2),d0				; left up
						move.w    50(a2),d1
						bsr collision_checkTilesByDir
						tst d0
						blt .no_coll1
						bsr p_transactionFalling
						bra .checkDone

.no_coll1
						bsr p_continueAnimation

						cmp.w  #-1,2(a3)
						bne.s 	.checkDone
						bsr p_transactionFalling
						bra .checkDone
.continue_state
						lea.l     joystick1_right,a0
                        tst.b     (a0)
                        bne       p_transactionJumpRightContinue	
						lea.l     joystick1_left,a0
                        tst.b     (a0)
                        beq        p_transactionJumpContinue					
.checkDone:
						rts


