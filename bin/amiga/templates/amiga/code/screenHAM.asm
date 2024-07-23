screen_scroll_speed_x         dc.w       0
screen_scroll_speed_y         dc.w       0

                                                                      ;PLAYER_LIVES_INITAL


screen_waitVBlank:
wait:              ; wait until at beam line 0
                              move.l     $dff004,d0                                                                 ; read VPOSR and VHPOSR into d0 as one long word
                              and.l      #$000fff00,d0
                              cmp.l      #$00011000,d0
                              bne.s      wait                                                                       ; if not equal jump to wait
                              rts


screen_waitVBlank2:				;wait for end of frame
                              lea        $dff000,a6
                              bsr        WaitBlitter
                              move.w     #312,d0
WaitRaster:				;Wait for scanline d0. Trashes d1.
.l:                           move.l     VPOSR(a6),d1
                              lsr.l      #1,d1
                              lsr.w      #7,d1
                              cmp.w      d0,d1
                              bne.s      .l                                                                         ;wait until it matches (eq)
                              ; 16 colors mode for screens
                              move.w     #$4200,copper_screen_mode+2
                              
                              rts

WaitBlitter:				;wait until blitter is finished
                              tst.w      (a6)                                                                       ;for compatibility with A1000
.loop:                        btst       #6,2(a6)
                              bne.s      .loop
                              rts


screen_init:	
                              lea.l      copper,a1                                                                  ; put copper address into a1
                              move.l     a1,$dff080                                                                 ; COP1LCH (also sets COP1LCL)
                              move.w     $dff088,d0                                                                 ; COPJMP1 
                              move.w     #$81a0,$dff096                                                             ; DMACON set bitplane, copper, sprite
                              bsr        screen_setSpriteColors
                              rts	
	

linecount                     dc.w       0

screen_initLevel:	
                              move.w     #$6A00,copper_screen_mode+2
                              move.w     #screenBuffer_height,linecount
screen_init_loop:	
                              bsr        screen_scroll_up_internal	
                              moveq      #0,d0
                              moveq      #0,d3
                              bsr        screen_addLineToAllScreens_internal	
                              sub.w      #1,linecount
                              move.w     linecount,d6
                              cmp.w      #0,d6
                              bne.s      screen_init_loop
	
                              lea        level_color0,a0
                              bsr        screen_setColors
                              rts

screen_swap:
                              lea.l      Screen_RENDER,a0
                              lea.l      Screen_SHOW,a5
                              move.l     (a0),d0                                                                    ;RENDER-> d0
                              move.l     (a5),(a0)                                                                  ;SHOW->RENDER
                              move.l     d0,(a5)   

                              lea.l      Screen_SHOW,a0
                              
                              move.l     (a0),d0                                                                    ;RENDER-> d0
                              lea        copper_screen,a0
                              moveq      #(screen_colorDepth-1),d7                                                  ; only 4 bitplanes here
ss1:
                              move       d0,6(a0) 
                              swap       d0 
                              move       d0,2(a0) 
                              swap       d0 
                              add.l      #screenBuffer_width_Byte,d0 
                              addq.l     #8,a0 

                              dbf        d7,ss1

                              lea        copperSlot,a0                                                              ; reset copper
                                                                             
                              move.l     $ffdffffe,(a0)+                                                            ; wait($df,$ff) enables waits > $ff vertical
                              move.l     $2c01fffe,(a0)+                                                            ; wait($01,$12c) - $2c is $12c
                              move.l     $01000200,(a0)+                                                            ; BPLCON0 unset bitplanes, enable color burst; needed to support older PAL chips						
                              move.l     $fffffffe,(a0)+  
                              rts


screen_scroll:
                              ifd        SCROLLING_DYNAMIC_FLAG
                              move.l     player_current,a2 
                              move.w     2(a2),d0
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
                              move.w     #0,screen_scroll_speed_y
.sc_done:
                              else
                              bsr        screen_scroll_up_internal	
                              moveq      #0,d0
                              moveq      #0,d3

                              bsr        screen_addLineToAllScreens_internal	
                              endif

                              ifd        SCROLLING_HORIZONTAL_FLAG
                              
                              lea        virtualscreen_xPosition,a0
                              move.l     player_current,a2 
                              move.w     (a2),d0                                                                    ; player x pos
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
                              move.w     #1,screen_scroll_speed_y

                              lea.l      virtualscreen_yPosition,a0
                              tst.w      (a0)                                                                       ; end reached?
                              beq        sc_mlp_done2
                              
                              sub.w      #1,(a0)
                              lea.l      screen_buffer_StartYOffset,a0
                              lea.l      screenBuffer_linePointerYPos,a1
                              sub.l      #screenBuffer_lineSize,(a0)
                              sub.w      #1,(a1)
                              cmp.l      #0,(a0)
                              bge        sc_mlp_done
                              move.l     #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,(a0)
                              move.w     #(screenBuffer_height)-1,(a1)
sc_mlp_done:
                              move.w     #screenBuffer_height,d0
                              sub.w      (a1),d0
                              ;add.w     #(44-32-1),d0
                              add.w      #(44),d0
                              lea.l      screenBottomWait,a0
                              move.w     d0,(a0)
sc_mlp_done2:
                              
                              rts
			

screen_scroll_down_internal:	
                              move.w     #-1,screen_scroll_speed_y

                              lea.l      virtualscreen_yPosition,a0
                              add.w      #1,(a0)
                              lea.l      screen_buffer_StartYOffset,a0
                              lea.l      screenBuffer_linePointerYPos,a1
                              add.l      #screenBuffer_lineSize,(a0)
                              add.w      #1,(a1)
                              cmp.l      #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,(a0)
                              ble        .sc_mlp_done
                              move.l     #0,(a0)
                              move.w     #0,(a1)
.sc_mlp_done:
                              move.w     #screenBuffer_height,d0                                                    ; same?
                              sub.w      (a1),d0
                              add.w      #(44),d0
                              lea.l      screenBottomWait,a0
                              move.w     d0,(a0)
.sc_mlp_done2:                
                              rts
			
