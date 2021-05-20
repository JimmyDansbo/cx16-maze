!ifdef MACHINE_C64 {
	!if MACHINE_C64=1 {
C64=1
	}
}
*=$0801			; Assembled code should start at $0801
			; (where BASIC programs start)
			; The real program starts at $0810 = 2064
!byte $0C,$08		; $080C - pointer to next line of BASIC code
!byte $0A,$00		; 2-byte line number ($000A = 10)
!byte $9E		; SYS BASIC token
!byte $20		; [space]
!byte $32,$30,$36,$34	; $32="2",$30="0",$36="6",$34="4"
			; (ASCII encoded nums for dec starting addr)
!byte $00		; End of Line
!byte $00,$00		; This is address $080C containing
			; 2-byte pointer to next line of BASIC code
			; ($0000 = end of program)
*=$0810			; Here starts the real program

; ******** Kernal APIs - C64 API can be found here: *******
; http://sta.c64.org/cbm64krnfunc.html
CHROUT=$FFD2		; CHROUT outputs a character (C64 Kernal API)
CHRIN=$FFCF		; CHRIN read from default input
GETIN=$FFE4		; GETIN reads a single byte from default input
			; returns #0 if no key is pressed = non-blocking
PLOT=$FFF0		; PLOT gets or sets cursor position
SETLFS=$FFBA		; Setup logical file
OPEN=$FFC0		; Open a logical file
CHKIN=$FFC6		; Open channel for input
CLALL=$FFE7		; Close all files and restore defaults
SETTIM=$FFDB		; Set realtime clock
RDTIM=$FFDE		; Read realtime clock
; ******** Kernal APIs from CX16 ***************************
SCRMOD=$FF5F
!ifdef C64 {
TMP0=$FB
TMP1=$FC
TMP2=$FD
TMP3=$FE
TMP4=$02
TMP5=$2A
TMP6=$52
SCREEN_HEIGHT=25
} else {
TMP0=$30
TMP1=$31
TMP2=$32
TMP3=$33
TMP4=$34
TMP5=$35
TMP6=$36
SCREEN_HEIGHT=30
}
; ******* Constants used in the source **********************
; PETSCII color codes
PET_BLACK	= $90
PET_WHITE	= $05
PET_RED		= $1C
PET_CYAN	= $9F
PET_PURPLE	= $9C
PET_GREEN	= $1E
PET_BLUE	= $1F
PET_YELLOW	= $9E
PET_ORANGE	= $81
PET_BROWN	= $95
PET_LIGHTRED	= $96
PET_DARKGRAY	= $97
PET_MIDGRAY	= $98
PET_LIGHTGREEN	= $99
PET_LIGHTBLUE	= $9A
PET_LIGHTGRAY	= $9B

Cursor=119
Wall=$A6
WallCol=PET_LIGHTGRAY
Trail=$A0

BitCnt=9

DirUp=1
DirLeft=2
DirDown=3
DirRight=4

NUMLEVELS=57


; ******* Global variables **********************************
	jmp	Main

.lvl		!byte	1
.mazesx		!byte	00
.mazesy		!byte	00
.fields		!byte	0
.mazeheight	!byte	00
.mazewidth	!byte	00
.cursorx	!byte 	0
.cursory	!byte	0
.rndnum		!byte	$2B
.trailcol	!byte	0

.title		!pet	"cx16-maze",0
.helptxt	!pet	" wasd=move spc=next r=reset q=quit ",0
.lvlstr		!pet	"lvl:",0
.lvltxt		!pet	"000",0
.cx16		!pet 	"commander  ",18," ",146," ",18," ",146,"  16",0
.xl1		!pet	127,18,"  ",127,146,"   ",18,169,"  ",146,169,0
.xl2		!pet	127,18,"  ",127,146," ",18,169,"  ",146,169,0
.xl3		!pet	127,18,"  ",146," ",18,"  ",146,169,0
.xl5		!pet	18,169,"  ",146," ",18,"  ",127,146,0
.xl6		!pet	18,169,"  ",146,169," ",127,18,"  ",127,146,0
.xl7		!pet	18,169,"  ",146,169,"   ",127,18,"  ",127,146,0

.ml1		!pet	"*   *    *    *****  *****",0
.ml2		!pet	"** **   * *      *   *",0
.ml3		!pet	"* * *  *****    *    ***",0
.ml4		!pet	"*   *  *   *   *     *",0
.ml5		!pet	"*   *  *   *  *****  *****",0

.completetxt	!pet	"level completed",0
.starttxt	!pet	"press return/enter",0

Main:
	jsr	SplashScreen
	jsr	InitSCR
	jsr	DrawMaze
	jsr	GameLoop

	rts			; Return to BASIC

; **************************************************************
; Moves the cursor in the direction chosen by the user if it
; is possible. Returns to caller when the cursor can not move
; **************************************************************
; INPUTS:	.cursorx, .cursory
; **************************************************************
MoveCursor:
	.direction=TMP2
	.newX=TMP3
	.newY=TMP4

	lda	#$12		; Reverse ON
	jsr	CHROUT

	ldx	.cursory
	ldy	.cursorx
	lda	.direction

.chkUp:
	cmp	#DirUp
	bne	.chkLeft
	dex			; Decrement Y coordinate
	jmp	.newCoord
.chkLeft:
	cmp	#DirLeft
	bne	.chkDown
	dey			; Decrement X coordinate
	jmp	.newCoord
.chkDown:
	cmp	#DirDown
	bne	.chkRight
	inx			; Increment Y coordinate
	jmp	.newCoord
.chkRight:
	cmp	#DirRight	; If we reach this point and we
	bne	.moveEnd	; do not have the direction,
				; .direction value is malformed
	iny			; Increment X coordinate

.newCoord:
	stx	.newY
	sty	.newX

	jsr	GotoXY		; Move to coordinate to test
	jsr	SetScrIn	; Read character there
	jsr	CHRIN		; Read char from current position
	cmp	#Wall
	bne	.isEmpty
	jmp	.moveEnd	; Jump to end if we have reached a wall

.isEmpty:
	cmp	#' '		; If the char is not a space
	bne	.Touched	; It is already "touched" and should not be counted
	dec	.fields		; Count the field as touched
.Touched:
	jsr	CLALL		; Reset back to default input

	; Draw the trail
	ldx	.cursory
	ldy	.cursorx
	jsr	GotoXY
	lda	#Trail
	jsr	CHROUT

	; Draw the "cursor" at new position
	ldx	.newY
	ldy	.newX
	stx	.cursory
	sty	.cursorx
	jsr	GotoXY
	lda	#Cursor
	jsr	CHROUT

	; Delay for 3 jiffies
	lda	#3
	sta	TMP5
	jsr	DoDelay

	lda	#$92		; Reverse OFF
	jsr	CHROUT

	; Check of all empty fields have been "touched"
	lda	#0
	cmp	.fields
	bne	.Continue	; If not 0, continue
	sta	.direction	; Set direction to 0
	jmp	.moveEnd	; End movement.
.Continue:
	jmp	MoveCursor
.moveEnd:
	jsr	CLALL		; Reset back to default input
	rts

; **************************************************************
; The main loop that takes care of reading keyboard input and
; ensuring that screen is updated
; **************************************************************
; INPUTS:	.direction, .lvltxt
; **************************************************************
GameLoop:
	.direction=TMP2

	jsr	Random
	jsr	GETIN		; Read keyboard input

	cmp	#'Q'		; If Q is not pressed, check for
	bne	.isUP		; UP key
	jmp	.endgl		; Q pressed, jmp to end

.isUP:	cmp	#$57
	;cmp	#145 		; If UP is not pressed, check for
	bne	.isLEFT		; LEFT key
	lda	#DirUp		; Set direction to up
	sta	.direction
	jmp	.doDirection

.isLEFT:
	cmp	#$41
;	cmp	#157		; If LEFT is not pressed, check for
	bne	.isDOWN		; DOWN key
	lda	#DirLeft	; Set direction to left
	sta	.direction
	jmp	.doDirection

.isDOWN:
	cmp	#$53
;	cmp	#17		; If DOWN is not pressed, check for
	bne	.isRIGHT	; RIGHT key
	lda	#DirDown	; Set direction to down
	sta	.direction
	jmp	.doDirection

