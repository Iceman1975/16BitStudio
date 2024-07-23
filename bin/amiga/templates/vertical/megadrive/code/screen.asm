

screen_waitVBlank:							
	move.w VDP_ctrl,d0			;Bit 3 defines if we're in Vblank
	and.w #%0000000000001000,d0		;See if vblank is running
	bne screen_waitVBlank					;wait until it is
		
.waitVBlank2:
	move.w VDP_ctrl,d0
	and.w #%0000000000001000,d0		;See if vblank is running
	beq .waitVBlank2					;wait until it isnt
	rts

	

; a0=pointer to colors
screen_setColors:
	;Define palette
	
	move.l #16,d1
	move.l #$C0000000,d0	;Color 0
PaletteAgain:
	
	move.l d0,(VDP_Ctrl)
	move.w (a0)+,(VDP_data)	;----BBB-GGG-RRR-
	add.l #$00020000,d0
	dbra d1,PaletteAgain
	rts
	
screen_setRed:
	;Define palette
	move.l #$00F,d1
	move.l #$C0000000,d0	;Color 0
	move.l d0,(VDP_Ctrl)
	move.w d1,(VDP_data)	;----BBB-GGG-RRR-
	rts


Screen_init:			;Set area (d0,d1) Wid:d2 Hei:D3
	moveq #0,d0
	moveq #0,d1
	moveq #40,d2
	moveq #20,d3
	moveq  #0,d4
	moveM.l d0-d7/a0-a7,-(sp)
		;lea level0,a0
		
		move.l #$40000003,d6	;C000 base (Scroll-A)
.FillAreaWithTilesAlt:
		clr.l d7
		
		subq.l #1,d3			;Reduce our counters by 1 for dbra
		subq.l #1,d2	
.NextTileLine:
		move.l d2,-(sp)			 ;Wid
			Move.L  d6,d5 		;offset + Vram command
			Move.L #0,d7
			Move.B d1,D7				
			
			rol.L #8,D7			;Calculate Ypos
			rol.L #8,D7
			rol.L #7,D7
			add.L D7,D5
			
			Move.B d0,D7		;Calculate Xpos
			rol.L #8,D7
			rol.L #8,D7
			rol.L #1,D7
			add.L D7,D5
		
			MOVE.L	D5,(VDP_ctrl);C00004 Get VRAM address
.NextTileb:		
			
			;move.w    (a0)+,d4
			 ;add.w  #256,d4
			MOVE.W	D4,(VDP_data);C00000 Select tile for mem loc
			addq.w #1,d4		 ;Increase Tilenum
			dbra d2,.NextTileb
			
			add.w #1,d1			 ;Move down a line
		move.l (sp)+,d2
		dbra d3,.NextTileLine	 ;Do next line
	moveM.l (sp)+,d0-d7/a0-a7
	rts

Screen_initLevel:			;Set area (d0,d1) Wid:d2 Hei:D3
	moveq #0,d0
	moveq #0,d1
	moveq #40,d2
	moveq #20,d3
	moveq  #0,d4
	moveM.l d0-d7/a0-a7,-(sp)
		lea level0,a0
		move.w virtualscreen_yPosition,d4
		lsr.w  #3,d4	; div by 8
		mulu.w #(tile_no_x)*2,d4	; TODO: tiles have to be double		
		add.l  d4,a0 ; pointer to first tile line		
		
		move.l #$40000003,d6	;C000 base (Scroll-A)
.FillAreaWithTilesAlt:
		clr.l d7
		
		subq.l #1,d3			;Reduce our counters by 1 for dbra
		subq.l #1,d2	
