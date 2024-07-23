
  include    "engine/enemies.asm"


;****************
;* draw enemy *
;****************
	


enemies_draw:
  lea.l      screen_restore_list,a6                   
                    
  cmp.l      #LIST_EMPTY_POINTER,enemy_active_list_start
  beq        e_draw_exit

  move.l     enemy_active_list_start,a0

  moveq      #0,d6
	
e_draw_init_blitter
  btst       #14,$dff002
  bne.s      e_draw_init_blitter
	
  move       #-2,$dff064                                    ;A Modulo
  move       #-2,$dff062                                    ;B Modulo

  clr        $dff042
  move.l     #$ffff0000,$dff044
	
e_draw_check
  cmp        #1,(a0)                                        ; enemy active?
  beq        e_draw_init                                    ; find active enemy
e_draw_next:
  bra        e_draw_skip                                    ; check next line

e_draw_init:
  move.l     INSTANCE_OBJECT_POINTER(a0),a5                 ; get bullet type config
  move.w     48(a5),d5                                      ; load modulo
  move       20(a5),d6                                      ; load blitsize
  move       4(a5),d7                                       ; load height
  move.w     38(a5),d0                                      ; get mask size
  tst.w      d0
  beq        e_draw_sprite                                  ; it is sprite

               ; a0 = pointer to instance
               ; a6 pointer to restore list
               ; d0 = mask size
               ; d5 = modulo
               ; d6 = blitsize
               ; d7 = height
  jsr        screen_drawObject
  bra.s      e_draw_skip

e_draw_sprite:          
  moveq      #0,d0
  move.w     INSTANCE_Y(a0),d0
  ;add.w      4(a5),d0                                       ;sort=y+height
  add.w      #44,d0
  sub.w      virtualscreen_yPosition,d0
                ;a0 pointer to object
                ;d0 y-sort value
  jsr        sprite_addPointer
e_draw_skip:	

  bsr        list_next
  cmp.l      #LIST_EMPTY_POINTER,a0
  bne        e_draw_check 

e_draw_exit:
  rts