.isRIGHT:
	cmp	#$44
;	cmp	#29		; If RIGHT is not pressed, check for
	bne	.isR		; Space key
	lda	#DirRight	; Set direction to right
	sta	.direction

.doDirection:
	jsr	MoveCursor	; Move the cursor
	cmp	.direction
	bne	.isR
	jsr	LevelComplete
	jmp	.doR		; Loop back to top

.isR:	cmp	#'R'		; If R is pressed
	beq	.doR
	jmp	GameLoop	; If R is not pressed, loop to top

.doR:	jsr	FillGA		; Reset the level
	lda	#PET_WHITE
	jsr	CHROUT
	lda	#$12		; Reverse ON
	jsr	CHROUT

	ldx	#1	; Set up for level text (top right corner)
	ldy	#35
	jsr	GotoXY
	jsr	LVLtoPET ; Create level as a petscii string
	ldx	#<.lvltxt
	ldy	#>.lvltxt
	jsr	PrintStr

	lda	#$92		; Reverse OFF
	jsr	CHROUT

	jsr	DrawMaze
	jmp	GameLoop	; Loop back to top
.endgl:
	rts


; *******************************************************************
; Find and draw the current maze on the gameboard
; *******************************************************************
; INPUTS:	.lvl and .mazes is used to find the maze to draw
; *******************************************************************
DrawMaze:
	.mazeaddr=TMP0		; Base address of current maze is held
				; in TMP0 and TMP1
	.linecnt=TMP2		; Counts lines of the maze (Y)
	.offset=TMP3		; Offset into maze data
	.currbyte=TMP4		; Value of current byte
	.bitcnt=TMP5		; Bit counter
	.rowcnt=TMP6		; Counts columns/rows of the maze (X)

	jsr	FindMaze
	jsr	GetMazeVals

	lda	#$00
	; Each time an empty space is drawn in the maze, the .fields
	; variable is incremented. That makes it a simple matter of
	; decrementing the .fields variable each time the cursor
	; passes an empty field and when it reaches 0, the maze is
	; completed.
	sta	.fields

	ldy	#5		; Offset of maze data
	sty	.offset

	lda	.mazeheight	; Copy mazeheight to linecnt so we can
	sta	.linecnt	; use it for couting down
.Ycnt:
	ldy	.offset		; Load a byte from maze data
	lda	(.mazeaddr),y
	sta	.currbyte	; Store it in .currbyte variable

	; Calculate .mazesy+(.mazeheight-.linecnt)
	; This calculates the correct Y coordinate for the current line
	lda	.mazeheight
	sec
	sbc	.linecnt	; (.mazeheight-.linecnt)
	clc
	adc	.mazesy		; + .mazesy
	tax
	ldy	.mazesx
	jsr	GotoXY		; Move cursor to the start coord of this line

	lda	#BitCnt
	sta	.bitcnt

	lda	.mazewidth
	sta	.rowcnt
.Xcnt:
	dec	.bitcnt		;
	bne	.ByteGood	; If .bitcnt>0 jump to handle current byte
	; Read new byte from maze data
	inc	.offset
	ldy	.offset
	lda	(.mazeaddr),y
	sta	.currbyte
	ldy	#BitCnt
	sty	.bitcnt
	jmp	.Xcnt
	; Handle current byte
.ByteGood:
	asl	.currbyte	; Check next bit
	bcs	.wall		; If Carry set, leave the wall char in place
	lda	#' '		; If Carry clear, load space character
	inc	.fields		; Another field needs color to finish maze
	jmp	.write
.wall:
	lda	#29		; Load "cursor right" to leave wall in place
.write:	jsr	CHROUT		; Do the output

	dec	.rowcnt
	beq	.endX
	jmp	.Xcnt
.endX:
	inc	.offset

	dec	.linecnt
	beq	.endIt
	jmp	.Ycnt
.endIt:
	dec	.fields
	jsr	SetTrailCol
	jsr	PlaceInitCursor
	rts
; *******************************************************************
; Calculate and store the cursor position and draw the cursor on
; the screen
; *******************************************************************
; INPUTS:	Expects address of maze in TMP0 and TMP1
; OUTPUTS:	.cursorx and .cursory
; *******************************************************************
PlaceInitCursor:
	ldy	#3
	lda	(TMP0),y	; Get cursor X coordinate from maze data
	clc
	adc	.mazesx		; Add it to the maze top left X coordinate
	sta	.cursorx	; Save the cursor X coordinate for later use
	iny
	lda	(TMP0),y	; Get cursor Y coordinate from maze data
	clc
	adc	.mazesy		; Att it to the maze top left Y coordinate
	sta	.cursory	; Save the cursor Y coordinate for later use

	; Move the cursor on the screen to the calculated coordinates
	tax
	ldy	.cursorx
	jsr	GotoXY

	lda	.trailcol	; Set the color to draw with
	jsr	CHROUT

	lda	#Cursor		; Draw the cursor
	jsr	CHROUT
	rts

; *******************************************************************
; Find maze height and width and calculate coordinates for top
; left corner of the maze
; *******************************************************************
; INPUTS:	Expects address of maze in TMP0 and TMP1
; OUTPUTS:	.mazewidth, .mazeheight, .mazesx & .mazesy
; *******************************************************************
GetMazeVals:
	ldy	#$01
	lda	(TMP0),y	; Load maze width
	sta	.mazewidth	; store it in variable and ZP memory
	sta	TMP2		; to do calculations
	iny
	lda	(TMP0),y	; Load maze height
	sta	.mazeheight	; store it in variable and ZP memory
	sta	TMP3		; to do calculations

	lsr	TMP2		; Divide width by 2 (half it)
	lsr	TMP3		; Divide height by 2 (half it)

	lda	#40/2		; Load A with half of the screen width
	sec
	sbc	TMP2		; Subtract half of the maze width
	sta	.mazesx		; Save the X coordinate of top left corner

	lda	#SCREEN_HEIGHT/2; Load A with half of the screen height

	sec
	sbc	TMP3		; Subtract half of the maze height
	sta	.mazesy		; Save the Y coordinate of top left corner
	rts

; *******************************************************************
; Find the correct maze for the current level
; *******************************************************************
; INPUTS:	.lvl and .mazes will be used to see which maze to draw
; OUTPUTS:	Stores address to current maze in TMP0 and TMP1
; *******************************************************************
FindMaze:
	lda	#<.mazes	; Load address of first maze into
	sta	TMP0		; ZP memory to use it for indirect
	lda	#>.mazes	; adressing.
	sta	TMP1

	ldx	.lvl		; Load current level
.findMaze:
	dex			; Count down to 0 to find the right maze
	beq	.FoundIt	; If we are at 0, we found it
	ldy	#0		; Load size of current maze
	lda	(TMP0),y
	clc			; Add maze size to address of current
	adc	TMP0		; maze. This is done by adding the
	sta	TMP0		; size to LSB followed by adding 0 to
	lda	TMP1		; MSB while retaining the carry bit from
	adc	#0		; the first addition. This is how an 8 bit
	sta	TMP1		; number is added to a 16 bit number
	jmp	.findMaze	; Check next
.FoundIt:
	rts

; *******************************************************************
; Initializes the game screen
; *******************************************************************
; INPUTS:	.lvl, .title, .helptxt, .lvlstr, .lvltxt
; *******************************************************************
InitSCR:
	lda	#PET_WHITE
	jsr	CHROUT

	lda	#147	; ClrHome
	jsr	CHROUT	; Clear Screen

	lda	#$12	; Reverse on (White background, black text)
	jsr	CHROUT

	ldx	#1	; Setup to create top horizontal line
	ldy	#1
	jsr	GotoXY

	lda	#' '
	ldx	#38
	jsr	HLine	; Draw horizontal line

	; Setup to create bottom horizontal line
	ldx	#SCREEN_HEIGHT-2
	ldy	#1
	jsr	GotoXY

	lda	#' '
	ldx	#38
	jsr	HLine	; Draw horizontal line

	ldx	#2	; Setup to create left most vertical line
	ldy	#1
	jsr	GotoXY

	ldx	#SCREEN_HEIGHT-4
	lda	#' '
	jsr	VLine	; Draw left most vertical line

	ldx	#2	; Setup to create right most vertical line
	ldy	#38
	jsr	GotoXY

	ldx	#SCREEN_HEIGHT-4
	lda	#' '
	jsr	VLine	; Draw right most vertical line

	ldx	#1	; Set up for title text
	ldy	#15
	jsr	GotoXY

	ldx	#<.title; Write the title text
	ldy	#>.title
	jsr	PrintStr

	ldx	#1	; Set up for level text (top right corner)
	ldy	#31
	jsr	GotoXY

	ldx	#<.lvlstr; Write the level text
	ldy	#>.lvlstr
	jsr	PrintStr

	jsr	LVLtoPET ; Create level as a petscii string

	ldx	#<.lvltxt
	ldy	#>.lvltxt
	jsr	PrintStr

	ldy	#2	; Set up for help text (bottom line)
	ldx	#SCREEN_HEIGHT-2
	jsr	GotoXY

	ldx	#<.helptxt
	ldy	#>.helptxt
	jsr	PrintStr

	lda	#$92	; Reverse off
	jsr	CHROUT
	jsr	FillGA
	rts

