

;****************
; create Enemy by trigger
;****************

;a4 pointer to enemy list
enemies_createEnemyByTrigger:
  tst.l      (a4) 
  beq        .done
  move.l     (a4)+,a3
  bsr        en_cr_start

  bra.s      enemies_createEnemyByTrigger                   ; more?
.done

  bsr        enemies_move
  rts


;****************
; create Enemy
;****************

enemies_createEnemy:
       
  move.l     enemy_list_pointer,a3                    
  move.w     virtualscreen_yPosition,d0

  cmp.w      (a3),d0                                        ; new enemy to activate?                                                          
  bgt        noenemy                                        ; hier reicht > wegen 2 pixel scrolling; derzeit ist aber alles gerade; geht also für test
  bsr        en_cr_start

noenemy:	
  bra        en_done

en_cr_start:
  lea.l      enemy_active_list,a0
  lea.l      enemy_active_list_start,a1
  bsr        list_create

  cmp.l      #LIST_EMPTY_POINTER,a0
  beq        en_done
                    
en_add:
                    ; add enemy to active list
  move.w     #1,(a0)                                        ;active
  move.w     6(a3),INSTANCE_X(a0)                           ; x
  move.w     8(a3),INSTANCE_Y(a0)                           ; y

  move.l     a3,INSTANCE_OBJECT_POINTER(a0)                 ; pointer to enemy in enemy list
  move.l     14(a3),INSTANCE_BOB_POINTER(a0)                ; pointer to enemy bob
  move.w     26(a3),INSTANCE_HITPOINTS(a0)                  ; init hitpoints
  move.w     22(a3),INSTANCE_ANIMATION_OFFSET(a0)
  move.l     10(a3),INSTANCE_PATH_POINTER(a0)
  move.w     #2,INSTANCE_TYPE(a0)                           ; type 2 = enemy (used for sprites)

                    ;*** hook for onCreate
  ifd        SCRIPTS_ENABLE
  tst.l      66(a3)
  beq        en_noScript                                    ; no script; 
  move.l     66(a3),a5                                      ; get script
  tst.l      4(a5)
  beq        en_noScript                                    ; no script for this method; 

  movem.l    d0-d7/a0-a4,-(sp)  
  move.l     a3,a2                                          ; shift pointer       

  move.l     70(a3),a3                                      ; get object

                    ; script entry point:
                    ; a0 - enemy active list pointer
                    ; a2 - enemy data
                    ; a3 - enemy object instance
                    ; a5 - pointer to class implementation
                    

  move.l     player_current,a4
  move.l     4(a5),a5
  jsr        (a5)
  movem.l    (sp)+,d0-d7/a0-a4

  endif



         ; increase pointer to next enemy
en_noScript:
                    
  add.l      #ENEMY_LIST_ENTRY_SIZE,enemy_list_pointer
en_done:
  rts


;***************
;* reset enemies *
;***************

enemies_reset:
  lea.l      enemy_active_list,a0
  move       #ENEMY_MAX_ON_SCREEN-1,d7
.e_reset:
  move.w     #0,(a0)
  adda.l     #LIST_ENTRY_SIZE,a0                            ; no next slot please
  dbf        d7,.e_reset
					
  move.l     #LIST_EMPTY_POINTER,enemy_active_list_start
  move.l     #LIST_EMPTY_POINTER,enemy_active_list_end
  rts

;***************
;* move enemies *
;***************


enemies_move:
  cmp.l      #LIST_EMPTY_POINTER,enemy_active_list_start
  beq        e_move_end

  move.l     enemy_active_list_start,a0
              

e_move:
  cmp.w      #0,(a0)                                        ; active?
  beq        e_move_next                                    ; no

  move.l     INSTANCE_OBJECT_POINTER(a0),a2                 ; get enemy

  cmp.w      #1,(a0)                                        ; still on page or currently outside?
  bne        e_move_page_check                              ; currently not on screen; only screen check necessary

                    
                    


  ifd        SCRIPTS_ENABLE
  tst.l      66(a2)
  beq        e_move_by_path                                 ; no script; use path instead
  move.l     66(a2),a5                                      ; get script
  tst.l      (a5)
  beq        e_move_by_path                                 ; no script for this method; use path instead

  movem.l    d0-d7/a0-a4,-(sp)                    
  move.l     70(a2),a3                                      ; get object

                    ; script entry point:
                    ; a0 - enemy active list pointer
                    ; a2 - enemy data
                    ; a3 - enemy object instance
                    ; a5 - pointer to class implementation
                    
  move.l     player_current,a4
  move.l     (a5),a5
  jsr        (a5)
  movem.l    (sp)+,d0-d7/a0-a4
                    ;bra        e_move_update_animation
  bra        e_move_page_check
  endif
                    
                    ; **** move by path **** Start
