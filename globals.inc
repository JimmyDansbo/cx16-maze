
Width		!byte 0
Height		!byte 0
Maze_x		!byte 0
Maze_y		!byte 0
Size		!byte 0
Start_x		!byte 0
Start_y		!byte 0

Trail_color	!byte 0

MAZE_PTR = TMP_PTR7

; Use the ASCII to VERA conversion table
!ct "asc2vera.ct" {
	; Large colored X
Xl0	!byte	$5F,$A0,$A0,$DF,$20,$20,$20,$E9,$A0,$A0,$69,0
Xl1	!byte	$20,$5F,$A0,$A0,$DF,$20,$E9,$A0,$A0,$69,$20,0
Xl2	!byte	$20,$20,$5F,$A0,$A0,$20,$A0,$A0,$69,$20,$20,0
Xl3	!byte	$20,$20,$E9,$A0,$A0,$20,$A0,$A0,$DF,$20,$20,0
Xl4	!byte	$20,$E9,$A0,$A0,$69,$20,$5F,$A0,$A0,$DF,$20,0
Xl5	!byte	$E9,$A0,$A0,$69,$20,$20,$20,$5F,$A0,$A0,$DF,0
V2	!text	"V2",0
Cx16	!text	"COMMANDER  "
	!byte	$A0,$20,$A0	; These are the middle if the large colored X
	!text	"  16",0
Jimmy	!text	"BY JIMMY DANSBO",0
Start	!text	"PRESS ENTER/RETURN",0
Caption	!text	"X16 MAZE",0
Level	!text	"LEVEL: 000",0
Time	!text	"00:00.00",0
Help0	!text	"CURSOR KEYS = MOVE, Q = QUIT",0
Help1	!text	"SPACE = GO TO NEXT LEVEL, R = RESTART",0
	; MAZE written in large letters
Maze	!byte	$66,$20,$20,$20,$66,$20,$20,$20,$20,$66,$20,$20,$20,$20,$66,$66,$66,$66,$66,$20,$20,$66,$66,$66,$66,$66,0
	!byte	$66,$66,$20,$66,$66,$20,$20,$20,$66,$20,$66,$20,$20,$20,$20,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$20,0
	!byte	$66,$20,$66,$20,$66,$20,$20,$66,$66,$66,$66,$66,$20,$20,$20,$20,$66,$20,$20,$20,$20,$66,$66,$66,$20,$20,0
	!byte	$66,$20,$20,$20,$66,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$66,$20,$20,$20,$20,$20,$66,$20,$20,$20,$20,0
	!byte	$66,$20,$20,$20,$66,$20,$20,$66,$20,$20,$20,$66,$20,$20,$66,$66,$66,$66,$66,$20,$20,$66,$66,$66,$66,$66,0
}
; Use normal CBM text conversion
Err_Ld	!text	"ERROR LOADING FILE: ",0
Mazes	!text	"MAZES.BIN"
Mazes_end	!byte	0