; **************************************************************
; Set screen resolution to 40x30, clear the screen and show
; the splash screen asking user to press return to continue
; **************************************************************
; INPUTS:	.cx16, .xl1-.xl7, .ml1-.ml5, .starttxt
; **************************************************************
SplashScreen:
!ifndef C64 {
	lda	#$00	; 40x30 text mode
	sec		; Ensure carry is set for SCRMOD to function
	jsr	SCRMOD	; Set screen mode
}
	; Clear screen with black background
!ifdef C64 {
	lda	#$00
	sta	$D020	; Border color
	sta	$D021	; Background color
} else {
	lda	#PET_BLACK
	jsr	CHROUT
	lda	#$01	; Swap fg/bg
	jsr	CHROUT
}
	lda	#147
	jsr	CHROUT

	; COMMANDER 16
	ldx	#5
	ldy	#11
	jsr	GotoXY
	lda	#PET_GREEN
	jsr	CHROUT
	ldx	#<.cx16
	ldy	#>.cx16
	jsr	PrintStr

	; Top line of "graphical" X
	ldx	#2
	ldy	#18
	jsr	GotoXY
	lda	#PET_PURPLE
	jsr	CHROUT
	ldx	#<.xl1
	ldy	#>.xl1
	jsr	PrintStr

	; Next line of "graphical" X
	ldx	#3
	ldy	#19
	jsr	GotoXY
	lda	#PET_LIGHTBLUE
	jsr	CHROUT
	ldx	#<.xl2
	ldy	#>.xl2
	jsr	PrintStr

	; Next line of "graphical" X
	ldx	#4
	ldy	#20
	jsr	GotoXY
	lda	#PET_CYAN
	jsr	CHROUT
	ldx	#<.xl3
	ldy	#>.xl3
	jsr	PrintStr

	; First line of bottom of "graphical" X
	ldx	#6
	ldy	#20
	jsr	GotoXY
	lda	#PET_YELLOW
	jsr	CHROUT
	ldx	#<.xl5
	ldy	#>.xl5
	jsr	PrintStr

	; Next line of "graphical" X
	ldx	#7
	ldy	#19
	jsr	GotoXY
	lda	#PET_ORANGE
	jsr	CHROUT
	ldx	#<.xl6
	ldy	#>.xl6
	jsr	PrintStr

	; Last line of "graphical" X
	ldx	#8
	ldy	#18
	jsr	GotoXY
	lda	#PET_RED
	jsr	CHROUT
	ldx	#<.xl7
	ldy	#>.xl7
	jsr	PrintStr

	; Print MAZE with large letters (height=5 lines)
	ldx	#20
	ldy	#7
	jsr	GotoXY
	lda	#PET_GREEN
	jsr	CHROUT
	ldx	#<.ml1
	ldy	#>.ml1
	jsr	PrintStr

	ldx	#21
	ldy	#7
	jsr	GotoXY
	ldx	#<.ml2
	ldy	#>.ml2
	jsr	PrintStr

	ldx	#22
	ldy	#7
	jsr	GotoXY
	ldx	#<.ml3
	ldy	#>.ml3
	jsr	PrintStr

	ldx	#23
	ldy	#7
	jsr	GotoXY
	ldx	#<.ml4
	ldy	#>.ml4
	jsr	PrintStr

	ldx	#24
	ldy	#7
	jsr	GotoXY
	ldx	#<.ml5
	ldy	#>.ml5
	jsr	PrintStr

	; Start text
	ldx	#14
	ldy	#11
	jsr	GotoXY
	lda	#PET_WHITE
	jsr	CHROUT
	ldx	#<.starttxt
	ldy	#>.starttxt
	jsr	PrintStr
.wloop
	jsr	Random		; Call the random generator
	jsr	GETIN		; While waiting for user to press enter
	cmp	#13
	bne	.wloop
	rts

; ***************************************************************
; Sets a random color for the trail of the maze
; ***************************************************************
; INPUTS:	.rndnum and .trailcol global variables
; ***************************************************************
SetTrailCol:
	jsr	Random		; Get random number into reg A
	lda	#$0F		; Only the low nibble is
	and	.rndnum		; randomized to use as index into PetCodes

	beq	SetTrailCol	; Avoid black, wallcolor and some
	cmp	#$00		; dark colors
	beq	SetTrailCol
	cmp	#$0B
	beq	SetTrailCol
	cmp	#$06
	beq	SetTrailCol
	tay
	lda	PetCodes,y
	sta	.trailcol	; Store the new color
	rts

PetCodes:	!byte	$90,$05,$1C,$9F,$9C,$1E,$1F,$9E,$81,$95,$96,$97,$98,$99,$9A,$9B

; **************************************************************
; Opens a logical file to Screen device and sets it as input
; **************************************************************
SetScrIn:
	lda	#17		; Logical file, chosen randomly
	ldx	#3		; Device - 3 = screen
	ldy	#255		; Command - None
	jsr	SETLFS
	jsr	OPEN		; Open the logical file
	ldx	#17
	jsr	CHKIN		; Make it an input stream
	rts

; **************************************************************
; Waits for a given number of jiffies.
; There are 60 jiffies in a second
; **************************************************************
; INPUTS:	TMP5 should contain the amount of jiffies to wait
; **************************************************************
DoDelay:
	lda	#0
	jsr	SETTIM		; SETTIM - Set real time clock

.dolop:	jsr	RDTIM		; RDTIM	- Read time
	cmp	TMP5		; 60 jiffies in 1 second
	bne	.dolop
	rts

; *******************************************************************
; Generates a pseudo random number. It is vital that this function
; is called in some sort of loop that has user input, otherwise it
; just generates a sequence of numbers that will be the same every
; time. In other words, the randomness of this routine comes from
; the fact that the user presses keys at random times.
; It was found here:
; https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
; *******************************************************************
; INPUTS:	Works with .rndnum global variable
; *******************************************************************
Random:
	lda	.rndnum
	beq	doeor
	asl
	beq	noeor
	bcc	noeor
doeor:	eor	#$1D
noeor:	sta	.rndnum
	rts

; *******************************************************************
; Finds the next level (increment or reset back to 1)
; Congratulates the user on completing the level and waits for
; user to press spacebar to advance to next level.
; *******************************************************************
; INPUT:	Works with .lvl global variable
; *******************************************************************
LevelComplete:
	lda	#10		; Store 10 in TMP5 to wait for 10
	sta	TMP5		; jiffies when calling DoDelay func

	lda	#PET_WHITE
	jsr	CHROUT

!ifdef C64 {
	@YCOORD=11
} else {
	@YCOORD=14
}
	; Create a black box in the middle of the screen and write
	; level completed in the box.
	ldx	#@YCOORD+0
	ldy	#11
	jsr	GotoXY

	lda	#' '
	ldx	#17
	jsr	HLine

	ldx	#@YCOORD+1
	ldy	#11
	jsr	GotoXY

	lda	#' '
	ldx	#17
	jsr	HLine

	ldx	#@YCOORD+2
	ldy	#11
	jsr	GotoXY

	lda	#' '
	ldx	#17
	jsr	HLine

	ldx	#@YCOORD+1
	ldy	#12
	jsr	GotoXY
	ldx	#<.completetxt
	ldy	#>.completetxt
	jsr	PrintStr

	inc	.lvl		; Increment level and check if it
	lda	#NUMLEVELS+1	; has been incremented past the
	cmp	.lvl		; total number of levels
	bne	.changeborder	; If level is OK, change border
	lda	#1		; Set level back to 1 if it is larger
	sta	.lvl		; than the number of levels

