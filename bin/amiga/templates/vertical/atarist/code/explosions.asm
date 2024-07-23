	include    "engine/explosions.asm"


;****************
;* draw explosion *
;****************
	


explosions_draw:  
				   cmp.l      #LIST_EMPTY_POINTER,explosion_active_list_start
			       beq        .ex_draw_exit

				   move.l     explosion_active_list_start,a0
                   moveq     #0,d6
	
.ex_draw_check
         cmp        #1,(a0)                                            ; enemy active?
         beq        .ex_draw_init                                      ; find active enemy
.ex_draw_next:
         bra        .ex_draw_skip                                      ; check next line
 
.ex_draw_init   
					movem.l    a0,-(sp)		
				    move.l     a0,a4
					   
                    move.l    14(a4),a5                                           ; get explosion config
					move.l    18(a4),a0  ; explosion type table pointer 
                    move      $2(a4),d0                                           ; x POS
					sub       virtualscreen_xPosition,d0 		; virtualscreen_xPosition has to be removed for real screen position
                    move      $4(a4),d1                                           ; y POS
					sub       virtualscreen_yPosition,d1 		; virtualscreen_yPosition has to be removed for real screen position
					
					move      14(a5),d2                                           ; width in words
                    move      12(a5),d3                                           ; height -1
					move.w    24(a5),d6 ; read modulo
					
					
		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=chunk(2*4)*2(width in words) 
					jsr screen_drawObject
			
					movem.l    (sp)+,a0
.ex_draw_skip:	
         

					jsr        list_next
					cmp.l      #LIST_EMPTY_POINTER,a0
					bne        .ex_draw_check 
.ex_draw_exit:
                       rts

