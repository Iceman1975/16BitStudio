enemyBehavior_setAnimationFrame:
  move.w     24(a2),d2                           ; check max
  lsr.w      #1,d2
  cmp.w      d2,d0   
  ble        .enemyBehavior_setAnimationFrame	
  moveq      #0,d0                               ; out of range, correct value
.enemyBehavior_setAnimationFrame
  mulu       18(a2),d0                           ; frame * size
  move.l     14(a2),d1                           ;pointer to image
  add.l      d0,d1
  move.l     d1,18(a0)                           ; set pointer to current image
  rts

enemyBehavior_playSound:
                         ;set sound and prio
  move.l     a5,a6                               ; load sound
  move.w     10(a6),d0                           ; get prio
  lea.l      soundEventPrio0,a6
  adda.w     d0,a6
  move.l     a5,(a6)                             ; set sound 
  rts

enemyBehavior_createBullet:
  movem.l    d0-d7/a0-a4,-(sp)  
  move.l     a5,a2
  move.w     d0,d3
  move.w     d1,d4
  moveq      #1,d5
					; a2 bullet pointer to be created
					; d3 shooter x
					; d4 shooter y
					; d5 shooter type (0=player, 1=enemy)						
					
  jsr        bullet_create
  movem.l    (sp)+,d0-d7/a0-a4
  rts