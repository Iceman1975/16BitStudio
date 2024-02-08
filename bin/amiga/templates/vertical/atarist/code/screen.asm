screen_scroll_speed_x         dc.w      0
screen_scroll_speed_y         dc.w      0


screen_waitVBlank2:
	move.w       #$25,-(sp)	;use XBIOS to wait for VBlank
	trap         #14
	addq.l       #2,sp
	rts

screen_waitVBlank:
    move.w  #37,-(sp)               ; wait vbl
    trap    #14
    addq.l  #2,sp 
	
	rts
	
screen_waitVBlank3:
    move.l  $462,d0               ; wait vbl
sc_wait:
	cmp.l $462,d0 
    beq  sc_wait
	
	rts
	
screen_init:	
	move.b #$00,$ff8260		;Screen Mode: 00=320x200 4 planes
	
    move.l #screen_mem1,d0  	;Move address to screen mem to d0
    add.l #$ff,d0      		;Add 255 d0 address
    clr.b d0           		;Clear lowest byte in address
    move.l d0,Screen_SHOW	;Save screen start
	
    lsr.w #8,d0       		;we need to convert $00ABCD?? into $00AB00CD
    move.l d0,$ff8200		;store the resulting 16 bits into the screen start register
							;&FF8201 = High byte
							;&FF8203 = Mid  byte
							;Low byte cannot be specified
							
    move.l #screen_mem2,d0  	;Move address to screen mem to d0
    add.l #$ff,d0      		;Add 255 d0 address
    clr.b d0           		;Clear lowest byte in address
    move.l d0,Screen_RENDER	;Save screen start	

	rts	
	
	
	
	ifd SCROLLING_MODE_HORIZONTAL
screen_initLevel:	
	jsr screen_initScreenByColumns
	jsr level_color0
	rts	
	else
screen_initLevel:	
	move.l #199,d6
screen_init_loop:	
	bsr       screen_scroll_up_internal	
    moveq     #0,d0
    moveq     #0,d3
	jsr        screen_addLineToAllScreens_internal	
	dbra      d6,screen_init_loop
	
	jsr level_color0
	rts
	endif
	
screen_swap:
			  ;move.w  #37,-(a7)               ; wait VBL
              ;trap    #14
              ;addq.l  #2,a7

			  lea.l     Screen_RENDER,a0
			  lea.l     Screen_SHOW,a5
			  move.l    (a0),d0                                                                           ;RENDER-> d0
			  move.l    (a5),(a0)                                                                         ;SHOW->RENDER
			  move.l    d0,(a5)                                                                           ;d0->SHOW
			  
			  move.l Screen_SHOW,d0 ;
			  
			 lsr.w #8,d0       		;we need to convert $00ABCD?? into $00AB00CD
    		 move.l d0,$ff8200		;store the resulting 16 bits into the screen start register
							;&FF8201 = High byte
							;&FF8203 = Mid  byte
							;Low byte cannot be specified

							
			  rts

	

							ifd SCROLLING_MODE_HORIZONTAL
screen_scroll:
                              move.l    player_current,a2 
                              move.w    (a2),d0
							  move.w    #0,screen_scroll_speed_x
                              cmp.w     #SCROLL_BOUNDERY_X1,d0
                              blt       .sc_checkleft		
							  move.w    virtualscreen_xPosition,d1
							  cmp.w     #SCROLL_X_MAX,d1
							  bge		.sc_checkleft
                              add.w  	#4,virtualscreen_xPosition
							  move.w    #-4,screen_scroll_speed_x
							  moveq     #1,d3
                              jsr       screen_addVerticalBlock
							  bra 		.sc_end
.sc_checkleft:
							  ifd       SCROLLING_ALLOW_BACK_FLAG
                              cmp.w     #SCROLL_BOUNDERY_X0,d0
                              bgt       .sc_end		
							  move.w    virtualscreen_xPosition,d1
							  cmp.w     #0,d1
							  ble		.sc_end
                              sub.w  	#4,virtualscreen_xPosition	
							  move.w    #4,screen_scroll_speed_x
							  moveq     #0,d3
                              jsr       screen_addVerticalBlock
							  endif
.sc_end:
							  rts
							else
