SCROLLING_DYNAMIC_FLAG        = 1
COLLISION_TILES               = 1
PLAYER_ANIMATION_GUNNER       = 1 
SCROLLING_ALLOW_BACK_FLAG     = 1 
SCRIPTS_ENABLE                = 1 
BUlLET_GROUP_SUPPPORT         = 1 
screen_width                  = 320
screen_height                 = 256
screen_bitplanesize           = (screen_width/8)*screen_height
screen_colorDepth             = 4
screenBuffer_width            = (screen_width+64+32)
screenBuffer_height           = screen_height+32 ; 32 is ok, but two many tiles (currently)
screenBuffer_bitplanesize     = (screenBuffer_width/8)*screenBuffer_height
screenBuffer_size             = screenBuffer_bitplanesize*screen_colorDepth
screenBuffer_modulo           = (screenBuffer_width_Byte*4)-(screen_width/8)-2
screenBuffer_width_Byte       = screenBuffer_width/8
screenBuffer_lineSize         = screenBuffer_width_Byte*screen_colorDepth
tile_width                    = 16
tile_height                   = 16
tile_size                     = ((tile_width/8)*tile_height)*screen_colorDepth
tile_no_x                     = 20
VIRTUALSCREEN_YPOSITION_START = 2544
;ENEMY_MAX_ON_SCREEN           = 30
EXPLOSION_MAX_ON_SCREEN       = 10
EXTRA_MAX_ON_SCREEN           = 2
BULLET_COUNT_MAX              = 30
;PLAYER_LIVES_INITAL           = 1
;PLAYER_ENERGY_INITAL          = 1
PLAYER_ENERGY_MAX             = 10
PLAYER_SPEED                  = 2
PLAYER_BOUNDERY_X0            = 0
PLAYER_BOUNDERY_X1            = PLAYER_BOUNDERY_X0+320-32
PLAYER_BOUNDERY_Y0            = 0
PLAYER_BOUNDERY_Y1            = 200-32
SCROLL_BOUNDERY_X0            = 100
SCROLL_BOUNDERY_X1            = 320-150
SCROLL_BOUNDERY_Y0            = 100
SCROLL_BOUNDERY_Y1            = 256-80
SHOOTER_NO_OF_SPRITE          = 31 ; size -1 
SHOOTER_IDLE_FRAME_NO         = SHOOTER_NO_OF_SPRITE/2
SHOOTER_SIZE_SIZE             = (32+5)*4 ;(26+5)*4 ;(in bytes) 1 sprite
STATS_LIVES_POS_X             = 18
STATS_LIVES_POS_Y             = 240-18
STATS_SCORE_POS_X             = 320-18
STATS_SCORE_POS_Y             = 240-18
SCROLL_X_MAX                  = 0
ENEMY_DEACTIVATION_MODE       = 0