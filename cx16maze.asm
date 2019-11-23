!zone Main {
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

; Seems that $DA contains the number of lines on the screen.
; If a new value is stored, it makes the text screen scroll on that line
; In 40x30 mode, I can avoid scrolling on the bottom right corner by
; setting the value in $DA to 31 instead of 30.

; Above information has changed in R34. Now the columns are at $02AE
; and the lines are at $02AF

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

; ******** Commander X16 specific **************************
;COLPORT=$02C9		; For ROM version > 34 ???
COLPORT=$0286		; This address contains both background (high nibble)
			; and foreground (low nibble) color. Writing to it
			; changes the colors. On C64 only foreground color
			; can be changed in low nibble

NUMCOLS=$02AE
NUMLINES=$02AF
			; This is remaining from older versions of the
			; CX16 emulator where only a handfull of ZP
			; addresses where available to the user.

TMP0=$00		; The first 3 unused zero page locations are used
TMP1=$01		; as temporary storage (registers)
TMP2=$02

TMP3=$03		; The last 4 unused zero page locations are also
TMP4=$04		; used as temporary storage (registers)
TMP5=$05
TMP6=$06

; ******* Constants used in the source **********************
Cursor=119
Wall=191
WallCol=$BB
Space=' '
Trail=224

BitCnt=9

DirUp=1
DirLeft=2
DirDown=3
DirRight=4


; ******* Global variables **********************************
	jmp	Main

.lvl		!byte	1
.bytecnt	!byte	0
.bitcnt		!byte	0
.linecnt	!byte	0
.colcnt		!byte	0
.mazesx		!byte	00
.mazesy		!byte	00
.fields		!byte	0
.currbyte	!byte	$FF
.mazeheight	!byte	00
.mazewidth	!byte	00
.cursorx	!byte 	0
.cursory	!byte	0
.rndnum		!byte	$2B
.trailcol	!byte	0

.title		!pet	"cx16-maze",0
.helptxt	!pet	"csrkeys=move spc=next r=reset q=quit",0
.lvlstr		!pet	"lvl:",0
.lvltxt		!pet	"000",0
.CX16		!pet 	"commander  ",18," ",146," ",18," ",146,"  16",0
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

.starttxt	!pet	"press return/enter",0

Main:
	jsr	SplashScreen
	jsr	InitSCR
	jsr	DrawMaze
	jsr	GameLoop

	rts

SplashScreen:
	lda	NUMCOLS	; $02AE contains the number of columns being shown
	cmp	#80	; if this is 80, we will switch to 40x30
	beq	.SetIt	; Set 40 column mode
	jmp	.NoSet
.SetIt:
	lda	#$00	; 40x30 text
	sec		; Ensure carry is set otherwise SCRMOD does not work
	jsr	SCRMOD	; Switch screenmode
.NoSet:
	lda	#$00
	sta	COLPORT
	lda	#147
	jsr	CHROUT

	; COMMANDER X16
	ldx	#5
	ldy	#10
	jsr	GotoXY
	lda	#$05
	sta	COLPORT
	ldx	#<.CX16
	ldy	#>.CX16
	jsr	PrintStr

	lda	#$04
	sta	COLPORT
	ldx	#2
	ldy	#17
	jsr	GotoXY
	ldx	#<.xl1
	ldy	#>.xl1
	jsr	PrintStr

	lda	#$0E
	sta	COLPORT
	ldx	#3
	ldy	#18
	jsr	GotoXY
	ldx	#<.xl2
	ldy	#>.xl2
	jsr	PrintStr

	lda	#$03
	sta	COLPORT
	ldx	#4
	ldy	#19
	jsr	GotoXY
	ldx	#<.xl3
	ldy	#>.xl3
	jsr	PrintStr

	lda	#$07
	sta	COLPORT
	ldx	#6
	ldy	#19
	jsr	GotoXY
	ldx	#<.xl5
	ldy	#>.xl5
	jsr	PrintStr

	lda	#$08
	sta	COLPORT
	ldx	#7
	ldy	#18
	jsr	GotoXY
	ldx	#<.xl6
	ldy	#>.xl6
	jsr	PrintStr

	lda	#$02
	sta	COLPORT
	ldx	#8
	ldy	#17
	jsr	GotoXY
	ldx	#<.xl7
	ldy	#>.xl7
	jsr	PrintStr

	; MAZE
	lda	#$05
	sta	COLPORT
	ldx	#20
	ldy	#7
	jsr	GotoXY
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
	lda	#$01
	sta	COLPORT
	ldx	#14
	ldy	#11
	jsr	GotoXY
	ldx	#<.starttxt
	ldy	#>.starttxt
	jsr	PrintStr

.wloop
	jsr	Random		; Call the random generator
	jsr	GETIN		; While waiting for user to press enter
	cmp	#13
	bne	.wloop
	rts

; This Pseudo Random Number Generator (PRNG) was found at
; https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
Random:
	lda	.rndnum
	beq	doeor
	asl
	beq	noeor
	bcc	noeor
doeor:	eor	#$1D
noeor:
	sta	.rndnum
	rts

; ***************************************************************
; Sets a random color for the trail of the maze
; ***************************************************************
; INPUTS:	none
; OUTPUTS:	none
; VARIABLES:	.rndnum & .trailcol
; CONSTANTS:	none
; REGISTERS:	A
; ***************************************************************
SetTrailCol:
	jsr	Random
	lda	#$F0		; Only the high nibble is
	and	.rndnum		; randomized as low nibble is 0
	beq	SetTrailCol	; If result is 0, try again
	cmp	#$B0		; if result is $B0, try again
	beq	SetTrailCol
	sta	.trailcol	; Store the new color
	rts

; **************************************************************
; Opens a logical file to Screen device and sets it as input
; **************************************************************
; INPUTS:	none
; OUTPUTS:	none
; VARIABLES:	none
; CONSTANTS:	SETLFS, OPEN and CHKIN - API calls
; REGISTERS:	A, X, Y
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
; Waits for a given number of jiffies, there are 60 jiffies
; in a second
; **************************************************************
; INPUTS:	TMP5 should contain the amount of jiffies to wait
; OUTPUTS:	none
; VARIABLES:	NONE
; CONSTANTS:	SETTIME & RDTIM
; REGISTERS:	NONE
DoDelay:
	lda	#0
	tax
	tay
	jsr	SETTIM		; SETTIM - Set real time clock

-	jsr	RDTIM		; RDTIM	- Read time
	cmp	TMP5		; 60 jiffies in 1 second
	bne	-
	rts

; **************************************************************
; Moves the cursor in the direction chosen by the user if it
; is possible. Returns to caller when the cursor can not move
; **************************************************************
; INPUTS:	TMP2 ZP location contains the direction
; OUTPUTS:	none
; VARIABLES:	Uses .cursorx and .cursory
; CONSTANTS:	TMP2 is used to hold direction flag
;		DirStop, DirUp, DirLeft, DirDown, DirRight
;		Trail
; **************************************************************
MoveCursor:
	.direction=TMP2
	.newX=TMP3
	.newY=TMP4

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
	bne	+
	jmp	.moveEnd

+	cmp	#Space
	bne	+
	dec	.fields
+
	jsr	CLALL		; Reset back to default input

	ldx	.cursory
	ldy	.cursorx
	jsr	GotoXY
	lda	#Trail
	jsr	CHROUT

	ldx	.newY
	ldy	.newX
	stx	.cursory
	sty	.cursorx
	jsr	GotoXY
	lda	#Cursor
	jsr	CHROUT

	lda	#3
	sta	TMP5
	jsr	DoDelay

	lda	#0
	cmp	.fields
	bne	+		; If not 0, continue

	sta	.direction
	jmp	.moveEnd
+	jmp	MoveCursor
.moveEnd:
	jsr	CLALL		; Reset back to default input
	rts

; **************************************************************
; The main loop that takes care of reading keyboard input and
; ensuring that screen is updated
; **************************************************************
; INPUTS:	none
; OUTPUTS:	none
; VARIABLES:	Uses ZP memory to hold direction flag
; CONSTANTS:	TMP2 is used to hold direction flag
;		DirStop, DirUp, DirLeft, DirDown, DirRight
; **************************************************************
GameLoop:
	.direction=TMP2

	jsr	Random
	jsr	GETIN		; Read keyboard input

	cmp	#'Q'		; If Q is not pressed, check for
	bne	.isUP		; UP key
	jmp	.endgl		; Q pressed, jmp to end

.isUP:	cmp	#145 		; If UP is not pressed, check for
	bne	.isLEFT		; LEFT key
	lda	#DirUp		; Set direction to up
	sta	.direction
	jmp	.doDirection

.isLEFT:
	cmp	#157		; If LEFT is not pressed, check for
	bne	.isDOWN		; DOWN key
	lda	#DirLeft	; Set direction to left
	sta	.direction
	jmp	.doDirection

.isDOWN:
	cmp	#17		; If DOWN is not pressed, check for
	bne	.isRIGHT	; RIGHT key
	lda	#DirDown	; Set direction to down
	sta	.direction
	jmp	.doDirection

.isRIGHT:
	cmp	#29		; If RIGHT is not pressed, check for
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
	lda	#$12
	sta	COLPORT
	ldx	#1	; Set up for level text (top right corner)
	ldy	#35
	jsr	GotoXY
	jsr	LVLtoPET ; Create level as a petscii string
	ldx	#<.lvltxt
	ldy	#>.lvltxt
	jsr	PrintStr

	jsr	DrawMaze
	jmp	GameLoop	; Loop back to top
.endgl:
	rts

LevelComplete:

	lda	#10
	sta	TMP5
	inc	.lvl
	lda	#11
	cmp	.lvl
	bne	.blinkborder
	lda	#1
	sta	.lvl
.blinkborder:
	jsr	Random
	lda	#$F0
	and	.rndnum
	sta	COLPORT
	jsr	DrawOutBorder
	jsr	DoDelay
	jsr	GETIN
	cmp	#' '
	bne	.blinkborder
	rts

; *******************************************************************
; Initializes the screen
; *******************************************************************
; INPUTS:	Gloabl variables
;		InitSC	.lvl
;			.title
;			.helptxt
;			.lvlstr
;			.lvltxt
; *******************************************************************
InitSCR:
	lda	#$01	; Black background, white text
	sta	COLPORT	; Set Color

	lda	#147	; ClrHome
	jsr	CHROUT	; Clear Screen

	lda	#$10	; White background, black text
	sta	COLPORT	; Set color

	ldx	#1	; Setup to create top horizontal line
	ldy	#1
	jsr	GotoXY

	lda	#Space
	ldx	#38
	jsr	HLine	; Draw horizontal line

	ldx	#28	; Setup to create bottom horizontal line
	ldy	#1
	jsr	GotoXY

	lda	#Space
	ldx	#38
	jsr	HLine	; Draw horizontal line

	ldx	#2	; Setup to create left most vertical line
	ldy	#1
	jsr	GotoXY

	lda	#Space
	ldx	#26
	jsr	VLine	; Draw left most vertical line

	ldx	#2	; Setup to create right most vertical line
	ldy	#38
	jsr	GotoXY

	lda	#Space
	ldx	#26
	jsr	VLine	; Draw right most vertical line

	lda	#$12	; Set color, white background, red text
	sta	COLPORT

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
	ldx	#28
	jsr	GotoXY

	ldx	#<.helptxt
	ldy	#>.helptxt
	jsr	PrintStr

	jsr	FillGA
	rts

; *******************************************************************
; Write a zero-terminated petscii string to screen
; *******************************************************************
; INPUTS:	X = Low byte of string starting address
;		Y = High byte of string starting address
; *******************************************************************
PrintStr:
	stx	TMP0
	sty	TMP1
	ldy	#0
.doprint
	lda	(TMP0), Y
	beq	.printdone
	jsr	CHROUT
	iny
	jmp	.doprint
.printdone:
	rts

; *******************************************************************
; Fill the "gamearea" with "wall tiles"
; *******************************************************************
; INPUTS:	Global constant WallCol is used.
; *******************************************************************
FillGA:
	lda	#WallCol	; Set background and foreground color
	sta	COLPORT

	ldx	#1		; X register holds the Y coordinate

.StartOfFill:
	inx			; Increment Y coordinate to go to next line
	stx	TMP0		; Save the Y coordinate in ZP
	cpx	#28		; If we have reached Y-coordinate 28,
	beq	.EndOfFill	; We are done, so branch to end
	ldy	#2		; Y register holds the X coordinate
	jsr	GotoXY		; Place cursor at X, Y coordinates
	lda	#Wall		; Load A with 'wall' character
	ldx	#36		; Create a horizontal line that is
	jsr	HLine		; 36 characters wide
	ldx	TMP0		; Restore Y coordinate from ZP
	jmp	.StartOfFill
.EndOfFill
	rts

DrawOutBorder:
	sta	COLPORT
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
	ldx	#28
	lda	#' '
	jsr	VLine

	; Right vertical line
	ldx	#0
	ldy	#39
	jsr	GotoXY
	ldx	#29
	lda	#' '
	jsr	VLine

	; The number of lines is 30 because we are in 40x30 mode
	; By setting the number of lines to 31, we ensure that the
	; screen does not scroll when the cursor goes beyound the
	; last character on the bottom line
	lda	#31
	sta	NUMLINES

	; Bottom horizontal line
	ldx	#29
	ldy	#0
	jsr	GotoXY
	ldx	#40
	lda	#' '
	jsr	HLine

	; Reset the number of lines back to standard
	lda	#30
	sta	NUMLINES

	rts

; *******************************************************************
; Print a vertical line
; *******************************************************************
; INPUTS:	A = Character used to print the line
;		X = Height of the line
; *******************************************************************
VLine:
	jsr	CHROUT	; Write character
	tay		; Save character in Y register
	lda	#157	; Cursoer Left
	jsr	CHROUT
	lda	#17	; Cursor Down
	jsr	CHROUT
	tya		; Restore character to A register
	dex		; Decrement line height
	bne	VLine	; Jump to top if we have not reached 0
	rts

; *******************************************************************
; Print a horizontal line
; *******************************************************************
; INPUTS:	A = Character used to print the line
;		X = Length of the line
; *******************************************************************
HLine:
	jsr	CHROUT
	dex
	bne	HLine
	rts

; *******************************************************************
; Ensures that Carry flag is cleared and calls PLOT to set cursor pos
; *******************************************************************
; INPUTS:	X = Column (Y coordinate)
;		Y = Row    (X coordinate)
; *******************************************************************
GotoXY:
	clc
	jsr	PLOT
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

	ldy	#'0'
	sty	.lvltxt
	sty	.lvltxt+1
	sty	.lvltxt+2

	lda	.lvl	; Load Reg A with current level

	; Check if .lvl is >= 200
	cmp	#200
	bcc	.is100	; branch to .is100 if .lvl <200
	ldy	#'2'	; Write '2' to first digit of .lvltxt
	sty	.lvltxt
	sbc	#200	; Subtract 200 from .lvl
	beq	.allDone; If result = 0, we are done
	jmp	.Tens
	; Check if .lvl is >= 100
.is100:
	cmp	#100
	bcc	.Tens	; branch to .Tens if .lvl < 100
	ldy	#'1'	; Write '1' to first digit of .lvltxt
	sty	.lvltxt
	sbc	#100	; Subtract 100 from .lvl
	beq	.allDone; If result = 0, we are done
	; Check if .lvl contains any tens (10-90)
.Tens:
	ldy	#9
	sty	.digit	; Store digit in zero-page memory
	ldy	#90
	sty	.num	; Store digit*10 in zero-page memory
.DoTens
	cmp	.num
	bcc	.Any10	; branch to .Any10 if .lvl < .num

	sta	.value	; Save current value as we need the accumulator
	lda	.digit
	ora	#$30	; OR $30 with digit to get petscii char
	sta	.lvltxt+1;Write digit to 2nd space of .lvltxt

	lda	.value	; Restore value into A register
	sec		; Set carry flag to ensure correct subtraction
	sbc	.num	; Subtract .num from current .value
	jmp	.Ones

.Any10	cmp	#10
	bcc	.Ones	; branch to .Ones if A < 10
	; subtract 10 from .value
	sta	.value	; Save current value
	lda	.num	; Subtract 10 from .number
	sec
	sbc	#10
	sta	.num
	lda	.value	; Restore A from TMP1
	dec	.digit
	jmp	.DoTens
.Ones:
	ora	#$30	; OR $30 with digit to get petscii char
	sta	.lvltxt+2;Write digit to 3rd space of .lvltxt
.allDone:
	rts

; *******************************************************************
; Draw the maze in the gamearea and place the "cursor"
; *******************************************************************
; INPUTS:	.lvl and .mazes will be used to see which maze to draw
; *******************************************************************
DrawMaze:
	jsr	SetTrailCol	; Set a random color for the trail

	lda	#<.mazes	; load A with LSB
	sta	TMP0		; Store in TMP0 ($00)
	lda	#>.mazes	; load A with MSB
	sta	TMP0+1		; Store in TMP0+1 = TMP1 ($01)
	; TMP0 can now be used as a pointer to .mazes
	ldx	.lvl		; Load current level
	; First byte in a maze is the total size of the maze. It is used
	; to calculate where en memory the next maze is found
.findMaze
	dex			; Level1 is the first level, but mazes are
				; indexed from 0 so decrement the level
	beq	.loadMaze	; If we have reached 0, we have reached the
				; right maze
	ldy	#0		; Y is used as index in indirect adressing
	lda	(TMP0),Y	; Load size of current maze
	clc			; Clear carry to ensure correct addition
	adc	TMP0		; Add current maze size to LSB of maze address
	sta	TMP0		; Store the new LSB
	lda	TMP1		; Load A with MSB of maze address
	adc	#0		; Add 0 (carry from previous addition will
				; ensure correct result)
	sta	TMP1		; Store the new MSB
	jmp	.findMaze
