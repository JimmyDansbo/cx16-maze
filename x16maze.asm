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

	jmp	main

!src "globals.inc"

; *****************************************************************************
; This is the main entry point of the program. From here all the
; initialization and gameloop will be called.
; *****************************************************************************
main:
	jsr	init_screen
	jsr	show_welcome
	jsr	CHRIN
	jsr	init_play_screen
	jsr	CHRIN
	!byte	$db
	jsr	load_mazes
	bcs	@end
	jsr	Clock_get_date_time

@end
	rts

; *****************************************************************************
; Load mazes from MAZES.BIN into memory bank 1 starting at address $A000
; If the function returns with Carry Set, it was unable to load the mazes.
; *****************************************************************************
; USES:		.A, .X, .Y
; *****************************************************************************
load_mazes:
	lda	#1			; Logical filenumber (must be unique)
	ldx	#8			; Device number (8 local filesystem)
	ldy	#255			; Secondary command 255=none
	jsr	SETLFS
	lda	#(Mazes_end-Mazes)	; Length of filename
	ldx	#<Mazes			; Address of filename
	ldy	#>Mazes
	jsr	SETNAM
	lda	#1			; Ensure RAM bank is set to 1
	sta	RAM_BANK
	lda	#0			; 0=load, 1=verify
	ldx	#<RAM_BANK_START	; Address to load data to
	ldy	#>RAM_BANK_START
	jsr	LOAD
	bcc	@no_error		; Carry Clear = No error
	clc
	ldy	#0			; Move cursor to 0, 15
	ldx	#15
	jsr	PLOT
	lda	#PET_RED		; Write with white text
	jsr	CHROUT			; on red background
	lda	#PET_SWAP_FGBG
	jsr	CHROUT
	lda	#PET_WHITE
	jsr	CHROUT
@err_loop:
	lda	Err_Ld,Y		; Write the error message
	beq	@next
	jsr	CHROUT
	iny
	bra	@err_loop
@next:
	ldy	#0
	sec
@name_loop:
	lda	Mazes,Y			; Write the filename that failed.
	beq	@no_error
	jsr	CHROUT
	iny
	bra	@name_loop
@no_error:
	rts

; *****************************************************************************
; Initializes the screen to start the game.
; *****************************************************************************
init_play_screen:
	lda	#PET_LIGHTGRAY	; Set background color
	jsr	CHROUT
	lda	#PET_SWAP_FGBG
	jsr	CHROUT
	lda	#PET_CLEAR	; Clear screen
	jsr	CHROUT

	+VERA_GOXY 0, 0		; Draw vertical line on left side of screen
	lda	#' '
	ldx	#(WHITE<<4)|RED
	ldy	#30
	jsr	draw_ver_line
	+VERA_GOXY 39, 0	; Draw vertical line on right side of screen
	lda	#' '
	ldy	#30
	jsr	draw_ver_line
	+VERA_GOXY 1, 0		; Draw horizontal line on top of screen
	lda	#' '
	ldy	#38
	jsr	draw_hor_line
	+VERA_GOXY 1, 28	; Draw 2 horizontal lines on bottom of screen
	lda	#' '
	ldy	#38
	jsr	draw_hor_line
	+VERA_GOXY 1, 29
	lda	#' '
	ldy	#38
	jsr	draw_hor_line

	+VERA_SET_STRIDE 2	; Write strings without setting color
	+VERA_GOXY 0, 0
	lda	#<Time		; Time digits in upper left corner
	sta	TMP_PTR0
	lda	#>Time
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 16, 0
	lda	#<Caption	; Headline on top middle of screen
	sta	TMP_PTR0
	lda	#>Caption
	sta	TMP_PTR0+1
	jsr	print_str

	+VERA_GOXY 30, 0
	lda	#<Level		; Level information in top right screen
	sta	TMP_PTR0
	lda	#>Level
	sta	TMP_PTR0+1
	jsr	print_str

	+VERA_GOXY 6, 28	; Helpful text at bottom 2 lines of scren
	lda	#<Help0
	sta	TMP_PTR0
	lda	#>Help0
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 1, 29
	lda	#<Help1
	sta	TMP_PTR0
	lda	#>Help1
	sta	TMP_PTR0+1
	jmp	print_str	; print_str function will rts to caller
				; of this function because it is not jsr'et to

