  SECTION    ChipData,  DATA_C

  include    "./generated/const.asm"
  include    "include/hw.i"
 
       
  ;jsr        system_checkMem

  ifd        FOOTER_ENABLED
  jsr        screen_initFooter
  endif

  jsr        init_clearFooterSprites
  bsr        init       
  


game:
	
  jsr        screen_init  
  jsr        sound_init
        


           
game_start:	
  
  jsr        game_showStartScreen		
  jsr        screen_initLevel
  ;jsr        player_create

  
game_loop:		
  
  jsr        screen_waitVBlank
  jsr        screen_swap2

  jsr        screen_scroll

  jsr        screen_restore 
  jsr        sprite_resetPointer
  ;jsr        amiga_addParallax1
  ;jsr        amiga_addParallax2
 
  ;move.w     #$0f0,$dff180


  ifd        ENEMY_ACTIVATION_BY_SCROLLING
  jsr        enemies_createEnemy
  endif

  jsr        enemies_move
  jsr        bullet_move
  jsr        extras_update
  jsr        explosions_update

  move.w     game_state,d0
  cmp.w      #GAME_STATE_DYING,d0
  beq        game_skip0

  jsr        joystick_update
  jsr        player_update
  jsr        pot_update
  ;move.w     #$f00,$dff180
  
 
game_skip0:
  jsr        collision_checkBullets
  jsr        collision_checkExtras
  ifd        COLLISION_TILES
  jsr        collision_checkTiles
  endif
  
 
  ;move.w     #$0f0,$dff180
  ifd        COLLISION_PLAYER_ENEMY
  jsr        collision_checkPlayerWithEnemy
  endif
  ;move.w     #$000,$dff180

  

  jsr        enemies_draw
  ;move.w     #$666,$dff180
  move.w     game_state,d0
  cmp.w      #GAME_STATE_DYING,d0
  beq        game_skip1 

  
  jsr        player_drawByCopper
  jsr        pot_draw
  
game_skip1:

  jsr        bullet_draw
  ;move.w     #$aaa,$dff180
  jsr        explosions_draw
  jsr        extras_draw
  ;move.w     #$00f,$dff180
  jsr        screen_drawLives
  jsr        screen_drawScore
  ;move.w     #$000,$dff180
  jsr        sound_update
  jsr        game_checkGameState

  tst        d0
  blt        game_start

  bra        game_loop		
	
	;jsr destroy
  rts
	
	
  
  include    "./code/global.asm"  
  include    "./code/init.asm"
  include    "./code/joystick.asm"

  include    "./code/sprites.asm"

  ifd        HAM_MODE                             
  include    "./code/screenHAM.asm"
  else
  include    "./code/screen.asm"                              
  endif	
  

  ;include    "./code/amigaSpecial.asm"

  include    "./data/Amiga_CM_player_imagedata.asm" 
  include    "./data/Amiga_CM_sound_data.asm"
  include    "./data/Amiga_CM_font_data.asm"
  include    "./data/Amiga_CM_enemies_imagedata.asm" 
  include    "./data/Amiga_CM_explosions_imagedata.asm" 
  include    "./data/Amiga_CM_extras_imagedata.asm" 
  include    "./data/Amiga_CM_bullets_imagedata.asm" 
  include    "./data/Amiga_CM_pots_imagedata.asm" 


mod:
 ; incbin     "./data/youtube.mod"
;end_chipmem:    



  section    data,data
  include    "./data/Amiga_FM_player_config.asm" 
  include    "./data/Amiga_FM_pots_config.asm" 
  include    "./data/Amiga_FM_tiles.asm"

  ifd        HAM_MODE
  SECTION    ChipData,  DATA_C
  endif

  include    "./data/Amiga_FM_level.asm"	
  include    "./data/Amiga_FM_level_config.asm"	
  
  include    "./data/Amiga_FM_screen_config.asm"	
  

  include    "./data/Amiga_FM_enemies_config.asm" 
  include    "./data/Amiga_FM_explosions_config.asm" 
  include    "./data/Amiga_FM_extras_config.asm" 
  include    "./data/Amiga_FM_sound_config.asm"
  include    "./data/Amiga_FM_font_config.asm"

  
  include    "./data/Amiga_FM_bullets_config.asm" 
  

  include    "./code/enemies.asm"
  include    "./code/player.asm"
  include    "./code/pot.asm"
  include    "./code/bullet.asm" 

  include    "./code/ptplayer.asm"
  include    "./engine/collision.asm" 
  include    "./code/sound.asm" 
  include    "./code/explosions.asm" 
  include    "./code/extras.asm" 
  include    "./code/game.asm" 
  include    "./engine/list.asm" 
   

  ifd        SCRIPTS_ENABLE
  include    "./generated/scripts.asm"  
  endif

  include    "./data/Amiga_FM_screen_data.asm"	
