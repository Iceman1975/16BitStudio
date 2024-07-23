  include    "engine/extras.asm"



;****************
;* draw extra *
;****************
	
extras_draw:

  cmp.l      #LIST_EMPTY_POINTER,extra_active_list_start
  beq        .extra_draw_exit

  move.l     extra_active_list_start,a0
  lea.l      screen_restore_list,a6                   

  moveq      #0,d6
	
.extra_draw_init_blitter
  btst       #14,$dff002
  bne.s      .extra_draw_init_blitter
	
  move       #-2,$dff064                                    ;A Modulo
  move       #-2,$dff062                                    ;B Modulo

  clr        $dff042
  move.l     #$ffff0000,$dff044
	
.extra_draw_check
  cmp        #1,(a0)                                        ; extra active?
  beq        .ex_draw_init                                  ; find active extra
.extra_draw_next:
  bra        .extra_draw_skip                               ; check next line
 

.ex_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  move.w     24(a5),d5                                      ; load modulo
  move       22(a5),d6                                      ; load blitsize
  move       6(a5),d7                                       ; load height
  move.w     20(a5),d0                                      ; get mask size
  tst.w      d0
  beq        .extra_draw_sprite                             ; it is sprite
               ; a0 = pointer to instance
               ; a6 pointer to restore list
               ; d0 = mask size
               ; d5 = modulo
               ; d6 = blitsize
               ; d7 = height
  jsr        screen_drawObject
  bra.s      .extra_draw_skip

.extra_draw_sprite:          
  moveq      #0,d0
  move.w     INSTANCE_Y(a0),d0
  add.w      #44,d0
  sub.w      virtualscreen_yPosition,d0
                ;a0 pointer to object
                ;d0 y-sort value
  jsr        sprite_addPointer

.extra_draw_skip:	
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        .extra_draw_check 

.extra_draw_exit:
  rts


