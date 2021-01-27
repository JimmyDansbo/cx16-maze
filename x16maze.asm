; *****************************************************************************
; The original version of CX16Maze was written to use the standard C64
; Kernal routines as much as possible. This was mostly done becase, at the
; time, both the ROM, the emulator and VERA was very volatile. Things are
; still changing but have settled down somewhat.
; This version 2.x will take full advantage of direct writes to VERA and I
; will also try to make the adding of mazes easier.
; *****************************************************************************
!cpu w65c02			; Pseudo code to tell ACME the CPU type
; Includes
!src "../cx16stuff/cx16.inc"
!src "../cx16stuff/vera0.9.inc"

; BASIC SYS command to start program at $810
+SYS_LINE

; *****************************************************************************
; This is the main entry point of the program. From here all the
; initialization and gameloop will be called.
; *****************************************************************************
main:
	jsr	init_screen
	lda	#$20
	sta	VERA_ADDR_H
	stz	VERA_ADDR_M
	stz	VERA_ADDR_L
	lda	#<Cx16
	sta	TMP0
	lda	#>Cx16
	sta	TMP0+1
	jsr	print_str
	rts

; *****************************************************************************
; Print a zero-terminated string, no longer than 255 characters starting at
; the current VERA address.
; Function assumes that increment is set to 2 which means that color value
; for each character is not changed.
; *****************************************************************************
; INPUTS:	TMP0 (TMP1) = pointer to start of string
; USES:		.A & .Y
; *****************************************************************************
print_str:
	ldy	#0
@loop:
	lda	(TMP0),Y
	beq	@end
	sta	VERA_DATA0
	iny
	bra	@loop
@end:
	rts

; *****************************************************************************
; Use Kernal calls to initialize screen to 40x30 mode and set green text on
; black background.
; *****************************************************************************
init_screen:
	; Use Kernal routine to set 40x30 text mode
	lda	#SCR_MOD_00
	jsr	Screen_set_mode
	; Set green text on black background
	lda	#PET_BLACK
	jsr	CHROUT
	lda	#PET_SWAP_FGBG
	jsr	CHROUT
	lda	#PET_GREEN
	jsr	CHROUT
	; Clear screen
	lda	#PET_CLEAR
	jsr	CHROUT
	rts

!ct "asc2vera.ct" {
Cx16	!text	"COMMANDER X16",0
}
