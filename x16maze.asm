; *****************************************************************************
; The original version of CX16Maze was written to use the standard C64
; Kernal routines as much as possible. This was mostly done becase, at the
; time, both the ROM, the emulator and VERA was very volatile. Things are
; still changing but have settled down somewhat.
; This version 2.x will take full advantage of direct writes to VERA and I
; will also try to make the adding of mazes easier.
; *****************************************************************************
!cpu w65c02			; Pseudo code to tell ACME the CPU type
; includes
!src ../cx16stuff/cx16.inc
!src ../cx16stuff/vera0.9.inc
; BASIC SYS command to start program at $810
+SYS_LINE

main:
	rts
