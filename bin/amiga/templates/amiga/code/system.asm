  incdir     "incl/"
  include    exec/types.i
  include    exec/exec.i
  include    exec/exec_lib.i
	;include hardware/custom.i
	;include hardware/dmabits.i
	;include hardware/intbits.i
	;include hardware/cia.i

system_checkMem:
  move.l     $4.w,a6                       ; Fetch sysbase

  move.l     #MEMF_CHIP|MEMF_LARGEST,d1    ;MEMF_CHIP|MEMF_LARGEST
  jsr        _LVOAvailMem(a6)
  rts

    ; d0 size
    ; d1 MEM type
    ; <- d0.l pointer to MEM
system_allocMem:		
		; Allocate memory for the foreground buffer
  move.l     #MEMF_CHIP,d1
  jsr        _LVOAllocMem(a6)
  rts