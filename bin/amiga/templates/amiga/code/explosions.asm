  include    "engine/explosions.asm"



;****************
;* draw explosion *
;****************
	


explosions_draw:  
         
  lea.l      screen_restore_list,a6                   
  
  cmp.l      #LIST_EMPTY_POINTER,explosion_active_list_start
  beq        .ex_draw_exit

  move.l     explosion_active_list_start,a0

  moveq      #0,d6
	
.ex_draw_init_blitter
  btst       #14,$dff002
  bne.s      .ex_draw_init_blitter
	
  move       #-2,$dff064                                        ;A Modulo
  move       #-2,$dff062                                        ;B Modulo

  clr        $dff042
  move.l     #$ffff0000,$dff044
	
.ex_draw_check
  cmp        #1,(a0)                                            ; enemy active?
  beq        .ex_draw_init                                      ; find active enemy
.ex_draw_next:
  bra        .ex_draw_skip                                      ; check next line
 

.ex_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                     ; get bullet type config
  move.w     24(a5),d5                                          ; load modulo
  move       22(a5),d6                                          ; load blitsize
  move       4(a5),d7                                           ; load height
  move.w     20(a5),d0                                          ; get mask size
  tst.w      d0
  beq        .ex_draw_sprite                                  ; it is sprite
               ; a0 = pointer to instance
               ; a6 pointer to restore list
               ; d0 = mask size
               ; d5 = modulo
               ; d6 = blitsize
               ; d7 = height
  jsr        screen_drawObject
  bra.s .ex_draw_skip

.ex_draw_sprite:          
  moveq      #0,d0
  move.w     INSTANCE_Y(a0),d0
  add.w      #44,d0
  sub.w      virtualscreen_yPosition,d0
                ;a0 pointer to object
                ;d0 y-sort value
  jsr        sprite_addPointer

.ex_draw_skip:	
         

  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .ex_draw_check 

.ex_draw_exit:
  rts