.changeborder:
	jsr	Random		; Get a random number
	lda	#$0F		; AND with $0F0 to get index to petscii code
	and	.rndnum
	tay
	lda	PetCodes,y
	jsr	DrawOutBorder	; Draw border with random color
	jsr	DoDelay		; Wait
	jsr	GETIN		; Check if key has been pressed
	cmp	#' '		; Is it space-key
	bne	.changeborder	; If not, change border
	rts

; *******************************************************************
; Converts value in byte to 3-digit decimal !pet-string
; *******************************************************************
; INPUTS:	Works with the .lvltxt and .lvl global variables
; *******************************************************************
LVLtoPET:
	; Local names to zero-page constants to make code a bit
	; more readable.
	.value=TMP0
	.digit=TMP1
	.num=TMP2

	; Ensure that the .lvltxt variable contains "000"
	ldy	#'0'
	sty	.lvltxt
	sty	.lvltxt+1
	sty	.lvltxt+2

	lda	.lvl		; Load Reg A with current level

	; Check if .lvl is >= 200
	cmp	#200
	bcc	.is100		; branch to .is100 if .lvl <200
	ldy	#'2'		; Write '2' to first digit of .lvltxt
	sty	.lvltxt
	sbc	#200		; Subtract 200 from .lvl
	beq	.allDone	; If result = 0, we are done
	jmp	.Tens
	; Check if .lvl is >= 100
.is100:
	cmp	#100
	bcc	.Tens		; branch to .Tens if .lvl < 100
	ldy	#'1'		; Write '1' to first digit of .lvltxt
	sty	.lvltxt
	sbc	#100		; Subtract 100 from .lvl
	beq	.allDone	; If result = 0, we are done
	; Check if .lvl contains any tens (10-90)
.Tens:
	ldy	#9
	sty	.digit		; Store digit in zero-page memory
	ldy	#90
	sty	.num		; Store digit*10 in zero-page memory
.DoTens
	cmp	.num
	bcc	.Any10		; branch to .Any10 if .lvl < .num

	sta	.value		; Save current value as we need the accumulator
	lda	.digit
	ora	#$30		; OR $30 with digit to get petscii char
	sta	.lvltxt+1	;Write digit to 2nd space of .lvltxt

	lda	.value		; Restore value into A register
	sec			; Set carry flag to ensure correct subtraction
	sbc	.num		; Subtract .num from current .value
	jmp	.Ones

.Any10	cmp	#10
	bcc	.Ones		; branch to .Ones if A < 10
	; subtract 10 from .value
	sta	.value		; Save current value
	lda	.num		; Subtract 10 from .number
	sec
	sbc	#10
	sta	.num
	lda	.value		; Restore A from TMP1
	dec	.digit
	jmp	.DoTens
.Ones:
	ora	#$30		; OR $30 with digit to get petscii char
	sta	.lvltxt+2	;Write digit to 3rd space of .lvltxt
.allDone:
	rts

; *******************************************************************
; Draw the outer border of the screen in a specific color
; *******************************************************************
; INPUTS:	A = Color to use when drawing the border
;		It is the background color that is used
; *******************************************************************
DrawOutBorder:
	jsr	CHROUT		; Set Color
	lda	#$12		; Reverse ON
	jsr	CHROUT
	; Top horizontal line
	ldx	#0
	ldy	#0
	jsr	GotoXY
	ldx	#39
	lda	#' '
	jsr	HLine

	; Left vertical line
	ldx	#1
	ldy	#0
	jsr	GotoXY
	ldx	#SCREEN_HEIGHT-2
	lda	#' '
	jsr	VLine

	; Right vertical line
	ldx	#0
	ldy	#39
	jsr	GotoXY
	ldx	#SCREEN_HEIGHT-1
	lda	#' '
	jsr	VLine

	; Bottom horizontal line
	ldx	#SCREEN_HEIGHT-1
	ldy	#0
	jsr	GotoXY
	ldx	#39
	lda	#' '
	jsr	HLine

	lda	#$92		; Reverse OFF
	jsr	CHROUT
	rts

; *******************************************************************
; Write a zero-terminated petscii string to screen
; *******************************************************************
; INPUTS:	X = Low byte of string starting address
;		Y = High byte of string starting address
; *******************************************************************
PrintStr:
	; Store address of string in ZP memory
	stx	TMP0
	sty	TMP1
	ldy	#0		; Y register used to index string
.doprint
	lda	(TMP0), Y	; Load character from string
	beq	.printdone	; If character is 0, we are done
	jsr	CHROUT		; Write charactoer to screen
	iny			; Inc Y to get next character
	jmp	.doprint	; Get next character
.printdone:
	rts

; *******************************************************************
; Fill the "gamearea" with "wall tiles"
; *******************************************************************
; INPUTS:	Global constant WallCol is used.
; *******************************************************************
FillGA:
	lda	#WallCol
	jsr	CHROUT
	lda	#$12		; Reverse ON
	jsr	CHROUT

	ldx	#1		; X register holds the Y coordinate

.StartOfFill:
	inx			; Increment Y coordinate to go to next line
	stx	TMP0		; Save the Y coordinate in ZP
	cpx	#SCREEN_HEIGHT-2; If we have reached bottom Y-coordinate
	beq	.EndOfFill	; We are done, so branch to end
	ldy	#2		; Y register holds the X coordinate
	jsr	GotoXY		; Place cursor at X, Y coordinates
	lda	#Wall		; Load A with 'wall' character
	ldx	#36		; Create a horizontal line that is
	jsr	HLine		; 36 characters wide
	ldx	TMP0		; Restore Y coordinate from ZP
	jmp	.StartOfFill
.EndOfFill
	lda	#$92		; Reverse OFF
	jsr	CHROUT
	rts

; *******************************************************************
; Print a vertical line
; *******************************************************************
; INPUTS:	A = Character used to print the line
;		X = Height of the line
; *******************************************************************
VLine:
	jsr	CHROUT		; Write character
	tay			; Save character in Y register
	lda	#157		; Cursor Left
	jsr	CHROUT
	lda	#17		; Cursor Down
	jsr	CHROUT
	tya			; Restore character to A register
	dex			; Decrement line height
	bne	VLine		; Jump to top if we have not reached 0
	rts

; *******************************************************************
; Print a horizontal line
; *******************************************************************
; INPUTS:	A = Character used to print the line
;		X = Length of the line
; *******************************************************************
HLine:
	jsr	CHROUT		; Print character to screen
	dex
	bne	HLine		; Repeat while X > 0
	rts

; *******************************************************************
; Ensures that Carry flag is cleared and calls PLOT to set cursor pos
; *******************************************************************
; INPUTS:	X = Column (Y coordinate)
;		Y = Row    (X coordinate)
; *******************************************************************
GotoXY:
	clc			; Clear Carry Flag
	jsr	PLOT		; Move cursor to coordinates in X & Y
	rts


	; Level 1
