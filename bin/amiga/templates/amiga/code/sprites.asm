SPRITE_LIST_LENGTH = 35

spritePointerStart    dc.l      -1,0
spritePointerList     ds.l      SPRITE_LIST_LENGTH*2
spritePointerListNum  dc.w      0


sprite_resetPointer:
                      move.w    #0,spritePointerListNum
                      rts

;a0 pointer to object
;d0 y-sort value
sprite_addPointer:
                      lea       spritePointerList(pc),a2
                      move.l    a0,d1
                      moveq     #0,d2
                      move.w    spritePointerListNum(pc),d2
                      lsl.w     #3,d2                                  ; *8 
                      add.l     d2,a2
                      move.l    d0,(a2)+                               ; set y-value
                      move.l    d1,(a2)+                               ; set pointer
                      add.w     #1,spritePointerListNum

.endCheck:            cmp.l     #-1,-16(a2)
                      beq.s     .done

.swap:                move.l    -8(a2),d2 
                      cmp.l     -16(a2),d2
                      bge.s     .done

                      move.l    -4(a2),d3
                      move.l    -16(a2),-8(a2)
                      move.l    -12(a2),-4(a2)
                      move.l    d2,-16(a2)
                      move.l    d3,-12(a2)
                      suba.l    #8,a2
                      bra.s     .endCheck
.done:
                      rts



sprites_updateCopperList:
                      ;bsr       screen_calcScrollWaitBottom           ; put scroll wait into d6
                    
                      ;d6 = vert wait 
                      lea.l     copperSlot,a1
                      lea.l     spritePointerList,a2
                      move.w    spritePointerListNum,d7
                      move.w    screenBottomWait,d6

                      cmp.w     #0,d7
                      beq       .uc_done                               ; nothing to do (empty list)

                      sub.w     #1,d7

.uc_loop:  
  
                      move.l    4(a2),a0                               ;a0 pointer to sprite data
                      move.l    (a2),d0                                ; load y
  
                      **** scroll check
                      cmp.w     #-1,d6
                      beq       .uc_scroll_skip
                      cmp.w     d0,d6
                      bgt       .uc_scroll_skip                       
                      bsr       screen_addScreenBottomToCopperList


.uc_scroll_skip:        
                      cmp.w     #(200+44),d0                           ; sprite is lower than footer
                      bge       .uc_done                               ;-> stop

                      move.b    d0,(a1)                                ; copper wait at y
                      move.b    #$01,1(a1)
                      move.w    #$ff00,2(a1)
                      cmp.l     #-1,a0
                      bne.s     .check_pot
                      ;move.w    #$f00,$dff180
                      bsr       sprite_addPlayerToCopperList
                      bra       .uc_skip
.check_pot: 
                      cmp.l     #-2,a0
                      bne.s     .check_pot2
                      ;move.w    #$ff0,$dff180
                      lea.l     spriteChannel4,a4                      ; pot0 always use channel 4,5
                      lea.l     pots,a0
                      bsr       sprite_addPotSpriteToCopperList
                      bra       .uc_skip            
.check_pot2: 
                      cmp.l     #-3,a0
                      bne.s     .check_type
                      ;move.w    #$ff0,$dff180
                      lea.l     spriteChannel6,a4                      ; pot0 always use channel 6,7
                      lea.l     pots+POT_ENTRY_SIZE,a0
                      bsr       sprite_addPotSpriteToCopperList
                      bra       .uc_skip            
        
.check_type:
                      move.w    INSTANCE_TYPE(a0),d0
                      cmp.w     #2,d0
                      bne.s     .check_isExplosion 
                      ;move.w    #$fff,$dff180
                      bsr       sprite_addEnemyToCopperList
                      ;move.w    #$0,$dff180
                      bra       .uc_skip

.check_isExplosion
                      cmp.w     #3,d0
                      bne.s     .check_isExtra 
                    
                      bsr       sprite_addExplosionToCopperList
                      bra       .uc_skip
