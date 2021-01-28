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
	jsr	show_welcome
	jsr	CHRIN
	rts

; *****************************************************************************
; This function displays the welcome screen.
; It is assumed that the screen has previously been cleared with green text
; on black background.
; *****************************************************************************
show_welcome:
	+VERA_SET_STRIDE 2	; Jump over color cells
	+VERA_GOXY 8, 5		; Commander  16
	lda	#<Cx16
	sta	TMP0
	lda	#>Cx16
	sta	TMP0+1
	jsr	print_str

	+VERA_GOXY 7, 19	; 1st line of MAZE
	lda	#<Maze
	sta	TMP0
	lda	#>Maze
	sta	TMP0+1
	jsr	print_str
	+VERA_GOXY 7, 20	; 2nd line of MAZE
	lda	#<(Maze+27)
	sta	TMP0
	lda	#>(Maze+27)
	sta	TMP0+1
	jsr	print_str
	+VERA_GOXY 7, 21	; 3rd line of MAZE
	lda	#<(Maze+27+27)
	sta	TMP0
	lda	#>(Maze+27+27)
	sta	TMP0+1
	jsr	print_str
	+VERA_GOXY 7, 22	; 4th line of MAZE
	lda	#<(Maze+27+27+27)
	sta	TMP0
	lda	#>(Maze+27+27+27)
	sta	TMP0+1
	jsr	print_str
	+VERA_GOXY 7, 23	; 5th line of MAZE
	lda	#<(Maze+27+27+27+27)
	sta	TMP0
	lda	#>(Maze+27+27+27+27)
	sta	TMP0+1
	jsr	print_str
	+VERA_GOXY 19, 25	; V2
	lda	#<V2
	sta	TMP0
	lda	#>V2
	sta	TMP0+1
	jsr	print_str

	+VERA_SET_STRIDE 1	; Include color cells when printing
	+VERA_GOXY 15, 2	; 1st line of X
	ldx	#BLACK|PURPLE	; Black background and purple foreground
	lda	#<Xl0
	sta	TMP0
	lda	#>Xl0
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 15, 3	; 2nd line of X
	ldx	#BLACK|LIGHTBLUE
	lda	#<Xl1
	sta	TMP0
	lda	#>Xl1
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 15, 4	; 3rd line of X
	ldx	#BLACK|CYAN
	lda	#<Xl2
	sta	TMP0
	lda	#>Xl2
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 15, 6	; 4th line of X
	ldx	#BLACK|YELLOW
	lda	#<Xl3
	sta	TMP0
	lda	#>Xl3
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 15, 7	; 5th line of X
	ldx	#BLACK|ORANGE
	lda	#<Xl4
	sta	TMP0
	lda	#>Xl4
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 15, 8	; 6th line of X
	ldx	#BLACK|RED
	lda	#<Xl5
	sta	TMP0
	lda	#>Xl5
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 11, 14	; Press Enter/Return
	ldx	#BLACK|WHITE
	lda	#<Start
	sta	TMP0
	lda	#>Start
	sta	TMP0+1
	jsr	print_col_str
	+VERA_GOXY 12, 28	; By Jimmy Dansbo
	ldx	#BLACK|WHITE
	lda	#<Jimmy
	sta	TMP0
	lda	#>Jimmy
	sta	TMP0+1
	bra	print_col_str	; Return from print_col_str will return to 
				; caller of this routine

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
	beq	@end		; If 0 read, we are done
	sta	VERA_DATA0
	iny
	bra	@loop
@end:
	rts

; *****************************************************************************
; Print a zero-terminated string, no longer than 255 characters starting at
; the current VERA address, set bg/fg color of each character to the value
; defined in .X register.
; Function assumes that increment is set to 1
; *****************************************************************************
; INPUTS:	TMP0 (TMP1) = pointer to start of string
;		.X = fg/bg color to use
; USES:		.A & .Y
; *****************************************************************************
print_col_str:
	ldy	#0
@loop:
	lda	(TMP0),Y
	beq	@end		; If 0 read, we are done
	sta	VERA_DATA0
	stx	VERA_DATA0
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
Xl0	!byte	$5F,$A0,$A0,$DF,$20,$20,$20,$E9,$A0,$A0,$69,0
Xl1	!byte	$20,$5F,$A0,$A0,$DF,$20,$E9,$A0,$A0,$69,$20,0
Xl2	!byte	$20,$20,$5F,$A0,$A0,$20,$A0,$A0,$69,$20,$20,0
Xl3	!byte	$20,$20,$E9,$A0,$A0,$20,$A0,$A0,$DF,$20,$20,0
Xl4	!byte	$20,$E9,$A0,$A0,$69,$20,$5F,$A0,$A0,$DF,$20,0
Xl5	!byte	$E9,$A0,$A0,$69,$20,$20,$20,$5F,$A0,$A0,$DF,0
V2	!text	"V2",0
Cx16	!text	"COMMANDER  "
	!byte	$A0,$20,$A0
	!text	"  16",0
Jimmy	!text	"BY JIMMY DANSBO",0
Start	!text	"PRESS ENTER/RETURN",0
Maze	!text	$66,$20,$20,$20,$66,$20,$20,$20,$20,$66,$20,$20,$20,$20,$66,$66,$66,$66,$66,$20,$20,$66,$66,$66,$66,$66,0
	!text	$66,$66,$20,$66,$66,$20,$20,$20,$66,$20,$66,$20,$20,$20,$20,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$20,0
	!text	$66,$20,$66,$20,$66,$20,$20,$66,$66,$66,$66,$66,$20,$20,$20,$20,$66,$20,$20,$20,$20,$66,$66,$66,$20,$20,0
	!text	$66,$20,$20,$20,$66,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$20,$20,$66,$20,$20,$20,$20,0
	!text	$66,$20,$20,$20,$66,$20,$20,$66,$20,$20,$20,$66,$20,$20,$66,$66,$66,$66,$66,$20,$20,$66,$66,$66,$66,$66,0
}
