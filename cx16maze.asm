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

; ******** Kernal APIs - C64 API can be found here: *******
; http://sta.c64.org/cbm64krnfunc.html
CHROUT=$FFD2		; CHROUT outputs a character (C64 Kernal API)
CHRIN=$FFCF		; CHRIN read from default input
GETIN=$FFE4		; GETIN reads a single byte from default input
			; returns #0 if no key is pressed = non-blocking
PLOT=$FFF0		; PLOT gets or sets cursor position
; ******** Kernal APIs from C128 ***************************
SWAPPER=$FF5F

; ******** Commander X16 specific **************************
COLPORT=$0286		; This address contains both background (high nibble)
			; and foreground (low nibble) color. Writing to it
			; changes the colors. On C64 only foreground color
			; can be changed in low nibble

TMP0=$00		; The first 3 unused zero page locations are used
TMP1=$01		; as temporary storage (registers)
TMP2=$02

TMP3=$FB		; The last 4 unused zero page locations are also
TMP4=$FC		; used as temporary storage (registers)
TMP5=$FD
TMP6=$FE

; ******* Constants used in the source **********************
Cursor=119
Wall=113
WallCol=$0B
Space=' '
BitCnt=9

; ******* Global variables **********************************
	jmp	Main

.lvl		!byte	3
.bytecnt	!byte	0
.bitcnt		!byte	0
.linecnt	!byte	0
.colcnt		!byte	0
.mazesx		!byte	00
.mazesy		!byte	00
.currbyte	!byte	$ff
.mazeheight	!byte	00
.mazewidth	!byte	00

.title		!pet	"cx16-maze",0
.helptxt	!pet	"w,a,s,d=move spc=next r=reset q=quit",0
.lvlstr		!pet	"lvl:",0
.lvltxt		!pet	"000",0


Main:
	jsr	InitSCR
	jsr	DrawMaze

	ldx	#29
	ldy	#40
	jsr	GotoXY

	jsr	CHRIN

	rts

; *******************************************************************
; Initializes the screen
; *******************************************************************
; INPUTS:	Gloabl variables
;			.lvl
;			.title
;			.helptxt
;			.lvlstr
;			.lvltxt
; *******************************************************************
InitSCR:
	lda	$D9	; $D9 contains the number of columns being shown
	cmp	#80	; if this is 80, we will switch to 40x30
	beq	.SetIt	; Set 40 column mode
	jmp	.NoSet
.SetIt:
	jsr	SWAPPER	; Switch screenmode
.NoSet:
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

;	ldx	#1
;	ldy	#35
;	jsr	GotoXY

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

; *******************************************************************
; Print a vertical line
; *******************************************************************
; INPUTS:	A = Character used to print the line
;		X = Height of the line
; *******************************************************************
VLine:
	stx	TMP0	; Store line height in TMP0 variable
	sec		; Set carry flag to get cursor position
	jsr	PLOT	; Get cursor postition into Y and X
	stx	TMP1	; Store Y position in TMP1 variable

.loopVL	jsr	CHROUT	; Write character
	inc	TMP1	; Increment Y position
	sta	TMP2	; Save A register as it is changed by GotoXY
	ldx	TMP1	; Load Y position into X register
	jsr	GotoXY	; Move cursor
	lda	TMP2	; Restore A register (character)
	dec	TMP0	; Decrement line height
	bne	.loopVL	; Jump to top if we have not reached 0
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
	clc		; Clear carry to ensure correct add
	adc	#$30	; Add $30 to digit to get petscii char
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
	clc		; Clear carry to ensure correct add
	adc	#$30	; Add $30 to get petscii char
	sta	.lvltxt+2;Write digit to 3rd space of .lvltxt
.allDone:
	rts

; *******************************************************************
; Draw the maze in the gamearea and place the "cursor"
; *******************************************************************
; INPUTS:	.lvl and .mazes will be used to see which maze to draw
; *******************************************************************
DrawMaze:
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

	lda	#WallCol	; Set color, black background, darkgray text
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
	inc	TMP2

	jmp	+
.DrawWall:
	lda	#Wall
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
	jsr	GotoXY

	; Set the cursor color and print the cursor
	lda	#$40		; Purple/Black
	sta	COLPORT

	lda	#Cursor		; Print the cursor in the right place
	jsr	CHROUT

	rts

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
