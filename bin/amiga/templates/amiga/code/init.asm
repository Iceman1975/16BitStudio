
		
init:
  LEA       CUSTOM,a6                           ;Point a0 at custom chips
  ;move.w    #$4000,$dff09a                      ; INTENA - clear external interrupt

  move.w    #%0011111111111111,$dff09a
  ;move.w    #%0001111111111111,$dff09a          ; 2. try

  or.b      #%10000000,$bfd100                  ; CIABPRB stops drive motors
  and.b     #%10000111,$bfd100                  ; CIABPRB

  move.w    #$01a0,$dff096                      ; DMACON clear bitplane, copper, sprite

  move.w    #$4000,$dff100                      ; BPLCON0 one bitplane, color burst
  move.w    #$0000,$dff102                      ; BPLCON1 scroll
  move.w    #$003f,$dff104                      ; BPLCON2 video

  move.w    #screenBuffer_width_Byte,$dff108
  move.w    #screenBuffer_width_Byte,$dff10a

  ifd       SCROLLING_VERTICAL_ONLY
  move.w    #$2c71,$dff08e                      ; DIWSTRT upper left corner of display ($81,$2c)
  move.w    #$30b1,$dff090                      ; DIWSTOP lower right corner of display ($1c1,$12c)
  else
  move.w    #$2c81,$dff08e                      ; DIWSTRT upper left corner of display ($81,$2c)
  move.w    #$30c1,$dff090                      ; DIWSTOP lower right corner of display ($1c1,$12c)
  endif
 

  ;move.w    #$0030,$dff092                      ; DDFSTRT Data fetch start
  ;move.w    #$00d0,$dff094                      ; DDFSTOP Data fetch stop

;HAM only?
  move.w    #$0038,$dff092                      ; DDFSTRT Data fetch start
  move.w    #$00d8,$dff094                      ; DDFSTOP Data fetch stop


  ;move.w    #%1100000000000000,$dff09a          ;enable interrupts for sound
  ;init mod player
  ;lea       $dff000,a6                          ; custom address
  ;sub.l     a0,a0
  ;moveq     #1,d0                               ; _mt_install_cia(a6=CUSTOM, a0=AutoVecBase, d0=PALflag.b)
  ;jsr       _mt_install_cia 

init_clearFooterSprites:
  lea.l     copper_footer_sprites,a2            ; put copper_sprite_setup address into a2
  bra.s     i_sprite_clear

init_clearSprites:
  lea.l     copper_sprite_setup,a2              ; put copper_sprite_setup address into a2

i_sprite_clear:
  lea.l     blanksprite,a1                      ; put blanksprite address into a1
  
  add.l     #2,a2                               ; add 10 to copper address in a2
  move.l    a1,d1                               ; move blanksprite address into d1
  moveq     #7,d0                               ; setup sprite counter

sprcoploop:            ; set all 7 sprite pointers
  swap      d1                                  ; high and low to point to blanksprite 
  move.w    d1,(a2)
  addq.l    #4,a2
  swap      d1
  move.w    d1,(a2)
  addq.l    #4,a2
  dbra      d0,sprcoploop                       ; loop trough all 7 sprite pointers		 
  rts
	
	
destroy:
  ; stop mod player
  lea       $dff000,a6                          ; custom address
  jsr       _mt_end
  lea       $dff000,a6                          ; custom address
  jsr       _mt_remove_cia

  move.w    #$0080,$dff096                      ; reestablish DMA's and copper
  LEA       CUSTOM,a6 
  move.l    $04,a6
  move.l    156(a6),a1
  move.l    38(a1),$dff080

  move.w    #$8080,$dff096

  move.w    #$c000,$dff09a
  rts

blanksprite:
  dc.w      $0000,$0000                         ; an empty sprite
  dc.w      $0000,$0000
  dc.w      $0000,$0000
  dc.w      $0000,$0000
  dc.w      $0000,$0000
  dc.w      $0000,$0000