.loadMaze
	ldy	#1
	lda	(TMP0),Y
	sta	TMP2		; Maze width
	sta	.mazewidth
	iny
	lda	(TMP0),Y
	sta	TMP3		; Maze height
	sta	.mazeheight
	clc
	lsr	TMP2		; Maze width / 2
	clc
	lsr	TMP3		; Maze height / 2
	lda	#18
	sec
	sbc	TMP2
	tay			; Starting X coordinate
	sty	.mazesx
	lda	#13
	sec
	sbc	TMP3
	tax			; Starting Y coordinate
	stx	.mazesy

	lda	#$00		; Set color, black background, black text
	sta	COLPORT

	; Draw the maze (this is a big mess)
	ldy	#0		;Number of fields that needs to be colored.
	sty	TMP2

	ldy	#5		;offset of maze data
	sty	.bytecnt
	; for .linecnt = .mazeheight downto 0
	lda	.mazeheight
	sta	.linecnt
.YCnt:
	ldy	.bytecnt	; Load byte from maze data
	lda	(TMP0),Y
	sta	.currbyte	; store it in .currbyte variable

	; gotoxy .mazesx, .mazesy+(.mazeheight-.linecnt)
	lda	.mazeheight
	sec
	sbc	.linecnt
	clc
	adc	.mazesy
	tax
	ldy	.mazesx
	jsr	GotoXY

	; .bitcnt = 9
	lda	#BitCnt
	sta	.bitcnt

	; for .colcnt = .mazewidth downto 0
	lda	.mazewidth
	sta	.colcnt
