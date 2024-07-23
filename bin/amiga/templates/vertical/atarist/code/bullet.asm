	include    "engine/bullet.asm"


	
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