.check_isExtra
                      cmp.w     #4,d0
                      bne.s     .check_isBullet 
                    
                      bsr       sprite_addExtraToCopperList
                      bra       .uc_skip
.check_isBullet: 
                      ;move.w    #$f,$dff180
                      bsr       sprite_addBulletToCopperList
                      ;move.w    #$0,$dff180
.uc_skip:
                      adda.l    #8,a2
                      dbf       d7,.uc_loop

	
.uc_done:

                      cmp.w     #-1,d6                                 ; bottom still not set -> please do now
                      beq       .uc_scroll_skip2
                      bsr       screen_addScreenBottomToCopperList
.uc_scroll_skip2:        
  ;****
                      ;move.w    #$0,$dff180
                      
                      rts

sprite_addBulletToCopperList:
                      ; fetch height
                      move.l    INSTANCE_OBJECT_POINTER(a0),a5
                      move.w    6(a5),d3                               ; load height
                      move.l    64(a5),a4

                      move.w    42(a5),d0	
                      cmp.w     #4,d0
                      beq.s     .skip
                      bsr       sprite_add4ColorSpriteToCopperList
                      rts
.skip:
                      move.w    18(a5),d2                              ;offset to 2 sprite
                      bsr       sprite_add16ColorSpriteToCopperList
                      rts

sprite_addEnemyToCopperList:
                      ; fetch height
                      move.l    INSTANCE_OBJECT_POINTER(a0),a5
                      move.w    4(a5),d3                               ; load height
                      move.w    18(a5),d2                              ;offset to 2 sprite
                      move.l    74(a5),a4
                      bsr       sprite_add16ColorSpriteToCopperList
                      rts


sprite_addExplosionToCopperList:
                      ; fetch height
                      move.l    INSTANCE_OBJECT_POINTER(a0),a5
                      move.w    6(a5),d3                               ; load height
                      move.w    14(a5),d2                              ;offset to 2 sprite
                      move.l    34(a5),a4
                      bsr       sprite_add16ColorSpriteToCopperList
                      rts

sprite_addExtraToCopperList:
                      ; fetch height
                      move.l    INSTANCE_OBJECT_POINTER(a0),a5
                      move.w    6(a5),d3                               ; load height
                      move.w    14(a5),d2                              ;offset to 2 sprite
                      move.l    58(a5),a4
                      bsr       sprite_add16ColorSpriteToCopperList
                      rts

sprite_add16ColorSpriteToCopperList:
                      move.l    INSTANCE_BOB_POINTER(a0),d0
                      addq.l    #4,d0

                      move.w    (a4),8(a1)                             ;SPRxPTL
                      move.w    d0,10(a1)                              ; low pointer to sprite data

                      move.w    2(a4),4(a1)                            ;SPRxPTH
                      swap      d0
                      move.w    d0,6(a1)                               ; hight pointer to sprite data

	                  ;dc.w	$0140,$784c ; SPR0POS  

                      move.w    4(a4),12(a1)                           ; SPRxPOS
                      move.w    6(a4),16(a1)                           ; SPRxCTL 
  
                      move.w    INSTANCE_X(a0),d0                      ; load x
                      sub.w     virtualscreen_xPosition,d0
                      add.w     #(2*57)+16,d0
                   
                      move.w    2(a2),d1                               ; load y (second word)

                      move.b    d1,14(a1)                              ; set y

                      move.w    #128,d5                                ; bset #8,d5 (=attached sprites)
                      btst      #8,d1                                  ; 8 Y Bit exist?
                      beq       .uc_noY8
                      ;bset      #2,d5
                      or        #%0100,d5
  
