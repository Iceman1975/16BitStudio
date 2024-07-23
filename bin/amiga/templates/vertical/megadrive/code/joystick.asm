joystick_update:
	move.l #0,joystick1_left
	move.l #0,joystick1_up
	move.l #0,joystick1_button

	
	bsr joystick_ReadControlsDual	;Read Joystick
	
	btst #0,d0
	bne JoyNotUp		;Jump if UP not pressed
	move.b #1,joystick1_up
	;subq.w #1,player_pos_y		;Move Y Up the screen
	;subq.w #1,virtualscreen_yPosition
	;sub.w #1,screen_line

JoyNotUp: 	
	btst #1,d0
	bne JoyNotDown		;Jump if DOWN not pressed
	move.b #1,joystick1_down

	;addq.w #1,(player_pos_y)		;Move Y DOWN the screen
	;addq.w #1,virtualscreen_yPosition
	;addq.w #1,screen_line

JoyNotDown: 	
	btst #2,d0
	bne JoyNotLeft		;Jump if LEFT not pressed
	move.b #1,joystick1_left

	;subq.w #1,(player_pos_x)		;Move X Left
JoyNotLeft: 	
	btst #3,d0
	bne JoyNotRight		;Jump if RIGHT not pressed
	move.b #1,joystick1_right
	;addq.w #1,(player_pos_x)		;Move X Right
JoyNotRight: 
	btst #4,d0
	bne JoyNotA		;Jump if A not pressed
	move.w #1,joystick1_button
	;addq.w #1,(player_pos_x)		;Move X Right
JoyNotA:
	btst #5,d0
	bne JoyNotB		;Jump if B not pressed
	move.w #1,joystick1_button_automatic
	
	;addq.w #1,(player_pos_x)		;Move X Right
JoyNotB:
	rts


joystick_ReadControlsDual:		;D0=1up D1=2up ---7654S321RLDU
	
	move.b #%01000000,($A1000B)	; Set direction IOIIIIII (I=In O=Out)
	move.l #$A10005,a0			;RW port for player 2
	jsr joystick_ReadOne			;Read buttons
	
	move.l d0,-(sp)
		move.b #%01000000,($A10009)	; Set direction IOIIIIII (I=In O=Out)
		move.l #$A10003,a0		;RW port for player 1
		jsr joystick_ReadOne		;Read buttons
	move.l (sp)+,d1
	rts
	
joystick_ReadOne:			;Read in and reformat a players buttons
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	move.b  (a0),d2		; d0.b = --CBRLDU	Store in D2
	
	move.b	#$0,(a0)	; TH = 0
	nop		;Delay
	nop
	move.b	(a0),d1		; d1.b = --SA--DU	Store in D1
	
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	move.b	#$0,(a0)	; TH = 0
	nop		;Delay
	nop
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	
	move.b	(a0),d3		; d1.b = --CBXYZM	Store in D3
	move.b	#$0,(a0)	; TH = 0
	
	clr.l d0			;Clear buildup byte
	roxr.b d2
	roxr.b d0			;U
	roxr.b d2
	roxr.b d0			;D
	roxr.b d2
	roxr.b d0			;L
	roxr.b d2
	roxr.b d0			;R
	roxr.b #5,d1
	roxr.b d0			;A
	roxr.b d2
	roxr.b d0			;B
	roxr.b d2
	roxr.b d0			;C
	roxr.b d1
	roxr.b d0			;S
	
	move.l d3,d1
	roxl.l #7,d1		;XYZ
	and.l #%0000011100000000,d1
	or.l d1,d0			
	
	move.l d3,d1
	roxl.l #8,d1		;M
	roxl.l #3,d1		
	and.l #%0000100000000000,d1
	or.l d1,d0
	
	or.l #$FFFFF000,d0	;Set unused bits to 1
	rts