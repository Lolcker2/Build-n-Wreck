;CODSEG

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

Macro &render_bf
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


