# Build-n-Wreck


a gamed based on stack tower.

in this game there are 2 phases: the building phase, and the wrecking phase.
- at the buiding phase you must stack as many bricks on top of eachother, the result of this phase is a tower like structure.
- at phase 2, a white vertical line would appear at the right, moving left with each and every frame.
  the wercking part isn't like a wrecking ball, rather a knife, and that vertial line represents that.

-score is awarded only at the cutting part, though in order to cut down a building in a "good" way, u must build a good and stable structure.

- there is only one button u must know, at the time that the titlescreen is active (the bmp), pressing esc would quit the game, during the game, you may press any button.

# code explanation

The code is separated to multiple files, i'l start by showing the files "sBuffer.inc", "bgBuffer.inc", all they do is initialize a buffer of 64000bytes 

"bgBuffer.inc":

	FARDATA _bg
	@@background_buffer db 64000 dup(0)
  
"sBuffer.inc":
	FARDATA _buffer
	@@screen_buffer db 64000 dup(0)


not much going on with those 2, the next file is called "Bmp.inc"

*that file was copied from assembly heights.

- "Bmp_OpenFile":
this procedure takes a filename, and opens that file for later use.

code: 

proc Bmp_OpenFile
	mov ah, 3Dh
	xor al, al
	mov dx, offset bmp_name
	int 21h
	jc openerror
	mov [bmp_handle], ax
	ret
	openerror :
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
endp Bmp_OpenFile


  - "ReadHeader":
  this procedure reads the header from the opened file, getting crusial data about the bmp fetch.
 code:
 
 proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [bmp_handle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

- "ReadPalette":
this procedure reads the color pallte and allowes the usag of that read palette
code:

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette

- "CopyPal":
this procedure  sets the current palette one to the read one.
code:

proc CopyPal
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	out dx,al
	inc dx
	PalLoop:
	mov al,[si+2] ; Get red value .
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx,al
	mov al,[si+1] ; Get green value .
	shr al,2
	out dx,al
	mov al,[si] ; Get blue value .
	shr al,2
	out dx,al
	add si,4 ; Point to next color .
	loop PalLoop
	ret
endp CopyPal


- "CopyBitmap":
this  procedure reads the bmp file, computes te color of the current pixel based on the palette, then coping it into on of my buffers.
code:


proc CopyBitmap
	; BMP graphics are saved upside-down .
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
	PrintBMPLoop :
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx

	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
	
	cld 
	mov cx,320
	mov si,offset ScrLine

	rep movsb 
	 ;rep movsb is same as the following code :
	 ;mov es:di, ds:si
	 ;inc si
	 ;inc di
	 ;dec cx
	 ;loop until cx=0
	
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap 

next file is "utils.inc", where most procedures and

-"write_pxl":
this procedure is al about writing a character to the screen while in text mode
code:

proc write_pxl
	mov bp, sp
	
	mov ax, [bp+4];// y
	mov dh, al
	mov ax, [bp+6];// x
	mov dl, al
	
	mov bh, 0
	mov al, 0
	mov ah, 2
	int 10h
	
	mov ax, [bp+8]
	mov bh, 0
	mov ah, 0ah
	mov cx, 1
	int 10h
	
	ret 6
endp write_pxl

- "&write_score":
its a macro that handles wrriting the score to the screen, asuuming that the screen is in text mode.
code:
macro &write_score
mov cx, 0
word_loop:
mov ax, cx
add ax, 5

push ax
push cx
	mov si, cx
	push [word ptr string+si]
	push ax	
	push 5
	call write_pxl
	
pop cx
pop ax

word_loop_eval:
inc cx
cmp cx, 26
jl word_loop


loop_score:
	mov ax, [score]
	mov bx, 10
	xor dx, dx
	div bx
	add dx, 48
	mov [score], ax
	;// write dx
	push dx
	push [asciix]
	push [asciiy]
	call write_pxl
	

loop_score_eval:
	dec [asciix]
	cmp [score], 0
	jg loop_score

endm &write_score


-"&brick":
this macro takes a position along the y axis, a position along the x axis, and a length,
creates a brick, and insert it into my screen buffer
code:
Macro &brick brick_y, brick_pos, brick_length

mov [break_line1], 2
mov [break_line2], 4
 
mov cx, 0
mov ax, brick_pos
mov [temp_pos], ax
mov ax, _buffer
	mov es, ax
loop1:
	mov ax, brick_y
	mov bx, 320
	mul bx
	mov bx, [temp_pos]
	add ax, bx
	mov si, ax
	
	
	;// first row
	mov al, 8
	mov [es:si], al
	add si, 320
	
	cmp cx, [break_line1]
	jne red
		add [break_line1], 4
		mov al, 8
	
	jmp color
	red:
		mov al, 13
	color:
	;// second row
	mov [es:si], al
	add si, 320
	;// third row
	mov [es:si], al
	add si, 320
	;// fourth row
		mov al, 8
		mov [es:si], al
	
	
	cmp cx, [break_line2]
	jne red2
		add [break_line2], 4
		mov al, 8
	
	jmp color2
	red2:
		mov al, 13
	color2:
	add si, 320
	;// fifth row
	mov [es:si], al
	add si, 320
	;// sixth row
	mov [es:si], al
	add si, 320
	;// seventh row
	mov al, 8
	mov [es:si], al
	
loop1_eval:
inc cx
inc [temp_pos]
cmp cx, brick_length
jle loop1

endm brick

- "clear_rect":
this procedure takes 2 points (top left, and bottom right) of a rectanlge, resetting all pixels that are in the rectangle from the screen buffer.
code: 

proc clear_rect basic far
; writes screen buffer to display
uses ax, si, di, cx, bx, dx, ds, es
arg @@x1:word, @@y1:word, @@x2:word, @@y2:word
; ------------------------

    mov bp, sp
    add bp, 16

    mov ax, [@@y1]
    mov bx, 320
	mul bx
    add ax, [@@x1]

    ; si = starting index
    mov si, ax
    
    mov ax, [@@x2]
    sub ax, [@@x1]

    ; dx = number of pixels in a row
    mov dx, ax

    mov ax, [@@y2]
    sub ax, [@@y1]

    ; bx = number of rows
    mov bx, ax

    ; es = buffer segment
    mov ax, _buffer
    mov es, ax
    
    mov al, 0
    mov ah, 0
    shl eax, 16
    mov al, 0
    mov ah, 0


    ; clear direction flag
    cld

@@next_row:
    mov di, si
    mov cx, dx

    rep movsb

    add si, ax

    dec bx
    jnz @@next_row

    ret
endp clear_rect

- "update_display":
this procedure takes 2 points (top left, and bottom right) of a rectanlge, coping all the pixel inside from the screen buffer to the display memory.
code:

proc update_display basic far
; writes screen buffer to display

uses ax, si, di, cx, bx, dx, ds, es
arg @@x1:word, @@y1:word, @@x2:word, @@y2:word

; ------------------------

    mov bp, sp
    add bp, 16

    mov ax, [@@y1]
	mov bx, 320 
    mul bx
    add ax, [@@x1]

    ; si = starting index
    mov si, ax
    
    mov ax, [@@x2]
    sub ax, [@@x1]

    ; dx = number of pixels in a row
    mov dx, ax

    mov ax, [@@y2]
    sub ax, [@@y1]

    ; bx = number of rows
    mov bx, ax

    ; ds = buffer segment
    mov ax, _buffer
    mov ds, ax
    
    ; es = display address
    mov ax, 0A000h
    mov es, ax

    ; ax = distance to new line
    mov ax, 320
    sub ax, [@@x2]
    add ax, [@@x1]

    ; clear direction flag
    cld

@@next_row:
    mov di, si
    mov cx, dx

    rep movsb

    add si, ax

    dec bx
    jnz @@next_row

    ret
endp update_display


- "&update_bg"
this macro copies the contant of the screen memory to the background buffer.
code:

Macro &update_bg
	 push ds
    ; ds = buffer segment
    mov ax, 0A000h
    mov ds, ax

    ; es = display address
    mov ax, _bg
    mov es, ax

    ; cx = addresses to copy
    mov cx, 16000
    
    ; set si and di to 0
    xor si, si
    xor di, di
    
    ; clear direction flag
    cld

    ; copy dwords from buffer to display
    rep movsd
pop ds
endm &update_bg


- "&render_bg":
this macro copies the contant of the background buffer to the screen memory.
code:

Macro &render_bg
	 push ds
    ; ds = buffer segment
    mov ax, _bg
    mov ds, ax

    ; es = display address
    mov ax, 0A000h
    mov es, ax

    ; cx = addresses to copy
    mov cx, 16000
    
    ; set si and di to 0
    xor si, si
    xor di, di
    
    ; clear direction flag
    cld

    ; copy dwords from buffer to display
    rep movsd
pop ds
endm &render_bg

- "&renderbf":
this macro copies the contant of the screen buffer to the screen memory.
code:Macro &render_bf
	 push ds
    ; ds = buffer segment
    mov ax, _buffer
    mov ds, ax

    ; es = display address
    mov ax, 0A000h
    mov es, ax

    ; cx = addresses to copy
    mov cx, 16000
    
    ; set si and di to 0
    xor si, si
    xor di, di
    
    ; clear direction flag
    cld

    ; copy dwords from buffer to display
    rep movsd
pop ds
endm &render_bf

- "&reset":
this macro resets all the data of the game
code: 

Macro &reset
mov [temp_pos], 0
mov [break_line1] , 2
mov [break_line2] , 4

mov [position] , 1
mov [llength] , 30
mov [pos_end] , 31 
mov [dir] , 1
mov [height] , 190

mov [first_time], 1

mov [x0] , 0
mov [y0] , 190
mov [x1], 320
mov [y1], 198

mov [pixel_address] , 0

mov [frame_counter] , 0
mov [speed_by_frame] , 35

mov [prev_position] , 0
mov [prev_pos_end] , 0

mov [render] , 1
mov [fail] , 0
mov [red_counter] , 0
mov [cut] , 0
mov [score] , 0
mov [is_red], 0
mov [is_start], 0

endm &reset


last file, its called "BNW.asm" (short for buildNwreck).
since that file doesnt contain any procedures , nor macros, (rather it contains the main algorithym), im going to put a diagram that'll show the behavior 
of the algorithym, then i'll put the code.

the diagram would be a list of steps:

1. display titlescreen
2. check for keypress, if the key id "ESC" exit the program, if there was no key, repeat step 2
3. is render true (meaning need to prep for phase 2), yes goto step 4, no goto step 5
4. set the current brick to the top right pixel, set fail true (continue 5)
5. is fail true yes goto 6, no goto 14
6. set render to false, dec the position of the brick, if the position is 0, goto 25
7. loop for each pixel directly below the brick position, check if its a brick yes goto 8, no goto 10
8. is cut true yes goto 9, no goto 10
9. color this pixel black (permenatly), and increment score
10. color this pixel white
11. check for button press if there was no key, goto step 12
12. set cut true
13. set cut false, goto 24
14.	clear screen
15.	is dir greater than 0 yes goto 16, no goto 17
16. brick position++ coninue 18
17. brick position --
18. is brick position at the edges of the screen yes goto 19, no togo 20
19. dir *= -1
20. check for keypress, if there was no key, goto step 14
21.	is it the first keypress yes goto 23, no goto 22
22. calculate loss, recalculate brick's length
23. render brick
24. goto step 3
25. quit

code :

.386
IDEAL
MODEL large
STACK 100h
CODESEG

include "utills.inc"
include "sBuffer.inc"
include "bgBuffer.inc"
include "Bmp.inc"

DATASEG
asciix dw 35
asciiy dw 5
string db "Time's up!, your score is:", 0	;// 26

temp_pos dw 0
break_line1 dw 2
break_line2 dw 4

position dw 1
llength dw 30
pos_end dw 31 
dir dw 1
height dw 190

first_time db 1

x0 dw 0
y0 dw 190
x1 dw 320
y1 dw 198

pixel_address dw 0

frame_counter dw 0
speed_by_frame dw 35

prev_position dw 0
prev_pos_end dw 0

render dw 1
fail dw 0
red_counter dw 0
cut dw 0
score dw 0
is_red dw 0
is_start dw 0
CODESEG
;// inc dist_to_wall doesnt work



start:
	mov ax, @data
	mov ds, ax	
	
	mov ax, 13h
	int 10h
start_game:


;// process bmp file
call Bmp_OpenFile
call ReadHeader
call ReadPalette
call CopyPal
call CopyBitmap

;// this loop holds the title screen till any button is pressed
	mov ah, 00h
	int 16h
		
	cmp al, 27
	je exit2	
&render_bf	;// resetting the background
	
main_loop:	
	cmp [render], 0	;// render is a variable regarding setting up the second phase
	jne fail_check
	
	mov [llength], 1
	mov [position], 318
	mov [pos_end], 319
	mov [y0], 0
	mov [y1], 1
	mov [fail], 1
	&update_bg
	
	fail_check:
	cmp [fail], 1
	jne main_loop_continue
	;// failed, the second phase starts
	
	mov [render], 1
	inc [frame_counter]	;// nerfing the speed of the line
	mov ax, [speed_by_frame]
	cmp [frame_counter], ax
	jl no_bg_render
	mov [frame_counter], 0
	
	
	cmp [position], 4
	jle after_all_loops

	sub [position], 4	;// dec the position of the line
	sub [pos_end], 4
	
	&render_bg
	no_bg_render:
	mov ax, [y0]
	mov bx, 320
	mul bx
	mov bx, [position]
	add ax, bx
	mov [pixel_address], ax
	mov cx, 199
	line_loop: ;// a loop going from the top pixel at the current column, to the bottom pixel
		cmp [cut], 1
		jne no_cut	;// the second part of the cutting
			mov ax, 0A000h
			mov es, ax
			inc si
			mov al, 0
			sub si, 320
			mov [es:si], al
			sub si, 320
			mov [es:si], al
			
			add si, 960
			mov [es:si], al
			add si, 320
			mov [es:si], al
		
	
	no_cut:
	mov ax, 0A000h
	mov es, ax
		;// checking the pixel that sits at the background
		mov ax, _bg
		mov es, ax
		mov al, [es:si]
		mov di, 0
		mov [es:di], al
		cmp al, 13
		jne not_red
		mov [is_red], 1
		
		not_red:
			cmp al, 8
			jne not_white
			mov [is_red], 1
			
		not_white:

		;// project the line
		mov ax, 0A000h
		mov es, ax
		mov si, [pixel_address]
		mov al, 7
		mov [es:si], al
		
		;// the first part of the cutting
		mov ax, _bg
		mov es, ax
		cmp [is_red], 1
		jne is_not_red
			mov [is_red], 0
			cmp [cut], 1
			jne is_not_red
			;// red pixel + cut == 1
			add [score], cx
			
			mov ax, _bg
			mov es, ax
			mov al, 0
			sub si, 320
			mov [es:si], al
			sub si, 320
			mov [es:si], al
			
			add si, 960
			mov [es:si], al
			add si, 320
			mov [es:si], al
			
			
		is_not_red:
		
	line_loop_eval:	;// loop that
		add [pixel_address], 320
		dec cx
		cmp cx, 0
		jge line_loop
		mov [cut], 0
	
	;// if any button if pressed, initiate the cut
	check_for_key2:
    ; === check for player commands:
		mov     ah, 01h
		int     16h
		jz      no_key2

	check_for_more_keys2:
		mov     ah, 00h
		int     16h

		push    ax
		mov     ah, 01h
		int     16h
		jz      no_more_keys2
		pop     ax
		jmp     check_for_more_keys2

	no_more_keys2:
		pop     ax
		mov [cut], 1
	
	no_key2:
		jmp main_loop_eval
		
	;// first phase loop
	main_loop_continue:
	push [x0]
	push [y0]
	push [x1]
	push [y1]
	call clear_rect	;// clears the current row of the brick

	inc [frame_counter]	;// nerfing the speed
	mov ax, [speed_by_frame]
	cmp [frame_counter], ax
	jl nospeed
	mov [frame_counter], 0
	
	;// inc \ dec the brick
	mov ax, [dir]
	add [position], ax
	add [pos_end], ax
	
	cmp [position], 0
	jne positionnotzero
	;// position == 0
		mov ax, [dir]
		not ax
		inc ax
		mov [dir], ax
	positionnotzero:
	
	cmp [pos_end], 320
	jne pos_endnotend
	;// pos_end == 320
		mov ax, [dir]
		not ax
		inc ax
		mov [dir], ax
	pos_endnotend:
	
	
	;// checks for any button press
	check_for_key:
    ; === check for player commands:
		mov     ah, 01h
		int     16h
		jz      no_key

	check_for_more_keys:
		mov     ah, 00h
		int     16h

		push    ax
		mov     ah, 01h
		int     16h
		jz      no_more_keys
		pop     ax
		jmp     check_for_more_keys

	no_more_keys:
		pop     ax
		mov ax, _buffer
		mov es, ax
			
		;// "inc" the height
		sub [y0], 8
		sub [y1], 8
		
		;// if it's the button press, no checks are involved
		cmp [first_time], 1
		je first_time_press
		;// not the first time		
		mov ax, [prev_position]
		cmp [position], ax
		jg right
	left: ;// if the left side of the current brick is "out" of the prev coords
		mov ax, [prev_position]
		mov bx, [position]
		sub ax, bx ;// the loss
		mov bx, [llength]
		sub bx ,ax	;// recalculate length
		mov [llength], bx
		jmp finish_decing
	right:	;// if the right side of the current brick is "out" of the prev coords
		mov ax, [pos_end]
		mov bx, [prev_pos_end]
		sub ax, bx 	;// the loss
		mov bx, [llength]
		sub bx ,ax  ;// recalculate length
		mov [llength], bx
		
	finish_decing:	;// did i lose?
		cmp [llength], 0
		jg finish_decing_continue
		mov [render], 0
		jmp main_loop_eval
	
	finish_decing_continue:
		;// prepping form the next "inc"
		;// and the next brick
		mov ax, [position]
		mov [prev_position], ax
		
		mov ax, [pos_end]
		mov [prev_pos_end], ax
		
		mov [position], 1
		mov [dir], 1
		mov ax, [llength]
		inc ax
		mov [pos_end], ax
		
		
	jmp no_key	
	first_time_press:
		mov [first_time], 0	;// if that was the first time, next ttime wont be the first
		mov ax, [position]
		mov [prev_position], ax
		
		mov ax, [pos_end]
		mov [prev_pos_end], ax
		mov [position], 1
		mov [dir], 1
		mov ax, [llength]
		inc ax
		mov [pos_end], ax
	
	no_key:
	
	nospeed:
	mov ax, _buffer
    mov es, ax
	
	;// brick coords be y->y0 | brick_pos->position | brick_length -> llength
	&brick [y0], [position], [llength]	;// initiate a brick
	push [x0]
	push [y0]
	push [x1]
	push [y1]
	call update_display	;// update the row of the brick
	
;jmp exit
main_loop_eval:
	jmp main_loop
after_all_loops:
	mov al, 03h
    mov ah, 0
    int 10h
	
	mov ax, [score]
	mov bx, 5
	xor dx, dx
	div bx
	mov [score], ax
	mov bx, 4
	xor dx, dx
	div bx
	mov [score], ax
	
	&write_score
	
	mov al, 0
mov ah, 86h
mov cx, 30
mov dx, 5
int 15h


	mov ax, 13h
	int 10h
	
mov [y0], 0
mov [x0], 0
mov [y1], 200
mov [x1], 320

fix_loop1:
	fix_loop2:
	
	mov ax, [y1]
	mov bx, 320
	mul bx
	mov bx, [x1]
	add ax, bx
	mov si, ax
	
	mov ax, _bg
	mov es, ax
	mov al, 0
	mov [es:si], al
	
	mov ax, _buffer
	mov es, ax
	mov al, 0
	mov [es:si], al
	
	mov ax, 0A000h
	mov es, ax
	mov al, 0
	mov [es:si], al
	
	fix_loop2_eval:
		dec [x1]
		cmp [x1], 0
		jge fix_loop2

fix_loop1_eval:
	dec [y1]
	cmp [y1], 0
	jge fix_loop1

&reset

jmp start_game
	
exit2:
&render_bg
	
exit:
	mov ax, 4c00h
	int 21h
END start
 
