
;**************************************************************************************
; In egnine constants:
ENEMY_LIST_ENTRY_SIZE        = 2*37
ENEMY_AVTIVE_LIST_ENTRY_SIZE = 2*12

GAME_STATE_INIT=0
GAME_STATE_RUNNING=1
GAME_STATE_DONE=2
GAME_STATE_OVER=3
GAME_STATE_RESPAWN=4
GAME_STATE_DYING=5

GAME_DYING_INIT=25

; joystick status
joystick1_changed			dc.w 0
joystick1_left:				dc.b 0
joystick1_right:			dc.b 0
joystick1_up:				dc.b 0
joystick1_down:				dc.b 0
joystick1_button			dc.w 0
joystick1_button_automatic	dc.w 0

enemy_active_list            ds.w    LIST_ENTRY_SIZE*ENEMY_MAX_ON_SCREEN
                             dc.w    -1

enemy_active_list_start      dc.l    -1
enemy_active_list_end        dc.l    -1


explosion_active_list        ds.w    LIST_ENTRY_SIZE*EXPLOSION_MAX_ON_SCREEN
                             dc.w    -1

explosion_active_list_start  dc.l    -1
explosion_active_list_end    dc.l    -1


bullet_active_list:
                             ds.b    LIST_ENTRY_SIZE*BULLET_COUNT_MAX
                             dc.w    -1 

bullet_active_list_start     dc.l    -1
bullet_active_list_end       dc.l    -1



extra_active_list            ds.w    LIST_ENTRY_SIZE*EXTRA_MAX_ON_SCREEN
                             dc.w    -1

extra_active_list_start      dc.l    -1
extra_active_list_end        dc.l    -1

player_lives		dc.w PLAYER_LIVES_INITAL
player_energy		dc.w PLAYER_ENERGY_INITAL
player_score		dc.l 0
player_current      dc.l player0

game_state			dc.w GAME_STATE_INIT
game_dying_counter 	dc.w GAME_DYING_INIT	

soundEventPrio0             dc.l    0
soundEventPrio1             dc.l    0
soundEventPrio2             dc.l    0
soundEventPrio3             dc.l    0

old_player_pos_x            dc.w    0
old_player_pos_y            dc.w    0
old_height                  dc.b    0
old_tile_type               dc.b    0
player_direction            dc.w    0

collision_end_level 		dc.w 0
