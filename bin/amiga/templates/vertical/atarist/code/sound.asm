currentSound dc.l 0

sound_prepare:
		;todo remove
		;lea introMusic,a0
		;move.l a0,soundEventPrio0
		
		
		move.l soundEventPrio0,d0
		movea.l d0,a0
		tst d0
		beq sp_done
		
		moveq #0,d0
		move.w 6(a0),d0
		
		move.l (a0),a0
		move.l soundEventPrio0,currentSound ; save for stopping
		jsr (a0)
		move.l #0,soundEventPrio0
sp_done:		
		rts

	

sound_stop:		
		move.l currentSound,d0
		tst    d0
		beq ss_stop
		move.l #0,currentSound
		move.l d0,a0
		move.l (a0),a0
		jsr	4(a0)

		move.l	#$08000000,$ffff8800.w
		move.l	#$09000000,$ffff8800.w
		move.l	#$0a000000,$ffff8800.w
ss_stop:
		rts

sound_update:
		move.l currentSound,d0
		tst    d0
		beq ss_up
		move.l d0,a0
		move.l (a0),a0
		adda.l   #8,a0
		
		movem.l	d0-a6,-(sp)
		;jsr	sndh+8
		jsr	(a0)
		movem.l	(sp)+,d0-a6
ss_up:	
		rts

		
		
save_vbl:	dc.l	0

		
;sndh:	
	;incbin "./sound.sndh"
;	even


	
sound_update_old:					;NVVTTTTT	Noise Volume Tone 
		move.l soundEventPrio0,d0
		and.l #$000000FF,d0
		tst.b d0				;See if d0=0
		beq silent
		
		move.l #0,soundEventPrio0 ; stop current sound
		
		move.l d0,d3;ld h,a
		and.b #%00000111,d0
		ror.b #3,d0				;rrca
								;rrca
								;rrca
		or.b #%00011111,d0
		move.b d0,d1
		move.b #0,d0			;TTTTTTTT Tone Lower 8 bits	A
		jsr SetAYRegister

		move.b d3,d0
		and.b #%00111000,d0
		ror.b #3,d0				;rrca
								;rrca
								;rrca
		move.b d0,d1			;ld c,a
		move.b #1,d0			;ld a,1			;----TTTT Tone Upper 4 bits
		jsr SetAYRegister		;call RegWrite
		;jsr monitor
		btst #7,d3				;bit 7,h
		beq AYNoNoise			;jr z,AYNoNoise

		move.b #7,d0			;ld a,7			;Mixer  --NNNTTT (1=off) --CBACBA
		move.b #%00110110,d1	;ld c,%00110110
		jsr SetAYRegister		;call RegWrite

		move.b #6,d0			;ld a,6			;Noise ---NNNNN
		move.b #%00011111,d1	;ld c,%00011111
		jsr SetAYRegister		;call RegWrite


		jmp AYMakeTone
	AYNoNoise:
		move.b #7,d0			;Mixer  --NNNTTT (1=off) --CBACBA
		move.b #%00111110,d1
		jsr SetAYRegister		;call RegWrite
		jmp AYMakeTone
	AYMakeTone:
		;*** these are incorrectly marked as Amplitude Control (Registers R10,R11,R12) in some documentation! ***
		move.b d3,d0
		and.b #%01000000,d0
		ror.b #4,d0				;rrca
								;rrca
								;rrca
								;rrca
		or.b #%00001011,d0
		move.b d0,d1
		move.b #8,d0			;4-bit Volume / 2-bit Envelope Select for channel A ---EVVVV
		jsr SetAYRegister		;call RegWrite
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
silent:
	move.b #7,d0			;Mixer  --NNNTTT (1=off) --CBACBA
	move.b #%00111111,d1
	jsr SetAYRegister		;call RegWrite
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetAYRegister:
	move.b d0,$FF8800	;Reg Num
	move.b d1,$FF8802	;Reg Val
	rts
	