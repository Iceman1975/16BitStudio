PLAYER_SPRITE_SIZE            = SHOOTER_SIZE_SIZE*4                                    ; all 4 sprites (2 per part)
PLAYER_LAST_ANIMATION_POINTER = PLAYER_SPRITE_SIZE*SHOOTER_NO_OF_SPRITE

player_current            dc.l       player0






player_current_speed_x  
                          dc.w       0
player_current_speed_y 
                          dc.w       0

player_animation_offset 
                          dc.w       0


                          ifd        PLAYER_ANIMATION_GUNNER 


player_animation_counter  dc.w       0                                                 ; *2 because of word steps
player_animation_current  dc.l       player_animation_idle                             
                          endif

player_create:
                          lea.l      blanksprite,a1                                    ; put blanksprite address into a1
                          lea.l      copper_sprite_setup,a2                            ; put copper address into a2
                          add.l      #10,a2                                            ; add 10 to copper address in a2
                          move.l     a1,d1                                             ; move blanksprite address into d1
                          moveq      #6,d0                                             ; setup sprite counter

s1_sprcoploop:            ; set all 7 sprite pointers
                          swap       d1                                                ; high and low to point to blanksprite 
                          move.w     d1,(a2)
                          addq.l     #4,a2
                          swap       d1
                          move.w     d1,(a2)
                          addq.l     #4,a2
                          dbra       d0,s1_sprcoploop                                  ; loop trough all 7 sprite pointers

;add player sprite
                          lea.l      player0_sprite,a1                                 ; put sprite address into a1
                          lea.l      copper_sprite_setup,a2                            ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper

                          lea.l      player0_sprite+SHOOTER_SIZE_SIZE,a1               ; put sprite address into a1
  ;PLAYER_SPRITE_SIZE should 124
  ;lea.l     sprite1_0,a1
                          lea.l      copper_sprite_setup+8,a2                          ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper
  ;rts
  ;debug end
	
                          lea.l      player0_sprite+(2*SHOOTER_SIZE_SIZE),a1           ; put sprite address into a1
                          lea.l      copper_sprite_setup+16,a2                         ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper

                          lea.l      player0_sprite+(3*SHOOTER_SIZE_SIZE),a1           ; put sprite address into a1
                          lea.l      copper_sprite_setup+24,a2                         ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper
                          rts


                          ifd        PLAYER_ANIMATION_SHOOTER 
player_update:
                          lea.l      player_current_speed_x,a1
                          lea.l      player0,a2                                        ;shooter_current_pos_x

                          move.w     screen_scroll_speed_x,d0                          ; scrolling has always to apply
                          add.w      d0,(a2)
                          move.w     screen_scroll_speed_y,d0
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
                          lea.l      player0,a2

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
                          cmp.w      #PLAYER_SPRITE_SIZE*SHOOTER_IDLE_FRAME_NO,(a5)
                          beq        spu_xMovement_done
                          cmp.w      #PLAYER_SPRITE_SIZE*SHOOTER_IDLE_FRAME_NO,(a5)
                          blt        spu_xMovement_1
                          sub.w      #PLAYER_SPRITE_SIZE,(a5)
  ;move.w #-SHOOTER_SPRITE_SIZE,d6  
                          bra        spu_xMovement_done
spu_xMovement_1:
                          add.w      #PLAYER_SPRITE_SIZE,(a5)
  ;move.w #SHOOTER_SPRITE_SIZE,d6
                          bra        spu_xMovement_done
spu_xMovement:
                          cmp.w      #0,(a1)
                          blt        spu_xMovement_left
   
spu_xMovement_right:
                          cmp.w      #PLAYER_SPRITE_SIZE*SHOOTER_NO_OF_SPRITE,(a5)
                          beq        spu_xMovement_done
                          add.w      #PLAYER_SPRITE_SIZE,(a5)
                          bra        spu_xMovement_done
spu_xMovement_left:
                          cmp.w      #0,(a5)
                          beq        spu_xMovement_done  
                          sub.w      #PLAYER_SPRITE_SIZE,(a5)
  
spu_xMovement_done:

                          lea.l      joystick1_button_automatic,a0                     ; shoot?
                          cmp.w      #1,(a0)
                          bne        spu_update_done

                          add.w      #1,34(a2)
                          move.w     34(a2),d0
					
                          cmp.w      32(a2),d0                                         ; firerate check
                          bne        spu_update_done                                   ; no shoot this time
                          move.w     #0,34(a2)					
                          moveq      #0,d5                                             ; set bullet type
                          move.l     28(a2),a4  
  				
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
                          lea.l      player0,a2                                        ; restore enemy pointer
                          bra        spu_shoot_nbullet