e_move_by_path:
	
  bsr        list_moveObjectOnPath

                    ; **** move by path **** end

e_move_update_animation:
  move.l     50(a2),a3                                      ; get animation pointer
  move.l     14(a2),INSTANCE_BOB_POINTER(a0)                ; reset pointer enemy images
  move.w     24(a2),d1                                      ; d1=max animation 

  bsr        list_animateObject


;still on page?
e_move_page_check:
  cmp.w      #2,(a0)                                        ; other state?
  bgt        e_move_next                                    ; yep skip


  move.w     (a0),d0                                        ; remember old state
  moveq      #ENEMY_DEACTIVATION_MODE,d1                    ; state if ouside of screen
  move.w     4(a2),d5                                       ; d5=height
  move.w     2(a2),d3                                       ; d3=width


  bsr        list_checkObjectIsOnScreen

e_move_check_state:
  cmp.w      (a0),d0
  beq        e_move_shoot                                   ; no status change

  ifd        SCRIPTS_ENABLE
  cmp.w      #1,d0                                          ; check old state; if old 1-> 2 if old 2->1
  beq.s      e_move_state_disable
                    ;enable

  tst.l      66(a2)
  beq        e_move_shoot                                   ; no script; skiü
  move.l     66(a2),a5                                      ; get script
  tst.l      8(a5)
  beq        e_move_shoot                                   ; no script for this method; skio

  movem.l    d0-d7/a0-a4,-(sp)                    
  move.l     70(a2),a3                                      ; get object

                    ; script entry point:
                    ; a0 - enemy active list pointer
                    ; a2 - enemy data
                    ; a3 - enemy object instance
                    ; a5 - pointer to class implementation
                    
  move.l     player_current,a4
  move.l     8(a5),a5
  jsr        (a5)
  movem.l    (sp)+,d0-d7/a0-a4
  bra.s      e_move_shoot
e_move_state_disable:
                    ;disable:
  tst.l      66(a2)
  beq        e_move_shoot                                   ; no script; use path instead
  move.l     66(a2),a5                                      ; get script
  tst.l      12(a5)
  beq        e_move_shoot                                   ; no script for this method; use path instead

  movem.l    d0-d7/a0-a4,-(sp)                    
  move.l     70(a2),a3                                      ; get object

                    ; script entry point:
                    ; a0 - enemy active list pointer
                    ; a2 - enemy data
                    ; a3 - enemy object instance
                    ; a5 - pointer to class implementation

  move.l     player_current,a4
  move.l     12(a5),a5
  jsr        (a5)
  movem.l    (sp)+,d0-d7/a0-a4

  endif


e_move_shoot:		;a0 active list; a2 enemy
  cmp.l      #0,54(a2)                                      ; has enemy buttet?
  beq        e_move_next                                    ; no

  add.w      #1,32(a2)
  move.w     32(a2),d0
					
  cmp.w      30(a2),d0                                      ; firerate check
  bne        e_move_next                                    ; no shoot this time
  move.w     #0,32(a2)					
  moveq      #1,d5                                          ; set bullet type
  move.l     54(a2),a4  
					
e_move_shoot_nbullet:
  move.w     2(a0),d3                                       ;x pos of enemy as start x
  move.w     4(a0),d4                                       ;y pos of enemy as start y
  move.l     (a4)+,a2                                       ; pointer to first bullet
					
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
					
  jsr        bullet_create
  tst.l      (a4)                                           ; has this enemy more bullets?
  beq        e_move_next                                    ; done
  move.l     14(a0),a2                                      ; restore enemy pointer
  bra        e_move_shoot_nbullet
e_move_next:
  cmp.w      #0,(a0)
  bne.s      e_move_next2

  lea.l      enemy_active_list_start,a1
  bsr        list_removeObject
e_move_next2:
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        e_move 

e_move_end:
  rts