screen_scroll:
                              ifd       SCROLLING_DYNAMIC_FLAG
                              move.l    player_current,a2 
                              move.w    2(a2),d0
                              cmp.w     #SCROLL_BOUNDERY_Y0,d0
                              bgt       .sc_checkDown		
                              bsr       screen_scroll_up_internal	
                              moveq     #0,d0
                              moveq     #0,d3
                              bsr       screen_addLineToAllScreens_internal	
                              bra       .sc_done

.sc_checkDown:                cmp.w     #SCROLL_BOUNDERY_Y1,d0
                              blt       .sc_skip	
                              ifd       SCROLLING_ALLOW_BACK_FLAG
                              move.w    virtualscreen_yPosition,d0
                              cmp.w     #VIRTUALSCREEN_YPOSITION_START-screen_height,d0                            ; still in level
                              bge       .sc_skip
                              bsr       screen_scroll_down_internal	
                              move.l    #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,d0
                              ;move.w    #screenBuffer_height+1,d3
							  move.l #screenBuffer_height,d3
                              bsr       screen_addLineToAllScreens_internal	
                              endif
                              bra       .sc_done
.sc_skip:
                              move.w    #0,screen_scroll_speed_y
.sc_done:
                              else
                              bsr       screen_scroll_up_internal	
                              moveq     #0,d0
                              moveq     #0,d3

                              bsr       screen_addLineToAllScreens_internal	
                              endif

.sc_end:                        
                              rts			
							  endif ;SCROLLING_MODE_HORIZONTAL
screen_scroll_up_internal:	
           move.w    #1,screen_scroll_speed_y

           lea.l     virtualscreen_yPosition,a0
           tst.w     (a0)                                                                       ; end reached?
           beq       .sc_mlp_done
                              
		  sub.w     #1,(a0)
		  lea.l     screenBuffer_linePointerOffset,a0
		  lea.l     screenBuffer_linePointerYPos,a1
		  sub.w     #screenBuffer_lineSize,(a0)
		  sub.w     #1,(a1)
		  cmp.w     #0,(a0)
		  bge       .sc_mlp_done
		  

		  move.w    #((screenBuffer_height*screenBuffer_width*4)/8)-((screenBuffer_width*4)/8),(a0)
		  move.w    #(screenBuffer_height)-1,(a1)
.sc_mlp_done:
                          
          rts			
			
screen_scroll_down_internal:	
                              move.w    #-1,screen_scroll_speed_y

                              lea.l     virtualscreen_yPosition,a0
                              add.w     #1,(a0)
                              lea.l     screenBuffer_linePointerOffset,a0
                              lea.l     screenBuffer_linePointerYPos,a1
                              add.w     #screenBuffer_lineSize,(a0)
                              add.w     #1,(a1)
                              cmp.w     #(screenBuffer_height*screenBuffer_lineSize)-(screenBuffer_lineSize),(a0)
                              ble       .sc_mlp_done
                              move.w    #0,(a0)
                              move.w    #0,(a1)
.sc_mlp_done:
            
                              rts
							  

