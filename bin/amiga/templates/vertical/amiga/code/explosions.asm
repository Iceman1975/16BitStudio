buffer2  ds.l       10

;LIST_ENTRY_SIZE = 2*11




                        ;status=0 inactive, 1=active, dying;    x;  y;  oldPosX;    oldPosY;    olderPosX;  olderPosY;  pointer to enemyList(longword); pointer_to_enemyBob; 



;****************
; create explosion
;****************

; a3 pointer to explosion config
; d0 x
; d1 y
explosions_create:
         movem.l    a0-a1,-(sp) 
         lea.l      explosion_active_list,a0
         lea.l      explosion_active_list_start,a1
         bsr        list_create

         cmp.l      #LIST_EMPTY_POINTER,a0
         beq        .ex_done


.ex_add:
                    ; add explosion to active list
         move.w     #1,(a0)                                            ;active
         move.w     (a3),INSTANCE_X(a0)                                ; x
         add.w      d0,INSTANCE_X(a0)                                  ;x pos
         move.w     2(a3),INSTANCE_Y(a0)                               ; y
         add.w      d1,INSTANCE_Y(a0)                                  ; y pos
         move.w     #0,INSTANCE_ANIMATION_OFFSET(a0)
         move.l     a3,INSTANCE_OBJECT_POINTER(a0)                     ; pointer to enemy in explosin list
         move.l     8(a3),INSTANCE_BOB_POINTER(a0)                     ; pointer to enemy bob
                    
                       ;set sound 
         move.l     30(a3),soundEventPrio0                             ; set sound 

.ex_done:
         movem.l    (sp)+,a0-a1
         rts


;***************
;* reset explosions *
;***************

explosions_reset:
         lea.l      explosion_active_list,a0
         move       #EXPLOSION_MAX_ON_SCREEN-1,d7
.ex_reset:
         move.w     #0,(a0)
         adda.l     #LIST_ENTRY_SIZE,a0                                ; no next slot please
         dbf        d7,.ex_reset
					
         move.l     #LIST_EMPTY_POINTER,explosion_active_list_start
         move.l     #LIST_EMPTY_POINTER,explosion_active_list_end
.ex_reset_end:
         rts


;***************
;* move explosion *
;***************


explosions_update:
         cmp.l      #LIST_EMPTY_POINTER,explosion_active_list_start
         beq        .ex_done

         move.l     explosion_active_list_start,a0
.ex_start:
         cmp.w      #0,(a0)                                            ; active?
         beq        .ex_checkState                                     ; no

         move.l     INSTANCE_OBJECT_POINTER(a0),a2                     ; get explosion object
		
.ex_update_animation:

         move.l     26(a2),a3
         move.l     8(a2),INSTANCE_BOB_POINTER(a0)                     ; reset pointer enemy images
         move.w     18(a2),d1
         bsr        list_animateObject    

         move.w     INSTANCE_ANIMATION_OFFSET(a0),d0
         cmp.w      #0,d0
         bne.s      .ex_page_check

.ex_reset_animation:
         move.w     #0,(a0)                                            ;deactivate after animation end
         bra.s      .ex_checkState

.ex_page_check:

         moveq      #0,d1
         move.w     4(a2),d3
         move.w     6(a2),d4
         bsr        list_checkObjectIsOnScreen


.ex_checkState:

         cmp.w      #0,(a0)
         bne.s      .ex_next
         lea.l      explosion_active_list_start,a1
         bsr        list_removeObject

.ex_next:                  
         bsr        list_next
         cmp.l      #LIST_EMPTY_POINTER,a0
         bne        .ex_start 
.ex_done:
         rts



;****************
;* draw explosion *
;****************
	


explosions_draw:  
         
         lea.l      screen_restore_list,a6                   
  
         cmp.l      #LIST_EMPTY_POINTER,explosion_active_list_start
         beq        .ex_draw_exit

         move.l     explosion_active_list_start,a0

         moveq      #0,d6
	
.ex_draw_init_blitter
         btst       #14,$dff002
         bne.s      .ex_draw_init_blitter
	
         move       #-2,$dff064                                        ;A Modulo
         move       #-2,$dff062                                        ;B Modulo

         clr        $dff042
         move.l     #$ffff0000,$dff044
	
.ex_draw_check
         cmp        #1,(a0)                                            ; enemy active?
         beq        .ex_draw_init                                      ; find active enemy
.ex_draw_next:
         bra        .ex_draw_skip                                      ; check next line
 

.ex_draw_init:
         move.l     INSTANCE_OBJECT_POINTER(a0),a5                     ; get bullet type config
         move.w     24(a5),d5                                          ; load modulo
         move       22(a5),d6                                          ; load blitsize
         move       4(a5),d7                                           ; load height
         move.w     20(a5),d0                                          ; get mask size

               ; a0 = pointer to instance
               ; a6 pointer to restore list
               ; d0 = mask size
               ; d5 = modulo
               ; d6 = blitsize
               ; d7 = height
         bsr        list_drawObject


.ex_draw_skip:	
         

         bsr        list_next
         cmp.l      #LIST_EMPTY_POINTER,a0
         bne        .ex_draw_check 

.ex_draw_exit:
         rts

