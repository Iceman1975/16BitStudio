linescrolls equ 1


;Ram Variables
userRAM equ $00FF0000		;Ram for Cursor Xpos

;Video Ports
VDP_data	EQU	$C00000	; VDP data, R/W word or longword access only
VDP_ctrl	EQU	$C00004	; VDP control, word or longword writes only

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 					Traps
	DC.L	$FFFFFE00		;SP register value
	DC.L	ProgramStart	;Start of Program Code
	DS.L	7,IntReturn		; bus err,addr err,illegal inst,divzero,CHK,TRAPV,priv viol
	DC.L	IntReturn		; TRACE
	DC.L	IntReturn		; Line A (1010) emulator
	DC.L	IntReturn		; Line F (1111) emulator
	DS.L	4,IntReturn		; Reserverd /Coprocessor/Format err/ Uninit Interrupt
	DS.L	8,IntReturn		; Reserved
	DC.L	IntReturn		; spurious interrupt
	DC.L	IntReturn		; IRQ level 1
	DC.L	IntReturn		; IRQ level 2 EXT
	DC.L	IntReturn		; IRQ level 3
	DC.L	IntReturn		; IRQ level 4 Hsync
	DC.L	IntReturn		; IRQ level 5
	DC.L	IntReturn		; IRQ level 6 Vsync
	DC.L	IntReturn		; IRQ level 7 
	DS.L	16,IntReturn	; TRAPs
	DS.L	16,IntReturn	; Misc (FP/MMU)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Header
	DC.B	"SEGA GENESIS    "	;System Name
	DC.B	"(C)16BIT"			;Copyright
 	DC.B	"2024.JAN"			;Date
	DC.B	"16BIT STUDIO                                    " ; Cart Name
	DC.B	"16BIT STUDIO                                    " ; Cart Name (Alt)
	DC.B	"GM 16BIT001-00"	;TT NNNNNNNN-RR T=Type (GM=Game) N=game Num  R=Revision
	DC.W	$0000				;16-bit Checksum (Address $000200+)
	DC.B	"J               "	;Control Data (J=3button K=Keyboard 6=6button C=cdrom)
	DC.L	$00000000			;ROM Start
	DC.L	$003FFFFF			;ROM Length
	DC.L	$00FF0000,$00FFFFFF	;RAM start/end (fixed)
	DC.B	"            "		;External RAM Data
	DC.B	"            "		;Modem Data
	DC.B	"                                        " ;MEMO
	DC.B	"JUE             "	;Regions Allowed

	include "./generated/const.asm"	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Generic Interrupt Handler
IntReturn:
	rte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Program Start
ProgramStart:
	;initialize TMSS (TradeMark Security System)
	move.b ($A10001),D0		;A10001 test the hardware version
	and.b #$0F,D0
	beq	NoTmss				;branch if no TMSS chip
	move.l #'SEGA',($A14000);A14000 disable TMSS 
NoTmss:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Set Up Graphics

	lea VDPSettings,A5		;Initialize Screen Registers
	move.l #VDPSettingsEnd-VDPSettings,D1 ;length of Settings
	
	move.w (VDP_ctrl),D0	;C00004 read VDP status (interrupt acknowledge?)
	move.l #$00008000,d5	;VDP Reg command (%8rvv)
	
NextInitByte:
	move.b (A5)+,D5			;get next video control byte
	move.w D5,(VDP_ctrl)	;C00004 send write register command to VDP
		;   8RVV - R=Reg V=Value
	add.w #$0100,D5			;point to next VDP register
	dbra D1,NextInitByte	;loop for rest of block


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Set up palette
	
	;Define palette
	
	;bsr screen_setColors
	
	
	;        ----BBB-GGG-RRR-
	move.w #%0000111011101110,VDP_data
	
	
	MOVE.W	#$8144,(VDP_Ctrl)		; C00004 reg 1 = 0x44 unblank display
	
	jsr initScript
	
	
game_start:	
  
  jsr game_showStartScreen		

  move.w #1000,virtualscreen_yPosition
  
  bsr screen_loadLevelTiles
  bsr Screen_initLevel

 game_loop:	
		
	bsr screen_waitVBlank
	bsr screen_scroll
	
	ifd        ENEMY_ACTIVATION_BY_SCROLLING	
	jsr        enemies_createEnemy
	endif

	jsr     enemies_move
	jsr 	bullet_move	
	jsr     extras_update
	jsr     explosions_update

  move.w     game_state,d0
  cmp.w      #GAME_STATE_DYING,d0
  beq        game_skip0	
	
	jsr joystick_update
	jsr player_update
	jsr pot_update
	
