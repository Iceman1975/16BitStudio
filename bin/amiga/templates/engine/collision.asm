

; collision turrican bullet with enemy
collision_checkBullets:
             cmp.l      #LIST_EMPTY_POINTER,bullet_active_list_start
             beq        c_bullet_done

             move.l     bullet_active_list_start,a0

c_bullet_loop:	
             cmp.w      #1,(a0)                                         ; active bullet
             beq        c_bullet_check                                  ; yes

c_bullet_loop_next:	
             bsr        list_next
             cmp.l      #LIST_EMPTY_POINTER,a0
             beq        c_bullet_done

             bra        c_bullet_loop


c_bullet_check:
             ifd        COLLISION_ONLY_SECOND_FRAME
             move.w     bullet_switch,d2
             cmp.w      6(a0),d2
             bne.s      c_bullet_loop_next
             endif

             move.l     INSTANCE_OBJECT_POINTER(a0),a4                  ; get bullet pointer
             move.w     INSTANCE_X(a0),d2                               ; dstx  bullet
             add.w      34(a4),d2
             move.w     INSTANCE_Y(a0),d3                               ; dsty  bullet
             add.w      36(a4),d3


  ;moveq     #20,d4
  ;moveq     #20,d5
  ;move.w    38(a4),d4                           ; src box width/2
  ;move.w    40(a4),d5                           ; src box height/2
    
             cmp.w      #0,INSTANCE_TYPE(a0)                            ; check if enemy bullet or player bullet
             bne        c_checkIfPlayerIsHit	
  
  ;bne       c_bullet_loop_next                  ; skip for debug
  
             lea.l      enemy_active_list,a1

c_bullet_enemy_loop
             cmp.w      #1,(a1)
             bne        c_bullet_enemy_no_hit                           ; no enemy in slot

             move.l     INSTANCE_OBJECT_POINTER(a1),a2                  ; get enemy
             move.w     INSTANCE_X(a1),d0                               ; srcx
             add.w      40(a2),d0                                       ; add coll x offset
             move.w     INSTANCE_Y(a1),d1                               ; srcy
             add.w      42(a2),d1                                       ; add coll y offset

  ;set width and height of coll box
             move.w     38(a4),d4                                       ; src box width/2
             move.w     40(a4),d5                                       ; src box height/2

             add.w      44(a2),d4                                       ; src box width/2 add  dst box width/2
             add.w      46(a2),d5                                       ; src box height/2 add dst box height/2

BoxCollision: 			
    ;d0-d5=srcx,srcy,dstx,dsty,src box width/2+dst 
	;box width/2,src box height/2+dst box height/2
             sub.w      d2,d0
             bpl.s      .nondx
             neg.w      d0
.nondx:  
             cmp.w      d4,d0                                           ;this will early-exit if bullets travel up or down.
             bhi        c_bullet_enemy_no_hit                           ;for left or right, change the x/y order.

             sub.w      d3,d1
             bpl.s      .nondy
             neg.w      d1
.nondy:  
             cmp.w      d5,d1
             bhi        c_bullet_enemy_no_hit	
  ;hit?
             ;move.w     #0,(a0)                             ; deactivate bullet
             ;sub.w      #1,bullet_count
             movem.l    a1,-(sp)
             lea.l      bullet_active_list_start,a1
             bsr        list_removeObject
             movem.l    (sp)+,a1

             cmp.l      #0,56(a4)                                       ; has bullet explosion
             beq        c_bullet_ex_sip

             move.l     56(a4),a3                                       ; bullet explosion
             move.w     INSTANCE_X(a0),d0                               ; bullet x pos
             move.w     INSTANCE_Y(a0),d1                               ; bullet y pos
             jsr        explosions_create

