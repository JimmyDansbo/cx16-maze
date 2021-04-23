; When you create a maze, it is easiest to ignore the byte size at first.
; You can even ignore the !byte label and the %-signs and just create the maze.
; Something like this:
; ..........
; .........
;  ........
;  .......
;   ......
;   .....
;    ....
;    ...
;     ..
;     .
; Then you add the preceding %- and #-characters
; %..........
; %.........
; %#........
; %#.......
; %##......
; %##.....
; %###....
; %###...
; %####..
; %####.
; Now we need to start counting becase the number of dots and # must always be
; divisable by 8 so 8, 16, 24, and so on.
; In our maze, the longest line is 10 dots so we need to add 6 #-characters
; The rest of the lines need to be as long.
; %..........######
; %.........#######
; %#........#######
; %#.......########
; %##......########
; %##.....#########
; %###....#########
; %###...##########
; %####..##########
; %####.###########
; Next we group the characters into 8ths by placing a comma and %-character.
; %........,%..######
; %........,%.#######
; %#.......,%.#######
; %#.......,%########
; %##......,%########
; %##.....#,%########
; %###....#,%########
; %###...##,%########
; %####..##,%########
; %####.###,%########
; Then we add the !byte keyword in front of every line.
; !byte	%........,%..######
; !byte	%........,%.#######
; !byte	%#.......,%.#######
; !byte	%#.......,%########
; !byte	%##......,%########
; !byte	%##.....#,%########
; !byte	%###....#,%########
; !byte	%###...##,%########
; !byte	%####..##,%########
; !byte	%####.###,%########
; Finally we can prepend the maze data with information about the size of the
; maze as well as where in the maze, the player starts.

; The first field is the actual size of the maze in bytes. We calculate it by
; counting the number of lines and multiplying with the number of sections.
; In above example, we have 10 lines each with 2 sections = 20 and then we
; add the header information which is always 5 so the final size of the maze
; comes to 25 bytes.

; The next two fields are the width and height of the maze. Height is easy as
; it is just the number of lines, in this case 10.
; Width is the maximum width of the maze so you need to find the dot or dots
; that are the furthest away from the beginning of a line and count how many
; characters it is away. In our case, the first line is also the widest and
; it is a total of 10 dots, so our width is 10.

; The last two fields in the header are the 0-based X and Y coordinates that
; the player should start at. You decide these coordinates your self, just
; ensure that you start the player inside the maze.
; In this case, we would like the player to start all the way to the left on
; the second line so the X coordinate is 0 = most left
; The Y coordinate is 1, as the first line would be 0.
; So the final maze will look like this:

; !byte	25,10,10
; !byte	00,01
; !byte	%........,%..######
; !byte	%........,%.#######
; !byte	%#.......,%.#######
; !byte	%#.......,%########
; !byte	%##......,%########
; !byte	%##.....#,%########
; !byte	%###....#,%########
; !byte	%###...##,%########
; !byte	%####..##,%########
; !byte	%####.###,%########

; If you have any trouble creating mazes, have a look at some of the mazes
; below to see how they are done or you can contact the author of this program
; on the Commander X16 forum or mail: jimmy at dansbo.dk
*=$A000
; Level 1
!byte	25,10,10		;size,width,height
!byte	00,01			;start coordinates (zero based)
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
!byte	15,8,10			;size,width,height
!byte	0,9			;start coordinates (zero based)
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
!byte	14,7,9			;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	12,7,7			;size,width,height
!byte	0,6			;start coordinates (zero based)
!byte	%......##
!byte	%.####..#
!byte	%.#.....#
!byte	%.#.##..#
!byte	%.#.....#
!byte	%.#####.#
!byte	%.......#

; Level 5
!byte	12,7,7			;size,width,height
!byte	0,6			;start coordinates (zero based)
!byte	%.......#
!byte	%.#####.#
!byte	%.#####.#
!byte	%.......#
!byte	%.#.#.#.#
!byte	%.#.#.#.#
!byte	%...#...#

; Level 6
!byte	25,10,10		;size,width,height
!byte	0,9			;start coordinates (zero based)
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
!byte	15,7,10			;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	23,10,9			;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	27,11,11		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	27,11,11		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	41,13,18		;size,width,height
!byte	0,14			;start coordinates (zero based)
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
!byte	25,10,10		;size,width,height
!byte	0,9			;start coordinates (zero based)
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
!byte	31,9,13			;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	25,10,10		;size,width,height
!byte	1,8			;start coordinates (zero based)
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
!byte	27,11,11		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,0			;start coordinates (zero based)
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
!byte	29,12,12		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	29,13,12		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	44,18,13		;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	31,14,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	33,13,14		;size,width,height
!byte	0,13			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	44,18,13		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	21,10,8			;size,width,height
!byte	0,6			;start coordinates (zero based)
!byte	%#..####.,%..######
!byte	%...###..,%..######
!byte	%....##.#,%..######
!byte	%........,%..######
!byte	%.#......,%..######
!byte	%.##.....,%..######
!byte	%........,%.#######
!byte	%#.......,%..######

; Level 32
!byte	41,13,18		;size,width,height
!byte	0,13			;start coordinates (zero based)
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
!byte	33,15,14		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	29,13,12		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	59,18,18		;size,width,height
!byte	0,15			;start coordinates (zero based)
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
!byte	59,18,18		;size,width,height
!byte	0,17			;start coordinates (zero based)
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
!byte	37,16,16		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	37,16,16		;size,width,height
!byte	0,15			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,12			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,13			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,13			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	33,14,14		;size,width,height
!byte	0,13			;start coordinates (zero based)
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
!byte	41,13,18		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,9			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	37,16,16		;size,width,height
!byte	0,14			;start coordinates (zero based)
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
!byte	44,18,13		;size,width,height
!byte	0,7			;start coordinates (zero based)
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
!byte	35,13,15		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	31,13,13		;size,width,height
!byte	0,8			;start coordinates (zero based)
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
!byte	35,14,15		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	41,13,18		;size,width,height
!byte	0,17			;start coordinates (zero based)
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
!byte	44,18,13		;size,width,height
!byte	0,11			;start coordinates (zero based)
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
!byte	35,14,15		;size,width,height
!byte	0,10			;start coordinates (zero based)
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
!byte	21,14,8
!byte	0,0
!byte	%....####,%##....##
!byte	%#....###,%#....###
!byte	%##....##,%....####
!byte	%###.....,%..######
!byte	%####....,%...#####
!byte	%##....##,%....####
!byte	%#....###,%#....###
!byte	%....####,%##....##

; No more level
!byte	0				;When size 0, there are no more mazes.