game_skip0:
  jsr        collision_checkBullets
  jsr        collision_checkExtras
  ifd        COLLISION_TILES
  jsr        collision_checkTiles
  endif
  
 
  ifd        COLLISION_PLAYER_ENEMY
  jsr        collision_checkPlayerWithEnemy
  endif
	
	
	bsr screen_drawAllObjects

	move.w     game_state,d0
	cmp.w      #GAME_STATE_DYING,d0
	beq        game_skip1 

		
game_skip1:

  ;jsr        screen_drawLives
  ;jsr        screen_drawScore
  ;jsr        sound_update
 
  jsr        game_checkGameState

  tst        d0
  blt        game_start

  bra        game_loop		
	
		

GAME_STATE_INIT       = 0
GAME_STATE_RUNNING    = 1
GAME_STATE_DONE       = 2
GAME_STATE_OVER       = 3
GAME_STATE_RESPAWN    = 4
GAME_STATE_DYING      = 5

GAME_DYING_INIT       = 25

	


			

	
	
	include "code/screen.asm"

	include "./engine/list.asm" 
	include "./engine/enemies.asm" 
	include "./engine/bullet.asm" 
	include "./engine/explosions.asm" 
	include "./engine/extras.asm" 
	include "./code/collision.asm" 
	include "./code/game.asm" 
	include "generated/global.asm"
	include "generated/scripts.asm"
	include "./code/joystick.asm"
	include "./code/player.asm"
	include "./code/pot.asm"
	include "data/SEGA_level.asm"
	include "data/SEGA_level_config.asm"
	include "data/SEGA_player_config.asm"
	include "data/SEGA_bullets_config.asm"
	include "data/SEGA_explosions_config.asm"
	include "data/SEGA_extras_config.asm"
	include "data/SEGA_pots_config.asm"
	include "data/SEGA_sound_config.asm"
	include "data/SEGA_sound_data.asm"
	include "data/SEGA_screen_config.asm"
	include "data/SEGA_screen_data.asm"
	
VDPSettings:
	DC.B $04 ; 0 mode register 1											---H-1M-
	DC.B $04 ; 1 mode register 2											-DVdP---
	DC.B $30 ; 2 name table base for scroll A (A=top 3 bits)				--AAA--- = $C000
	DC.B $3C ; 3 name table base for window (A=top 4 bits / 5 in H40 Mode)	--AAAAA- = $F000
	DC.B $07 ; 4 name table base for scroll B (A=top 3 bits)				-----AAA = $E000
	DC.B $6C ; 5 sprite attribute table base (A=top 7 bits / 6 in H40)		-AAAAAAA = $D800
	DC.B $00 ; 6 unused register											--------
	DC.B $00 ; 7 background color (P=Palette C=Color)						--PPCCCC
	DC.B $00 ; 8 unused register											--------
	DC.B $00 ; 9 unused register											--------
	DC.B $FF ;10 H interrupt register (L=Number of lines)					LLLLLLLL
	
	;X and Y scroll now at the CELL level
	
	
	;ifnd linescrolls
		;Scroll horizontally in blocks
	;	DC.B $06 ;11 mode register 3						----IVHL
	;else
		;Scroll horizontally in lines
	;	DC.B $07 ;11 mode register 3						----IVHL
	;endif
	;We can only scroll vertically in blocks!
	DC.B $00 ; 11 full screen v/h
	
	DC.B $81 ;12 mode register 4 (C bits both1 = H40 Cell)					C---SIIC
	DC.B $37 ;13 H scroll table base (A=Top 6 bits)							--AAAAAA = $DC00
	DC.B $00 ;14 unused register											--------
	DC.B $02 ;15 auto increment (After each Read/Write)						NNNNNNNN
	DC.B $01 ;16 scroll size (Horiz & Vert size of ScrollA & B)				--VV--HH = 64x32 tiles
	DC.B $00 ;17 window H position (D=Direction C=Cells)					D--CCCCC
	DC.B $00 ;18 window V position (D=Direction C=Cells)					D--CCCCC
	DC.B $FF ;19 DMA length count low										LLLLLLLL
	DC.B $FF ;20 DMA length count high										HHHHHHHH
	DC.B $00 ;21 DMA source address low										LLLLLLLL
	DC.B $00 ;22 DMA source address mid										MMMMMMMM
	DC.B $80 ;23 DMA source address high (C=CMD)							CCHHHHHH
VDPSettingsEnd:
	even
	

	
	include "./data/SEGA_enemies_config.asm"
	