c_bullet_ex_sip:

             move.w     24(a4),d6                                       ; get bullet hitpoints
             sub.w      d6,INSTANCE_HITPOINTS(a1)                       ; reduce hitpoints  
             cmp.w      #0,INSTANCE_HITPOINTS(a1)                       ; dead?
             bge        c_bullet_enemy_no_hit  

             ;******* new removal ********** 
             movem.l    d0-d7/a0-a4,-(sp)   
             move.l     a1,a0
             lea.l      enemy_active_list_start,a1
             bsr        list_removeObject
             ;move       #0,(a1)                             ; dead-> deactivate
             movem.l    (sp)+,d0-d7/a0-a4
              ;******* new removal **********

             move.w     player_score,d6
             moveq      #0,d7
             add.w      28(a2),d7
             abcd       d7,d6
             bcc        .c_no_cc
             ror        #8,d6                                           ;add carry flag
             moveq      #0,d7                                           ; no value necessary; carry flag is added!
             abcd       d7,d6
             rol        #8,d6
.c_no_cc:
             move.w     d6,player_score

  
  ; create explosion

             cmp.l      #0,58(a2) 
             beq        c_bullet_enemy_no_ex_check_extra                ; ok no explosion for this enemy

             move.l     58(a2),a3                                       ; explosion pointer
             move.w     INSTANCE_X(a1),d0                               ; enemy x pos
             move.w     INSTANCE_Y(a1),d1                               ; enemy y pos
             jsr        explosions_create

;.nohitx:
                                       ;flags set to either hi or ls. or use Sls, -1=hit.
                                       
c_bullet_enemy_no_ex_check_extra:
             cmp.l      #0,62(a2)                                       ; check if extra exist for this enemy
             beq        c_bullet_enemy_no_hit 
             move.l     62(a2),a3                                       ; extra pointer
             move.w     INSTANCE_X(a1),d0                               ; enemy x pos
             move.w     INSTANCE_Y(a1),d1                               ; enemy y pos
             jsr        extras_create  
  ;move.w #$0070,$ff8240	
	
c_bullet_enemy_no_hit:
             adda.l     #LIST_ENTRY_SIZE,a1
             cmp.w      #1,(a1)
             beq        c_bullet_enemy_loop
             cmp.w      #-1,(a1)
             beq        c_bullet_loop_next                              ; no slot found
             bra        c_bullet_enemy_no_hit                           ; next enemy please     

c_bullet_done:
             rts
  
  
  
;**** player collision


c_checkIfPlayerIsHit:
  
             move.l     player_current,a2                               ; get player
             move.w     (a2),d0                                         ; srcx
             add.w      virtualscreen_xPosition,d0
             add.w      18(a2),d0                                       ; add coll x offset
             move.w     2(a2),d1                                        ; srcy  
             add.w      20(a2),d1                                       ; add coll y offset
             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition
  


  ;set width and height of coll box
             move.w     38(a4),d4                                       ; src box width/2
             move.w     40(a4),d5                                       ; src box height/2
    
             add.w      22(a2),d4                                       ; src box width/2 add  dst box width/2
             add.w      24(a2),d5                                       ; src box height/2 add dst box height/2
	
  
  
BoxCollisionPlayer: 			
    ;d0-d5=srcx,srcy,dstx,dsty,src box width/2+dst 
	;box width/2,src box height/2+dst box height/2
             sub.w      d2,d0
             bpl.s      nondxP
             neg.w      d0
nondxP:  
             cmp.w      d4,d0                                           ;this will early-exit if bullets travel up or down.
             bhi.s      c_bullet_player_no_hit                          ;for left or right, change the x/y order.

  ;works till here
  ;move.w #$0070,$ff8240
  
             sub.w      d3,d1
             bpl.s      nondyP
             neg.w      d1
nondyP:  
             cmp.w      d5,d1
             bhi.s      c_bullet_player_no_hit	
  
  
  
  ;hit?
             ;move.w     #0,(a0)                             ; deactivate bullet
             ;sub.w      #1,bullet_count
             movem.l    a1,-(sp)
             lea.l      bullet_active_list_start,a1
             bsr        list_removeObject
             movem.l    (sp)+,a1

             cmp.l      #0,56(a4)                                       ; has bullet explosion
             beq        c_bullet_ex_sipP

             move.l     56(a4),a3                                       ; bullet explosion
             move.w     2(a0),d0                                        ; bullet x pos
             move.w     4(a0),d1                                        ; bullet y pos
             jsr        explosions_create