.NextTileLine:
		move.l d2,-(sp)			 ;Wid
			Move.L  d6,d5 		;offset + Vram command
			Move.L #0,d7
			Move.B d1,D7				
			
			rol.L #8,D7			;Calculate Ypos
			rol.L #8,D7
			rol.L #7,D7
			add.L D7,D5
			
			Move.B d0,D7		;Calculate Xpos
			rol.L #8,D7
			rol.L #8,D7
			rol.L #1,D7
			add.L D7,D5
		
			MOVE.L	D5,(VDP_ctrl);C00004 Get VRAM address
.NextTileb:		
			
			move.w    (a0)+,d4
			MOVE.W	D4,(VDP_data);C00000 Select tile for mem loc
			addq.w #1,d4		 ;Increase Tilenum
			dbra d2,.NextTileb
			
			add.w #1,d1			 ;Move down a line
		move.l (sp)+,d2
		dbra d3,.NextTileLine	 ;Do next line
	moveM.l (sp)+,d0-d7/a0-a7
	rts
	
screen_initSprite:
	lea player0_sprite,a0					;Source data
	;move.w #player_image_end-player_image_start,d1
	
	move.w #32*20,d1
	move.l #1*32,d2				;32 bytes per tile
	jsr screen_internal_DefineTiles	
	rts
	
	
	
screen_loadLevelTiles:

	move.l levelpointer,a1
	move.l 6(a1),a0
	;lea.l level_color0,a0
	bsr	screen_setColors
	

	lea allTiles,a0					;Source data
	move.w #(allTilesEnd-allTiles)/4,d1
	move.l #0,d2				;32 bytes per tile
	jsr screen_internal_DefineTiles	
	rts
	
screen_internal_DefineTiles:						;Copy D1 bytes of data from A0 to VDP memory D2 
	jsr screen_internal_prepareVram					;Calculate the memory location we want to write
.DefineTilesAgain:						; the tile pattern definitions to
		move.l (a0)+,d0				
		move.l d0,(VDP_data)		;Send the tile data to the VDP
		dbra d1,.DefineTilesAgain		
	rts


screen_drawAllObjects:
	
	bsr enemies_draw
	bsr bullets_draw
	bsr explosions_draw
	bsr extras_draw
	move.l d6,d0
	bsr player_drawPlayer
	rts

enemies_draw:                  
  moveq #0,d6
  cmp.l      #LIST_EMPTY_POINTER,enemy_active_list_start
  beq        e_draw_exit

  move.l     enemy_active_list_start,a0

	
e_draw_check
  cmp        #1,(a0)                                        ; enemy active?
  beq        e_draw_init                                    ; find active enemy
e_draw_next:
  bra        e_draw_skip                                    ; check next line

e_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  moveq #0,d0
  moveq #0,d1
  moveq #0,d2
  
  move.w d6,d0
  addq.w #1,d6
  
  move.w 48(a5),d4 ;size 8*8->32*32
  move.b d6,d4
  

  move.w  INSTANCE_X(a0),d1
  sub.w  virtualscreen_xPosition,d1
  add.l #128,d1 ; x
  
  move.w  INSTANCE_Y(a0),d2
  sub.w virtualscreen_yPosition,d2
  add.w #128,d2
  
  move.l     INSTANCE_BOB_POINTER(a0),d3
  sub.l    14(a5),d3
  
  add.w  18(a5),d3
  	;d0 = sprite number
	;d1 = x
	;d2 = y
	;d3 = tilePointer
	;d4 = h:size, l: pointer to next sprite

  
  bsr        screen_SetSprite

e_draw_skip:
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        e_draw_check 

e_draw_exit:
  rts
  

;*********** draw bullets *************
  
bullets_draw:
 cmp.l      #LIST_EMPTY_POINTER,bullet_active_list_start
  beq        b_draw_done
  move.l     bullet_active_list_start,a0

b_draw_check
  cmp        #1,(a0)                                         ; bullet active?
  beq        b_draw_init                                     ; find active bullet
b_draw_next:
  bra        b_draw_skip                                     ; check next line

