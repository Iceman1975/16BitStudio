; joystick status
joystick1_changed			dc.w 0
joystick1_left:				dc.b 0
joystick1_right:			dc.b 0
joystick1_up:				dc.b 0
joystick1_down:				dc.b 0
joystick1_button			dc.w 0
joystick1_button_automatic	dc.w 0

screen_width        		= 320
screen_height       		= 200
screen_bitplanesize     	= (screen_width/8)*screen_height
screen_colorDepth			= 4
screenBuffer_width    		= 320
screenBuffer_height     	= 200 ; 32 is ok, but two many tiles (currently)
screenBuffer_bitplanesize	= (screenBuffer_width/8)*screenBuffer_height
screenBuffer_size			= screenBuffer_bitplanesize*screen_colorDepth

tile_width					= 16
tile_height					= 16
tile_size					= ((tile_width/8)*tile_height)*screen_colorDepth



ENEMY_LIST_ENTRY_SIZE        = 2*29
ENEMY_AVTIVE_LIST_ENTRY_SIZE = 2*11
ENEMY_MAX_ON_SCREEN          = 10



                        ;status=0 inactive, 1=active, dying;    x;  y;  oldPosX;    oldPosY;    olderPosX;  olderPosY;  pointer to enemyList(longword); pointer_to_enemyBob; 


enemy_active_list   ds.w      ENEMY_AVTIVE_LIST_ENTRY_SIZE*ENEMY_MAX_ON_SCREEN
                    dc.w      -1

enemy_list_pointer  dc.l      enemy_list


PLAYER_SPEED                  = 2

PLAYER_BOUNDERY_X0            = 0
PLAYER_BOUNDERY_X1            = PLAYER_BOUNDERY_X0+320-48
PLAYER_BOUNDERY_Y0            = 44
PLAYER_BOUNDERY_Y1            = 220

player_score		dc.w 0
	