c_bullet_ex_sipP:
	
	
  
             move.w     24(a4),d6                                       ; get bullet hitpoints
             sub.w      d6,player_energy                                ; reduce hitpoints  
             cmp.w      #0,player_energy                                ; dead?
             bge        c_bullet_player_no_hit  
  
             move.w     #GAME_STATE_DYING,game_state
  
  ; create explosion
  
             cmp.l      #0,36(a2) 
             beq        c_bullet_player_no_hit                          ; ok no explosion for player

             move.l     36(a2),a3                                       ; explosion pointer
             move.w     (a2),d0                                         ; player x pos
             move.w     2(a2),d1                                        ; player y pos
             add.w      virtualscreen_xPosition,d0                      ; add current virtualscreen_xPosition
             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition
             jsr        explosions_create


c_bullet_player_no_hit:
             bra        c_bullet_loop_next                              ; back to main loop
  

;**** extra collision


collision_checkExtras:
  
             move.l     player_current,a2                               ; get player
             move.w     (a2),d0                                         ; srcx
             add.w      virtualscreen_xPosition,d0
             add.w      18(a2),d0                                       ; add coll x offset
             move.w     2(a2),d1                                        ; srcy  
             add.w      20(a2),d1                                       ; add coll y offset
             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition
  
             lea.l      extra_active_list,a0

.c_extra_loop:	
             cmp.w      #1,(a0)                                         ; active bullet
             beq        .c_extra_check                                  ; yes
             cmp.w      #-1,(a0)                                        ; no more bullets?
             beq        .c_extra_done
.c_extra_loop_next:	
             adda.l     #LIST_ENTRY_SIZE,a0                             ;  next slot please
             bra        .c_extra_loop
  
.c_extra_check:
             move.l     14(a0),a4                                       ; get extra pointer
             move.w     2(a0),d2                                        ; dstx  extra
             add.w      46(a4),d2
             move.w     4(a0),d3                                        ; dsty  extra
             add.w      48(a4),d3


  ;set width and height of coll box
             move.w     50(a4),d4                                       ; src box width/2
             move.w     52(a4),d5                                       ; src box height/2
    
             add.w      22(a2),d4                                       ; src box width/2 add  dst box width/2
             add.w      24(a2),d5                                       ; src box height/2 add dst box height/2
	
  
  
.boxCollisionPlayer: 			
    ;d0-d5=srcx,srcy,dstx,dsty,src box width/2+dst 
	;box width/2,src box height/2+dst box height/2
             sub.w      d2,d0
             bpl.s      .nondxP
             neg.w      d0
.nondxP:  
             cmp.w      d4,d0                                           ;this will early-exit if bullets travel up or down.
             bhi.s      .c_extra_player_no_hit                          ;for left or right, change the x/y order.

  ;works till here
  ;move.w #$0070,$ff8240
  
             sub.w      d3,d1
             bpl.s      .nondyP
             neg.w      d1
.nondyP:  
             cmp.w      d5,d1
             bhi.s      .c_extra_player_no_hit	
  
  
  
  ;hit?


             cmp.l      #0,34(a4)                                       ; has extra explosion
             beq        .c_extra_no_explosion

             move.l     34(a4),a3                                       ; extra explosion/animation
             move.w     2(a0),d0                                        ; extra x pos
             move.w     4(a0),d1                                        ; extra y pos
             jsr        explosions_create

.c_extra_no_explosion:
  ; get your reward:
             movem.l    d0-d7/a0-a4,-(sp) 
             jsr        extras_activate
             movem.l    (sp)+,d0-d7/a0-a4
             
             move.w     #0,(a0)                                         ; deactivate extra

             lea.l      extra_active_list_start,a1
             bsr        list_removeObject
             
             rts                                                        ; end after first

.c_extra_player_no_hit:
             bra        .c_extra_loop_next                              ; back to main loop

.c_extra_done:
  
             rts
  
             ifd        COLLISION_TILES