.XCnt:
	dec	.bitcnt
	; if .bitcnt = 0, go to next byte from maze
	bne	.ByteStillGood
	inc	.bytecnt
	ldy	.bytecnt
	lda	(TMP0),Y
	sta	.currbyte
	ldy	#BitCnt
	sty	.bitcnt
.ByteStillGood:

	asl	.currbyte
	bcs	.DrawWall
	lda	#Space
	inc	TMP2		; Another field needs to be colored to finish maze
	jmp	+
.DrawWall:
	lda	#29		; Curser right (write nothing)
+	jsr	CHROUT

	; endof for .colcnt = .mazewidth downto 0
	dec	.colcnt
	beq	.EndXCnt
	jmp	.XCnt
.EndXCnt:
	inc	.bytecnt
	lda	#BitCnt
	sta	.bitcnt
	; endof for .linecnt = .mazeheight downto 0
	dec	.linecnt
	beq	.EndIt
	jmp	.YCnt
.EndIt:
	lda	TMP2
	sta	.fields		; decrement .fields as
	dec	.fields		; 1 field is filled by the cursor.

	; Calculate cursor placement
	ldy	#3		; Get cursor X coordinate from
	lda	(TMP0),Y	; maze data
	clc
	adc	.mazesx		; Add it to maze start X coordinate
	sta	TMP2		; Save it in ZP while Y is calculated

	ldy	#4		; Get cursor Y coordinate from
	lda	(TMP0),Y	; maze data
	clc
	adc	.mazesy		; Add it to maze start Y coordinate
	tax			; Y coordinate in X register
	ldy	TMP2		; X coordinate in Y register
	stx	.cursory
	sty	.cursorx
	jsr	GotoXY

	; Set the cursor color and print the cursor
	lda	.trailcol
	sta	COLPORT

	lda	#Cursor		; Print the cursor in the right place
	jsr	CHROUT

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

	; Level 3
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

	; Level 4
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

	; Level 5
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

	; Level 6
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

	; Level 7
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

	; Level 8
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

	; Level 9
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

	; Level 10
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
}