b_draw_init:
  
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  moveq #0,d0
  moveq #0,d1
  moveq #0,d2
  
  move.w d6,d0
  addq.w #1,d6
  
  move.w 42(a5),d4 ;size 8*8->32*32
  ;test:
  ;move.w #$500,d4
  
  move.b d6,d4 

  move.w  INSTANCE_X(a0),d1
  sub.w  virtualscreen_xPosition,d1
  add.l #128,d1 ; x
  
  move.w  INSTANCE_Y(a0),d2
  sub.w virtualscreen_yPosition,d2
  add.w #128,d2
  
  move.l   INSTANCE_BOB_POINTER(a0),d3
  sub.l    12(a5),d3
  add.w  16(a5),d3
   
 ;move.w 16(a5),d3
  ;move.l #128,d1
  ;move.w #128,d2
  ;move.w  #510,d3
  	;d0 = sprite number
	;d1 = x
	;d2 = y
	;d3 = tilePointer
	;d4 = h:size, l: pointer to next sprite

  bsr        screen_SetSprite

b_draw_skip:	
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        b_draw_check 

b_draw_done:
	rts
 
;*********** draw bullets done ************* 


;*********** draw explosions *************
explosions_draw:  
  
  cmp.l      #LIST_EMPTY_POINTER,explosion_active_list_start
  beq        .ex_draw_exit

  move.l     explosion_active_list_start,a0

	
.ex_draw_check
  cmp        #1,(a0)                                            ; enemy active?
  beq        .ex_draw_init                                      ; find active enemy
.ex_draw_next:
  bra        .ex_draw_skip                                      ; check next line
 

.ex_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  moveq #0,d0
  moveq #0,d1
  moveq #0,d2
  
  move.w d6,d0
  addq.w #1,d6
  
  move.w 24(a5),d4 ;size 8*8->32*32 
  move.b d6,d4 

  move.w  INSTANCE_X(a0),d1
  sub.w  virtualscreen_xPosition,d1
  add.l #128,d1 ; x
  
  move.w  INSTANCE_Y(a0),d2
  sub.w virtualscreen_yPosition,d2
  add.w #128,d2
  
  move.l   INSTANCE_BOB_POINTER(a0),d3
  sub.l    8(a5),d3
  add.w  12(a5),d3
   

  	;d0 = sprite number
	;d1 = x
	;d2 = y
	;d3 = tilePointer
	;d4 = h:size, l: pointer to next sprite

  bsr        screen_SetSprite

.ex_draw_skip:	
   
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .ex_draw_check 

.ex_draw_exit:
  rts
;*********** draw explosions done ************
 
;********** draw extras **********************

extras_draw:

  cmp.l      #LIST_EMPTY_POINTER,extra_active_list_start
  beq        .extra_draw_exit

  move.l     extra_active_list_start,a0
 
.extra_draw_check
  cmp        #1,(a0)                                        ; extra active?
  beq        .ex_draw_init                                  ; find active extra
.extra_draw_next:
  bra        .extra_draw_skip                               ; check next line
 
.ex_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  moveq #0,d0
  moveq #0,d1
  moveq #0,d2
  
  move.w d6,d0
  addq.w #1,d6
  
  move.w 24(a5),d4 ;size 8*8->32*32 
  move.b d6,d4 

  move.w  INSTANCE_X(a0),d1
  sub.w  virtualscreen_xPosition,d1
  add.l #128,d1 ; x
  
  move.w  INSTANCE_Y(a0),d2
  sub.w virtualscreen_yPosition,d2
  add.w #128,d2
  
  move.l   INSTANCE_BOB_POINTER(a0),d3
  sub.l    8(a5),d3
  add.w  12(a5),d3
   

  	;d0 = sprite number
	;d1 = x
	;d2 = y
	;d3 = tilePointer
	;d4 = h:size, l: pointer to next sprite

  bsr        screen_SetSprite

.extra_draw_skip:	
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .extra_draw_check 

