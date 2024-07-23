
;****************
; create extra
;****************

; a3 pointer to extra config
; d0 x
; d1 y
extras_create:


.extra_cr_start:
  movem.l    d0-d7/a0-a4,-(sp) 
  lea.l      extra_active_list,a0
  lea.l      extra_active_list_start,a1
  bsr        list_create

  cmp.l      #LIST_EMPTY_POINTER,a0
  beq        .extra_done


                    ; add extra to active list
  move.w     #1,(a0)                                        ;active
  move.w     (a3),INSTANCE_X(a0)                            ; x
  add.w      d0,INSTANCE_X(a0)                              ;x pos
  move.w     2(a3),INSTANCE_Y(a0)                           ; y
  add.w      d1,INSTANCE_Y(a0)                              ; y pos

  move.l     a3,INSTANCE_OBJECT_POINTER(a0)                 ; pointer to EXTRA in extra list
  move.l     8(a3),INSTANCE_BOB_POINTER(a0)                 ; pointer to extra bob
  move.w     #0,INSTANCE_ANIMATION_OFFSET(a0)
  move.w     #4,INSTANCE_TYPE(a0)                           ; type 4 = extra (used for sprites)       
            
.extra_done:
  movem.l    (sp)+,d0-d7/a0-a4
  rts

;*************************
; activate extra
;**************************

;a2 player pointer
;a4 extra pointer

extras_activate:
; sound first          
                       ;set sound and prio
  move.l     30(a4),soundEventPrio0                         ; set sound 


  move.w     38(a4),d0
  cmp.w      #0,d0
  bne        .extra_activate_energy
	
	;0=get extra live
  add.w      #1,player_lives
  bra        .extra_activate_done

.extra_activate_energy:
  cmp.w      #1,d0
  bne        .extra_activate_killAll
  move.w     40(a4),d0                                      ; read extra energy
  add.w      d0,player_energy
  move.w     player_energy,d0
  cmp.w      #PLAYER_ENERGY_MAX,d0
  bgt.s      .extra_activate_done
  move.w     #PLAYER_ENERGY_MAX,player_energy 
  bra.s      .extra_activate_done
	
.extra_activate_killAll:
  
  cmp.w      #4,d0
  bne        .extra_activate_extra_weapon
  lea.l      enemy_active_list,a1                           ; kill all
.extra_kill_enemy_loop
  cmp.w      #1,(a1)
  bne        .extra_no_enemy                                ; no enemy in slot

  move.l     14(a1),a2                                      ; get enemy
  move       #0,(a1)                                        ; kill enemy

                         ; create explosion

  cmp.l      #0,58(a2) 
  beq        .extra_no_enemy                                ; ok no explosion for this enemy

  move.l     58(a2),a3                                      ; explosion pointer
  move.w     2(a1),d0                                       ; enemy x pos
  move.w     4(a1),d1                                       ; enemy y pos
  jsr        explosions_create


.extra_no_enemy:
  adda.l     #LIST_ENTRY_SIZE,a1
  cmp.w      #1,(a1)
  beq        .extra_kill_enemy_loop
  cmp.w      #-1,(a1)
  beq        .extra_activate_done                           ; no slot found
  bra        .extra_kill_enemy_loop                         ; next enemy please                        

                       

.extra_activate_extra_weapon:
  cmp.w      #2,d0
  bne        .extra_activate_upgrade_weapon
  move.l     42(a4),28(a2)
  bra.s      .extra_activate_done

.extra_activate_upgrade_weapon:
  cmp.w      #3,d0
  bne        .extra_activate_add_pot
  bra.s      .extra_activate_done

.extra_activate_add_pot:
  cmp.w      #5,d0
  bne        .extra_activate_done
  move.l     54(a4),a0
  bsr        pot_addPot
                       ;bra.s     .extra_activate_done

.extra_activate_done:
  rts
	
	
	
;***************
;* reset extras *
;***************

extras_reset:
  lea.l      extra_active_list,a0
  move       #EXTRA_MAX_ON_SCREEN-1,d7
.extra_reset:
  move.w     #0,(a0)
  adda.l     #LIST_ENTRY_SIZE,a0                            ; no next slot please
  dbf        d7,.extra_reset
  move.l     #LIST_EMPTY_POINTER,extra_active_list_start
  move.l     #LIST_EMPTY_POINTER,extra_active_list_end
.extra_reset_end:
  rts

;***************
;* move extra *
;***************


extras_update:
  cmp.l      #LIST_EMPTY_POINTER,extra_active_list_start
  beq        .extra_move_end

  move.l     extra_active_list_start,a0
.extra_move:
  cmp.w      #0,(a0)                                        ; active?
  beq        .extra_move_next                               ; no
		
  cmp.w      #1,(a0)                                        ; still moving?
  bne        .extra_move_next                               ; no
	
  move.l     INSTANCE_OBJECT_POINTER(a0),a2                 ; get extra
  ;animation
  move.l     26(a2),a3                                      ; pointer to animation
  move.l     8(a2),INSTANCE_BOB_POINTER(a0)                 ; reset pointer enemy images
  move.w     18(a2),d1
  bsr        list_animateObject 
   ; animation done


;still on page?
.extra_move_page_check:

  moveq      #0,d1
  move.w     4(a2),d3
  move.w     6(a2),d5
  bsr        list_checkObjectIsOnScreen

  tst.w      (a0)
  bne        .extra_move_next
               
  lea.l      extra_active_list_start,a1
  bsr        list_removeObject
.extra_move_next:
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .extra_move
.extra_move_end:
  rts



