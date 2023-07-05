
DATASEG
	bmp_name db 'Titles.bmp',0
	bmp_handle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10 ,'$'
	
CODESEG


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


proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [bmp_handle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette


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

;// process bmp file
;// call Bmp_OpenFile
;//call ReadHeader
;// call ReadPalette
;// call CopyPal
;// call CopyBitmap
