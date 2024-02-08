

sound_update:  

  lea.l     soundEventPrio0,a1 
  tst.l     (a1)
  beq       .ss_done0
           
  lea       $dff000,a6
  move.l    (a1),a0         
  jsr       _mt_playfx
  move.l    #0,(a1)
.ss_done0
  rts
  
; and play

sound_init:
  lea       $dff000,a6            ; custom address
  sub.l     a0,a0
  moveq     #1,d0                 ; _mt_install_cia(a6=CUSTOM, a0=AutoVecBase, d0=PALflag.b)
  jsr       _mt_install_cia 
  rts 

; a0 pointer to mod
sound_initMod
  lea       $dff000,a6            ; custom address
  
  moveq     #0,d0                 ; _mt_init(a6=CUSTOM, a0=TrackerModule, a1=Samples|NULL, d0=InitialSongPos.b)
  sub.l     a1,a1
  jsr       _mt_init 
  rts

sound_playMod
  lea       $dff000,a6            ; custom address
  st        _mt_Enable
  rts

sound_stopMod
  lea       $dff000,a6            ; custom address
  move.w    0,_mt_Enable
  rts