;d0.l = buffer offset (e.g (screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize or 0)
;d3.w = y offset (0 or 200)							  
screen_addLineToAllScreens_internal:
 
	
		  lea.l     screenBuffer_linePointerOffset,a5
		  add.w    (a5),d0                                                                           ;load screen offset

          cmp.l     #(screenBuffer_height*screenBuffer_lineSize)-(screenBuffer_lineSize),d0
          ble       .sc_add_done
          sub.l     #(screenBuffer_height*screenBuffer_lineSize),d0

.sc_add_done:	
		  
		  lea.l     screen_REPAIR,a5
		  move.l    a5,d1
		  add.l     d0,d1                                                                             ; add offset to screen
		
		  move.l    d1,a1
		  	
		  lea.l     virtualscreen_yPosition,a5
		  
		  move.w    (a5),d0     
		  add.w     d3,d0
		  
		  lsr       #4,d0                                                                             ; div 16 = bock row
		  mulu      #2*tile_no_x,d0                                                                          ; mul row table size 
		
		  move.w    (a5),d2   
		  add.w     d3,d2		; don't forget to add again 		  
		  ; get offset in tiles
		  and.l     #%0000000000001111,d2
		  lsl       #3,d2                                                                             ; in words*bitplanes 2*4
		  
		  move.l     levelpointer,a5                                                                          ; find level row
		  adda.l    d0,a5
		
		  lea.l     tiles,a0
		  move.w    (a5),d0
		  adda.l    d0,a0
		  adda.l    d2,a0                                                                             ; add in tile position= tile line
		
		  moveq     #((screenBuffer_width/16)-1),d7	;(320)/16-1 ?
		   		   		   
sc_al1:
		  move.l    (a0)+,(a1)+
		  move.l    (a0)+,(a1)+

		  addq.l    #2,a5                                                                             ; next block in row
		  lea.l     tiles,a0
		  move.w    (a5),d0
		  adda.l    d0,a0
		  adda.l    d2,a0                                                                             ; add in tile position= tile line
		 	
		  dbra      d7,sc_al1
		  rts

		  
		  

		  
screen_restore:
		lea  Screen_REPAIR,a0
		ifd SCROLLING_MODE_HORIZONTAL
		  move.w #0,screenBuffer_linePointerOffset
		  move.w #0,screenBuffer_linePointerYPos  

		  move.w  virtualscreen_xPosition,d0
		  moveq #0,d1
		  move.w d0,d1
		  and.w #%1111,d0
		  cmp.w #0,d0
		  beq.s .sc_done
		  cmp.w #4,d0
		  bne.s .sc_add8
		  add.l #(1*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a0
		  bra .sc_done	
.sc_add8:		  
		  cmp.w #8,d0
		  bne.s .sc_add12
		  add.l #(2*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a0
		  bra .sc_done	
.sc_add12:		  
		  cmp.w #12,d0
		  bne.s .sc_add16
		  add.l #(3*(screenBuffer_size+SCROLL_BUFFER_SIZE)),a0
		  bra .sc_done
.sc_add16:
		  ;add.l #4,a0
.sc_done:
		lsr #4,d1
		lsl #3,d1
		adda.l d1,a0
		endif
		
		move.l Screen_RENDER,a1
		moveq #0,d0
		move.w screenBuffer_linePointerOffset,d0
		add.l  d0,a0
		move.w screenBuffer_linePointerYPos,d0
		cmp.w  #screenBuffer_height-1,d0
		beq    s_part2
		
		move.w  #screenBuffer_height-1,d0
		sub.w screenBuffer_linePointerYPos,d0
		
		cmp.w  #screenBuffer_height-1-FOOTER_HEIGHT,d0
		ble.s  s_line
		move.w #screenBuffer_height-1-FOOTER_HEIGHT,d0
s_line:

		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(A1),A1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d4
		movem.l d1-d4,(a1)
		lea 16(a1),a1

		dbra d0,s_line
		
		;lea -16(a1),a1		
		
s_part2:
		lea  Screen_REPAIR,a0
		move.w screenBuffer_linePointerYPos,d0
		;cmp.w  #0,d0
		;beq    s_done
		cmp.w  #FOOTER_HEIGHT,d0
		ble    s_done
		
		move.w screenBuffer_linePointerYPos,d0
		subq #1,d0
		subq #FOOTER_HEIGHT,d0
		
s_line2:
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(A1),A1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d4
		movem.l d1-d4,(a1)
		lea 16(a1),a1

		dbra d0,s_line2		
s_done:		
		rts
	

screen_copyFooterToScreen:
		move.l Screen_RENDER,a1
		moveq #0,d0
		move.w #screenBuffer_lineSize*(screenBuffer_height-FOOTER_HEIGHT),d0
		add.l  d0,a1

		move.l InGameScreen,a0
		move.w #FOOTER_HEIGHT-1,d0
.s_line:

		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(A1),A1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,(a1)
		lea 48(a1),a1
		movem.l (a0)+,d1-d4
		movem.l d1-d4,(a1)
		lea 16(a1),a1

		dbra d0,.s_line
		rts


		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=chunk(2*4)*2(width in words) =16*(width in words)
	
	
screen_copyBitmap:
		tst d1 ; check if y < 0
		bge .screen_skipTopClipping
		add.w d1,d3 ; add because d1<0
		
		neg d1
		
		add #1,d2 ; korrect width
		mulu d2,d1 ; clipHeight* widthInWords
		add.w d1,d1 ; in bytes
		adda.l d1,a1
		
		add.w d1,d1 
		add.w d1,d1 ;*4
		adda.l d1,a0
				
		sub #1,d2  ; go back to width-1
		moveq #0,d1

.screen_skipTopClipping		
		move.w d1,d5  ; load y
		add.w  d3,d5  ; add height-1
		sub.w  #screen_height-1,d5 ; sub screen_height -1 because of bitmap height-1
		ble    .screen_startDraw
		;move.w #$0007,$ff8240
		sub.w  d5,d3 ; do clipping
		ble    .screen_copy_done
		
.screen_startDraw:		

		move.l d2,d5 ; save value for loop
		move.l Screen_RENDER,a2
		mulu  #160,d1
		adda.l d1,a2
		
		;x
		; x/16*8 , r4,l3->x/2
		;move.l d0,d6
		and.w #$FFF0,d0
		lsr #1,d0
		adda.l d0,a2

.screen_copyloop:			
		
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen
		
		lea 2(a2),a2  ; next bitplane 1
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen		

		lea 2(a2),a2  ; next bitplane 2
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen	

		lea 2(a2),a2  ; next bitplane 3
		move.w  (a2),d4 ; read screen
		and.w  (a1)+,d4 ; cookie cut     +1 for next mask byte
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen		

		;adda.l d6,a2	; and back to bitplane 0	second byte	or next chunk
		;lea -5(a2),a2  ; and back to bitplane 0	second byte	
		lea 2(a2),a2  ; next word chunk
		
		dbra d2,.screen_copyloop
		
		;lea -16(a2),a2												;TODO chunk(2*4)*2(width) 
		suba.l  d6,a2   ; set pointer back to the beginning
		move.w  d5,d2  ; reload loop value
		
		adda.l #160,a2	; next line
		
		
		dbra d3,.screen_copyloop
.screen_copy_done:				
		rts
		



		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=((player width+1)/16  )*8 
	
;clipping Top: a0 + (clip-Height*width/8*4)
;   		   a1 + (clip-Height*width/8)
;clipping bottom: 
; 			  d3 - clipHeight
;clipping right:
;			  d2 - clipwidth/16
;			  d6 + ?

;clip_x  		dc.l 8
;clip_x_chunk0 	dc.l 1
;clip_x_chunk1 	dc.l 2

clip_x  			dc.l 0
clip_x_chunk0 		dc.l 0
clip_x_chunk1 		dc.l 0
clip_leftOffset 	dc.l 0
clip_leftOffsetMask dc.l 0

screen_copyBitmap_clip:
		adda.l clip_leftOffset,a0
		adda.l clip_leftOffsetMask,a1
		
		tst d1 ; check if y < 0
		bge .screen_skipTopClipping
		add.w d1,d3 ; add because d1<0
		
		neg d1
		
		add #1,d2 ; korrect width
		mulu d2,d1 ; clipHeight* widthInWords
		add.w d1,d1 ; in bytes
		adda.l d1,a1
		
		add.w d1,d1 
		add.w d1,d1 ;*4
		adda.l d1,a0
				
		sub #1,d2  ; go back to width-1
		moveq #0,d1

.screen_skipTopClipping			
		
	
		move.w d1,d5  ; load y
		add.w  d3,d5  ; add height-1
		sub.w  #screen_height,d5 ; sub screen_height
		ble    .screen_startDraw_clip
		;move.w #$0007,$ff8240
		sub.w  d5,d3 ; do clipping
		ble    .screen_copy_done_clip
		
.screen_startDraw_clip:		
		sub.l  clip_x_chunk0,d2 ; clipping test
		;subq #8,d2
		sub.l  clip_x,d6 ; clipping test
		
		

		move.l d2,d5 ; save value for loop
		move.l Screen_RENDER,a2
		mulu  #160,d1
		adda.l d1,a2
		
		;x
		; x/16*8 , r4,l3->x/2
		;move.l d0,d6
		and.w #$FFF0,d0
		lsr #1,d0
		adda.l d0,a2



.screen_copyloop_clip:			
		
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen
		
		lea 2(a2),a2  ; next bitplane 1
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen		

		lea 2(a2),a2  ; next bitplane 2
		move.w  (a2),d4 ; read screen
		and.w  (a1),d4 ; cookie cut
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen	

		lea 2(a2),a2  ; next bitplane 3
		move.w  (a2),d4 ; read screen
		and.w  (a1)+,d4 ; cookie cut     +1 for next mask byte
		or.w   (a0)+,d4  ; add bitmap
		move.w d4,(a2) ;write screen		

		;adda.l d6,a2	; and back to bitplane 0	second byte	or next chunk
		;lea -5(a2),a2  ; and back to bitplane 0	second byte	
		lea 2(a2),a2  ; next word chunk
		
		dbra d2,.screen_copyloop_clip
		
		;lea -16(a2),a2												;TODO chunk(2*4)*2(width) 
		suba.l  d6,a2   ; set pointer back to the beginning
		move.w  d5,d2  ; reload loop value
		
		adda.l #160,a2	; next line
		
		;clipping
		adda.l clip_x,a0
		adda.l clip_x_chunk1,a1
		
		dbra d3,.screen_copyloop_clip
.screen_copy_done_clip:				
		rts

		
screen_drawLives:
		lea.l      InGameScreen,a6
        move.l     16(a6),a3
		
		lea player_lives,a4

		;last
		move.l 8(a3),a0
		move.l 8(a3),a1
		
		move.w (a4),d0
		and.l #$f,d0
		mulu  14(a3),d0
		adda.l d0,a0
		adda.l d0,a1

		move.l     #STATS_LIVES_POS_X,d0
        move.l     #STATS_LIVES_POS_Y,d1
		btst #3,d0
		bne.s .sdl_no
		adda.w 12(a3),a0
		adda.w 12(a3),a1
.sdl_no:
		
		bsr screen_drawNumber
		
		rts
		
screen_drawScore:
		
		lea.l      InGameScreen,a6
		move.l     20(a6),a3
		lea player_score,a4

		;last
		move.l 8(a3),a0
		move.l 8(a3),a1
		
		move.w (a4),d0	
	
		;move.w #1,d0
			
		and.l #$f,d0
		mulu  14(a3),d0
		adda.l d0,a0
		adda.l d0,a1

		;move.l #320-18,d0
		move.l #STATS_SCORE_POS_X,d7
		move.l d7,d0
		
		btst #3,d0
		bne.s .sds_no0
		adda.w 12(a3),a0
		adda.w 12(a3),a1
.sds_no0:

		move.l #STATS_SCORE_POS_Y,d1
		bsr screen_drawNumber

		;last - 1
		
		move.l 8(a3),a0
		move.l 8(a3),a1
		
		move.w (a4),d0		
		lsr		#4,d0
		
		and.l #$f,d0
		mulu  14(a3),d0
		adda.l d0,a0
		adda.l d0,a1

		sub.w  6(a3),d7	;next pos; current x-font width
		move.l d7,d0
		
		btst #3,d0
		bne.s .sds_no1
		adda.w 12(a3),a0
		adda.w 12(a3),a1
.sds_no1:
		
		move.l #STATS_SCORE_POS_Y,d1
		bsr screen_drawNumber

		;last - 2
		
		move.l 8(a3),a0
		move.l 8(a3),a1
		
		move.w (a4),d0		
		lsr		#8,d0
		
		and.l #$f,d0
		mulu  14(a3),d0
		adda.l d0,a0
		adda.l d0,a1

		sub.w  6(a3),d7	;next pos; current x-font width
		move.l d7,d0
		
		btst #3,d0
		bne.s .sds_no2
		adda.w 12(a3),a0
		adda.w 12(a3),a1
.sds_no2:
		move.l #STATS_SCORE_POS_Y,d1
		bsr screen_drawNumber
		
		;last - 3
		
		move.l 8(a3),a0
		move.l 8(a3),a1
		
		move.w (a4),d0
		lsr		#8,d0
		lsr		#4,d0
				
		and.l #$f,d0
		mulu  14(a3),d0
		adda.l d0,a0
		adda.l d0,a1

		sub.w  6(a3),d7	;next pos; current x-font width
		move.l d7,d0
				
		btst #3,d0
		bne.s .sds_no3
		adda.w 12(a3),a0
		adda.w 12(a3),a1
.sds_no3:
		move.l #STATS_SCORE_POS_Y,d1
		bsr screen_drawNumber
		
		rts
		


		;x,y d0,d1
		;a3 pointer of font
		;a0 pointer to font bitmap
		;a1 pointer to font mask
screen_drawNumber:
		moveq #0,d2
		move.w 4(a3),d2
		adda.l d2,a1
		moveq #0,d2
		
		moveq  #0,d3
		move.w 6(a3),d3
		subq.w #1,d3	;height-1
		
	
		moveq #8,d6

		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=modulo = (virtualscreen_w-width)/8
		bsr screen_copyBitmap
		
		rts

		
		
		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
		; d2= width-1 (in words)
		; d3=height-1 	
		; d6=chunk(2*4)*2(width in words) 	
screen_drawObject

	
	;start clipping
	tst d0
	bge .pd_biggerZero
	
	moveq #0,d4
	move.w d0,d4
	add #screen_width,d0	
	
	
	;move.w  #-17,d4
	
	neg.w d4
		
	lsr #4,d4   ; div 16
	addq #1,d4	; +1 (at least 1 shift)
	
;clip_x  			dc.l 8
;clip_x_chunk0 		dc.l 1
;clip_x_chunk1 		dc.l 2
;clip_leftOffset 	dc.l 8
;clip_leftOffsetMask dc.l 2	

	;moveq #2,d4

	move.l d4,clip_x_chunk0
	add		d4,d4 ;*2
	move.l d4,clip_x_chunk1
	move.l d4,clip_leftOffsetMask
	
	add		d4,d4 ;
	add		d4,d4 ; *4
	
	move.l d4,clip_x
	move.l d4,clip_leftOffset
	
	
	move      d0,d4
	and.l     #$f,d4 				; online last 4 digits(0-15)
	lsl       #3,d4					;*8 (pointer table size)
	add.l     d4,a0		; add 0-16 pixel shift
	
	move.l 4(a0),a1		; set mask pointer
	move.l (a0),a0		; set image pointer
	
	moveq #0,d0

	jsr screen_copyBitmap_clip
	rts	
	
	
.pd_biggerZero:	
	add.w     4(a3),d0  ; add width
	;add.w     #32,d0
	
	cmp.w     #screen_width,d0
	blt  .pd_noClipping
	
	;move.w #$0007,$ff8240
	
	move.l #0,clip_leftOffset
	move.l #0,clip_leftOffsetMask
	
	moveq #0,d4
	move d0,d4
	;sub.w     4(a3),d0  ; sub width again, clean up
	sub.w #32,d0
	
	sub  #screen_width,d4
	
	lsr #4,d4   ; div 16
	addq #1,d4	; +1 (at least 1 shift)
	
	;debug
	;moveq #2,d4
	
	move.l d4,clip_x_chunk0
	add		d4,d4 ;*2
	move.l d4,clip_x_chunk1
	add		d4,d4 ;
	add		d4,d4 ; *4
	
	move.l d4,clip_x
	
	
	move      d0,d4
	and.l     #$f,d4 				; online last 4 digits(0-15)
	lsl       #3,d4					;*8 (pointer table size)
	add.l     d4,a0		; add 0-16 pixel shift
	
	move.l 4(a0),a1		; set mask pointer
	move.l (a0),a0		; set image pointer
	
	jsr screen_copyBitmap_clip
	rts			

.pd_noClipping:	
	;move.w #$0000,$ff8240
	sub.w     4(a3),d0  ; sub width again
	;sub.w     #32,d0  ; sub width again
	move      d0,d4
	and.l     #$f,d4 				; online last 4 digits(0-15)
	lsl       #3,d4					;*8 (pointer table size)
	add.l     d4,a0		; add 0-16 pixel shift
	
	move.l 4(a0),a1		; set mask pointer
	move.l (a0),a0		; set image pointer
	jsr screen_copyBitmap
	
	rts	
		
screenBuffer_linePointerOffset	dc.w screenBuffer_height*4*(screenBuffer_width/8)-((screenBuffer_width*4)/8)    
screenBuffer_linePointerYPos    dc.w screenBuffer_height-1


                                                      ;n*virtualscreen_width_Byte
virtualscreen_yPosition			dc.w VIRTUALSCREEN_YPOSITION_START

virtualscreen_xPosition			dc.w 0	
		
   ; SECTION BSS ;Block Started by Symbol - Data initialised to Zero
	
	
screen_mem1:			;Reserve screen memory 
    ds.b    32256
	
screen_mem2:			;Reserve screen memory 
    ds.b    32256
	

	ifd SCROLLING_MODE_HORIZONTAL
screen_REPAIR:			;Reserve screen memory 
	ds.b screenBuffer_size+SCROLL_BUFFER_SIZE
	ds.b screenBuffer_size+SCROLL_BUFFER_SIZE
	ds.b screenBuffer_size+SCROLL_BUFFER_SIZE
	ds.b screenBuffer_size+SCROLL_BUFFER_SIZE
	else
screen_REPAIR:			;Reserve screen memory 
	ds.b    screenBuffer_size
	endif
    
Screen_SHOW: ds.l 1
Screen_RENDER: ds.l 1				
		
