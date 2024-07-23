  include    "engine/bullet.asm"
	
	
;****************
;* draw bullets *
;****************
	
	


bullet_draw:
  cmp.l      #LIST_EMPTY_POINTER,bullet_active_list_start
  beq        b_draw_done
  move.l     bullet_active_list_start,a0

  lea.l      screen_restore_list,a6                   

               

b_draw_init_blitter
  btst       #14,$dff002
  bne.s      b_draw_init_blitter
	
  move       #-2,$dff064                                     ;A Modulo
  move       #-2,$dff062                                     ;B Modulo

  clr        $dff042
  move.l     #$ffff0000,$dff044
	
b_draw_check
  cmp        #1,(a0)                                         ; bullet active?
  beq        b_draw_init                                     ; find active bullet
b_draw_next:
  bra        b_draw_skip                                     ; check next line

b_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                  ; get bullet type config
  move.w     42(a5),d5                                       ; load modulo
  move       32(a5),d6                                       ; load blitsize
  move       6(a5),d7                                        ; load height
  move.w     30(a5),d0                                       ; get mask size

  tst.w      d0
  beq        b_draw_sprite                                   ; it is sprite
b_draw_nextbullet: 


               ; a0 = pointer to instance
               ; a6 pointer to restore list
               ; d0 = mask size
               ; d5 = modulo
               ; d6 = blitsize
               ; d7 = height
  jsr        screen_drawObject
  bra.s      b_draw_skip

b_draw_sprite:          
  moveq      #0,d0
  move.w     INSTANCE_Y(a0),d0
  ;add.w      6(a5),d0                                        ;sort=y+height
  add.w      #44,d0
  sub.w      virtualscreen_yPosition,d0
                ;a0 pointer to object
                ;d0 y-sort value
  jsr        sprite_addPointer


b_draw_skip:	
  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        b_draw_check 

b_draw_done:
  rts