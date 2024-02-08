


bullet_count  dc.w      0
bullet_switch  dc.w       0



; a2 bullet pointer to be created
; d3 shooter x
; d4 shooter y
; d5 shooter type (0=player, 1=enemy)


bullet_create:
               movem.l    d0-d7/a0-a4,-(sp) 

               lea.l      bullet_active_list,a0
               lea.l      bullet_active_list_start,a1
               jsr        list_create

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
               movem.l    (sp)+,d0-d7/a0-a4
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


bullet_movex:
              lea.l     bullet_active_list,a0
              lea.l     bullet_count,a2

              move      #BULLET_COUNT_MAX-1,d7
b_move:
              cmp.w     #0,(a0)                               ; active?
              beq       b_move_next                           ; no
	
              ;move.l    $6(a0),$a(a0)               	; only needed on Amiga                                                                                                                                                 
              ;move.l    $2(a0),$6(a0)                  ; current to old (x and y)	
	
              cmp.w     #1,(a0)                               ; still moving?
              bne       b_move_next                           ; no
	
              move.l    14(a0),a1                             ; load pointer to bulletType
			  
              move.w    (a1),d0
              add.w     d0,2(a0)                              ; add speed x                                                                                                                                                                
	          
              move.w    2(a1),d0
              add.w     d0,4(a0)                              ; add speed y                                                                                                                                

			  ;TODO animation!!!!!
			  
              sub.w     #1,INSTANCE_LIVE_COUNTER(a0)                             ; decrease liveTimeCounter                                                                                                                                                   
              cmp.w     #0,INSTANCE_LIVE_COUNTER(a0)
              bne       b_move_page_check
              move.w    #0,(a0)
              sub.w     #1,(a2) 
			
;still on page?
b_move_page_check			
			   moveq      #0,d1
               move.w     4(a1),d3
               move.w     6(a1),d5
               jsr        list_checkObjectIsOnScreen


	
b_move_next:
              tst.w     (a0)
              bne       b_move_next2
              sub.w     #1,(a2)                               ; decrease bullet counter
              
b_move_next2:
              adda.l    #LIST_ENTRY_SIZE,a0                  ; no next slot please
              dbf       d7,b_move
b_move_end:
              rts


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
               jsr        list_animateObject 
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
               jsr        list_checkObjectIsOnScreen
.b_remove:
               tst.w      (a0)
               bne        .b_skip
               
               lea.l      bullet_active_list_start,a1
               jsr        list_removeObject

              
.b_skip:
               jsr        list_next
               cmp.l      #LIST_EMPTY_POINTER,a0
               bne        .b_loop 
.b_end:
               rts			  
	
;****************
;* draw bullets *
;****************
	
	
bullet_draw:                    
                    moveq     #0,d6
					moveq     #0,d0
					moveq     #0,d1
					moveq     #0,d2
					moveq     #0,d3
	
					cmp.l      #LIST_EMPTY_POINTER,bullet_active_list_start
					beq        b_draw_done
                    move.l     bullet_active_list_start,a0

b_draw_check:
					cmp        #1,(a0)                                         ; bullet active?
					beq        b_draw_init                                     ; find active bullet
b_draw_next:
					bra        b_draw_skip                                     ; check next line

b_draw_init:
					movem.l    a0,-(sp)		
				    move.l     a0,a4
                    move.l    INSTANCE_OBJECT_POINTER(a4),a5                                           ; get bulletType config
					
                    move      INSTANCE_X(a4),d0                                           ; x POS	
					sub       virtualscreen_xPosition,d0 		; virtualscreen_xPosition has to be removed for real screen position					
					move      INSTANCE_Y(a4),d1                                           ; y POS
					sub       virtualscreen_yPosition,d1 		; virtualscreen_yPosition has to be removed for real screen position
					
					move      18(a5),d2                                           ; width in word-1
                    move      16(a5),d3                                           ; height -1
					
					move.l    12(a5),a0  ; bulletType table pointer 
					move.w    42(a5),d6 ; read modulo
					

					; a0 pointer to bitmap
					; a1 pointer to bitmap mask
					; d0,d1 x,y
					; d2= width-1 (in words)
					; d3=height-1 	
					; d6=chunk(2*4)*2(width in words) 
					jsr screen_drawObject
			
					movem.l    (sp)+,a0
b_draw_skip:	
					jsr        list_next
					cmp.l      #LIST_EMPTY_POINTER,a0
					bne        b_draw_check 

b_draw_done:
					rts