.extra_draw_exit:
  rts

;********** draw extras done *****************
 
player_drawPlayer:
	move.l player_current,a6

	move.l #128,d1 ; x
	add.w  (player_pos_x),d1

	move.l #128,d2 ; y
	add.w  (player_pos_y),d2

	move.w 14(a6),d3
	;move.l #710,d3
	add.w (player_animation_offset),d3
	move.l #$0F00,d4	;32*32 and last
	bsr screen_SetSprite
	rts
	
	;d0 = sprite number
	;d1 = x
	;d2 = y
	;d3 = tilePointer
	;d4 = h:size, l: pointer to next sprite

	
screen_SetSprite:	;D0=SpriteNumber, (D1,D2)=(X,Y) D3=Tilenum D4=Link to next sprite

		move.l d2,-(sp)
		move.l d0,d2
		rol.l #3,d2			;4 bytes per Sprite
		add.l #$D800,d2		;Base Sprite Address
		jsr screen_internal_prepareVram
		move.l (sp)+,d2
		
		move.w d2,(VDP_data)	; ------VV VVVVVVVV - Vpos
		move.w d4,(VDP_data)	; ----WWHH -LLLLLLL - Width, Height, Link (to next sprite)
		move.w d3,(VDP_data)	; PCCVHNNN NNNNNNNN - Priority, Color palette , Vflip, Hflip, tile Number
		move.w d1,(VDP_data)	; -------H HHHHHHHH - Hpos
		rts	
	

	
screen_internal_prepareVram:							;To select a memory location D2 we need to calculate 
										;the command byte... depending on the memory location
	moveM.l d0-d7/a0-a7,-(sp)			;$7FFF0003 = Vram $FFFF.... $40000000=Vram $0000
		move.l d2,d0
		and.w #%1100000000000000,d0		;Shift the top two bits to the far right 
		rol.w #2,d0
		
		and.l #%0011111111111111,d2	    ; shift all the other bits left two bytes
		rol.l #8,d2		
		rol.l #8,d2
		
		or.l d0,d2						
		or.l #$40000000,d2				;Set the second bit from the top to 1
										;#%01000000 00000000 00000000 00000000
		move.l d2,(VDP_ctrl)
	moveM.l (sp)+,d0-d7/a0-a7
	rts
	
	
	
screen_scroll:
                              ifd        SCROLLING_DYNAMIC_FLAG
                              move.w     player_pos_y,d0
                              cmp.w      #SCROLL_BOUNDERY_Y0,d0
                              bgt        .sc_checkDown		
                              bsr        screen_scroll_up_internal	
                              moveq      #0,d0
                              moveq      #0,d3
                              bsr        screen_addLineToAllScreens_internal	
                              bra        .sc_done

.sc_checkDown:                cmp.w      #SCROLL_BOUNDERY_Y1,d0
                              blt        .sc_skip	
                              ifd        SCROLLING_ALLOW_BACK_FLAG
                              move.w     virtualscreen_yPosition,d0
                              cmp.w      #VIRTUALSCREEN_YPOSITION_START-screen_height,d0                            ; still in level
                              bge        .sc_skip
                              bsr        screen_scroll_down_internal	
                              move.l     #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,d0
                              move.w     #screenBuffer_height,d3
                              bsr        screen_addLineToAllScreens_internal	
                              endif
                              bra        .sc_done
.sc_skip:
                              ;move.w     #0,screen_scroll_speed_y
.sc_done:
                              else
                              bsr        screen_scroll_up_internal	
                              moveq      #0,d0
                              moveq      #0,d3

                              bsr        screen_addLineToAllScreens_internal	
                              endif

                              ifd        SCROLLING_HORIZONTAL_FLAG
                              
                              lea        virtualscreen_xPosition,a0
                              move.w     player_pos_x,d0                                                                    ; player x pos
                              cmp.w      #SCROLL_BOUNDERY_X0,d0
                              bgt        .sc_checkRight

                              tst.w      (a0)
                              ble        .sc_checkRight
                              sub.w      #1,(a0)
                              bra.s      .sc_end
