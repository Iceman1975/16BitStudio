INSTANCE_STATUS           = 0                                          ;W
INSTANCE_X                = 2                                          ;W
INSTANCE_Y                = 4                                          ;W
INSTANCE_COLL_FLAG        = 6                                          ;W
INSTANCE_DRAW_FLAG        = 8                                          ;W
INSTANCE_PATH_POINTER     = 10                                         ;L
INSTANCE_OBJECT_POINTER   = 14                                         ;L
INSTANCE_BOB_POINTER      = 18                                         ;L
INSTANCE_ANIMATION_OFFSET = 22                                         ;W
INSTANCE_HITPOINTS        = 24                                         ;W
INSTANCE_TYPE             = 24                                         ;W
INSTANCE_LIVE_COUNTER     = 26                                         ;W
INSTANCE_OBJECT_SCRIPT    = 28                                         ;L
INSTANCE_PRESECCOR        = 32                                         ;L
INSTANCE_SUCCESOR         = 36                                         ;L

LIST_ENTRY_SIZE           = 40

LIST_EMPTY_POINTER        = -1


;---- enemy

                        ;status=0 inactive, 1=active, 2=diabled;    
                        ;x  
                        ;y  
                        ;coll flag      ---- new
                        ;oldPosY;   = 0 ---- new
                        ;olderPosX;  pointer_to_path (l statt w)-- new
                        ;olderPosY;  -- new
                        ;pointer to enemyList(longword); 
                        ;pointer_to_enemyBob;
;--
    ;anumationOffset
;--

                        ;hitpoints(w) 

;--------  bullets
;status=0 inactive, 1=active,  
;x,
;y,
;coll flag,     --- new
;draw flag      --- new
;olderPosX,     pointer_to_path (l statt w)-- new
;olderPosY,
;pointerToBullet(longword),
;--
;pointer_to_bulletBob;
;--
;anumationOffset
;
;type (0=player,1=enemy),
;liveTimeCounter

;-------extras
;status=0 inactive, 1=active, dying;    
;x; 
;y;  
;oldPosX;    
;oldPosY;    
;olderPosX;  pointer_to_path (l statt w)-- new
;olderPosY;  
;pointer to extraList(longword); 
;pointer_to_extraBob; 
;anumationOffset -- new

;-------explosions:
;status=0 inactive, 1=active, dying;    
;x;  
;y;  
;oldPosX;    
;oldPosY;    
;olderPosX;  pointer_to_path (l statt w)-- new
;olderPosY;  
;pointer to enemyList(longword); 
;pointer_to_enemyBob; 
;anumationOffset -- new

              xdef      list_findSlot
list_findSlot:
; find empty slot in list
; a0 = Pointer to list

              cmp.w     #0,(a0)
              beq.s     .lfs_done 
              adda.l    #LIST_ENTRY_SIZE,a0
              cmp.w     #-1,(a0) 
              bne.s     list_findSlot
              move.l    #LIST_EMPTY_POINTER,a0
.lfs_done:
              rts


              xdef      list_removeObject
list_removeObject:
; Removes instance from list
; a0 = Pointer to Instance
; a1 = pointer to first element of list

              move.w    #0,(a0)                                        ;  set inactive    

              cmp.l     #LIST_EMPTY_POINTER,INSTANCE_SUCCESOR(a0)
              bne.s     .lro_notLast
              cmp.l     #LIST_EMPTY_POINTER,INSTANCE_PRESECCOR(a0)
              beq.s     .lro_emptyQueue

              move.l    INSTANCE_PRESECCOR(a0),4(a1)                   ; set preseccor as last
              move.l    INSTANCE_PRESECCOR(a0),a1
              move.l    #LIST_EMPTY_POINTER,INSTANCE_SUCCESOR(a1)
              rts

.lro_notLast:  
              cmp.l     #LIST_EMPTY_POINTER,INSTANCE_PRESECCOR(a0)     ;first element?
              bne.s     .lro_inTheMiddle                               ; no -> in the middle
              move.l    INSTANCE_SUCCESOR(a0),a0                       ; new first
              move.l    a0,(a1)                                                   
              move.l    #LIST_EMPTY_POINTER,INSTANCE_PRESECCOR(a0)     ; remove preseccor
              cmp.l     #LIST_EMPTY_POINTER,INSTANCE_SUCCESOR(a0)
              beq.s     .lro_noLastDone
              move.l    INSTANCE_SUCCESOR(a0),a1
              move.l    a0,INSTANCE_PRESECCOR(a1)
.lro_noLastDone:
              rts
  
.lro_inTheMiddle:
              move.l    INSTANCE_PRESECCOR(a0),a1                      ;fetch preseccor
              move.l    INSTANCE_SUCCESOR(a0),INSTANCE_SUCCESOR(a1)    ;link preseccor successor to instance successor
              move.l    INSTANCE_SUCCESOR(a0),a0  
              move.l    a1,INSTANCE_PRESECCOR(a0)
              rts
