GAME_CLICK_DELAY = 2*50                                                                          ; (2s)

game_showStartScreen:
                             bsr        game_clear                                               ; clear buffers
                             lea.l      StartScreen,a6
                             tst.l      (a6)
                             beq.s      .gss_skip
                             move.l     (a6),a0
							 move.w #(StartScreen_image_end-StartScreen_image)/4,d1
                             jsr        game_loadScreen

.gss_skip:
                             lea        StartScreen_color,a0
                             jsr        screen_setColors
  
                             lea        StartScreen,a1
                             bra        ss_init


game_showGameOverScreen:
                             bsr        game_clear                                               ; clear buffers
                             lea.l      GameOver,a6
                             tst.l      (a6)
                             beq.s      .gss_skip
                             move.l     (a6),a0
							 move.w #(GameOver_image_end-GameOver_image)/4,d1
                             jsr        game_loadScreen

.gss_skip:

                             lea        GameOver_color,a0
                             jsr        screen_setColors

                             lea        GameOver,a1
                             bra        ss_init

game_showFinalScreen:
                             bsr        game_clear                                               ; clear buffers

                             lea.l      FinalScreen,a6
                             tst.l      (a6)
                             beq.s      .gss_skip
                             move.l     (a6),a0
							 move.w #(FinalScreen_image_end-FinalScreen_image)/4,d1
                             jsr        game_loadScreen

.gss_skip:

                             lea        FinalScreen_color,a0
                             jsr        screen_setColors

                             lea        FinalScreen,a1
                             bra        ss_init
  
  
ss_init:                            
                            ;set sound and prio
                            ; init mod here
                             tst.l      10(a1)
                             beq.s      ss_init_no_sound
                             move.l     10(a1),a0
                             ;jsr        sound_initMod
                             ;jsr        sound_playMod
ss_init_no_sound:
                             move.w     #GAME_CLICK_DELAY,game_block_interaction_time
                             cmp.l      #0,10(a1)
                             beq        ss_loop


ss_loop:  
                             
                             jsr        screen_waitVBlank
  
                             ;jsr        screen_swap

                             ;jsr        screen_restore
                             jsr        joystick_update

        
                             lea        game_block_interaction_time,a0 
                             sub.w      #1,(a0)
                             tst.w      (a0)
                             bgt.s      ss_loop

                             lea.l      joystick1_button,a0
                             cmp.w      #1,(a0)
                             beq        static_done
  
                             bra        ss_loop
                             
static_done:  
                             ;jsr        sound_stopMod
                             rts
  
  
  
 
game_reset:
                             ;TODO: move.w     #(screenBuffer_height-1),screenBuffer_linePointerYPos 
	
                             move.w     #PLAYER_LIVES_INITAL,player_lives
                             move.w     #PLAYER_ENERGY_INITAL,player_energy
                             move.w     #0,player_score
                             lea.l      pots,a0
                             move.l     #0,(a0)
                             adda.l     #POT_ENTRY_SIZE,a0
                             move.l     #0,(a0)
	
                             move.w     #GAME_STATE_RUNNING,game_state
	
                             lea.l      enemy_list0,a0
                             move.l     a0,enemy_list_pointer
	
                             jsr        enemies_reset
                             jsr        bullet_reset
                             jsr        explosions_reset
	
                             lea        levelmap,a0	
                             move.w     4(a0),virtualscreen_yPosition
                             move.l     (a0),levelpointer
                             move.l     14(a0),levelMetapointer
                             rts
	
game_respawn:
                             jsr        enemies_reset
                             jsr        bullet_reset
                             jsr        explosions_reset
                             move.w     #GAME_STATE_RUNNING,game_state
                             move.w     #PLAYER_ENERGY_INITAL,player_energy
	
                             rts

game_checkGameState:
                             ifd        LEVEL_END_BY_SCROLLING
                             lea        virtualscreen_yPosition,a0
                             tst.w      (a0)
                             bne        .gc_done
                             bsr        game_nextLevel
                             endif
							 
							              ; ifd LEVEL_END_BY_TRIGGER
                            ; lea        collision_end_level,a0
                            ; tst.w      (a0)
                            ; beq        .gc_done
							              ; move.w     #0,(a0)
                            ; bsr        game_nextLevel
							              ;endif
                            
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
                             jsr        enemies_reset
                             jsr        bullet_reset
                             jsr        explosions_reset
	
                             moveq      #0,d0                                                    ; get current level pointer
                             add.w      #1,levelNo
                             move.w     levelNo,d0
                             mulu       #LEVEL_MAP_ENTRY_SIZE,d0
	
                             lea        levelmap,a0	
                             adda.l     d0,a0
	
                             move.l     (a0),d1
                             cmp.l      #-1,d1
                             bne        g_setLevel
	; no more levels -> game done
                             move.w     #GAME_STATE_DONE,game_state
                             rts
	
g_setLevel:	
                             move.l     (a0),levelpointer
                             move.l     14(a0),levelMetapointer
                             move.w     4(a0),virtualscreen_yPosition
                             rts
  
game_isDying:
                             move.w     game_state,d0
                             cmp.w      #GAME_STATE_DYING,d0
                             bne        g_notDying
	
	
                             sub.w      #1,game_dying_counter
                             move.w     game_dying_counter,d0
                             tst.w      d0
                             bne        g_notDying
	
                             move.w     #GAME_DYING_INIT,game_dying_counter                      ; reinit

                             sub.w      #1,player_lives
                             move.w     player_lives,d0
                             tst.w      d0
                             bne        g_notDead
                             move.w     #GAME_STATE_OVER,game_state
                             rts
	
g_notDead	
                             move.w     #GAME_STATE_RESPAWN,game_state
	
g_notDying:	
                             rts

; a6 pointer to screen info
; a0 pointer screen tiles	
; d1 tiles size in longwords						 
game_loadScreen:	
	; load screen tiles
	move.l #0,d2
	jsr screen_internal_DefineTiles	
	jsr Screen_init
    rts


game_clear:                 
                             ;TODO
							 rts