.mazes	!byte	25,10,10	;size,width,Height
	!byte	00,01		;start coordinates (zero based)
	!byte	%........,%..######
	!byte	%........,%.#######
	!byte	%#.......,%.#######
	!byte	%#.......,%########
	!byte	%##......,%########
	!byte	%##.....#,%########
	!byte	%###....#,%########
	!byte	%###...##,%########
	!byte	%####..##,%########
	!byte	%####.###,%########

	; Level 2
	!byte	15,8,10
	!byte	0,9
	!byte	%........
	!byte	%.####.#.
	!byte	%.##...#.
	!byte	%.#......
	!byte	%.#....##
	!byte	%.#......
	!byte	%.#....#.
	!byte	%.#...##.
	!byte	%.##.###.
	!byte	%........

	; Level 3
	!byte	14,7,9
	!byte	0,8
	!byte	%.......#
	!byte	%.#####.#
	!byte	%.......#
	!byte	%.#######
	!byte	%.......#
	!byte	%######.#
	!byte	%.......#
	!byte	%.#####.#
	!byte	%.......#

	; Level 4
	!byte	12,7,7
	!byte	0,6
	!byte	%......##
	!byte	%.####..#
	!byte	%.#.....#
	!byte	%.#.##..#
	!byte	%.#.....#
	!byte	%.#####.#
	!byte	%.......#

	; Level 5
	!byte	12,7,7
	!byte	0,6
	!byte	%.......#
	!byte	%.#####.#
	!byte	%.#####.#
	!byte	%.......#
	!byte	%.#.#.#.#
	!byte	%.#.#.#.#
	!byte	%...#...#

	; Level 6
	!byte	25,10,10	;size,width,height
	!byte	0,9		;start coordinates (zero based)
	!byte	%........,%.#######
	!byte	%.#......,%..######
	!byte	%.#.#####,%#.######
	!byte	%.#.#....,%#.######
	!byte	%.#.#..#.,%#.######
	!byte	%.#.#..#.,%#.######
	!byte	%.#.####.,%#.######
	!byte	%.#......,%#.######
	!byte	%.#######,%#.######
	!byte	%........,%..######

	; Level 7
	!byte	15,7,10
	!byte	0,8
	!byte	%#.....##
	!byte	%..###..#
	!byte	%.......#
	!byte	%...#...#
	!byte	%.#.#.#.#
	!byte	%.#.#.#.#
	!byte	%.#...#.#
	!byte	%.#####.#
	!byte	%...#...#
	!byte	%#.....##

	; Level 8
	!byte	23,10,9
	!byte	0,8
	!byte	%##......,%.#######
	!byte	%##.#####,%..######
	!byte	%.......#,%..######
	!byte	%.#.#....,%..######
	!byte	%.#.#.###,%########
	!byte	%.#......,%.#######
	!byte	%.##.....,%.#######
	!byte	%.#######,%.#######
	!byte	%........,%.#######

	; Level 9
	!byte	31,13,13
	!byte	0,12
	!byte	%####....,%.....###
	!byte	%......##,%####.###
	!byte	%.###..#.,%.....###
	!byte	%........,%..#..###
	!byte	%####..##,%###..###
	!byte	%......#.,%.##..###
	!byte	%.####.#.,%.##..###
	!byte	%.####.#.,%.##..###
	!byte	%.####.#.,%.##..###
	!byte	%...##...,%.##..###
	!byte	%##.#####,%.##..###
	!byte	%...#....,%.##..###
	!byte	%...#....,%.##..###

	; Level 10
	!byte	27,11,11
	!byte	0,10
	!byte	%........,%########
	!byte	%.###....,%..######
	!byte	%.##.....,%...#####
	!byte	%....###.,%.#.#####
	!byte	%.#..#...,%.#.#####
	!byte	%.#.##.#.,%##.#####
	!byte	%.#.##.#.,%##.#####
	!byte	%.#.##.#.,%##.#####
	!byte	%......#.,%##.#####
	!byte	%......#.,%.#.#####
	!byte	%..######,%...#####

	; Level 11
	!byte	27,11,11
	!byte	0,10
	!byte	%...###..,%...#####
	!byte	%.#...#..,%...#####
	!byte	%.#......,%.#######
	!byte	%.#....##,%..######
	!byte	%.##.....,%..######
	!byte	%.#....#.,%...#####
	!byte	%.#....#.,%...#####
	!byte	%.##.#.##,%#..#####
	!byte	%.##...#.,%..######
	!byte	%.##.###.,%########
	!byte	%.##.....,%########

	; Level 12
	!byte	31,13,13
	!byte	0,11
	!byte	%#.......,%###..###
	!byte	%..#####.,%.##..###
	!byte	%..#####.,%.##..###
	!byte	%..#####.,%.##..###
	!byte	%.....##.,%.##..###
	!byte	%.###.###,%.....###
	!byte	%.......#,%####.###
	!byte	%.####...,%...#.###
	!byte	%..###..#,%##.#.###
	!byte	%..###..#,%##.#.###
	!byte	%..###...,%.#...###
	!byte	%..####.#,%.#.#####
	!byte	%#......#,%.....###

	; Level 13
	!byte	31,13,13
	!byte	0,11
	!byte	%#....###,%..######
	!byte	%..##...#,%....####
	!byte	%..##.#.#,%....####
	!byte	%.......#,%.....###
	!byte	%...#.###,%.....###
	!byte	%.###.###,%.....###
	!byte	%........,%.....###
	!byte	%####.##.,%.....###
	!byte	%.....##.,%...#####
	!byte	%.##.###.,%...#####
	!byte	%..#.....,%.#######
	!byte	%..#####.,%########
	!byte	%#.......,%########

	; Level 14
	!byte	41,13,18
	!byte	0,14
	!byte	%......#.,%.#######
	!byte	%.#.##.#.,%.#######
	!byte	%.#....#.,%...#####
	!byte	%.#.####.,%.#.#####
	!byte	%.#......,%....####
	!byte	%.#...##.,%.#..####
	!byte	%.######.,%.....###
	!byte	%........,%.....###
	!byte	%########,%.#...###
	!byte	%##.....#,%.....###
	!byte	%#......#,%##...###
	!byte	%#.####.#,%####.###
	!byte	%#....#.#,%####.###
	!byte	%#.##.#..,%.....###
	!byte	%..##.###,%####.###
	!byte	%.....#..,%.....###
	!byte	%.#####..,%.....###
	!byte	%.......#,%########

	; Level 15
	!byte	25,10,10
	!byte	0,9
	!byte	%.......#,%########
	!byte	%.#####..,%.#######
	!byte	%.#.....#,%.#######
	!byte	%.#.#####,%.#######
	!byte	%.#.#....,%..######
	!byte	%........,%..######
	!byte	%##.#.##.,%..######
	!byte	%........,%..######
	!byte	%.#.#.##.,%..######
	!byte	%...#....,%.#######

	; Level 16
	!byte	31,9,13
	!byte	0,12
	!byte	%#......#,%########
	!byte	%#.#.##.#,%########
	!byte	%#.#.....,%.#######
	!byte	%#.#.####,%.#######
	!byte	%#.......,%.#######
	!byte	%###.####,%########
	!byte	%#...##..,%.#######
	!byte	%..####.#,%.#######
	!byte	%.###....,%.#######
	!byte	%.###.#.#,%########
	!byte	%........,%.#######
	!byte	%.###.#.#,%.#######
	!byte	%.....#..,%.#######

	; Level 17
	!byte	25,10,10
	!byte	1,8
	!byte	%#...#...,%.#######
	!byte	%........,%..######
	!byte	%....#.#.,%#.######
	!byte	%........,%..######
	!byte	%......#.,%..######
	!byte	%.#......,%.#######
	!byte	%........,%..######
	!byte	%..#.....,%..######
	!byte	%#.......,%########
	!byte	%###....#,%########

	; Level 18
	!byte	27,11,11
	!byte	0,10
	!byte	%......##,%#..#####
	!byte	%.##.#.##,%...#####
	!byte	%.......#,%...#####
	!byte	%###.#..#,%...#####
	!byte	%....#..#,%...#####
	!byte	%.#..#..#,%...#####
	!byte	%.#.##..#,%##.#####
	!byte	%.#.#....,%.#.#####
	!byte	%.###.#.#,%.#.#####
	!byte	%.......#,%.#.#####
	!byte	%.....###,%...#####

	; Level 19
	!byte	31,13,13
	!byte	0,12
	!byte	%#..#####,%####.###
	!byte	%#....###,%##...###
	!byte	%#....###,%.....###
	!byte	%#......#,%.....###
	!byte	%#......#,%.....###
	!byte	%#.....##,%.....###
	!byte	%........,%.....###
	!byte	%......#.,%.....###
	!byte	%......#.,%.....###
	!byte	%......#.,%.....###
	!byte	%......#.,%.....###
	!byte	%....####,%#....###
	!byte	%..######,%###..###

	; Level 20
	!byte	31,13,13
	!byte	0,0
	!byte	%........,%.....###
	!byte	%####.###,%####.###
	!byte	%###.....,%.###.###
	!byte	%##......,%..##.###
	!byte	%#.......,%#.##.###
	!byte	%#.#.....,%...#.###
	!byte	%#.##.#.#,%#..#.###
	!byte	%#....#.#,%#..#.###
	!byte	%#...##.#,%..##.###
	!byte	%###.##.#,%.###.###
	!byte	%###.....,%.....###
	!byte	%###.....,%..######
	!byte	%######..,%.#######

	; Level 21
	!byte	29,12,12
	!byte	0,11
	!byte	%####...#,%....####
	!byte	%####.#.#,%.#######
	!byte	%####.#.#,%.#######
	!byte	%##.....#,%....####
	!byte	%##.#..##,%.##.####
	!byte	%##.##...,%.##.####
	!byte	%##.#####,%.##.####
	!byte	%...#....,%....####
	!byte	%.#.#.##.,%########
	!byte	%.#......,%########
	!byte	%.###.###,%########
	!byte	%.....###,%########

	; Level 22
	!byte	31,13,13
	!byte	0,12
	!byte	%..######,%....####
	!byte	%....####,%.##..###
	!byte	%....####,%.###.###
	!byte	%#.#.#...,%.###.###
	!byte	%#.#.#...,%.....###
	!byte	%#.#...##,%#.##.###
	!byte	%#.###.##,%#.##.###
	!byte	%..#...#.,%..##.###
	!byte	%..#.###.,%####.###
	!byte	%....###.,%...#.###
	!byte	%..######,%##.#.###
	!byte	%........,%.#.#.###
	!byte	%........,%.#...###

	; Level 23
	!byte	29,13,12
	!byte	0,10
	!byte	%#####..#,%#....###
	!byte	%........,%#....###
	!byte	%.####.#.,%####.###
	!byte	%....#.#.,%##...###
	!byte	%###.#.#.,%.....###
	!byte	%....#.##,%##.#####
	!byte	%.####.##,%##.#####
	!byte	%..##..##,%##.#####
	!byte	%#.##....,%.#...###
	!byte	%...#.###,%.#.#.###
	!byte	%...#.#..,%...#.###
	!byte	%##...#..,%.#...###

	; Level 24
	!byte	33,14,14
	!byte	0,12
	!byte	%#...#...,%##..####
	!byte	%....#...,%......##
	!byte	%..#.#.#.,%##..#.##
	!byte	%..#.#.#.,%##..#.##
	!byte	%........,%......##
	!byte	%....###.,%##..#.##
	!byte	%#....##.,%##..#.##
	!byte	%#..#....,%....#.##
	!byte	%...#....,%......##
	!byte	%.....#..,%###...##
	!byte	%...###..,%......##
	!byte	%.......#,%##.#..##
	!byte	%.#......,%.....###
	!byte	%#####..#,%##...###

	; Level 25
	!byte	31,13,13
	!byte	0,11
	!byte	%.#......,%.....###
	!byte	%.#.####.,%.....###
	!byte	%......#.,%########
	!byte	%.####.#.,%########
	!byte	%...##.#.,%....####
	!byte	%##.##.##,%.....###
	!byte	%.......#,%####.###
	!byte	%.#.....#,%####.###
	!byte	%.#####..,%.###.###
	!byte	%.#####.#,%.###.###
	!byte	%.#####.#,%.###.###
	!byte	%.....#.#,%.....###
	!byte	%#.......,%....####

	; Level 26
	!byte	44,18,13
	!byte	0,8
	!byte	%........,%######..,%..######
	!byte	%.######.,%##......,%#.######
	!byte	%......#.,%#..#.##.,%#.######
	!byte	%.#.#..#.,%#..#.##.,%#.######
	!byte	%.#.#..#.,%#..#....,%#.######
	!byte	%...#.##.,%#..#####,%#.######
	!byte	%####.##.,%#.....#.,%..######
	!byte	%........,%#####.#.,%.#######
	!byte	%........,%..###.#.,%.#######
	!byte	%##.#.#..,%#.###.#.,%.#######
	!byte	%##......,%...##.#.,%.#######
	!byte	%####....,%...##.#.,%.#######
	!byte	%######..,%........,%.#######

	; Level 27
	!byte	31,14,13
	!byte	0,11
	!byte	%........,%....####
	!byte	%.#...###,%###.####
	!byte	%........,%###...##
	!byte	%##...##.,%###...##
	!byte	%##...##.,%#####.##
	!byte	%##......,%..###.##
	!byte	%###.....,%...##.##
	!byte	%###.....,%...##.##
	!byte	%####....,%...##.##
	!byte	%####.###,%#.###.##
	!byte	%........,%......##
	!byte	%........,%..######
	!byte	%##......,%..######

	; Level 28
	!byte	33,13,14
	!byte	0,13
	!byte	%########,%...#.###
	!byte	%########,%.#.#.###
	!byte	%######..,%.#.#.###
	!byte	%####...#,%#....###
	!byte	%####.#.#,%#.######
	!byte	%#....#.#,%#.######
	!byte	%#.......,%.....###
	!byte	%#.#.....,%.#######
	!byte	%#.#.#.##,%.#...###
	!byte	%#.#...##,%...#.###
	!byte	%...#....,%...#.###
	!byte	%.#......,%...#.###
	!byte	%.#.#.##.,%..#..###
	!byte	%........,%#...####

	; Level 29
	!byte	31,13,13
	!byte	0,12
	!byte	%#....#..,%.#######
	!byte	%.....#.#,%.....###
	!byte	%..####.#,%.#...###
	!byte	%.......#,%.#.#####
	!byte	%#.#.##.#,%.#...###
	!byte	%..#....#,%.#.#.###
	!byte	%..######,%.#.#.###
	!byte	%........,%...#.###
	!byte	%.#......,%...#.###
	!byte	%.#.#####,%####.###
	!byte	%.#......,%.....###
	!byte	%.####.#.,%####.###
	!byte	%......#.,%.....###

	; Level 30
	!byte	44,18,13
	!byte	0,12
	!byte	%#.......,%....####,%########
	!byte	%#..#.##.,%......##,%########
	!byte	%#..#.##.,%........,%########
	!byte	%#..#.###,%.#..#.#.,%########
	!byte	%#..#.###,%........,%..######
	!byte	%#..#.###,%##......,%..######
	!byte	%...#....,%.#.##.##,%########
	!byte	%.######.,%.#.##.#.,%..######
	!byte	%.#....#.,%.#.#..#.,%#.######
	!byte	%.#.##.#.,%.#.#..#.,%#.######
	!byte	%.#.##.#.,%.#.#....,%..######
	!byte	%.#......,%##.#####,%#.######
	!byte	%....####,%##......,%..######

	; Level 31
	!byte	21,10,8
	!byte	0,6
	!byte	%#..####.,%..######
	!byte	%...###..,%..######
	!byte	%....##.#,%..######
	!byte	%........,%..######
	!byte	%.#......,%..######
	!byte	%.##.....,%..######
	!byte	%........,%.#######
	!byte	%#.......,%..######

	; Level 32
	!byte	41,13,18
	!byte	0,13
	!byte	%..####..,%##..####
	!byte	%..##....,%##..####
	!byte	%..##....,%....####
	!byte	%..##....,%#...####
	!byte	%........,%....####
	!byte	%...#....,%#...####
	!byte	%...#....,%#...####
	!byte	%...#....,%#...####
	!byte	%...#....,%#...####
	!byte	%...#....,%#...####
	!byte	%........,%.....###
	!byte	%........,%.....###
	!byte	%...#...#,%#....###
	!byte	%.......#,%#....###
	!byte	%#..#...#,%###..###
	!byte	%#..#...#,%###..###
	!byte	%#......#,%########
	!byte	%#..##..#,%########

	; Level 33
	!byte	33,15,14
	!byte	0,12
	!byte	%##...###,%##...###
	!byte	%#....#.#,%##...###
	!byte	%#.......,%#.....##
	!byte	%........,%#.....##
	!byte	%........,%.##...##
	!byte	%...#.#..,%..#..###
	!byte	%.....##.,%..#...##
	!byte	%#.......,%.......#
	!byte	%.###.##.,%..#....#
	!byte	%........,%..#....#
	!byte	%####.#.#,%......##
	!byte	%........,%.....###
	!byte	%........,%...#####
	!byte	%####...#,%..######

	; Level 34
	!byte	33,14,14
	!byte	0,8
	!byte	%##......,%.....###
	!byte	%......##,%#.##.###
	!byte	%..#.....,%......##
	!byte	%....#...,%......##
	!byte	%#.#.#..#,%#.##.###
	!byte	%#.#.#..#,%#.##.###
	!byte	%#.#.....,%......##
	!byte	%.......#,%#.##..##
	!byte	%...##..#,%#.....##
	!byte	%#..#....,%#.######
	!byte	%#..#.##.,%......##
	!byte	%#.......,%..##..##
	!byte	%##......,%......##
	!byte	%#.....##,%.....###

	; Level 35
	!byte	31,13,13
	!byte	0,10
	!byte	%#####...,%.....###
	!byte	%#...#.##,%.###.###
	!byte	%#.#.#..#,%.....###
	!byte	%#.#.##.#,%.#.#####
	!byte	%#.#.....,%...#####
	!byte	%#.#..##.,%.#.#####
	!byte	%..#####.,%.#...###
	!byte	%....###.,%.#.#.###
	!byte	%.....##.,%.#...###
	!byte	%........,%####.###
	!byte	%......#.,%.....###
	!byte	%#..#..#.,%##.#####
	!byte	%#######.,%...#####

	; Level 36
	!byte	29,13,12
	!byte	0,10
	!byte	%#####...,%.....###
	!byte	%#.......,%...#.###
	!byte	%#.###.##,%####.###
	!byte	%#.#.....,%...#.###
	!byte	%#.#.####,%##.#.###
	!byte	%#.......,%.....###
	!byte	%..#.....,%.#...###
	!byte	%.####.##,%.#.#####
	!byte	%.##.....,%.....###
	!byte	%.##.#...,%.#.#.###
	!byte	%..#.####,%##.#.###
	!byte	%#.......,%.....###

	; Level 37
	!byte	59,18,18
	!byte	0,15
	!byte	%#.......,%..###..#,%########
	!byte	%#.......,%...##..#,%########
	!byte	%#.#.....,%...#...#,%..######
	!byte	%#.#..###,%####....,%..######
	!byte	%#.#..#..,%........,%..######
	!byte	%..#..#..,%#####...,%..######
	!byte	%..#.....,%........,%..######
	!byte	%.##..#..,%...#....,%..######
	!byte	%.#...##.,%#..#....,%.#######
	!byte	%.#......,%#####...,%.#######
	!byte	%.#....##,%#..##...,%.#######
	!byte	%......##,%...##...,%.#######
	!byte	%.##...##,%....#...,%.#######
	!byte	%..######,%.##.#...,%.#######
	!byte	%..#.....,%....#...,%.#######
	!byte	%..#.##.#,%..#.###.,%.#######
	!byte	%#.......,%.....##.,%.#######
	!byte	%######..,%..#..###,%########

	; Level 38
	!byte	59,18,18
	!byte	0,17
	!byte	%......##,%###..###,%..######
	!byte	%.####..#,%#....###,%..######
	!byte	%....##..,%....##..,%..######
	!byte	%.....#..,%#.#.##..,%..######
	!byte	%#.#..#..,%#.......,%..######
	!byte	%#.######,%#.#..#..,%..######
	!byte	%#.....#.,%........,%..######
	!byte	%#####...,%#.#..#..,%.#######
	!byte	%##......,%#.#..#..,%.#######
	!byte	%##.###..,%#.#..#..,%.#######
	!byte	%##...#..,%#.#..#..,%.#######
	!byte	%#....#..,%#.#..#..,%.#######
	!byte	%...###..,%#.#..#..,%.#######
	!byte	%...###..,%#.#..#..,%.#######
	!byte	%........,%........,%.#######
	!byte	%..####..,%.....##.,%.#######
	!byte	%..####..,%###..##.,%.#######
	!byte	%..######,%########,%########

	; Level 39
	!byte	37,16,16
	!byte	0,11
	!byte	%..####..,%........
	!byte	%....##.#,%#.......
	!byte	%........,%#......#
	!byte	%.#..###.,%##.....#
	!byte	%.#.####.,%##.#.###
	!byte	%.#....#.,%##.#...#
	!byte	%.####.#.,%...#...#
	!byte	%........,%.#.###.#
	!byte	%#####.##,%.#.#....
	!byte	%......##,%.#.#....
	!byte	%.####.##,%.#.#...#
	!byte	%....#.#.,%.#.##..#
	!byte	%#.......,%.......#
	!byte	%###.###.,%.#.##..#
	!byte	%###.....,%.......#
	!byte	%###.....,%#..##..#

	; Level 40
	!byte	37,16,16
	!byte	0,15
	!byte	%.....###,%...#...#
	!byte	%..##.###,%.#.#.#..
	!byte	%#....#..,%...#.#..
	!byte	%#.####.#,%.###.#..
	!byte	%..##....,%.###.#..
	!byte	%.###.#.#,%.###.#..
	!byte	%.###....,%.#...#..
	!byte	%...###.#,%##.####.
	!byte	%...###..,%........
	!byte	%#....###,%##.###..
	!byte	%#.#..###,%##.###..
	!byte	%#.#.####,%##...#..
	!byte	%........,%.....#..
	!byte	%..#.####,%###.##..
	!byte	%..#.....,%....##..
	!byte	%..######,%######..

	; Level 41
	!byte	33,14,14
	!byte	0,12
	!byte	%...##...,%.#...###
	!byte	%.#..#.##,%.#.#.###
	!byte	%.##.....,%......##
	!byte	%.####.##,%.#.##.##
	!byte	%........,%.#.##.##
	!byte	%#####.##,%##....##
	!byte	%....#...,%.#######
	!byte	%........,%.#..####
	!byte	%###.#..#,%##..####
	!byte	%###.#...,%.....###
	!byte	%###.#..#,%.#.#.###
	!byte	%........,%.#.#.###
	!byte	%....#..#,%##.#.###
	!byte	%#####..#,%##...###

	; Level 42
	!byte	33,14,14
	!byte	0,13
	!byte	%.......#,%......##
	!byte	%.#####.#,%.####.##
	!byte	%....#..#,%....#.##
	!byte	%###...##,%....#.##
	!byte	%.....###,%..###.##
	!byte	%.#####..,%....#.##
	!byte	%.###....,%..#.#.##
	!byte	%.#...#.#,%..#.#.##
	!byte	%.#.#.#.#,%..#.#.##
	!byte	%.#.#.#.#,%###.#.##
	!byte	%.#.#.#.#,%......##
	!byte	%.#......,%....#.##
	!byte	%.###.#.#,%.#.##.##
	!byte	%.....#..,%.#....##

	; Level 43
	!byte	33,14,14
	!byte	0,13
	!byte	%#....#..,%..#...##
	!byte	%.....#.#,%#.#.#.##
	!byte	%.###...#,%......##
	!byte	%...#####,%..###.##
	!byte	%##.####.,%..###.##
	!byte	%........,%.##...##
	!byte	%.#.####.,%.#...###
	!byte	%......#.,%.#.#.###
	!byte	%##.##.#.,%......##
	!byte	%##....##,%.#.#..##
	!byte	%#####...,%......##
	!byte	%....#..#,%.#.##.##
	!byte	%........,%.#....##
	!byte	%.......#,%########

	; Level 44
	!byte	31,13,13
	!byte	0,11
	!byte	%#.......,%.....###
	!byte	%..######,%####.###
	!byte	%........,%####.###
	!byte	%#####.#.,%#....###
	!byte	%###...#.,%#.######
	!byte	%###.#.#.,%#....###
	!byte	%#.......,%...#.###
	!byte	%..#.###.,%##.#.###
	!byte	%..#.....,%##.#.###
	!byte	%..#..#..,%#..#.###
	!byte	%.#####..,%#..#.###
	!byte	%.....#..,%#....###
	!byte	%#......#,%#...####

	; Level 45
	!byte	33,14,14
	!byte	0,13
	!byte	%...##...,%.#....##
	!byte	%...#...#,%.#..#.##
	!byte	%.###...#,%.#..#.##
	!byte	%.....###,%.#..#.##
	!byte	%.#####..,%....#.##
	!byte	%.####..#,%.#.##.##
	!byte	%.#.....#,%......##
	!byte	%.#.##.##,%#.######
	!byte	%........,%....####
	!byte	%.#..#.##,%#.#.####
	!byte	%.####.#.,%......##
	!byte	%....#.#.,%....#.##
	!byte	%..#.#.##,%#.###.##
	!byte	%..#...##,%#.....##

	; Level 46
	!byte	41,13,18
	!byte	0,11
	!byte	%######..,%.....###
	!byte	%.......#,%####.###
	!byte	%.......#,%.....###
	!byte	%.#######,%.##..###
	!byte	%.......#,%.##.####
	!byte	%.#####.#,%....####
	!byte	%.#####.#,%###.####
	!byte	%...###..,%....####
	!byte	%.....#..,%...#####
	!byte	%...#.###,%########
	!byte	%........,%.....###
	!byte	%......##,%####.###
	!byte	%#..#..##,%...#.###
	!byte	%#.......,%...#.###
	!byte	%##.#..##,%##.#.###
	!byte	%##....#.,%...#.###
	!byte	%####..#.,%##.#.###
	!byte	%####..#.,%.....###

	; Level 47
	!byte	31,13,13
	!byte	0,9
	!byte	%##...#..,%##..####
	!byte	%#..#.#..,%.#...###
	!byte	%#.#..#.#,%.#.#.###
	!byte	%....##..,%.....###
	!byte	%..######,%.#.#####
	!byte	%........,%.....###
	!byte	%########,%.#.#.###
	!byte	%###....#,%.#.#.###
	!byte	%........,%.#.#.###
	!byte	%.....###,%##.#.###
	!byte	%###..#..,%.....###
	!byte	%###....#,%##.#####
	!byte	%######..,%...#####

	; Level 48
	!byte	31,13,13
	!byte	0,11
	!byte	%###.....,%..######
	!byte	%..#..###,%#..#####
	!byte	%.....#..,%##.#####
	!byte	%..####..,%.#...###
	!byte	%....##.#,%.#.#.###
	!byte	%..#.##.#,%.#.#.###
	!byte	%..#....#,%.#.#.###
	!byte	%.#######,%.#.#.###
	!byte	%........,%.....###
	!byte	%########,%.#.#####
	!byte	%........,%.....###
	!byte	%..######,%.#.#.###
	!byte	%#.......,%.#...###

	; Level 49
	!byte	37,16,16
	!byte	0,14
	!byte	%........,%........
	!byte	%........,%......#.
	!byte	%########,%#.#####.
	!byte	%######..,%#.....#.
	!byte	%##......,%#####.#.
	!byte	%...###.#,%#.......
	!byte	%...###.#,%....#.##
	!byte	%...###.#,%..###.##
	!byte	%.....#.#,%..###..#
	!byte	%...#....,%.#####..
	!byte	%...#...#,%.#......
	!byte	%...#...#,%.#.#####
	!byte	%..##....,%........
	!byte	%..##...#,%.#.####.
	!byte	%..##...#,%.#......
	!byte	%####..##,%.......#

	; Level 50
	!byte	44,18,13
	!byte	0,7
	!byte	%....#...,%...#....,%..######
	!byte	%.##.#.##,%##.#.###,%#.######
	!byte	%.##.#.##,%.....###,%#.######
	!byte	%......#.,%...#####,%#.######
	!byte	%.####.#.,%.##.....,%..######
	!byte	%.#......,%.##.#.##,%########
	!byte	%.#.##.#.,%###.#.##,%########
	!byte	%......#.,%###.#.##,%########
	!byte	%##.####.,%###.#.##,%########
	!byte	%##.####.,%###.#...,%..######
	!byte	%##.####.,%......##,%#.######
	!byte	%##.####.,%########,%#.######
	!byte	%##......,%........,%..######

	; Level 51
	!byte	35,13,15
	!byte	0,11
	!byte	%#.......,%.....###
	!byte	%#.###.##,%####.###
	!byte	%........,%..##.###
	!byte	%..##....,%.....###
	!byte	%..#.#.#.,%#.######
	!byte	%..#.....,%...#####
	!byte	%..#.#.#.,%#..#####
	!byte	%..#...#.,%.....###
	!byte	%........,%#..#.###
	!byte	%.#....#.,%#..#.###
	!byte	%.#.#....,%.....###
	!byte	%......##,%#..#.###
	!byte	%##.##...,%#..#.###
	!byte	%##.####.,%####.###
	!byte	%##......,%.....###

	; Level 52
	!byte	31,13,13
	!byte	0,8
	!byte	%#...#...,%.....###
	!byte	%........,%####.###
	!byte	%..#.###.,%...#.###
	!byte	%..#...#.,%.#.#.###
	!byte	%..#.#.#.,%.#.#.###
	!byte	%###.#.#.,%.#...###
	!byte	%......#.,%.#.#####
	!byte	%.######.,%.#...###
	!byte	%........,%.#.#.###
	!byte	%#.#####.,%.#.#.###
	!byte	%#.......,%.#.#.###
	!byte	%#..#.###,%##.#.###
	!byte	%#..#....,%.....###

	; Level 53
	!byte	35,14,15
	!byte	0,11
	!byte	%##...#.#,%...#####
	!byte	%........,%....####
	!byte	%.....#.#,%..#.####
	!byte	%..#....#,%#....###
	!byte	%#.....##,%##.#.###
	!byte	%###..##.,%......##
	!byte	%###...#.,%##....##
	!byte	%..#.#.#.,%..######
	!byte	%......#.,%.#...###
	!byte	%..#...##,%.....###
	!byte	%.#...#..,%.###.###
	!byte	%...#...#,%.....###
	!byte	%#####...,%.#.#####
	!byte	%#####..#,%#..#####
	!byte	%######..,%..######

	; Level 54
	!byte	41,13,18
	!byte	0,17
	!byte	%.....#..,%.....###
	!byte	%.###.#.#,%####.###
	!byte	%.###...#,%####.###
	!byte	%.#.#.##.,%.....###
	!byte	%.#.#.##.,%#.######
	!byte	%.#......,%#.######
	!byte	%.#.####.,%#.######
	!byte	%.#.#....,%.....###
	!byte	%.#.#.##.,%#.##.###
	!byte	%........,%...#.###
	!byte	%####.##.,%#..#.###
	!byte	%..##.##.,%#....###
	!byte	%...#.##.,%##.#####
	!byte	%.#.#.##.,%.....###
	!byte	%.#.....#,%##.#.###
	!byte	%.###.#.#,%##.#.###
	!byte	%.###.#..,%.....###
	!byte	%.....###,%########

	; Level 55
	!byte	44,18,13
	!byte	0,11
	!byte	%###...##,%##......,%..######
	!byte	%###.#.##,%#..#.###,%#.######
	!byte	%#.....##,%........,%..######
	!byte	%#.#.###.,%..##.#.#,%#.######
	!byte	%....###.,%#.#.....,%#.######
	!byte	%......#.,%#.#..#..,%#.######
	!byte	%...##.#.,%#.#..#..,%#.######
	!byte	%...##.#.,%#.#..#..,%#.######
	!byte	%........,%........,%#.######
	!byte	%.#.##.#.,%#.#..#.#,%#.######
	!byte	%.#.##...,%#.##.#.#,%#.######
	!byte	%...####.,%........,%..######
	!byte	%#.......,%#......#,%########

	; Level 56
	!byte	35,14,15
	!byte	0,10
	!byte	%####...#,%########
	!byte	%###.....,%#...####
	!byte	%##......,%......##
	!byte	%##......,%......##
	!byte	%#...##.#,%##....##
	!byte	%........,%.#..####
	!byte	%........,%..######
	!byte	%#..#....,%....####
	!byte	%.....#.#,%.....###
	!byte	%...#.#.#,%#...####
	!byte	%........,%......##
	!byte	%#..#.#..,%#.....##
	!byte	%#..#.#..,%......##
	!byte	%#..#.#..,%.....###
	!byte	%#..#..#.,%...#####

	; Level 57
	!byte	21,15,8
	!byte	0,0
	!byte	%....####,%###....#
	!byte	%#....###,%##....##
	!byte	%##....##,%#....###
	!byte	%###.....,%...#####
	!byte	%####....,%....####
	!byte	%##....##,%#....###
	!byte	%#....###,%##....##
	!byte	%....####,%###....#
