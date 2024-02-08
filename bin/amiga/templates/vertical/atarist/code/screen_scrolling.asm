screen_initScreenByColumns:
		moveq #0,d6
		moveq 	#20-1,d5
		moveq   #12-1,d7	
	    lea.l     screen_REPAIR,a2
		move.l     levelpointer,a3     
        bsr screen_fillScreen
		moveq #4,d6
		moveq 	#20-1,d5
		moveq   #12-1,d7	
	    lea.l     screen_REPAIR+screenBuffer_size+SCROLL_BUFFER_SIZE,a2
		move.l     levelpointer,a3     
        bsr screen_fillScreen
		moveq #8,d6
		moveq 	#20-1,d5
		moveq   #12-1,d7	
	    lea.l     screen_REPAIR+(2*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a2
		move.l     levelpointer,a3     
        bsr screen_fillScreen
		moveq #12,d6
		moveq 	#20-1,d5
		moveq   #12-1,d7	
	    lea.l     screen_REPAIR+(3*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a2
		move.l     levelpointer,a3     
        bsr screen_fillScreen
		rts
		  
screen_fillScreen:
		  moveq  #0,d0
		  lea.l     tiles,a0
		  move.w    (a3),d0
		  adda.l    d0,a0
		  
		  lea.l     tiles,a1
		  move.w    2(a3),d0
		  adda.l    d0,a1                                                                            ; add in tile position= tile line
		
		  bsr screen_addTile
		  
		  lea (screenBuffer_lineSize*16)(a2),a2 ; next tile line
		  lea (2*tile_no_x)(a3),a3

		  dbf d7,screen_fillScreen		
		  suba.l  #(screenBuffer_lineSize*16*12)-8,a2
		  suba.l  #(2*tile_no_x*12)-2,a3
		  moveq   #12-1,d7
		  dbf d5,screen_fillScreen
		rts
		

;d3=0 add left;1 add right		
screen_addVerticalBlock:
		  moveq #0,d6
		  moveq #0,d1
		  moveq #0,d2
		  lea.l     screen_REPAIR,a2
		  move.w  virtualscreen_xPosition,d6
		  
		  move.w d6,d1
		  move.w d6,d2
		  and.w #%1111,d6
		  cmp.w #0,d6
		  beq.s .sc_done
		  cmp.w #4,d6
		  bne.s .sc_add8
		  add.l #(1*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a2
		  bra .sc_done	
.sc_add8:		  
		  cmp.w #8,d6
		  bne.s .sc_add12
		  add.l #(2*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a2
		  
		  bra .sc_done	
.sc_add12:		  
		  cmp.w #12,d6
		  bne.s .sc_done
		  add.l #(3*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a2

.sc_done:	
		  lsr #4,d1
		  lsl #3,d1
		  adda.l d1,a2                                                                          ; div 16 = 16 pixel width per block *2 =2 bytes per block

		  tst d3
		  beq .sc_skip
		  adda.l   #(((320-16)/16)*4*2),a2  ;right border		  
		  add.w #320-16,d2
.sc_skip:
		  lsr #4,d2
		  add.w d2,d2
		  
		  move.l     levelpointer,a3                                                                          ; find level row
		  adda.l    d2,a3
		  
		  moveq   #12-1,d7
.sv_loop:
		  moveq  #0,d0
		  lea.l     tiles,a0
		  move.w    (a3),d0
		  adda.l    d0,a0
		  
		  lea.l     tiles,a1
		  move.w    2(a3),d0
		  adda.l    d0,a1                                                                            ; add in tile position= tile line
		
		  bsr screen_addTile
		  
		  lea (screenBuffer_lineSize*16)(a2),a2 ; next tile line
		  lea (2*tile_no_x)(a3),a3

		  dbf d7,.sv_loop
		 rts

;aaaaaaaa bbbbbbbb

;-> aaab

;bbbb swap :bbbb0000
;aaaa -> bbbbaaaa
;rol  8		
;bbbaaaab

; aaab

;a0 left tile
;a1 right tile
;a2 destination on screen
;d6 number of shifts 0,4,8,12

screen_addTile:
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(a2)      ;Write the merged line 1 graphics into buffer
		
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,screenBuffer_lineSize(a2)      ;Write the merged line 1 graphics into buffer

		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*2)(a2)      ;Write the merged line 1 graphics into buffer

		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*3)(a2)      ;Write the merged line 1 graphics into buffer

		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*4)(a2)      ;Write the merged line 1 graphics into buffer

		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*5)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*6)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*7)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*8)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*9)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*10)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*11)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*12)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*13)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*14)(a2)      ;Write the merged line 1 graphics into buffer
		movem.w (a1)+,d0-d3     ;Read right tile line 1 graphics into d0-d3
        swap    d0              ;Bitplane 1 into high word
        swap    d1              ;Bitplane 2 into high word
        swap    d2              ;Bitplane 3 into high word
        swap    d3              ;Bitplane 4 into high word
        move.w  (a0)+,d0        ;Read left tile bitplane 1 graphics to low word of d0
        move.w  (a0)+,d1        ;Read left tile bitplane 2 graphics to low word of d1
        move.w  (a0)+,d2        ;Read left tile bitplane 3 graphics to low word of d2
        move.w  (a0)+,d3        ;Read left tile bitplane 4 graphics to low word of d3
        rol.l   d6,d0           ;Rotate bitplane 1 data to merge the tiles
        rol.l   d6,d1           ;Rotate bitplane 2 data to merge the tiles
        rol.l   d6,d2           ;Rotate bitplane 3 data to merge the tiles
        rol.l   d6,d3           ;Rotate bitplane 4 data to merge the tiles
        movem.w d0-d3,(screenBuffer_lineSize*15)(a2)      ;Write the merged line 1 graphics into buffer


		rts
		



