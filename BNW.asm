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