collision_checkTiles:
             moveq      #0,d0
             moveq      #0,d1
             move.l     player_current,a2                               ; get player
             move.w     (a2),d0                                         ; srcx
             add.w      virtualscreen_xPosition,d0
             add.w      40(a2),d0                                       ; add coll x offset
  
             move.w     2(a2),d1                                        ; srcy  
             add.w      42(a2),d1                                       ; add coll y offset

             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition

             lsr.w      #4,d0                                           ; Div 16
             lsr.w      #4,d1                                           ; Div 16
             mulu.w     #tile_no_x,d1                                   ; mul tile per row
             add.w      d0,d1                                           ; y+x

             lsl.w      #2,d1                                           ; *4 (one longword per tile)

             move.l     levelMetapointer,a0
             adda.l     d1,a0

 
             cmp.b      #1,(a0)                                         ;wall?
             beq        collTilesHit                                    ; yes -> always hit
  
             cmp.b      #2,(a0)                                         ; stairs 
             beq        collTilesNoHit -> no hit

             cmp.b      #0,(a0)                                         ; no obstacle
             beq        collStairCheck
             bra        collTilesNoHit                                  ; done -> no hit so far
  

collStairCheck:
             move.b     old_height,d1                                   ; height change?
             cmp.b      1(a0),d1
             beq        collTilesNoHit                                  ; no -> no hit
             move.b     old_tile_type,d1
             cmp.b      #2,d1
             bne        collTilesHit
             bra        collTilesNoHit

collTilesHit:
             move.w     old_player_pos_x,(a2)                           ; rollback
             move.w     old_player_pos_y,2(a2)
             bsr        checkTrigger					   
             rts

collTilesNoHit:                                 ; update old values
             move.b     1(a0),old_height
             move.b     (a0),old_tile_type
             bsr        checkTrigger					   
             rts
             endif


collision_checkPlayerWithEnemy:
  
             move.l     player_current,a2                               ; get player
             move.w     (a2),d0                                         ; srcx

             add.w      virtualscreen_xPosition,d0 
             add.w      18(a2),d0                                       ; add coll x offset
  
             move.w     2(a2),d1                                        ; srcy  
             add.w      20(a2),d1                                       ; add coll y offset
             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition
  
             lea.l      enemy_active_list,a0

.c_ene_loop:	
             cmp.w      #1,(a0)                                         ; active enemy
             beq        .c_ene_check                                    ; yes
             cmp.w      #-1,(a0)                                        ; no more enemy?
             beq        .c_ene_done
.c_ene_loop_next:	
             adda.l     #LIST_ENTRY_SIZE,a0                             ;  next slot please
             bra        .c_ene_loop
  
.c_ene_check:
             move.l     INSTANCE_OBJECT_POINTER(a0),a4                  ; get enemy pointer
             move.w     INSTANCE_X(a0),d2                               ; dstx  ene
             add.w      40(a4),d2
             move.w     INSTANCE_Y(a0),d3                               ; dsty  ene
             add.w      42(a4),d3


  ;set width and height of coll box
             move.w     44(a4),d4                                       ; src box width/2
             move.w     46(a4),d5                                       ; src box height/2
    
             add.w      22(a2),d4                                       ; src box width/2 add  dst box width/2
             add.w      24(a2),d5                                       ; src box height/2 add dst box height/2
	
  
  
.boxCollisionPlayer: 			
    ;d0-d5=srcx,srcy,dstx,dsty,src box width/2+dst 
	;box width/2,src box height/2+dst box height/2
             sub.w      d2,d0
             bpl.s      .nondxP
             neg.w      d0
.nondxP:  
             cmp.w      d4,d0                                           ;this will early-exit if bullets travel up or down.
             bhi.s      .c_ene_player_no_hit                            ;for left or right, change the x/y order.

  ;works till here
  ;move.w #$0070,$ff8240
  
             sub.w      d3,d1
             bpl.s      .nondyP
             neg.w      d1
.nondyP:  
             cmp.w      d5,d1
             bhi.s      .c_ene_player_no_hit	
  
  
  
  ;hit?

             ;******* new removal ********** 
             lea.l      enemy_active_list_start,a1
             bsr        list_removeObject
              ;******* new removal **********

             cmp.l      #0,58(a4)                                       ; has ene explosion
             beq        .c_ene_no_explosion

             move.l     58(a4),a3                                       ; ene explosion/animation
             move.w     INSTANCE_X(a0),d0                               ; ene x pos
             move.w     INSTANCE_Y(a0),d1                               ; ene y pos
             jsr        explosions_create