;d0.l = buffer offset (e.g (screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize or 0)
;d3.w = y offset (0 or 255)
screen_addLineToAllScreens_internal:  
                              ;moveq     #0,d0
                              move.l     d0,d4
                              lea.l      screen_buffer_StartYOffset,a5
                              add.l      (a5),d0                                                                    ;load screen offset
                                      
                              cmp.l      #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,d0
                              ble        .sc_add_done
                              sub.l      #(screenBuffer_height*screenBuffer_lineSize),d0
                              sub.l      #(screenBuffer_height*screenBuffer_lineSize),d4

.sc_add_done:
                              lea.l      Screen_RENDER,a5
                              move.l     (a5),d1
                              add.l      d0,d1                                                                      ; add offset to screen

                              move.l     d1,a1
                              move.l     d1,a2
                              move.l     d1,a3
                              move.l     d1,a4
                              adda.l     #screenBuffer_width_Byte,a2                                                ; add bitplane offset
                              adda.l     #(2*screenBuffer_width_Byte),a3
                              adda.l     #(3*screenBuffer_width_Byte),a4


                              lea.l      virtualscreen_yPosition,a5
		  
                              move.w     (a5),d0    
                              add.w      d3,d0

                              lsr        #5,d0                                                                      ; div 32 = bock row
                              mulu       #4*tile_no_x,d0                                                            ; mul row table size 

                              move.w     (a5),d2                                                                    ; get offset in tiles
                              and.l      #%0000000000011111,d2
                              ;lsl        #3,d2                                                                      ; in words*bitplanes 2*4
                              mulu       #(6*4),d2
		  ;moveq     #8*2*4,d2

                              move.l     levelpointer,a5                                                            ; find level row
                              adda.l     d0,a5

                              lea.l      tiles,a0
                              move.l     (a5),d0                                                                    ;xxx for HAM it is 32 instead of 16 .w->.l
                              adda.l     d0,a0
                              adda.l     d2,a0                                                                      ; add in tile position= tile line


                              moveq      #(tile_no_x-1),d7

sc_al1:
                              
                              move.l     (a0)+,(a1)+
                              move.l     (a0)+,(a2)+
                              move.l     (a0)+,(a3)+                                  
                              move.l     (a0)+,(a4)+
                              move.l     (a0)+,(screenBuffer_width_Byte-4)(a4)
                              move.l     (a0)+,((2*screenBuffer_width_Byte)-4)(a4)
                              
                              addq.l     #4,a5                                                                      ; next block in row
                              lea.l      tiles,a0
                              move.l     (a5),d0
                              adda.l     d0,a0
                              adda.l     d2,a0                                                                      ; add in tile position= tile line
			
                              dbra       d7,sc_al1
                              

sc_addLineToAllScreens:
                              moveq      #0,d0
                              lea.l      screen_buffer_StartYOffset,a5
                              move.l     (a5),d0                                                                    ;load screen offset
                              add.l      d4,d0

                          
                              lea.l      Screen_RENDER,a5
                              move.l     (a5),a0
                              adda.l     d0,a0
                              lea.l      Screen_SHOW,a5
                              move.l     (a5),a1  
                              adda.l     d0,a1
                              lea.l      screen_REPAIR,a2
                              adda.l     d0,a2

                              moveq      #(screenBuffer_lineSize/4)-1,d7
                              

sc_aL2AC:
                              move.l     (a0),(a1)+
                              move.l     (a0)+,(a2)+
                              dbra       d7,sc_aL2AC

                              rts


screen_swap2:
                              lea.l      Screen_RENDER,a0
                              lea.l      Screen_SHOW,a5
                              move.l     (a0),d0                                                                    ;RENDER-> d0
                              move.l     (a5),(a0)                                                                  ;SHOW->RENDER
                              move.l     d0,(a5)   

	  
screen_setScreenViewTop
                              moveq      #0,d1
                              lea.l      screen_buffer_StartYOffset,a0
                              move.l     (a0),d1
                              cmp.l      #(screenBuffer_height*screenBuffer_lineSize)-screenBuffer_lineSize,d1
                              ble        screen_sSVT
screen_sSVT:

                              lea.l      virtualscreen_xPosition,a1                                                 ;X Pos
                              move       (a1),d2                                                                    ; X Position of screen 
                              add        #$f,d2                                                                     ; d2 = X+15
                              moveq      #-1,d3	 
                              sub.b      d2,d3                                                                      ; d3 = -1-(X+15)
                              and.b      #$f,d3                                                                     ; d3 = (-1-(X+15))&15 = BPLC0N1
                              move.b     d3,copper_scroll+3
                              lsl.b      #4,d3
                              or.b       d3,copper_scroll+3	

                              lsr.w      #4,d2
                              add.w      d2,d2

                              lea.l      Screen_SHOW,a0
                              move.l     (a0),d0 
                              add.l      d1,d0				
                              add.l      d2,d0	

                              lea        copper_screen,a0
                              moveq      #screen_colorDepth-1,d7                                                    ; only 4 bitplanes here
screen_sSVT_1:
                              move       d0,6(a0) 
                              swap       d0 
                              move       d0,2(a0) 
                              swap       d0 
                              add.l      #screenBuffer_width_Byte,d0 
                              addq.l     #8,a0 

                              dbf        d7,screen_sSVT_1  

                              bsr        sprites_updateCopperList
                              bsr        screen_addCopperListEnd
                              rts
	  
	  

; a1 copper slot pointer (use a3,a4,d6)
; d6 wait vert

screen_addScreenBottomToCopperList:
                              ifd        FOOTER_ENABLED
                              cmp.w      #244,d6                                                                    ; 244 is hack
                              bge        s_aSB2CLi_done 
                              endif
															; set vert wait
                              cmp.w      #$ff,d6
                              ble        s_aSB2CLi_wait
                              move.l     #$ffe1fffe,(a1)+                                                           ; ok,we are below $FF second wait necessary
s_aSB2CLi_wait:  

                              move.l     #$ff01ff00,(a1)+ 
                              move.b     d6,-4(a1)

                              moveq      #0,d6 
                              move.w     virtualscreen_xPosition,d6
                              add        #$f,d6
                              lsr.w      #4,d6  

                              add.w      d6,d6  
  
s_aSB2CLi_pointer:
     
                              ;move.l    #$0180000F,(a1)+                                                           ;copper wait
                              lea.l      Screen_SHOW,a3
	  
                              add.l      (a3),d6
                              	  
                              swap       d6
                              move.w     #BPL1PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL1PTL,(a1)+
                              move.w     d6,(a1)+
                              add.l      #screenBuffer_width_Byte,d6

                              swap       d6	
                              move.w     #BPL2PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL2PTL,(a1)+
                              move.w     d6,(a1)+
                              add.l      #screenBuffer_width_Byte,d6

                              swap       d6
                              move.w     #BPL3PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL3PTL,(a1)+
                              move.w     d6,(a1)+
                              add.l      #screenBuffer_width_Byte,d6

                              swap       d6
                              move.w     #BPL4PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL4PTL,(a1)+
                              move.w     d6,(a1)+
                              add.l      #screenBuffer_width_Byte,d6

                              swap       d6
                              move.w     #BPL5PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL5PTL,(a1)+
                              move.w     d6,(a1)+
                              add.l      #screenBuffer_width_Byte,d6

                              swap       d6
                              move.w     #BPL6PTH,(a1)+
                              move.w     d6,(a1)+
                              swap       d6
                              move.w     #BPL6PTL,(a1)+
                              move.w     d6,(a1)+

                              move.w     #$102,(a1)+
                              move.w     copper_scroll+2,(a1)+
                              moveq      #-1,d6
s_aSB2CLi_done:          
                              rts

screen_addCopperListEnd:
                              ifnd       FOOTER_ENABLED
                              lea        copper_end,a0
                              endif

                              ifd        FOOTER_ENABLED
                              lea        cooper_footer_pointer,a0
                              endif

                              move.l     a0,d0
                              move.w     #COP2LCL,(a1)+
                              move.w     d0,(a1)+
                              move.w     #COP2LCH,(a1)+
                              swap       d0
                              move.w     d0,(a1)+
                              move.w     #COPJMP2,(a1)+
                              move.w     #0,(a1)+
                              rts






screen_restore2:
                              move.l     Screen_RENDER,a0
                              lea        screen_REPAIR,a1
                              move.l     #(screenBuffer_width_Byte*screenBuffer_height),d7
.sr_loop:
                              move.l     (a1)+,(a0)+
                              dbf        d7,.sr_loop

                              rts
	  
;***************  screen restore ****************************************
screen_restore:
                              move.l     Screen_RENDER,d1
                              lea.l      screen_restore_list,a0
sr_next:                      move.w     (a0),d0
                              cmp.w      #1,d0                                                                      ; restore entry?                                                   
                              beq        sr_restore
                              cmp.w      #-1,d0                                                                     ; last entry?
                              beq        sr_restore_done
sr_next2                              
                              adda.l     #SCREEN_RESTORE_LIST_ENTRY_SIZE,a0
                              bra        sr_next

sr_restore:                   cmp.l      2(a0),d1                                                                   ; restore image in this frame?
                              bne        sr_next2                                                                   ; no


sr_restore_init_blitter
                              btst       #14,$dff002
                              bne.s      sr_restore_init_blitter
                              ;bne.s      sr_restoreByCPU
	
                              move       12(a0),$dff062                                                             ; set modulo                                                     ;B          ;TODO hardcoded                              
                              move       12(a0),$dff066                                                             ; set modulo                                         ;D                               
                              
                              move.l     #%00000101110011000000000000000000,$dff040
	
                              move.l     Screen_RENDER,a2
                              lea        screen_REPAIR,a3

                              adda.l     6(a0),a2                                                                   ; add offset to destination                              
                              adda.l     6(a0),a3                                                                   ; add offset to source

                              

sr_waitblit_4
                              btst       #14,$dff002
                              bne.s      sr_waitblit_4
	
                              move.l     a3,$dff04c                                                                 ;B
                              move.l     a2,$dff054                                                                 ;D                              
                              move       10(a0),$dff058                                                             ; set blitsize and blit
                              move.w     #0,(a0)                                                                    ; restore done                            
sr_restore_copy_done:                              
                              bra        sr_next2
sr_restore_done:
                              rts
	
sr_restoreByCPU:
                              move.l     Screen_RENDER,a2
                              lea.l      screen_REPAIR,a3
                              moveq      #0,d5
                              moveq      #0,d7
                              moveq      #0,d6
                              adda.l     6(a0),a2                                                                   ; add offset to destination                              
                              adda.l     6(a0),a3                                                                   ; add offset to source

                              move       10(a0),d7
                              lsr        #6,d7
                              sub.w      #1,d7

                              move       10(a0),d6
                              and.w      #%11111,d6
                              sub.w      #1,d6
                              move.w     d6,d5

ssr_copy
                              move.w     (a3)+,(a2)+
                              dbf        d5,ssr_copy
                              move.w     d6,d5
                              
                              adda.l     12(a0),a2                                                                  ; add modulo to destination                              
                              adda.l     12(a0),a3                                                                  ; add modulo to source
                              dbf        d7,ssr_copy

                              move.w     #0,(a0)                                                                    ; restore done  
                              bra        sr_restore_copy_done

;***************  screen restore end ************************************

		; a0 pointer to bitmap
		; a1 pointer to bitmap mask
		; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo


screen_copyBitmap:
                              lea.l      screen_restore_list,a6                   
  

	
.bitmap_draw_init_blitter
                              btst       #14,$dff002
                              bne.s      .bitmap_draw_init_blitter
	
                              move       #-2,$dff064                                                                ;A Modulo
                              move       #-2,$dff062                                                                ;B Modulo

                              clr        $dff042
                              move.l     #$ffff0000,$dff044
	
 
.bitmap_draw_nextbullet: 
                              tst.w      (a6)                                                                       ; first: search for empty restore slot
                              beq        .bitmap_restore_slot
                              adda.l     #SCREEN_RESTORE_LIST_ENTRY_SIZE,a6
                              bra        .bitmap_draw_nextbullet
.bitmap_restore_slot:   

	
                              move.l     Screen_RENDER,a2                     
                              move.w     d5,d4                                                                      ; load blitsize

                   
                              add        screenBuffer_linePointerYPos,d1

                              cmp.w      #0,d1                                                                      ; out of screen buffer?
                              bgt        .bitmap_draw_correct_y_skip
                              add.w      #(screenBuffer_height-1),d1                                                ; yes, move to bottom

.bitmap_draw_correct_y_skip:                

                              cmp.w      #(screenBuffer_height-1),d1
                              ble        .bitmap_draw_no_top_correction
                    
                              sub.w      #(screenBuffer_height),d1                                                  ; completly ouside
                              bra        .bitmap_draw_correction_done                                               ; no more correction necessary
                    
.bitmap_draw_no_top_correction:
                              add.w      d6,d1                                                                      ; add height
                              move.l     #(screenBuffer_height),d3
                              cmp.w      d3,d1
                              ble        .bitmap_draw_no_half_correction
                    ;oh blit is outside of screen buffer, reduce height
                              sub.w      d1,d3
                              neg.w      d3
                              lsl        #8,d3                                                                      ; *64 *4 (4 bitplanes)
                              sub        d3,d4                                                                      ; set new height
.bitmap_draw_no_half_correction:
                              sub.w      d6,d1                                                                      ; sub height

.bitmap_draw_correction_done:
                              mulu       #screenBuffer_lineSize,d1                                                  ; calculate y offset

                    ; store all in restore list
                              move.w     #1,(a6)
                              move.l     Screen_RENDER,2(a6)
                              move.l     d1,6(a6)
                              move.w     d7,12(a6)                                                                  ; save modulo
                              move.w     d4,10(a6)                                                                  ; save blisize
                    ; save restore data done

                              add.l      d1,a2                                                                      ; add to address
                              move.l     d0,d1 
                              lsr        #3,d0 
                              add.l      d0,a2                                                                      ; add x offset
                              add.l      d0,6(a6)                                                                   ; add also to restore value

                              ror        #4,d1 
                              and        #$f000,d1 
	
.bitmap_waitblit_1
                              btst       #14,$dff002
                              bne.s      .bitmap_waitblit_1


                              move       d7,$dff060                                                                 ;C Address TODO BULLET_WIDTH_BLITTER was replaced by static 32 and 16 for the blitter
                              move       d7,$dff066                                                                 ;D Address
                              move       d1,$dff042 
                              or         #%0000111111001010,d1 
                              move       d1,$dff040 

.bitmap_waitblit_2
                              btst       #14,$dff002
                              bne.s      .bitmap_waitblit_2
	
                              move.l     a1,$dff050                                                                 ;A=Maske
                              move.l     a0,$dff04c                                                                 ;B=Source
                              move.l     a2,$dff048                                                                 ;C=Dest read
                              move.l     a2,$dff054                                                                 ;D=Dest write
                    ;blisize (bitplanes*height*64)+((width_in_pixel+16)/16)
                    ;move      #((3*25*64)+((32+16)/16)),$dff058
                              move       d4,$dff058

                              cmp.w      d5,d4
                    ;debug
                    ;bra       e_draw_skip
                              beq        .bitmap_draw_skip                                                          ; done with this enemy

.bitmap_draw_findRestoreSlot: 
                              tst.w      (a6)                                                                       ; first: search for empty restore slot
                              beq        .bitmap_restore_slot_found
                              adda.l     #SCREEN_RESTORE_LIST_ENTRY_SIZE,a6
                              bra        .bitmap_draw_findRestoreSlot
.bitmap_restore_slot_found:
                              move.w     #1,(a6)
                              move.l     Screen_RENDER,2(a6)

.bitmap_waitblit_3         


                              btst       #14,$dff002                                                                ; we have to draw the rest
                              bne.s      .bitmap_waitblit_3                   
                              move.l     Screen_RENDER,a2
                              add        d0,a2

                              move.l     d0,6(a6)                                                                   ; save offset for restore
                                                                    ; a1,a0 are increased by Blitter
                              move.l     a2,$dff048                                                                 ;C=Dest read
                              move.l     a2,$dff054                                                                 ;D=Dest write

                              ;test
                              ;move.l     #4098,d5
                              ;test done
                              move.w     d5,d4  
                              and.w      #$3F,d4                                                                    ; remove old height                      
                              add.w      d3,d4                                                                      ; only the rest height
                              move       d4,$dff058              

                              move.w     d7,12(a6)                                                                  ; save modulo
                              move.w     d4,10(a6)                                                                  ; save blisize for restore
.bitmap_draw_skip:	


.bitmap_draw_exit:                              
                              rts

 
screen_drawLives:
                              lea        player_lives,a4
                              move.w     (a4),d0

                              ifd        FOOTER_ENABLED
                              cmp.w      player_lives_old,d0
                              bne.s      .sc_dS_start
                              rts
.sc_dS_start:                  
                              move.w     d0,player_lives_old                               
                              endif 

                              lea.l      InGameScreen,a6
                              move.l     16(a6),a3
                              lea        player_lives,a4

		;last
                              move.l     8(a3),a0
                              move.l     8(a3),a1
		
                              
                              and.l      #$f,d0

                              move.w     4(a3),d1
                              lsl.w      d1,d0

                              adda.l     d0,a0                                                                      ; pointer to mask
                              add.w      16(a3),d0
                              adda.l     d0,a1

                              move.l     #STATS_LIVES_POS_X,d0
                              move.l     #STATS_LIVES_POS_Y,d1
                              move.w     12(a3),d5
                              move.w     14(a3),d7   
                              move.w     6(a3),d6                                

    ; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo
                              ifd        FOOTER_ENABLED                             
                              move.w     26(a6),d7 
                              bsr        screen_copyBitmapToFooter
                              else
                              bsr        screen_copyBitmap
                              endif
		
                              rts


                              ifd        FOOTER_ENABLED
;***** copy Bitmap to footer ******

	  ; a0 pointer to bitmap
		; a1 pointer to bitmap mask
    ; a6 footer repair
		; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo


screen_copyBitmapToFooter:
                                      

	
.bitmap_draw_init_blitter
                              btst       #14,$dff002
                              bne.s      .bitmap_draw_init_blitter
	
                              move       #-2,$dff064                                                                ;A Modulo
                              move       #-2,$dff062                                                                ;B Modulo

                              clr        $dff042
                              move.l     #$ffff0000,$dff044

                              lea.l      footer_mem,a2  
 
                              add.l      d1,a2                                                                      ; add to address
                              move.l     d0,d1 
                              lsr        #3,d0 
                              add.l      d0,a2                                                                      ; add x offset
 
                              ror        #4,d1 
                              and        #$f000,d1 
	
.bitmap_waitblit_1
                              btst       #14,$dff002
                              bne.s      .bitmap_waitblit_1


                              move       d7,$dff060                                                                 ;C Address TODO BULLET_WIDTH_BLITTER was replaced by static 32 and 16 for the blitter
                              move       d7,$dff066                                                                 ;D Address
                              move       d1,$dff042 
                              or         #%0000111111001010,d1 
                              move       d1,$dff040 

.bitmap_waitblit_2
                              btst       #14,$dff002
                              bne.s      .bitmap_waitblit_2
	
                              move.l     a1,$dff050                                                                 ;A=Maske
                              move.l     a0,$dff04c                                                                 ;B=Source
                              move.l     a2,$dff048                                                                 ;C=Dest read
                              move.l     a2,$dff054                                                                 ;D=Dest write
                    ;blisize (bitplanes*height*64)+((width_in_pixel+16)/16)
                    ;move      #((3*25*64)+((32+16)/16)),$dff058
                              move       d5,$dff058

                              rts
;********** done **********************
                              endif




screen_drawScore:
		
                              lea        player_score,a4
                              move.w     (a4),d0

                              ifd        FOOTER_ENABLED
                              move.w     player_score_old,d1
                              cmp.w      d1,d0
                              bne.s      .sc_dS_start
                              rts
.sc_dS_start:                  
                              move.w     d0,player_score_old                               
                              endif 


                              lea.l      InGameScreen,a6
                              move.l     20(a6),a3
                              

		;last
                              move.l     8(a3),a0
                              move.l     8(a3),a1
		
                              
                              and.l      #$f,d0
                              
                              move.w     4(a3),d1
                              lsl.w      d1,d0
                              adda.l     d0,a0

                              add.w      16(a3),d0
                              ;add.l      #2*8*4,d0

                              adda.l     d0,a1

                              move.l     #STATS_SCORE_POS_X,d0
                              move.l     #STATS_SCORE_POS_Y,d1

                           
                              move.w     12(a3),d5
                              move.w     14(a3),d7   
                              move.w     6(a3),d6                           

    ; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo
                          
                              ifd        FOOTER_ENABLED                             
                              move.w     26(a6),d7 
                              bsr        screen_copyBitmapToFooter
                              else
                              bsr        screen_copyBitmap
                              endif
                              
		;last - 1
		
                              move.l     8(a3),a0
                              move.l     8(a3),a1
		
                              move.w     (a4),d0
                              lsr        #4,d0
                              and.l      #$f,d0
                              
                              move.w     4(a3),d1
                              lsl.w      d1,d0
                              adda.l     d0,a0

                              add.w      16(a3),d0

                              ;add.l      #2*16*4,d0
                              adda.l     d0,a1

                              move.l     #STATS_SCORE_POS_X-FOOTER_FONT_WIDTH,d0
                              move.l     #STATS_SCORE_POS_Y,d1
                              move.w     12(a3),d5
                              move.w     14(a3),d7   
                              move.w     6(a3),d6                              

    ; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo
                              ifd        FOOTER_ENABLED                             
                              move.w     26(a6),d7 
                              bsr        screen_copyBitmapToFooter
                              else
                              bsr        screen_copyBitmap
                              endif
                              
		;last - 2
		
                              move.l     8(a3),a0
                              move.l     8(a3),a1
		
                              move.w     (a4),d0
                              lsr        #8,d0
                              and.l      #$f,d0
                              
                              move.w     4(a3),d1
                              lsl.w      d1,d0
                              adda.l     d0,a0
                              ;add.l      #2*16*4,d0
                              add.w      16(a3),d0
                              adda.l     d0,a1

                              move.l     #STATS_SCORE_POS_X-(FOOTER_FONT_WIDTH*2),d0
                              move.l     #STATS_SCORE_POS_Y,d1
                              move.w     12(a3),d5
                              move.w     14(a3),d7   
                              move.w     6(a3),d6                            

    ; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo
                              ifd        FOOTER_ENABLED                             
                              move.w     26(a6),d7 
                              bsr        screen_copyBitmapToFooter
                              else
                              bsr        screen_copyBitmap
                              endif	
		;last - 3
		
                              move.l     8(a3),a0
                              move.l     8(a3),a1
		
                              move.w     (a4),d0
                              lsr        #8,d0
                              lsr        #4,d0
		
                              and.l      #$f,d0
                              
                              move.w     4(a3),d1
                              lsl.w      d1,d0
                              adda.l     d0,a0
                              ;add.l      #2*16*4,d0
                              add.w      16(a3),d0
                              adda.l     d0,a1

                              move.l     #STATS_SCORE_POS_X-(FOOTER_FONT_WIDTH*3),d0
                              move.l     #STATS_SCORE_POS_Y,d1
                              move.w     12(a3),d5
                              move.w     14(a3),d7   
                              move.w     6(a3),d6                           

    ; d0,d1 x,y
    ; d5 blitsize
    ; d6 height
    ; d7 modulo
                              ifd        FOOTER_ENABLED                             
                              move.w     26(a6),d7 
                              bsr        screen_copyBitmapToFooter
                              else
                              bsr        screen_copyBitmap
                              endif
                              rts



;a0 pointer to colors
screen_setColors
                              lea        copper_colors,a1
                              moveq      #15,d0
sr_col_loop                   move.l     (a0)+,(a1)+
                              dbf        d0,sr_col_loop
                              rts


;a0 pointer to colors
screen_setSpriteColors  
                              move.l     player_current,a0
                              move.l     44(a0),a0
                              lea        copper_colors_sprite,a1
                              moveq      #15,d0
.sr_col_loop                  move.l     (a0)+,(a1)+
                              dbf        d0,.sr_col_loop
                              rts



                              xdef       screen_drawObject
screen_drawObject:
; a0 = pointer to instance in item list
; d0 = mask size
; d5 = modulo
; d6 = blitsize
; d7 = height

                              move.l     INSTANCE_BOB_POINTER(a0),a1                                                               
                              ;adda.l     d0,a1                                                                      ; set pointer to mask
                              lea.l      defaultmask,a1
                              
                              move.l     Screen_RENDER,a2                     

                              moveq      #0,d0
                              moveq      #0,d1
                              move       INSTANCE_X(a0),d0                                                          ; x POS
                              move       INSTANCE_Y(a0),d1                                                          ; y POS

                              move       d6,d4                                                                      ; load blitsize

                              sub        virtualscreen_yPosition,d1                                                 ; calcilate pos on screen
                              add        screenBuffer_linePointerYPos,d1

                              cmp.w      #0,d1                                                                      ; out of screen buffer?
                              bgt        .draw_correct_y_skip
                              add.w      #(screenBuffer_height-1),d1                                                ; yes, move to bottom

.draw_correct_y_skip:    

                              cmp.w      #(screenBuffer_height-1),d1
                              ble        .draw_no_top_correction
                    
                              sub.w      #(screenBuffer_height),d1                                                  ; completly ouside
                              bra        .draw_correction_done                                                      ; no more correction necessary
                    
.draw_no_top_correction:
                              add.w      d7,d1                                                                      ; add height
                              move.l     #(screenBuffer_height),d3
                              cmp.w      d3,d1
                              ble        .draw_no_half_correction
                    ;oh blit is outside of screen buffer, reduce height
                              sub.w      d1,d3
                              neg.w      d3
              
                              ;lsl        #8,d3                                                                      ; *64 *4 (4 bitplanes)
                              mulu       #64*6,d3
                              sub        d3,d4                                                                      ; set new height
.draw_no_half_correction:
                              sub.w      d7,d1                                                                      ; sub height

.draw_correction_done:
                              mulu       #screenBuffer_lineSize,d1                                                  ; calculate y offset

                              add.l      d1,a2                                                                      ; add to address
                              move.l     d0,d1 
                              lsr        #3,d0 
                              add        d0,a2                                                                      ; add x offset

                              ror        #4,d1 
                              and        #$f000,d1 


	
.waitblit_1
                              btst       #14,$dff002
                              bne.s      .waitblit_1


                              move       d5,$dff060                                                                 ;C Address TODO BULLET_WIDTH_BLITTER was replaced by static 32 and 16 for the blitter
                              move       d5,$dff066                                                                 ;D Address
                              move       d1,$dff042 
                              or         #%0000111111001010,d1 
                              move       d1,$dff040 

.waitblit_2
                              btst       #14,$dff002
                              bne.s      .waitblit_2
	
                              move.l     a1,$dff050                                                                 ;A=Maske
                              move.l     INSTANCE_BOB_POINTER(a0),$dff04c                                           ;B=Source
                              move.l     a2,$dff048                                                                 ;C=Dest read
                              move.l     a2,$dff054                                                                 ;D=Dest write

                              move       d4,$dff058

                              cmp.w      d6,d4
  
                              beq        .draw_skip                                                                 ; done with this enemy

                             
.waitblit_3         


                              btst       #14,$dff002                                                                ; we have to draw the rest
                              bne.s      .waitblit_3                   
                              move.l     Screen_RENDER,a2
                              add        d0,a2

                                                                    ; a1,a0 are increased by Blitter
                              move.l     a2,$dff048                                                                 ;C=Dest read
                              move.l     a2,$dff054                                                                 ;D=Dest write

                              move.w     d6,d4  
                              and.w      #$3F,d4                                                                    ; remove old height                      
                              add.w      d3,d4                                                                      ; only the rest height
                              move       d4,$dff058              

.draw_skip: 
                              rts



	;d0		;x pos
	;d1		;y pos
	;d2			;length
	;d3			;depth	
	;a0 pointer to logo
	
screen_zoomAndCopyToScreen:	
; calculate start address
                              muls.w     MAGNIFY,d0
                              asr.w      #4,d0
                              addi.w     #$A0,d0
                              muls.w     MAGNIFY,d1
                              asr.w      #4,d1
                              addi.w     #$64,d1
                              movea.l    Screen_RENDER,a1                                                           
                              muls.w     #screenBuffer_lineSize,d1
	
                              adda.w     d1,a1
                              move.w     d0,d1
                              andi.w     #$F,d0
                              sub.w      d0,d1
                              lsr.w      #3,d1
                              adda.w     d1,a1
                              move.l     #$10000,d1
                              lsl.l      d0,d1
	
; calculate start address done
	
                              lea        ZOOMTAB,a2			
                              adda.w     MAGNIFY,a2
                              adda.w     MAGNIFY,a2                                                                 ; add scale factor; 2 time because of words?
                              move.w     (a2),d4                                                                    ; fetch value
                              swap       d4                                                                         ; swap to upper word
                              move.w     (a2),d4                                                                    ; fetch to again, so upper and lower equal
                              move.w     d3,-(a7)                                                                   ; save d3 (depth)
l1192F8	
                              move.l     d1,-(a7)                                                                   ;save d1
                              move.l     d1,d0
                              move.l     d1,d3
                              move.l     d1,d5
                              move.w     d2,d7                                                                      ; move length to d7
                              swap       d4                                                                         ; swap again? loop?
                              rol.w      #1,d4                                                                      ; rol left <-
                              bcs.s      l119318                                                                    ; value is to big/moved over left border
                              swap       d4
                              andi.w     #$FFF0,d7
                              lsr.w      #1,d7
                              lea        8(a0,d7.w),a0                                                              ; go to end of logo image
                              bra        l1193A2
	
l119318                       swap       d4
                              movea.l    a1,a2
                              moveq      #0,d6
l11931E                       dbf        d6,l11932C

                              move.w     (a0)+,d1                                                                   ; Read ST bitplane 1 chunk
                              move.w     (a0)+,d0                                                                   ; ...2
                              move.w     (a0)+,d3                                                                   ; ...3
                              move.w     (a0)+,d5                                                                   ; ...4
	
                              moveq      #$f,d6                                                                     ; 16 chunks?
l11932C                       rol.w      #1,d4
                              bcc.s      l119372
	
                              add.l      d1,d1
                              add.l      d0,d0
                              add.l      d3,d3
                              add.l      d5,d5
	
                              dbcs       d7,l11931E
	
                              bcc.s      l11937E
	
                              swap       d1
                              swap       d0
                              swap       d3
                              swap       d5
	
                              move.w     d0,screenBuffer_width_Byte*1(a2)                                           ; Last chunk done here.
                              move.w     d3,screenBuffer_width_Byte*2(a2)
                              move.w     d5,screenBuffer_width_Byte*3(a2)
                              move.w     d1,(a2)+
	
                              move.w     #1,d0
                              move.w     d0,d1
                              move.w     d0,d3
                              move.w     d0,d5
	
                              swap       d0
                              swap       d1
                              swap       d3
                              swap       d5
                              dbf        d7,l11931E
                              bra.s      l11937E
	
l119372                       add.w      d1,d1
                              add.w      d0,d0
                              add.w      d3,d3
                              add.w      d5,d5
                              dbf        d7,l11931E
	
l11937E                       add.l      d1,d1
                              add.l      d0,d0
                              add.l      d3,d3
                              add.l      d5,d5
                              bcc.s      l11937E
	
                              swap       d1
                              swap       d0
                              swap       d3
                              swap       d5
                              move.w     d0,screenBuffer_width_Byte*1(a2)                                           ; Last chunk done here.
                              move.w     d3,screenBuffer_width_Byte*2(a2)
                              move.w     d5,screenBuffer_width_Byte*3(a2)
                              move.w     d1,(a2)+
                              lea        screenBuffer_lineSize(a1),a1

l1193A2                       move.l     (a7)+,d1
                              subq.w     #1,(a7)
                              bpl        l1192F8
                              addq.w     #2,a7
                              rts


; a0 pointer to image
screen_zoom_test:                    
                              move.w     #15,MAGNIFY
                              ;lea        X2LOGO,a0
	
                              moveq      #-$70,d0
                              moveq      #$10,d1
                              move.w     #$cf,d2
                              moveq      #$35,d3

                              move.w     #64-1,d2                                                                   ;length
                              move.w     #42-1,d3                                                                   ;depth
                              bsr        screen_zoomAndCopyToScreen
	
                              rts

MAGNIFY:                      dc.w       8

ZOOMTAB:	
                              dc.w       $0000,$0100,$1010,$2104,$4444,$4912,$5252,$552A
                              dc.w       $AAAA,$AB55,$B5B5,$B76D,$DDDD,$DF7B,$F7F7,$FF7F
                              dc.w       $FFFF

                              ifd        FOOTER_ENABLED
screen_initFooter             lea        InGameScreen,a0
                              moveq      #0,d7

                              move.w     4(a0),d7
                              subq       #1,d7
                              move.l     (a0),a0
                              lea        footer_mem,a1
                              
.sc_init                      move.b     (a0)+,(a1)+
                              dbf        d7,.sc_init

                              lea        footer_mem,a0
                              move.l     a0,d0                                                                      ;RENDER-> d0
                              lea        copper_footer,a0
                              moveq      #3,d7                                                                      ; only 4 bitplanes here
.sc_init_screen
                              move       d0,6(a0) 
                              swap       d0 
                              move       d0,2(a0) 
                              swap       d0 
                              add.l      #(screen_width/8),d0 
                              addq.l     #8,a0 

                              dbf        d7,.sc_init_screen
                              rts
                              endif


;***************** restore list start *****************
                              xdef       restore_findSlot
restore_findSlot:
; find empty slot in list
; a6 = Pointer to list

                              cmp.w      #0,(a6)
                              beq.s      .lfs_done 
                              adda.l     #SCREEN_RESTORE_LIST_ENTRY_SIZE,a6
                              cmp.w      #-1,(a6) 
                              bne.s      restore_findSlot
                              move.l     #LIST_EMPTY_POINTER,a6
.lfs_done:
                              rts


                              xdef       restore_next
restore_next:
; get next element in list
; a0 = Pointer to Instance

                              move.l     RESTORE_ATTRIBUTE_SUCCESOR(a0),a0
                              rts

                              xdef       restore_create
                              
restore_create:
; creates new empty instance; set active flag and pre and sucessor
; a0 = Pointer to  list (e.g enemy_active_list)
; a1 = Pointer to start instance in list

                              bsr        restore_findSlot
                              cmp.l      #SCREEN_RESTORE_LIST_ENTRY_SIZE,a0
                              beq.s      .lc_done
                              move.w     #1,(a0)
                              move.l     #LIST_EMPTY_POINTER,RESTORE_ATTRIBUTE_SUCCESOR(a0)                         ; new so no successor
 
  ;put into list
                              cmp.l      #LIST_EMPTY_POINTER,(a1)                                                   ; check if first element
                              beq.s      .lc_isFirst     
                              
                              move.l     4(a1),a6                                                                   ;fetch current last elememt
                              move.l     a0,4(a1)                                                                   ; set new element as last element  
                                                                 ;                               
                              move.l     a0,RESTORE_ATTRIBUTE_SUCCESOR(a6)                                          ;  set pre and succ
                              rts
.lc_isFirst:
                              move.l     a0,(a1)+                                                                   ; start pointer = new element
                              move.l     a0,(a1)                                                                    ; last= same (only one element)
.lc_done:
                              rts          


                              xdef       restore_removeObject
restore_removeObject:
; Removes instance from list
; a0 = Pointer to Instance
; a1 = pointer to preseccor element
; -> a0 next instance in queue

                              move.w     #0,(a0)                                                                    ;  set inactive    

                              cmp.l      #LIST_EMPTY_POINTER,RESTORE_ATTRIBUTE_SUCCESOR(a0)
                              bne.s      .lro_notLast
                              cmp.l      #LIST_EMPTY_POINTER,a1
                              beq.s      .lro_emptyQueue

                              move.l     a1,screen_restore_list_end                                                 ; set preseccor as last
                              move.l     #LIST_EMPTY_POINTER,RESTORE_ATTRIBUTE_SUCCESOR(a1)
                              move.l     #LIST_EMPTY_POINTER,a0 
                              rts

.lro_notLast:  
                              cmp.l      #LIST_EMPTY_POINTER,a1                                                     ;first element?
                              bne.s      .lro_inTheMiddle                                                           ; no -> in the middle
                              move.l     RESTORE_ATTRIBUTE_SUCCESOR(a0),a0                                          ; new first
                              move.l     a0,screen_restore_list_start                                                   
                              rts
  
.lro_inTheMiddle:
                              move.l     RESTORE_ATTRIBUTE_SUCCESOR(a0),RESTORE_ATTRIBUTE_SUCCESOR(a1)              ;link preseccor successor to instance successor
                              move.l     RESTORE_ATTRIBUTE_SUCCESOR(a0),a0
                              rts
.lro_emptyQueue:
                              move.l     #LIST_EMPTY_POINTER,screen_restore_list_start                              ; first and last pointer NULL
                              move.l     #LIST_EMPTY_POINTER,screen_restore_list_end 
                              move.l     #LIST_EMPTY_POINTER,a0
                              rts
;*****************  restore list end  *****************

SCREEN_RESTORE_LIST_ENTRY_SIZE = 18
SCREEN_RESTORE_LIST_ENTRY_MAX  = 60

;flag (w),destination(l), offset (l), blisize(w), modulo
screen_restore_list           ds.w       SCREEN_RESTORE_LIST_ENTRY_SIZE*SCREEN_RESTORE_LIST_ENTRY_MAX
                              dc.w       -1

screen_restore_list_start     dc.l       -1
screen_restore_list_end       dc.l       -1

RESTORE_ATTRIBUTE_FLAG         = 0                                                                                  ; W
RESTORE_ATTRIBUTE_DESTINATION  = 2                                                                                  ; L
RESTORE_ATTRIBUTE_OFFSET       = 6                                                                                  ; L
RESTORE_ATTRIBUTE_BLITSIZE     = 10                                                                                 ; W
RESTORE_ATTRIBUTE_MODULO       = 12                                                                                 ; W
RESTORE_ATTRIBUTE_SUCCESOR     = 14                                                                                 ; L
                                                                          


;screenBuffer_linePointerOffset  dc.w      screenBuffer_height*4*(screenBuffer_width/8)-((screenbuffer_width*4)/8)    
screenBuffer_linePointerYPos  dc.w       1


                                                      ;n*virtualscreen_width_Byte
virtualscreen_yPosition       dc.w       VIRTUALSCREEN_YPOSITION_START                                              ;2544                                         ;(256*40)-16                                                                ;n*virtualscreen_width_Byte

virtualscreen_xPosition       dc.w       0

	



screen_buffer_StartYOffset
                              dc.l       screenBuffer_lineSize                                                      ;n*virtualscreen_width_Byte



screenBottomWait
                              dc.w       $FF  
	
screen_mem1:			;Reserve screen memory 
                              ds.b       screenBuffer_size

screen_mem2:			;Reserve screen memory 
                              ds.b       screenBuffer_size

screen_REPAIR:			;Reserve screen memory 
                              ds.b       screenBuffer_size
    
Screen_SHOW:                  dc.l       screen_mem1
Screen_RENDER:                dc.l       screen_mem2			
		

defaultmask: 
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                              dc.l       $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF


copper:
                           ;   dc.w      DIWSTRT,$3081
                            ;  dc.w      DIWSTOP,$30c1
                            ;  dc.w      DDFSTRT,$30
                            ;  dc.w      DDFSTOP,$d0 

                              dc.w       $0084,$0000                                                                ; init COP2LCH and COP2LCL
                              dc.w       $0086,$0000
                              ;dc.w       $0096,$8020                                                                ;enable sprites
copper_screen:
                              dc.w       BPL1PTH,0
                              dc.w       BPL1PTL,0
                              dc.w       BPL2PTH,0
                              dc.w       BPL2PTL,0
                              dc.w       BPL3PTH,0
                              dc.w       BPL3PTL,0
                              dc.w       BPL4PTH,0
                              dc.w       BPL4PTL,0
                              dc.w       BPL5PTH,0
                              dc.w       BPL5PTL,0
                              dc.w       BPL6PTH,0
                              dc.w       BPL6PTL,0

	
copper_scroll:
                              dc.w       BPLCON1, $0000
 
                              

copper_sprite_setup:
                              dc.w       $0120,$0000                                                                ; SPR0PTH
                              dc.w       $0122,$0000                                                                ; SPR0PTL
                              dc.w       $0124,$0000                                                                ; SPR1PTH
                              dc.w       $0126,$0000                                                                ; SPR1PTL
                              dc.w       $0128,$0000                                                                ; SPR2PTH
                              dc.w       $012a,$0000                                                                ; SPR2PTL
                              dc.w       $012c,$0000                                                                ; SPR3PTH
                              dc.w       $012e,$0000                                                                ; SPR3PTL
                              dc.w       $0130,$0000                                                                ; SPR4PTH
                              dc.w       $0132,$0000                                                                ; SPR4PTL
                              dc.w       $0134,$0000                                                                ; SPR5PTH
                              dc.w       $0136,$0000                                                                ; SPR5PTL
                              dc.w       $0138,$0000                                                                ; SPR6PTH
                              dc.w       $013a,$0000                                                                ; SPR6PTL
                              dc.w       $013c,$0000                                                                ; SPR7PTH
                              dc.w       $013e,$0000                                                                ; SPR7PTL
	


copper_screen_mode:
                              dc.w       BPLCON0,$6A00
                              dc.w       BPL1MOD,screenBuffer_modulo
                              dc.w       BPL2MOD,screenBuffer_modulo

;tile colors

copper_colors:
                              dc.w       COLOR00, $0776
                              dc.w       COLOR01, $0789
                              dc.w       COLOR02, $0651
                              dc.w       COLOR03, $099b
                              dc.w       COLOR04, $0665
                              dc.w       COLOR05, $0354
                              dc.w       COLOR06, $0ace
                              dc.w       COLOR07, $0432
                              dc.w       COLOR08, $010e
                              dc.w       COLOR09, $0475
                              dc.w       COLOR10, $0a75
                              dc.w       COLOR11, $0861
                              dc.w       COLOR12, $0697
                              dc.w       COLOR13, $0111
                              dc.w       COLOR14, $0fa1
                              dc.w       COLOR15, $0ee6

copper_colors_sprite
                              dc.w       COLOR16, $0776
                              dc.w       COLOR17, $0789
                              dc.w       COLOR18, $0651
                              dc.w       COLOR19, $099b
                              dc.w       COLOR20, $0665
                              dc.w       COLOR21, $0354
                              dc.w       COLOR22, $0ace
                              dc.w       COLOR23, $0432
                              dc.w       COLOR24, $010e
                              dc.w       COLOR25, $0475
                              dc.w       COLOR26, $0a75
                              dc.w       COLOR27, $0861
                              dc.w       COLOR28, $0697
                              dc.w       COLOR29, $0111
                              dc.w       COLOR30, $0fa1
                              dc.w       COLOR31, $0ee6


copperSlot:
                              dc.w       $ffdf,$fffe                                                                ; wait($df,$ff) enables waits > $ff vertical
                              dc.w       $2c01,$fffe                                                                ; wait($01,$12c) - $2c is $12c
                              dc.w       BPLCON0,$0200                                                              ; BPLCON0 unset bitplanes, enable color burst; needed to support older PAL chips						
                              dc.w       $ffff,$fffe                                                                ; end of copper
                              ds.w       (20+22+4)

                              ds.w       (2+16+16)*SPRITE_LIST_LENGTH                                               ;worst case all sprites are attached

                             ; ifd        FOOTER_ENABLED
                              
footer_mem:
                              ds.b       ((screen_width/8)*screen_colorDepth)*(56+8)


cooper_footer_pointer         dc.w       $F401,$FF00                                                                ; f4=200
                              dc.w       BPLCON0,$4200                                                              ;only 16 colors
                              dc.w       BPL1MOD,(((screen_width/8)*4)-(screen_width/8)-2)
                              dc.w       BPL2MOD,(((screen_width/8)*4)-(screen_width/8)-2)
copper_footer                 dc.w       BPL1PTH,0
                              dc.w       BPL1PTL,0
                              dc.w       BPL2PTH,0
                              dc.w       BPL2PTL,0
                              dc.w       BPL3PTH,0
                              dc.w       BPL3PTL,0
                              dc.w       BPL4PTH,0
                              dc.w       BPL4PTL,0

                              ;dc.w       $0096,$0020                                                                ;disable sprites
copper_footer_sprites:
                              dc.w       $0120,$0000                                                                ; SPR0PTH
                              dc.w       $0122,$0000                                                                ; SPR0PTL
                              dc.w       $0124,$0000                                                                ; SPR1PTH
                              dc.w       $0126,$0000                                                                ; SPR1PTL
                              dc.w       $0128,$0000                                                                ; SPR2PTH
                              dc.w       $012a,$0000                                                                ; SPR2PTL
                              dc.w       $012c,$0000                                                                ; SPR3PTH
                              dc.w       $012e,$0000                                                                ; SPR3PTL
                              dc.w       $0130,$0000                                                                ; SPR4PTH
                              dc.w       $0132,$0000                                                                ; SPR4PTL
                              dc.w       $0134,$0000                                                                ; SPR5PTH
                              dc.w       $0136,$0000                                                                ; SPR5PTL
                              dc.w       $0138,$0000                                                                ; SPR6PTH
                              dc.w       $013a,$0000                                                                ; SPR6PTL
                              dc.w       $013c,$0000                                                                ; SPR7PTH
                              dc.w       $013e,$0000                                                                ; SPR7PTL

                              dc.w       SPR0POS,0
                              dc.w       SPR1POS,0
                              dc.w       SPR2POS,0
                              dc.w       SPR3POS,0
                              dc.w       SPR4POS,0
                              dc.w       SPR5POS,0
                              dc.w       SPR6POS,0
                              dc.w       SPR7POS,0
                              
copper_end:
                              dc.w       $ffdf,$fffe                                                                ; wait($df,$ff) enables waits > $ff vertical
                              dc.w       $2c01,$fffe                                                                ; wait($01,$12c) - $2c is $12c
                              dc.w       BPLCON0,$0200                                                              ; BPLCON0 unset bitplanes, enable color burst; needed to support older PAL chips						
                              dc.w       $ffff,$fffe                                                                ; end of copper
                              ;endif