.sc_checkRight:            
                              cmp.w      #SCROLL_BOUNDERY_X1,d0
                              blt        .sc_end

                              cmp.w      #SCROLL_X_MAX,(a0)
                              bge        .sc_end
                              add.w      #1,(a0)
                              
                              endif 
.sc_end:                        
                              rts

							  
screen_scroll_up_internal:	
                              ;move.w     #1,screen_scroll_speed_y

                              lea.l      virtualscreen_yPosition,a0
                              tst.w      (a0)                                                                       ; end reached?
                              beq        sc_mlp_done
                              
                              sub.w      #1,(a0)
                              lea.l      screen_line,a0
                              sub.w      #1,(a0)
                              cmp.l      #0,(a0)
                              bge        sc_mlp_done
                              move.w     #(32*8)-1,(a0)
sc_mlp_done:

                              move.w  screen_line,d0
							  move.l #$40000010,d1		;$00=Ypos A	$02=Ypos B
							  move.l d1,(VDP_Ctrl)
							  move.w d0,(VDP_data)		;Send the tile data to the VDP
                              rts
			

screen_scroll_down_internal:	
                              ;move.w     #-1,screen_scroll_speed_y

                              lea.l      virtualscreen_yPosition,a0
                              add.w      #1,(a0)
                              ;lea.l      screen_buffer_StartYOffset,a0
                              ;lea.l      screenBuffer_linePointerYPos,a1
                              ;add.l      #screenBuffer_lineSize,(a0)
                              add.w      #1,(a1)
                              cmp.l      #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,(a0)
                              ble        .sc_mlp_done
                              move.l     #0,(a0)
                              move.w     #0,(a1)
.sc_mlp_done:
                              move.w     #screenBuffer_height,d0                                                    ; same?
                              sub.w      (a1),d0
                              add.w      #(44),d0
                              ;lea.l      screenBottomWait,a0
                              move.w     d0,(a0)
.sc_mlp_done2:                
                              rts				
							
							

						
screen_addLineToAllScreens_internal:			;Set area (d0,d1) Wid:d2 Hei:D3
			moveM.l d0-d7/a0-a7,-(sp)
			lea level0,a0
		
			move.w virtualscreen_yPosition,d4
			lsr.w  #3,d4	; div by 8
			mulu.w #(tile_no_x)*2,d4	; TODO: tiles have to be double		
			add.l  d4,a0 ; pointer to first tile line
		
			move.l #$40000003,d5	;C000 base (Scroll-A)
		
			move.w screen_line,d1	;SY
			lsr.w  #3,d1
		
			moveq #0,d7
			moveq  #0,d0
			moveq  #(tile_no_x),d2

			Move.B d1,D7			;Calculate Ypos		
			swap d7
			rol.L #7,D7
			add.L D7,D5
			
			Move.B d0,D7		;Calculate Xpos			
			swap d7
			rol.L #1,D7
			add.L D7,D5
		
			MOVE.L	D5,(VDP_ctrl);C00004 Get VRAM address
.NextTileb:		
			
			move.w    (a0)+,d4
			MOVE.W	D4,(VDP_data);C00000 Select tile for mem loc
			dbra d2,.NextTileb
			
			moveM.l (sp)+,d0-d7/a0-a7
			rts
			
allTiles:
	include "data/SEGA_tiles.asm"
	include "data/SEGA_enemies_imageData.asm"
	include "data/SEGA_bullets_imageData.asm"
	include "data/SEGA_explosions_imageData.asm"
	include "data/SEGA_extras_imageData.asm"

	include "data/SEGA_player_imageData.asm"
	include "data/SEGA_pots_imageData.asm"
allTilesEnd:
	even


