




; a2 bullet pointer to be created
; d3 shooter x
; d4 shooter y
; d5 shooter type (0=player, 1=enemy)

bullet_create:
  movem.l    d0-d7/a0-a6,-(sp) 

  lea.l      bullet_active_list,a0
  lea.l      bullet_active_list_start,a1
  bsr        list_create

  cmp.l      #LIST_EMPTY_POINTER,a0
  beq        .b_create_end
	
  move.w     #1,(a0)                                         ;set active                                                                                                                                                            ; set active
	        
  add.w      60(a2),d3                                       ; add x offset                                                                                                                                                             ;global
  move.w     d3,INSTANCE_X(a0)                               ; init x                                                                                                                                                       ; POS X
              
  add.w      62(a2),d4                                       ; add y offset                                                                                                                                        ; POS X older                                                                                                                                                                     ; mid of sprite
  move.w     d4,INSTANCE_Y(a0)                               ; init y                                                                                                                                                 ; POS Y
							
  move.l     a2,INSTANCE_OBJECT_POINTER(a0)                  ; store bullet type pointer
  move.l     12(a2),INSTANCE_BOB_POINTER(a0)
  move.w     #0,INSTANCE_ANIMATION_OFFSET(a0)
  move.w     10(a2),INSTANCE_LIVE_COUNTER(a0)                ; init live time
  move.w     d5,INSTANCE_TYPE(a0)                            ; store type
	
               
  move.w     bullet_switch,INSTANCE_COLL_FLAG(a0)            ; collision switch
  cmp.w      #0,INSTANCE_COLL_FLAG(a0)
  beq.s      .b_switch
  move.w     #0,bullet_switch
  bra.s      .b_switch_done
.b_switch:   
  move.w     #1,bullet_switch
.b_switch_done:

  cmp.l      #0,48(a2)
  beq        .b_create_end

              ;set sound and prio
  move.l     48(a2),soundEventPrio0                          ; set sound 
              
.b_create_end
  movem.l    (sp)+,d0-d7/a0-a6
  rts


;***************
;* reset bullet *
;***************
bullet_reset:
  lea.l      bullet_active_list,a0
  move.l     #BULLET_COUNT_MAX-1,d7
.b_reset:
  move.w     #0,(a0)                
  adda.l     #LIST_ENTRY_SIZE,a0                             ;  next slot please
  dbf        d7,.b_reset
  move.l     #LIST_EMPTY_POINTER,bullet_active_list_start
  move.l     #LIST_EMPTY_POINTER,bullet_active_list_end

  rts	

;***************
;* move bullet *
;***************


bullet_move:
  cmp.l      #LIST_EMPTY_POINTER,bullet_active_list_start
  beq        .b_end
  move.l     bullet_active_list_start,a0
               

.b_loop:
  cmp.w      #0,(a0)                                         ; active?
  beq        .b_skip                                         ; no
	
  move.l     INSTANCE_OBJECT_POINTER(a0),a2                  ; load pointer to bulletType
			  
  move.w     (a2),d0
  add.w      d0,INSTANCE_X(a0)                               ; add speed x                                                                                                                                                                
	          
  move.w     2(a2),d0
  add.w      d0,INSTANCE_Y(a0)                               ; add speed y                                                                                                                                

               ;animation
  move.l     44(a2),a3
  move.l     12(a2),INSTANCE_BOB_POINTER(a0)                 ; reset pointer enemy images
  move.w     22(a2),d1
  bsr        list_animateObject 
               ; animation done

  sub.w      #1,INSTANCE_LIVE_COUNTER(a0)                    ; decrease liveTimeCounter                                                                                                                                                   
  cmp.w      #0,INSTANCE_LIVE_COUNTER(a0)
  bne        .b_move_page_check
  move.w     #0,(a0)
  bra.s      .b_remove
			
;still on page?
.b_move_page_check			

  moveq      #0,d1
  move.w     4(a2),d3
  move.w     6(a2),d5
  bsr        list_checkObjectIsOnScreen
.b_remove:
  tst.w      (a0)
  bne        .b_skip
               
  lea.l      bullet_active_list_start,a1
  bsr        list_removeObject

              
.b_skip:
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .b_loop 
.b_end:
  rts
	
	
