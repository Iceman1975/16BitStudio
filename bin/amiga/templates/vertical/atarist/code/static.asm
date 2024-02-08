
show_startScreen:
  jsr StartScreen_color
  jsr static_loadScreen

ss_loop:
  jsr        screen_waitVBlank
  jsr        screen_swap
  		
  jsr        screen_restore
  jsr        joystick_update
  
  
  lea.l     joystick1_down,a0
  tst.b     (a0)
  ;lea.l     joystick1_button,a0               ; button?
  ;cmp.w     #1,(a0)
  bne       static_done
  
  bra ss_loop
static_done:  
  rts
  
static_loadScreen:
		lea  StartScreen_image,a0
		lea  screen_REPAIR,a1
		
		move.l #199,d0
		
static_copy:
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

		dbra d0,static_copy		
		rts