spu_update_done:
                          rts
                          endif



                          ifd        PLAYER_ANIMATION_GUNNER 
player_update:
                          lea.l      player_current_speed_x,a1
                          lea.l      player0,a2                                        ;shooter_current_pos_x

                          lea.l      player_animation_idle,a6
                          ;move.w    #0,player_direction                               ; init dir = 0 (up)

                          move.w     screen_scroll_speed_x,d0                          ; scrolling has always to apply
                          add.w      d0,(a2)
                          move.w     screen_scroll_speed_y,d0
                          add.w      d0,2(a2)

                          move.w     (a2),old_player_pos_x                             ; save values before change
                          move.w     2(a2),old_player_pos_y

                          move.w     #0,(a1)                                           ;initialize speed with 0
                          lea.l      joystick1_left,a0
                          tst.b      (a0)
                          beq        spu_noLeft
                          lea.l      player_animation_left,a6
                          move.w     #6*4,player_direction
                          cmp.w      #PLAYER_BOUNDERY_X0,(a2)
                          ble        spu_noLeft
                          sub.w      #PLAYER_SPEED,(a2)
                          move.w     #-PLAYER_SPEED,(a1)
                          
spu_noLeft:
                          lea.l      joystick1_right,a0
                          tst.b      (a0)
                          beq        spu_noRight
                          lea.l      player_animation_right,a6
                          move.w     #2*4,player_direction
                          cmp.w      #PLAYER_BOUNDERY_X1,(a2)
                          bgt        spu_noRight
                          add.w      #PLAYER_SPEED,(a2)
                          move.w     #PLAYER_SPEED,(a1)
                          
spu_noRight:
                          lea.l      player_current_speed_y,a3
                          lea.l      player0,a2

                          move.w     #0,(a3)                                           ;initialize speed with 0
                          lea.l      joystick1_up,a0
                          tst.b      (a0)
                          beq        spu_noUp
                          lea.l      player_animation_up,a6
                          move.w     #0*4,player_direction
                          cmp.w      #PLAYER_BOUNDERY_Y0,2(a2)
                          ble        spu_noUp
                          sub.w      #PLAYER_SPEED,2(a2)
                          move.w     #-PLAYER_SPEED,(a3)
                          cmp.w      #0,player_current_speed_x
                          blt.s      .spu_no_x_correction_up_left
                          bgt.s      .spu_no_x_correction_up_right
                          
                          bra.s      spu_noUp
.spu_no_x_correction_up_left:                        
                          lea.l      player_animation_up_left,a6
                          move.w     #7*4,player_direction
                          bra.s      spu_noUp
.spu_no_x_correction_up_right:
                          lea.l      player_animation_up_right,a6
                          move.w     #1*4,player_direction

spu_noUp:
                          lea.l      joystick1_down,a0
                          tst.b      (a0)
                          beq        spu_noDown
                          lea.l      player_animation_down,a6
                          move.w     #4*4,player_direction

                          cmp.w      #PLAYER_BOUNDERY_Y1,2(a2)
                          bgt        spu_noDown
                          add.w      #PLAYER_SPEED,2(a2)
                          move.w     #PLAYER_SPEED,(a3)

                          cmp.w      #0,player_current_speed_x
                          blt.s      .spu_no_x_correction_down_left
                          bgt.s      .spu_no_x_correction_down_right
                          
                          bra.s      spu_noDown
.spu_no_x_correction_down_left:                        
                          lea.l      player_animation_down_left,a6
                          move.w     #5*4,player_direction
                          bra.s      spu_noDown
.spu_no_x_correction_down_right:
                          lea.l      player_animation_down_right,a6
                          move.w     #3*4,player_direction

spu_noDown:                          
                          move.l     player_animation_current,d0
                          lea.l      player_animation_idle,a1
                          cmpa.l     a6,a1
                          bne.s      .spu_check_correction
                          move.l     player_animation_current,a6                       ;if idle ignore state change
                          move.w     #0,player_animation_counter                       ; in this case; always stop animation
                          
.spu_check_correction
                          cmp.l      a6,d0                                             ; still same animation?
                          beq.s      .spu_no_counter_correction
                          move.w     #0,player_animation_counter                       ; no -> reset counter

.spu_no_counter_correction:
                          
                          move.l     a6,player_animation_current
                             ;move.l    d6,a6
                       
                          moveq      #0,d0
                          add.w      #2,player_animation_counter
                          move.w     player_animation_counter,d0
                          adda.l     d0,a6

                          cmp.w      #-1,(a6)
                          bne.s      .spu_set_animation                                ; end of animation reached?
                          move.w     #0,player_animation_counter                       ; yes
                          move.l     player_animation_current,a6                       ;reset animation