.uc_noY8:
                      add.w     d3,d1                                  ; y+height
                      ;move.w    #0,18(a1)                              ;  clean up
                      move.b    d1,18(a1)                              ; set height

                      btst      #8,d1                                  ; byte 8 exists for y+height?
                      beq       .uc_noZ8
                      ;bset      #1,d5
                      or        #%0010,d5
  
.uc_noZ8:
                      lsr       #1,d0                                  ; x1-x7 only
                      bcc.s     .uc_noX0
                      ;bset      #0,d5
                      or        #%0001,d5
.uc_noX0:

                      move.b    d0,15(a1)                              ; set x
                      move.b    d5,19(a1) 

                      move.w    10(a4),20(a1)                          ;SPRxPTH
                      move.w    8(a4),24(a1)                           ;SPRxPTL

                      move.w    12(a4),28(a1)                          ;SPRxPOS
                      move.w    14(a4),32(a1)                          ;SPRxCTL

                      move.w    14(a1),30(a1)                          ;copy
                      move.w    18(a1),34(a1)



                      move.l    INSTANCE_BOB_POINTER(a0),d0

                      addq.l    #4,d0
                      
                      add.w     d2,d0                                  ; + offset to 2 sprite
                      move.w    d0,26(a1)                              ; low pointer to sprite data

                      swap      d0
                      move.w    d0,22(a1)                              ; hight pointer to sprite data

                      adda.l    #(20+16),a1                            ; 9 instructions
                      rts





sprite_add4ColorSpriteToCopperList:
                      move.l    INSTANCE_BOB_POINTER(a0),d0
                      addq.l    #4,d0

                      move.w    (a4),8(a1)                             ;SPRxPTL
                      move.w    d0,10(a1)                              ; low pointer to sprite data

                      move.w    2(a4),4(a1)                            ; SPRxPTH
                      swap      d0
                      move.w    d0,6(a1)                               ; hight pointer to sprite data

                      move.w    4(a4),12(a1)                           ; SPRxPOS
                      move.w    6(a4),16(a1)                           ; SPRxCTL 
  
                      move.w    INSTANCE_X(a0),d0                      ; load x
                      sub.w     virtualscreen_xPosition,d0
                      add.w     #(2*57)+16,d0
                   

                      move.w    2(a2),d1                               ; load y (second word)
                      move.b    d1,14(a1)                              ; set y

                      moveq     #0,d5
                      btst      #8,d1                                  ; 8 Y Bit exist?
                      beq       .uc_noY8
                      ;bset      #2,d5
                      or        #%0100,d5
  
.uc_noY8:
                      add.w     d3,d1                                  ; y+height
                      move.w    #0,18(a1)                              ;  clean up
                      move.b    d1,18(a1)                              ; set height

                      btst      #8,d1                                  ; byte 8 exists for y+height?
                      beq       .uc_noZ8
                      ;bset      #1,d5
                      or        #%0010,d5
.uc_noZ8:
                      lsr       #1,d0                                  ; x1-x7 only
                      bcc.s     .uc_noX0
                      or        #%0001,d5
                      ;bset      #0,d5
.uc_noX0:
                      move.b    d0,15(a1)                              ; set x
                      move.b    d5,19(a1) 

                      adda.l    #(20),a1                               ; 5 instructions
                      rts

                    ; a0 pointer to instance in pot list
                    ; a4 spriteChannel
                    ; a1 copperList
