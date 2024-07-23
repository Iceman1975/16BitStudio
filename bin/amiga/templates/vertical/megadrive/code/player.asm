                          ifd        PLAYER_ANIMATION_SHOOTER 
player_update:
                          lea.l      player_current_speed_x,a1
                          lea.l      player_pos_x,a2                                        ;shooter_current_pos_x

                          ;move.w     screen_scroll_speed_x,d0                          ; scrolling has always to apply
                          ;add.w      d0,(a2)
                          ;move.w     screen_scroll_speed_y,d0
                          ;add.w     d0,2(a2)

                          move.w     (a2),old_player_pos_x                             ; save values before change
                          move.w     2(a2),old_player_pos_y

                          move.w     #0,(a1)                                           ;initialize speed with 0
                          lea.l      joystick1_left,a0
                          tst.b      (a0)
                          beq        spu_noLeft
                          cmp.w      #PLAYER_BOUNDERY_X0,(a2)
                          ble        spu_noLeft
                          sub.w      #PLAYER_SPEED,(a2)
                          move.w     #-PLAYER_SPEED,(a1)
spu_noLeft:
                          lea.l      joystick1_right,a0
                          tst.b      (a0)
                          beq        spu_noRight
                          cmp.w      #PLAYER_BOUNDERY_X1,(a2)
                          bgt        spu_noRight
						  
                          add.w      #PLAYER_SPEED,(a2)
                          move.w     #PLAYER_SPEED,(a1)
spu_noRight:
                          lea.l      player_current_speed_y,a3
                          lea.l      player_pos_x,a2

                          move.w     #0,(a3)                                           ;initialize speed with 0
                          lea.l      joystick1_up,a0
                          tst.b      (a0)
                          beq        spu_noUp
                          cmp.w      #PLAYER_BOUNDERY_Y0,2(a2)
                          ble        spu_noUp
                          sub.w      #PLAYER_SPEED,2(a2)
                          move.w     #-PLAYER_SPEED,(a3)
spu_noUp:
                          lea.l      joystick1_down,a0
                          tst.b      (a0)
                          beq        spu_noDown
                          cmp.w      #PLAYER_BOUNDERY_Y1,2(a2)
                          bgt        spu_noDown
                          add.w      #PLAYER_SPEED,2(a2)
                          move.w     #PLAYER_SPEED,(a3)
spu_noDown:

                          lea.l      player_animation_offset,a5
                          moveq      #0,d6
                          cmp.w      #0,(a1)
                          bne        spu_xMovement
                          cmp.w      #SHOOTER_SIZE_SIZE*SHOOTER_IDLE_FRAME_NO,(a5)
                          beq        spu_xMovement_done
                          cmp.w      #SHOOTER_SIZE_SIZE*SHOOTER_IDLE_FRAME_NO,(a5)
                          blt        spu_xMovement_1
                          sub.w      #SHOOTER_SIZE_SIZE,(a5)
                          bra        spu_xMovement_done
spu_xMovement_1:
                          add.w      #SHOOTER_SIZE_SIZE,(a5)
                          bra        spu_xMovement_done
spu_xMovement:
                          cmp.w      #0,(a1)
                          blt        spu_xMovement_left
   
spu_xMovement_right:
                          cmp.w      #SHOOTER_SIZE_SIZE*SHOOTER_NO_OF_SPRITE,(a5)
                          beq        spu_xMovement_done
                          add.w      #SHOOTER_SIZE_SIZE,(a5)
                          bra        spu_xMovement_done
spu_xMovement_left:
                          cmp.w      #0,(a5)
                          beq        spu_xMovement_done  
                          sub.w      #SHOOTER_SIZE_SIZE,(a5)
  
spu_xMovement_done:

                          lea.l      joystick1_button_automatic,a0                     ; shoot?
                          cmp.w      #1,(a0)
                          bne        spu_update_done
						  
						  lea.l    player0,a6

                          add.w      #1,player_shoot_count
                          move.w     player_shoot_count,d0
					
                          cmp.w      player_shoot_count_max,d0                                         ; firerate check
                          bne        spu_update_done                                   ; no shoot this time
                          move.w     #0,player_shoot_count					
                          moveq      #0,d5                                             ; set bullet type
                          move.l     28(a6),a4  
  				
spu_shoot_nbullet:
                          move.w     (a2),d3                                           ;x pos of enemy as start x
                          
                          add.w      virtualscreen_xPosition,d3
                          move.w     2(a2),d4                                          ;y pos of enemy as start y
                          
                          add.w      virtualscreen_yPosition,d4
                          move.l     (a4)+,a2                                          ; pointer to first bullet
					
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
						  
                          jsr        bullet_create
                          tst.l      (a4)                                              ; has this enemy more bullets?
                          beq        spu_update_done                                   ; done
                          ;lea.l      player_pos_x,a2                                        ; restore enemy pointer
                          bra        spu_shoot_nbullet
spu_update_done:
                          rts
                          endif