.spu_set_animation
                          lea.l      player_animation_offset,a5

                          move.w     (a6),(a5)
              
  
spu_xMovement_done:

                          lea.l      joystick1_button_automatic,a0                     ; shoot?
                          cmp.w      #1,(a0)
                          bne        spu_update_done

                          add.w      #1,34(a2)
                          move.w     34(a2),d0
					
                          cmp.w      32(a2),d0                                         ; firerate check
                          bne        spu_update_done                                   ; no shoot this time
                          move.w     #0,34(a2)					
                          moveq      #0,d5                                             ; set bullet type
                          move.l     28(a2),a4                                         ; pointer to bullet list or bullet group
  				
spu_shoot_nbullet:
                          move.w     (a2),d3                                           ;x pos of enemy as start x
                          
                          add.w      virtualscreen_xPosition,d3
                          move.w     2(a2),d4                                          ;y pos of enemy as start y
                          
                          add.w      virtualscreen_yPosition,d4
                          
                          ifd        BULLET_SIMPLE
                          move.l     (a4)+,a2                                          ; pointer to first bullet 
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
					
                          jsr        bullet_create
                          tst.l      (a4)                                              ; has this enemy more bullets?
                          beq        spu_update_done                                   ; done
                          lea.l      player0,a2                                        ; restore enemy pointer
                          bra        spu_shoot_nbullet
                          endif

                          ifd        BUlLET_GROUP_SUPPPORT
                          adda.w     player_direction,a4
                          move.l     (a4),a2
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
					
                          jsr        bullet_create                          
                          endif

spu_update_done:
                          rts
                          endif

player_drawByCopper:
                          moveq      #0,d0
                          move.l     player_current,a0
                          move.w     2(a0),d0
                          add.w      #44,d0
                           ;a0 pointer to object
                           ;d0 y-sort value
                          movea.l    #-1,a0                                            ;flag for player
                          jsr        sprite_addPointer
                          rts

player_draw:
	;get player position 
                          lea.l      player0,a4
                          moveq      #0,d4                                             
                          move.w     (a4),d4                                           ; load x pos

                          lsr.w      #1,d4                                             ; amiga correction
                          ;add.w     #112,d4                                           ; correct x
                          add.w      #57,d4
   
                          moveq      #0,d5
                          move.w     2(a4),d5                                          ; load y pos

                          add.w      #44,d5                                            ; amiga correct y?

                          move.w     d5,d6
                          add.w      6(a4),d6                                          ; add player height
	
	
	;set sprite:
                          move.w     player_animation_offset,d2
  ;debug
  ;move.w    #PLAYER_SPRITE_SIZE*2,d2
	
                          lea.l      player0_sprite,a1                                 ; put sprite address into a1
	
                          add.l      d2,a1	
                          move.b     d4,1(a1)                                          ; set x pos
                          move.b     d5,(a1)                                           ; set y pos
                          move.b     d6,2(a1)                                          ; set y pos + height
	
                          lea.l      copper_sprite_setup,a2                            ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper

                          lea.l      player0_sprite+(1*SHOOTER_SIZE_SIZE),a1           ; put sprite address into a1
  ;lea.l     sprite1_0,a1
	;add.l	#4*152,a1
                          add.l      d2,a1
                          move.b     d4,1(a1)                                          ; set x pos
                          move.b     d5,(a1)                                           ; set y pos
                          move.b     d6,2(a1)                                          ; set y pos + height
                          lea.l      copper_sprite_setup+8,a2                          ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper

  ;rts
  ;debug
	
                          add.w      #8,d4                                             ; shift 2 bytes for right part x+2
	
                          lea.l      player0_sprite+(2*SHOOTER_SIZE_SIZE),a1           ; put sprite address into a1
	;add.l	#4*152,a1
                          add.l      d2,a1
                          move.b     d4,1(a1)                                          ; set x pos
                          move.b     d5,(a1)                                           ; set y pos
                          move.b     d6,2(a1)                                          ; set y pos + height
                          lea.l      copper_sprite_setup+16,a2                         ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper

                          lea.l      player0_sprite+(3*SHOOTER_SIZE_SIZE),a1           ; put sprite address into a1
	;add.l	#4*152,a1
                          add.l      d2,a1
                          move.b     d4,1(a1)                                          ; set x pos
                          move.b     d5,(a1)                                           ; set y pos
                          move.b     d6,2(a1)                                          ; set y pos + height
                          lea.l      copper_sprite_setup+24,a2                         ; put copper address into a2
                          move.l     a1,d1                                             ; move sprite address into d1
                          move.w     d1,6(a2)                                          ; transfer sprite address high to copper
                          swap       d1                                                ; swap
                          move.w     d1,2(a2)                                          ; transfer sprite address low to copper
                          rts