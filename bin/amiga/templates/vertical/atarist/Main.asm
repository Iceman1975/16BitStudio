    SECTION TEXT		;CODE Section
	
	include    "./code/const.asm"
init:
    ;pea    	game     ;Push address to call to onto stack
    ;move.w  #$26,-(sp)  ;Supexec (38: set supervisor execution)
    ;trap    #14         ;XBIOS Trap
    ;addq.w  #6,sp       ;remove item from stack
	;jmp *				;Wait for Supervisor mode to start
	jsr     initialise
game:
	
	jsr joystick_init
	jsr screen_init
	
	jsr sound_prepare
	


game_start:	
	jsr game_showStartScreen	
	
	;jsr stopsndh
		
	jsr screen_initLevel
	
	jsr screen_copyFooterToScreen
	jsr screen_swap
	jsr screen_copyFooterToScreen

game_loop:		
  ;jsr        screen_waitVBlank
  jsr        screen_swap
  jsr        screen_waitVBlank
  
  jsr    	 sound_update
  
  		
  jsr        screen_scroll	 
  jsr        screen_restore 
 
  ifd ENEMY_ACTIVATION_BY_SCROLLING
  jsr        enemies_createEnemy
  endif
  
  jsr        enemies_move
  jsr        bullet_move
  jsr        explosions_update
  jsr        extras_update

  move.w  game_state,d0
  cmp.w   #GAME_STATE_DYING,d0
  beq game_skip0
  jsr        joystick_update
  jsr        player_update
  jsr        pot_update

game_skip0:
  
  jsr        collision_checkBullets
  jsr 		 collision_checkExtras
  
  ifd        COLLISION_TILES
  jsr        collision_checkTiles
  endif
  
  ifd        COLLISION_PLAYER_ENEMY
  jsr        collision_checkPlayerWithEnemy
  endif
  
  jsr        enemies_draw
  
  move.w  game_state,d0
  cmp.w   #GAME_STATE_DYING,d0
  beq game_skip1  
  jsr        player_draw
  jsr        pot_draw
game_skip1:
  
  jsr        bullet_draw
  jsr        explosions_draw
  jsr        extras_draw
  
  jsr        screen_drawScore
  jsr		screen_drawLives
  
  jsr        sound_prepare

  jsr        game_checkGameState

  tst        d0
  blt        game_start
  
  
  bra game_loop			
	;jsr destroy
  rts
	
	include    "./data/ST_sound_config.asm" 
	include    "./data/ST_sound_data.asm" 
	
	
	include    "./global.asm"
	include    "./code/list.asm"
	include    "./code/joystick.asm"
	
	include    "./code/screen.asm"
	include    "./code/screen_scrolling.asm"
	include    "./code/enemies.asm"
	include    "./code/player.asm"
	include    "./code/pot.asm"
	include    "./code/bullet.asm"
	include    "./code/explosions.asm"
	include    "./code/collision.asm"
	include    "./code/sound.asm"
	include    "./code/game.asm"
	include    "./code/extras.asm"

	ifd        SCRIPTS_ENABLE
	include    "./code/scripts.asm"  
	endif
  
	include    "./data/ST_tiles.asm"
	include    "./data/ST_level.asm"
	include    "./data/ST_level_config.asm" 
	
	include    "./data/ST_enemies_imagedata.asm" 
	include    "./data/ST_enemies_config.asm" 
	include    "./data/ST_player_imagedata.asm" 
	include    "./data/ST_player_config.asm" 
	include    "./data/ST_bullets_imagedata.asm" 
	include    "./data/ST_bullets_config.asm" 
	include    "./data/ST_explosions_imagedata.asm" 
	include    "./data/ST_explosions_config.asm" 
	include    "./data/ST_extras_imagedata.asm" 
	include    "./data/ST_extras_config.asm" 
	
	include    "./data/ST_screen_config.asm" 
	include    "./data/ST_screen_data.asm" 
	
	include    "./data/ST_font_config.asm" 
	include    "./data/ST_font_data.asm" 

	
	include    "./data/ST_pots_config.asm" 
	include    "./data/ST_pots_imagedata.asm" 
	
initialise
; set supervisor
                clr.l   -(a7)                    ; clear stack
                move.w  #32,-(a7)               ; prepare for user mode
                trap    #1                       ; call gemdos
                addq.l  #6,a7                   ; clean up stack
                move.l  d0,old_stack            ; backup old stack pointer
; end set supervisor

; save the old palette; old_palette
                move.l  #old_palette,a0         ; put backup address in a0
                movem.l $ffff8240,d0-d7         ; all palettes in d0-d7
                movem.l d0-d7,(a0)              ; move data into old_palette
; end palette save

; saves the old screen adress
                move.w  #2,-(a7)                ; get physbase
                trap    #14
                addq.l  #2,a7
                move.l  d0,old_screen           ; save old screen address
; end screen save

; save the old resolution into old_resolution
; and change resolution to low (0)
                move.w  #4,-(a7)                ; get resolution
                trap    #14
                addq.l  #2,a7
                move.w  d0,old_resolution       ; save resolution
                
                move.w  #0,-(a7)                ; low resolution
                move.l  #-1,-(a7)               ; keep physbase
                move.l  #-1,-(a7)               ; keep logbase
                move.w  #5,-(a7)                ; change screen
                trap    #14
                add.l   #12,a7
; end resolution save  

                rts

restore  
; restores the old resolution and screen adress
                move.w  old_resolution,d0       ; res in d0
                move.w  d0,-(a7)                ; push resolution
                move.l  old_screen,d0           ; screen in d0
                move.l  d0,-(a7)                ; push physbase
                move.l  d0,-(a7)                ; push logbase
                move.w  #5,-(a7)                ; change screen
                trap    #14
                add.l   #12,a7
; end resolution and screen adress restore

; restores the old palette
                move.l  #old_palette,a0         ; palette pointer in a0
                movem.l (a0),d0-d7              ; move palette data
                movem.l d0-d7,$ffff8240         ; smack palette in
; end palette restore

; set user mode again
                move.l  old_stack,-(a7)         ; restore old stack pointer
                move.w  #32,-(a7)               ; back to user mode
                trap    #1                       ; call gemdos
                addq.l  #6,a7                   ; clear stack
; end set user
                
                rts

                section data

old_resolution  dc.w    0
old_stack       dc.l    0
old_screen      dc.l    0


                section bss

old_palette     ds.l    8	

