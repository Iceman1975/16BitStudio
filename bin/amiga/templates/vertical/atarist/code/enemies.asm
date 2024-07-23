  include    "engine/enemies.asm"
  





;****************
;* draw enemy *
;****************
	
	
enemies_draw:                    
                    moveq     #0,d6
					moveq     #0,d0
					moveq     #0,d1
					moveq     #0,d2
					moveq     #0,d3
                    cmp.l      #LIST_EMPTY_POINTER,enemy_active_list_start
                    beq        e_draw_exit

                    move.l     enemy_active_list_start,a0

e_draw_check
                    cmp        #1,(a0)                                        ; enemy active?
                    beq        e_draw_init                                    ; find active enemy
e_draw_next:
                    bra        e_draw_skip                                    ; check next line

e_draw_init:
					movem.l    a0,-(sp)		
				    move.l     a0,a4
                    move.l    INSTANCE_OBJECT_POINTER(a4),a5                                           ; get enemy config
	
                    move      INSTANCE_X(a4),d0                                           ; x POS
					sub		  virtualscreen_xPosition,d0

                    move      INSTANCE_Y(a4),d1                                           ; y POS
					sub       virtualscreen_yPosition,d1  ; virtualscreen_yPosition has to be removed for real screen position
					
					move      20(a5),d2                                           ; width in bytes-1
                    move      18(a5),d3                                           ; height -1
					
					move.w    48(a5),d6 ; read modulo
					
					move.l    INSTANCE_BOB_POINTER(a4),a0  ; enemy type table pointer 
					
		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=chunk(2*4)*2(width in words) 
					jsr screen_drawObject
                    
                    movem.l    (sp)+,a0
                    

e_draw_skip:	

                    jsr        list_next
                    cmp.l      #LIST_EMPTY_POINTER,a0
                    bne        e_draw_check 

e_draw_exit:
                    rts