.c_ene_no_explosion:
  ; kill player:
             move.w     #GAME_STATE_DYING,game_state
			 
			 ; create player explosion
  
             cmp.l      #0,36(a2) 
             beq        .c_ene_done                                     ; ok no explosion for player

             move.l     36(a2),a3                                       ; explosion pointer
             move.w     (a2),d0                                         ; player x pos
             move.w     2(a2),d1                                        ; player y pos
             add.w      virtualscreen_xPosition,d0                      ; add current virtualscreen_xPosition
             add.w      virtualscreen_yPosition,d1                      ; add current virtualscreen_yPosition
             jsr        explosions_create
			 
  
             rts                                                        ; end after first

.c_ene_player_no_hit:
             bra        .c_ene_loop_next                                ; back to main loop

.c_ene_done:
  
             rts



             ifd        PLAYER_ANIMATION_JUMPER 

; d0 coll offset x
; d1 coll offset y
; old pos in old_player_pos_x and old_player_pos_y
coll_temp_x  dc.w       0
coll_temp_y  dc.w       0
collision_checkTilesByDir:
  ;moveq     #0,d0
  ;moveq     #0,d1
             move.l     player_current,a2                               ; get player
             add.w      (a2),d0                                         ; srcx
             add.w      virtualscreen_xPosition,d0
             add.w      2(a2),d1                                        ; srcy  
  ;add.w     virtualscreen_yPosition,d1          ; add current virtualscreen_yPosition
             move.w     d1,coll_temp_y                                  ; save for response
  
  ;add.w     40(a2),d0                           ; add coll x offset  
  ;add.w     42(a2),d1                           ; add coll y offset

             lsr.w      #4,d0                                           ; Div 16
             lsr.w      #4,d1                                           ; Div 16
             mulu.w     #tile_no_x,d1                                   ; mul tile per row
             add.w      d0,d1                                           ; y+x

             lsl.w      #2,d1                                           ; *4 (one longword per tile)

             move.l     levelMetapointer,a0
             adda.l     d1,a0

 
             cmp.b      #1,(a0)                                         ;wall?
             beq        collTilesHit                                    ; yes -> always hit
  
             cmp.b      #2,(a0)                                         ; stairs 
             beq        collTilesNoHit                                  ;-> no hit

             cmp.b      #0,(a0)                                         ; no obstacle
             beq        collStairCheck
             bra        collTilesNoHit                                  ; done -> no hit so far
  

collStairCheck:
             move.b     old_height,d1                                   ; height change?
             cmp.b      1(a0),d1
             beq        collTilesNoHit                                  ; no -> no hit
             move.b     old_tile_type,d1
             cmp.b      #2,d1
             bne        collTilesHit
             bra        collTilesNoHit

collTilesHit:
  ;move.w    old_player_pos_x,(a2)               ; rollback
  ;move.w    old_player_pos_y,2(a2)
             bsr        checkTrigger
             move.w     coll_temp_x,d0
             and.l      #$f,d0
             swap       d0
             move.w     coll_temp_y,d0
             and.l      #$f,d0
;  tst  d0					; correction
;  beq.s .colldone
;  moveq #1,d0
;.colldone  
  ;move.w #$0070,$ff8240
             rts

collTilesNoHit:                                 ; update old values
             move.b     1(a0),old_height
             move.b     (a0),old_tile_type
             bsr        checkTrigger
             moveq      #-1,d0
  ;move.w #$0700,$ff8240
             rts
             endif

             ifd        COLLISION_TILES
;a0 pointer to tile meta data
checkTrigger:
             tst.b      3(a0)
             beq        .done
             moveq      #0,d0
             move.b     3(a0),d0
             lsl.w      #4,d0  
			 
             lea.l      triggerLevel0,a0
			 ;move.l    levelMetapointer,a0
             add.l      d0,a0
             tst.w      (a0)                                            ;still active?
             beq        .done
	
             tst.w      2(a0)                                           ; trigger for enemies or extra
             bne        .levelEnd                                       ; other
	
             tst.l      4(a0)
             beq        .noEnemies
	
             move.w     #0,(a0)                                         ; deactivate trigger
             move.l     4(a0),a4
             bsr        enemies_createEnemyByTrigger
.noEnemies:

		
.done:
             rts
	
.levelEnd:
             move.w     #1,collision_end_level
             rts
             endif