sprite_addPotSpriteToCopperList:
                      move.l    (a0),a5                                ; pot data
                      moveq     #0,d2
                      
                      move.l    4(a0),a6                               ; pointer to current frame image
                      move.w    8(a0),d2
                      add.l     d2,a6
                      move.w    (a6),d4                                ; animation offset

                      move.l    8(a5),d0
                      add.w     d4,d0


                      move.w    66(a5),d2                              ;offset to second frame
                      move.w    6(a5),d3                               ; load height
                      
                      addq.l    #4,d0

                      move.w    (a4),8(a1)                             ;SPRxPTL
                      move.w    d0,10(a1)                              ; low pointer to sprite data

                      move.w    2(a4),4(a1)                            ;SPRxPTH
                      swap      d0
                      move.w    d0,6(a1)                               ; hight pointer to sprite data

                      move.w    4(a4),12(a1)                           ; SPRxPOS
                      move.w    6(a4),16(a1)                           ; SPRxCTL 
  
                      move.l    player_current,a6
                      move.w    (a6),d0                                ; load x
                      ;move.w    #150,d0
                      add.w     (a5),d0                                ; add x offset
                      sub.w     virtualscreen_xPosition,d0
                      add.w     #(2*57)+16,d0
                   
                      move.w    2(a2),d1                               ; load y (second word)

                      move.b    d1,14(a1)                              ; set y

                      move.w    #128,d5                                ; bset #8,d5 (=attached sprites)
                      btst      #8,d1                                  ; 8 Y Bit exist?
                      beq       .uc_noY8
                      or        #%0100,d5
  
.uc_noY8:
                      add.w     d3,d1                                  ; y+height
                      move.b    d1,18(a1)                              ; set height

                      btst      #8,d1                                  ; byte 8 exists for y+height?
                      beq       .uc_noZ8
                      or        #%0010,d5
  
.uc_noZ8:
                      lsr       #1,d0                                  ; x1-x7 only
                      bcc.s     .uc_noX0
                      or        #%0001,d5
.uc_noX0:

                      move.b    d0,15(a1)                              ; set x
                      move.b    d5,19(a1) 

                      move.w    10(a4),20(a1)                          ;SPRxPTH
                      move.w    8(a4),24(a1)                           ;SPRxPTL

                      move.w    12(a4),28(a1)                          ;SPRxPOS
                      move.w    14(a4),32(a1)                          ;SPRxCTL

                      move.w    14(a1),30(a1)                          ;copy
                      move.w    18(a1),34(a1)


                      
                      move.l    8(a5),d0                               ; current frame, second part

                      addq.l    #4,d0
                      
                      add.w     d4,d0                                  ; add animation frame
                      add.w     d2,d0                                  ; + offset to 2 sprite
                      move.w    d0,26(a1)                              ; low pointer to sprite data

                      swap      d0
                      move.w    d0,22(a1)                              ; hight pointer to sprite data

                      adda.l    #(20+16),a1                            ; 9 instructions
                      rts

sprite_addPlayerToCopperList:
                      lea.l     spriteChannel0,a4                      ; player always use channel 0,1,2,3
                      

                      move.l    player_current,a0

                      moveq     #0,d0
                      move.w    player_animation_offset,d0             ; current animation frame
                      add.l     8(a0),d0                               ; image pointer
                      ;addq.l    #4,d0                                  ; correct pointer


                      move.w    #SHOOTER_SIZE_SIZE,d2                  ;offset to 2 sprite
                      move.w    6(a0),d3                               ; load height


                      move.w    (a4),8(a1)                             ;SPRxPTL
                      move.w    d0,10(a1)                              ; low pointer to sprite data

                      move.w    2(a4),4(a1)                            ;SPRxPTH
                      swap      d0
                      move.w    d0,6(a1)                               ; hight pointer to sprite data

	                  ;dc.w	$0140,$784c ; SPR0POS  

                      move.w    4(a4),12(a1)                           ; SPRxPOS
                      move.w    6(a4),16(a1)                           ; SPRxCTL 
  
                      move.w    (a0),d0                                ; load x
                      sub.w     virtualscreen_xPosition,d0
                      add.w     #(2*57)+16,d0
                   
                      move.w    2(a2),d1                               ; load y (second word)

                      move.b    d1,14(a1)                              ; set y

                      move.w    #128,d5                                ; bset #8,d5 (=attached sprites)
                      btst      #8,d1                                  ; 8 Y Bit exist?
                      beq       .uc_noY8
                      ;bset      #2,d5
                      or        #%0100,d5
  