; *****************************************************************************
; Draws a horizontal line from left to right starting at the current position
; in VERA memory.
; Assumes that VERA stride is set to 1.
; *****************************************************************************
; INPUTS:	.A = Character to use for drawing
;		.X = fg/bg color to use
;		.Y = Length of line
; *****************************************************************************
draw_hor_line:
	sta	VERA_DATA0
	stx	VERA_DATA0
	dey
	bne	draw_hor_line
	rts

; *****************************************************************************
; Draws a vertical line from top to bottom starting at the current position
; in VERA memory.
; Assumes that VERA stride is set to 1
; *****************************************************************************
; INPUTS:	.A = Character to use for drawing
;		.X = fg/bg color to use
;		.Y = Length of line
; *****************************************************************************
draw_ver_line:
	sta	VERA_DATA0
	stx	VERA_DATA0
	dec	VERA_ADDR_L
	dec	VERA_ADDR_L
	inc	VERA_ADDR_M
	dey
	bne	draw_ver_line
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
	sta	TMP_PTR0
	lda	#>Cx16
	sta	TMP_PTR0+1
	jsr	print_str

	+VERA_GOXY 7, 19	; 1st line of MAZE
	lda	#<Maze
	sta	TMP_PTR0
	lda	#>Maze
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 7, 20	; 2nd line of MAZE
	lda	#<(Maze+27)
	sta	TMP_PTR0
	lda	#>(Maze+27)
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 7, 21	; 3rd line of MAZE
	lda	#<(Maze+27+27)
	sta	TMP_PTR0
	lda	#>(Maze+27+27)
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 7, 22	; 4th line of MAZE
	lda	#<(Maze+27+27+27)
	sta	TMP_PTR0
	lda	#>(Maze+27+27+27)
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 7, 23	; 5th line of MAZE
	lda	#<(Maze+27+27+27+27)
	sta	TMP_PTR0
	lda	#>(Maze+27+27+27+27)
	sta	TMP_PTR0+1
	jsr	print_str
	+VERA_GOXY 19, 25	; V2
	lda	#<V2
	sta	TMP_PTR0
	lda	#>V2
	sta	TMP_PTR0+1
	jsr	print_str

	+VERA_SET_STRIDE 1	; Include color cells when printing
	+VERA_GOXY 15, 2	; 1st line of X
	ldx	#(BLACK<<4)|PURPLE	; Black background and purple foreground
	lda	#<Xl0
	sta	TMP_PTR0
	lda	#>Xl0
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 15, 3	; 2nd line of X
	ldx	#(BLACK<<4)|LIGHTBLUE
	lda	#<Xl1
	sta	TMP_PTR0
	lda	#>Xl1
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 15, 4	; 3rd line of X
	ldx	#(BLACK<<4)|CYAN
	lda	#<Xl2
	sta	TMP_PTR0
	lda	#>Xl2
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 15, 6	; 4th line of X
	ldx	#(BLACK<<4)|YELLOW
	lda	#<Xl3
	sta	TMP_PTR0
	lda	#>Xl3
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 15, 7	; 5th line of X
	ldx	#(BLACK<<4)|ORANGE
	lda	#<Xl4
	sta	TMP_PTR0
	lda	#>Xl4
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 15, 8	; 6th line of X
	ldx	#(BLACK<<4)|RED
	lda	#<Xl5
	sta	TMP_PTR0
	lda	#>Xl5
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 11, 14	; Press Enter/Return
	ldx	#(BLACK<<4)|WHITE
	lda	#<Start
	sta	TMP_PTR0
	lda	#>Start
	sta	TMP_PTR0+1
	jsr	print_col_str
	+VERA_GOXY 12, 28	; By Jimmy Dansbo
	ldx	#(BLACK<<4)|WHITE
	lda	#<Jimmy
	sta	TMP_PTR0
	lda	#>Jimmy
	sta	TMP_PTR0+1
	bra	print_col_str	; Return from print_col_str will return to
				; caller of this routine

; *****************************************************************************
; Print a zero-terminated string, no longer than 255 characters starting at
; the current VERA address.
; Function assumes that increment is set to 2 which means that color value
; for each character is not changed.
; *****************************************************************************
; INPUTS:	TMP_PTR0 = pointer to start of string
; USES:		.A & .Y
; *****************************************************************************
print_str:
	ldy	#0
@loop:
	lda	(TMP_PTR0),Y
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
; INPUTS:	TMP_PTR0 = pointer to start of string
;		.X = fg/bg color to use
; USES:		.A & .Y
; *****************************************************************************
print_col_str:
	ldy	#0
@loop:
	lda	(TMP_PTR0),Y
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
