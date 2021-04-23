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

!macro ADD16 .ptr, .byteval {
	lda	.ptr
	clc
	adc	#.byteval
	sta	.ptr
	lda	.ptr+1
	adc	#0
	sta	.ptr+1
}

; *****************************************************************************
; This is the main entry point of the program. From here all the
; initialization and gameloop will be called.
; *****************************************************************************
main:
	jsr	init_screen
	jsr	show_welcome
-	jsr	GETIN
	cmp	#13
	bne	-
	jsr	init_play_screen
	jsr	load_mazes
	bcs	@end

	lda	#<RAM_BANK_START
	sta	MAZE_PTR
	lda	#>RAM_BANK_START
	sta	MAZE_PTR+1

@empty_loop:
	jsr	GETIN
	bne	@empty_loop
	jsr	load_level
-	jsr	GETIN
	beq	-
	bra	@empty_loop
@end:
	rts

; *****************************************************************************
; Load a level from memory to screen, update the level counter and place the
; player
; *****************************************************************************
; *****************************************************************************
load_level:
	lda	(MAZE_PTR)
	bne	+		; If 0, start over from beginning of RAM bank
	lda	#<RAM_BANK_START
	sta	MAZE_PTR
	lda	#>RAM_BANK_START
	sta	MAZE_PTR+1
	jsr	init_play_screen

+	jsr	inc_level
	jsr	get_maze_vals
	jsr	draw_maze
	jsr	place_player
	jsr	prep_next_maze
	rts

; *****************************************************************************
; *****************************************************************************
; *****************************************************************************
prep_next_maze:
	lda	Size
	clc
	adc	MAZE_PTR
	sta	MAZE_PTR
	lda	#0
	adc	MAZE_PTR+1
	sta	MAZE_PTR+1
	rts

; *****************************************************************************
; *****************************************************************************
; *****************************************************************************
place_player:
	lda	Maze_y
	clc
	adc	Start_y
	sta	VERA_ADDR_M
	lda	Maze_x
	clc
	adc	Start_x
	asl
	inc
	sta	VERA_ADDR_L
	jsr	set_trail_col
	sta	VERA_DATA0
	rts

; *****************************************************************************
; *****************************************************************************
; *****************************************************************************
draw_maze:
@x_cnt = TMP0
@y_cnt = TMP1
	jsr	clear_field
	lda	#$20		; Increment by 2 at each write to VERA
	sta	VERA_ADDR_H
	+VERA_GOXY ~Maze_x, ~Maze_y
	inc	VERA_ADDR_L	; Ensure we change color settings
	+ADD16 MAZE_PTR, 5	; Move pointer to start of actual maze

	lda	Width		; Store width and height in temporary variables
	sta	@x_cnt
	lda	Height
	sta	@y_cnt

	ldy	#255
@sizeloop:
	iny
	lda	(MAZE_PTR),Y

	jsr	draw_maze_byte	; Draw contents of 1 byte to screen

	sec			; Subtract 8 from the maze-width to figure
	lda	@x_cnt		; out if we need to go to the next line
	sbc	#8
	sta	@x_cnt
	beq	@nextline	; If 0, we need to go to next line
	bpl	@sizeloop	; If number still positive, we do next byte
	; Go to next line in maze
@nextline:
	lda	Width
	sta	@x_cnt		; Reset x_cnt
	inc	VERA_ADDR_M	; Go to next line in VERA
	lda	Maze_x		; Reset X coordinate in VERA
	asl
	inc
	sta	VERA_ADDR_L
	dec	@y_cnt
	bne	@sizeloop	; If y_cnt has reached 0, we are done
	rts

; *****************************************************************************
; *****************************************************************************
; *****************************************************************************
draw_maze_byte:
	ldx	#8
@loop:	asl
	bcc	@do_draw
	; skip this character
	inc	VERA_ADDR_L
	inc	VERA_ADDR_L
	bra	@continue