.lro_emptyQueue:
              move.l    #LIST_EMPTY_POINTER,(a1)                       ; first and last pointer NULL
              move.l    #LIST_EMPTY_POINTER,4(a1)  
              rts



              xdef      list_next
list_next:
; get next element in list
; a0 = Pointer to Instance

              move.l    INSTANCE_SUCCESOR(a0),a0
              rts

              xdef      list_create
list_create:
; creates new empty instance; set active flag and pre and sucessor
; a0 = Pointer to  list (e.g enemy_active_list)
; a1 = Pointer to start instance in list

              bsr       list_findSlot
              cmp.l     #LIST_EMPTY_POINTER,a0
              beq.s     .lc_done
              move.w    #1,(a0)
              move.l    #LIST_EMPTY_POINTER,INSTANCE_SUCCESOR(a0)      ; new so no successor
 
  ;put into list
              cmp.l     #LIST_EMPTY_POINTER,(a1)                       ; check if first element
              beq.s     .lc_isFirst     

              move.l    4(a1),a6                                       ; fetch current last elememt
              move.l    a0,4(a1)                                       ; set new element as last element
  
              move.l    a0,INSTANCE_SUCCESOR(a6)                       ;  set pre and succ
              move.l    a6,INSTANCE_PRESECCOR(a0)
              rts
.lc_isFirst:
              move.l    #LIST_EMPTY_POINTER,INSTANCE_PRESECCOR(a0)
              move.l    a0,(a1)+                                       ; start pointer = new element
              move.l    a0,(a1)                                        ; last= same (only one element)
.lc_done:
              rts


              xdef      list_animateObject
list_animateObject:
; a0 = pointer to current list item
; a3 = pointer to animation 
; d1 = max animation steps *2 
; d0 working register

              moveq     #0,d0
              add.w     #2,INSTANCE_ANIMATION_OFFSET(a0)               ; increase animation counter
              move.w    INSTANCE_ANIMATION_OFFSET(a0),d0               ; load animation counter

              cmp.w     d1,d0                                          ; max animation reached
              bge       .reset_animation

              bra       .set_animation_pointer

.reset_animation:
              move.w    #0,INSTANCE_ANIMATION_OFFSET(a0)               ; reset counter
              moveq     #0,d0

.set_animation_pointer
              adda.l    d0,a3
                    
              move.w    (a3),d0                                        ; add pointer to current frame
              add.l     d0,INSTANCE_BOB_POINTER(a0)                    ; set pointer to current image
              rts


              xdef      list_moveObjectOnPath
list_moveObjectOnPath:
; a0 = pointer to current list item
; d0,a1  working register

              move.l    INSTANCE_PATH_POINTER(a0),a1                   ; get path
              move.w    (a1),d0                                        ; add xSpeed
              add.w     d0,INSTANCE_X(a0)                              ; 
	
              move.w    2(a1),d0                                       ; add ySpeed
              add.w     d0,INSTANCE_Y(a0)                              ; add ySpeed

              add.l     #4,INSTANCE_PATH_POINTER(a0)                   ; increase enemy.path

              move.l    INSTANCE_PATH_POINTER(a0),a1                   ; get current path pointer
              move.w    (a1),d0                                        ; check if path ends
              cmp.w     #10,d0
              blt       .move_done 
              and.l     #$FFFF,d0                                      ; remove upper word
              sub.l     d0,INSTANCE_PATH_POINTER(a0)                   ; back to th start
.move_done:
              rts


              xdef      list_checkObjectIsOnScreen
list_checkObjectIsOnScreen:
;a0        = pointer to current list item
;d1  = destination state if not on screen anymore
;d3 = width
;d5 = height
; d4,d2 working register

              move.w    #1,(a0)                                        ; init = on screen  
              move.w    INSTANCE_Y(a0),d2                              ; sub level pos y
              sub.w     virtualscreen_yPosition,d2
              add.w     d2,d5                                          ; d2=y; d5=y+height

              cmp.w     #0,d5
              bgt       .check_bottom
              move.w    d1,(a0)
              bra.s     .check_done
.check_bottom:
              cmp.w     #screen_height-1,d2
              blt       .checkX
              move.w    d1,(a0)
              bra.s     .check_done
.checkX
              move.w    INSTANCE_X(a0),d4         
              sub.w     virtualscreen_xPosition,d4	    
					            
.check_right:    
              cmp.w     #screen_width-1,d4
              blt       .check_left                                    ; still on buffer screen
              move.w    d1,(a0) 
              bra.s     .check_done

.check_left:  add.w     d3,d4                                          ; add width
              cmp.w     #0,d4
              bgt       .check_done                                    ; still on buffer screen
              move.w    d1,(a0) 
.check_done:
              rts

 