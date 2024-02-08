    SECTION TEXT		;CODE Section

init:
    pea    	game     ;Push address to call to onto stack
    move.w  #$26,-(sp)  ;Supexec (38: set supervisor execution)
    trap    #14         ;XBIOS Trap
    addq.w  #6,sp       ;remove item from stack
	jmp *				;Wait for Supervisor mode to start
	
	rts
	
	
destroy:
	rts