@do_draw:
	stz	VERA_DATA0
@continue:
	dex
	bne	@loop
	rts

; *****************************************************************************
; Find maze height, width and size and calculate coordinates for top left corner
; of the maze.
; *****************************************************************************
; INPUTS:	Expects MAZE_PTR to point to beginning of maze data
; OUTPUTS:	Size, Width, Height, Maze_x, Maze_y, Start_x & Start_y
; *****************************************************************************
get_maze_vals:
	ldy	#0
	lda	(MAZE_PTR),Y	; Load total maze size
	sec
	sbc	#5		; Subtract size of header
	sta	Size
	iny
	lda	(MAZE_PTR),Y	; Load width of maze
	sta	Width
	sta	Maze_x		; also store in Maze_x for later calculations
	iny
	lda	(MAZE_PTR),Y	; Load height of maze
	sta	Height
	sta	Maze_y		; also store in Maze_y for later calculations

	lsr	Maze_x		; Calculate maze starting X coordinate
	lda	#40/2
	sec
	sbc	Maze_x
	sta	Maze_x

	lsr	Maze_y		; Calculate maze starting Y coordinate
	lda	#30/2
	sec
	sbc	Maze_y
	sta	Maze_y

	iny
	lda	(MAZE_PTR),Y	; Load players starting x position
	sta	Start_x
	iny
	lda	(MAZE_PTR),Y	; Load players starting y position
	sta	Start_y
	rts

; *****************************************************************************
; Increment the level counter on screen (rolls over to 000 after 999)
; *****************************************************************************
; USES:		.A
; *****************************************************************************
inc_level:
	stz	VERA_ADDR_H
	+VERA_GOXY 39,0
	lda	VERA_DATA0
	inc
	cmp	#$3A		; is value > $39 ?
	bcc	@end
	lda	#$30
	sta	VERA_DATA0
	dec	VERA_ADDR_L
	dec	VERA_ADDR_L
	lda	VERA_DATA0
	inc
	cmp	#$3A
	bcc	@end
	lda	#$30
	sta	VERA_DATA0
	dec	VERA_ADDR_L
	dec	VERA_ADDR_L
	lda	VERA_DATA0
	inc
	cmp	#$3A
	bcc	@end
	lda	#$30
@end:	sta	VERA_DATA0
	rts

; *****************************************************************************
; Sets a random color for the trail of the maze.
; *****************************************************************************
; USES:		.A, .X, .Y & TMP0
; OUTPUT:	Trail_color global variable set to random number
; *****************************************************************************
set_trail_col:
	jsr	Entropy_get	; Get 24bit "random" number
	stx	TMP0		; Combine to 4 bits
	eor	TMP0
	sty	TMP0
	eor	TMP0
	sta	TMP0
	lsr
	lsr
	lsr
	lsr
	eor	TMP0
	and	#$0F

	cmp	#BLACK		; Avoid Black
	beq	set_trail_col
	cmp	#LIGHTGRAY	; Avoid lightgray (background color)
	beq	set_trail_col
	cmp	#DARKGRAY	; Avoid darkgray
	beq	set_trail_col
	cmp	#BLUE		; Avoid blue
	beq	set_trail_col
	asl
	asl
	asl
	asl
	sta	Trail_color
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
; *****************************************************************************
; *****************************************************************************
clear_field:
	lda	#$10
	sta	VERA_ADDR_H
	lda	#1
	sta	VERA_ADDR_M
	inc
	sta	VERA_ADDR_L
	ldx	#' '
	ldy	#((LIGHTGRAY<<4)|LIGHTGRAY)
@loop:
	stx	VERA_DATA0
	sty	VERA_DATA0
	lda	VERA_ADDR_L
	cmp	#(39*2)
	bne	@loop
	lda	#2
	sta	VERA_ADDR_L
	inc	VERA_ADDR_M
	lda	VERA_ADDR_M
	cmp	#28
	bne	@loop
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
