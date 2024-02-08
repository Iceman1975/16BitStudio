GAME_CLICK_DELAY = 50                                                                          ; (2s)
game_block_interaction_time  dc.w       GAME_CLICK_DELAY    


game_showStartScreen:

  lea  StartScreen_image,a0
  
  jsr game_loadScreen
  jsr StartScreen_color
  
  lea StartScreen,a1
  bra ss_init


game_showGameOverScreen:
  lea  GameOver_image,a0
  
  jsr game_loadScreen
  jsr GameOver_color
  lea GameOver,a1
  bra ss_init

game_showFinalScreen:
  lea  FinalScreen_image,a0
  
  jsr game_loadScreen
  jsr FinalScreen_color
  lea FinalScreen,a1
  bra ss_init
  
  
ss_init:
  move.w     #GAME_CLICK_DELAY,game_block_interaction_time
  cmp.l     #0,10(a1)
  beq       ss_loop
  move.l    10(a1),soundEventPrio0                ; set sound (TODO: prio offset)
ss_loop:  
  jsr        sound_prepare
  jsr        screen_waitVBlank
  jsr 		 sound_update
  jsr        screen_swap
  		
  jsr        screen_restore
  jsr        joystick_update
  
  lea        game_block_interaction_time,a0 
  sub.w      #1,(a0)
  tst.w      (a0)
  bgt.s      ss_loop
  
  lea.l     joystick1_down,a0
  tst.b     (a0)
  ;lea.l     joystick1_button,a0               ; button?
  ;cmp.w     #1,(a0)
  bne       static_done
  
  bra ss_loop
static_done:  
  jsr sound_stop
  rts
  
  
  
 
game_reset:
	move.w #(screenBuffer_height*4*(screenBuffer_width/8)-((screenBuffer_width*4)/8)),screenBuffer_linePointerOffset
	move.w #(screenBuffer_height-1),screenBuffer_linePointerYPos 
	
	move.w #PLAYER_LIVES_INITAL,player_lives
	move.w #PLAYER_ENERGY_INITAL,player_energy
	move.w #0,player_score
	; player_current      dc.l player0
	
	move.w #GAME_STATE_RUNNING,game_state
	
	lea.l enemy_list0,a0
	move.l a0,enemy_list_pointer
	
	jsr enemies_reset
	jsr bullet_reset
	jsr explosions_reset
	
	lea levelmap,a0	
	move.l     (a0),levelpointer
	move.w 4(a0),virtualscreen_yPosition
	move.l     14(a0),levelMetapointer
	rts
	
game_respawn:
	jsr enemies_reset
	jsr bullet_reset
	jsr explosions_reset
	move.w #GAME_STATE_RUNNING,game_state
	move.w #PLAYER_ENERGY_INITAL,player_energy
	
	rts
	
	
game_checkGameState:
							 ifd LEVEL_END_BY_SCROLLING
                             lea        virtualscreen_yPosition,a0
                             tst.w      (a0)
                             bne        .gc_done
                             bsr        game_nextLevel
							 endif
.gc_done:

                             bsr        game_isDying
  
                             move.w     game_state,d0
                             cmp.w      #GAME_STATE_OVER,d0
                             bne        g_0
  

                             jsr        game_reset
                             jsr        game_showGameOverScreen                                  ; game over  
                             bra        g_doInit
  
g_0:
                             move.w     game_state,d0                                            ; respawn
                             cmp.w      #GAME_STATE_RESPAWN,d0
                             bne        g_1
                             jsr        game_respawn
                             bra        g_done
  
g_1:
                             move.w     game_state,d0                                            ; final
                             cmp.w      #GAME_STATE_DONE,d0  
                             bne        g_done
                             jsr        game_showFinalScreen	 
                             jsr        game_reset
                             bra        g_doInit

g_done: 
                             rts
                             
g_doInit:                    moveq      #-1,d0  
                             rts
							 
							 
game_nextLevel:
	jsr enemies_reset
	jsr bullet_reset
	jsr explosions_reset
	
	moveq #0,d0							; get current level pointer
	add.w #1,levelNo
	move.w levelNo,d0
	mulu   #LEVEL_MAP_ENTRY_SIZE,d0
	
	lea levelmap,a0	
	adda.l d0,a0
	
	move.l (a0),d1
	cmp.l  #-1,d1
	bne   g_setLevel
	; no more levels -> game done
	move.w #GAME_STATE_DONE,game_state
	rts
	
g_setLevel:	
	move.l (a0),levelpointer
	move.l 14(a0),levelMetapointer
	move.w 4(a0),virtualscreen_yPosition
	rts
  
game_isDying:
	move.w  game_state,d0
	cmp.w   #GAME_STATE_DYING,d0
	bne g_notDying
	
	
	sub.w #1,game_dying_counter
	move.w game_dying_counter,d0
	tst.w d0
	bne g_notDying
	
	move.w #GAME_DYING_INIT,game_dying_counter	; reinit

	sub.w #1,player_lives
	move.w player_lives,d0
	tst.w d0
	bne g_notDead
	move.w #GAME_STATE_OVER,game_state
	rts
	
g_notDead	
    move.w #GAME_STATE_RESPAWN,game_state
	
g_notDying:	
	rts
  
game_loadScreen:		
		lea  screen_REPAIR,a1		
		move.l #199,d0
		
game_copy:
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(A1),A1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d4
		movem.l d1-d4,(a1)
		lea 16(a1),a1

		dbra d0,game_copy		
		rts