.uc_noY8:
                      add.w     d3,d1                                  ; y+height
                      ;move.w    #0,18(a1)                              ;  clean up
                      move.b    d1,18(a1)                              ; set height

                      btst      #8,d1                                  ; byte 8 exists for y+height?
                      beq       .uc_noZ8
                      ;bset      #1,d5
                      or        #%0010,d5
  
.uc_noZ8:
                      lsr       #1,d0                                  ; x1-x7 only
                      bcc.s     .uc_noX0
                      ;bset      #0,d5
                      or        #%0001,d5
.uc_noX0:

                      move.b    d0,15(a1)                              ; set x
                      move.b    d5,19(a1) 

                      move.w    10(a4),20(a1)                          ;SPRxPTH
                      move.w    8(a4),24(a1)                           ;SPRxPTL

                      move.w    12(a4),28(a1)                          ;SPRxPOS
                      move.w    14(a4),32(a1)                          ;SPRxCTL

                      move.w    14(a1),30(a1)                          ;copy
                      move.w    18(a1),34(a1)



                      moveq     #0,d0
                      move.w    player_animation_offset,d0             ; current animation frame
                      add.l     8(a0),d0                               ; image pointer
                      addq.l    #4,d0
                      
                      add.w     d2,d0                                  ; + offset to 2 sprite
                      move.w    d0,26(a1)                              ; low pointer to sprite data

                      swap      d0
                      move.w    d0,22(a1)                              ; hight pointer to sprite data
                      swap      d0

.sprite_2:

                      move.w    18(a4),36(a1)                          ;SPRxPTH
                      move.w    16(a4),40(a1)                          ;SPRxPTL

                      move.w    20(a4),44(a1)                          ;SPRxPOS
                      move.w    22(a4),48(a1)                          ;SPRxCTL

                      move.w    14(a1),46(a1)                          ;copy
                      add.b     #8,47(a1)
                      move.w    18(a1),50(a1)

                      add.w     d2,d0                                  ; + offset to 2 sprite
                      move.w    d0,42(a1)                              ; low pointer to sprite data

                      swap      d0
                      move.w    d0,38(a1)                              ; hight pointer to sprite data
                      swap      d0

.sprite_3:                     
                      move.w    26(a4),52(a1)                          ;SPRxPTH
                      move.w    24(a4),56(a1)                          ;SPRxPTL

                      move.w    28(a4),60(a1)                          ;SPRxPOS
                      move.w    30(a4),64(a1)                          ;SPRxCTL

                      move.w    14(a1),62(a1)                          ;copy
                      add.b     #8,63(a1)
                      move.w    18(a1),66(a1)

                      add.w     d2,d0                                  ; + offset to 2 sprite
                      move.w    d0,58(a1)                              ; low pointer to sprite data

                      swap      d0
                      move.w    d0,54(a1)                              ; hight pointer to sprite data
           

                      adda.l    #(20+16+16+16),a1                      ; 9 instructions
                      rts

spriteChannel0        dc.w      SPR0PTL,SPR0PTH,SPR0POS,SPR0CTL
spriteChannel1        dc.w      SPR1PTL,SPR1PTH,SPR1POS,SPR1CTL

spriteChannel2        dc.w      SPR2PTL,SPR2PTH,SPR2POS,SPR2CTL
spriteChannel3        dc.w      SPR3PTL,SPR3PTH,SPR3POS,SPR3CTL

spriteChannel4        dc.w      SPR4PTL,SPR4PTH,SPR4POS,SPR4CTL
spriteChannel5        dc.w      SPR5PTL,SPR5PTH,SPR5POS,SPR5CTL

spriteChannel6        dc.w      SPR6PTL,SPR6PTH,SPR6POS,SPR6CTL
spriteChannel7        dc.w      SPR7PTL,SPR7PTH,SPR7POS,SPR7CTL