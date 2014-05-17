; 특정 메모리 주소의 CX바이트 영역의 메모리 HEX 값을
; 덤프하는 함수
_print_hex:
	push ebp
	mov ebp, esp
	pusha

	mov dl, byte [LineCounter32]
	mov al, 80*2
	mul dl

	inc dl
	mov byte [LineCounter32], dl
	; 라인수 계산
	mov si, ax

	xor edx, edx
	xor ax, ax
	mov edi, [ebp+8]
	; init

	mov ax, [ebp+16]
	mov cx, 80
	mul cx
	mov si, ax
	add si, word [ebp+20]

	mov ecx, [ebp+12]
	shl ecx, 1
	; ecx = ecx * 2

	mov ax, VideoDescriptor
	mov es, ax
	; video memory
.for_loop:
	cmp edx, ecx
	je .for_end
	; break for_loop

	mov bl, byte [edi]
	mov al, bl
	; 1byte copy

	mov bx, dx
	and bx, 1
	; 최하위 1bit가 1이면 홀수 0이면 짝수
	cmp bx, 1
	jne .hex4bit

	inc edi
	; 다음 메모리 값 검사

	shl al, 4
.hex4bit:
	shr al, 4
	and al, 0x0F
	; 상위 4bit and mask

	mov bx, dx
	and bx, 1
	cmp bx, 1
	je .hex1byteSpace
.hex1byteSpace:
	cmp al, 10
	jae .hex4bitAtoF

	add al, 0x30
	; 0 ~ 9
	jmp .hex4bitPrint
.hex4bitAtoF:
	add al, 0x37
	; 10 ~ 15
.hex4bitPrint:
	mov byte [es:si], al
	mov byte [es:si+1], 0x04

	add si, 2
	inc dx

	jmp .for_loop

.for_end:
	popa
	mov esp, ebp
	pop ebp
	ret 16

; 특정 메모리 주소의 CX바이트 영역의 메모리 HEX 값을
; 덤프하는 함수
_print_byte_dump32:
	push ebp
	mov ebp, esp

	pusha

	mov dl, byte [LineCounter32]
	mov al, 80*2
	mul dl

	inc dl
	mov byte [LineCounter32], dl
	; 라인수 계산
	mov si, ax

	xor edx, edx
	xor ax, ax
	mov edi, [ebp+8]
	; init

	mov ecx, [ebp+12]
	shl ecx, 1
	; ecx = ecx * 2

	mov ax, VideoDescriptor
	mov es, ax
	; video memory
.for_loop:
	cmp edx, ecx
	je .for_end
	; break for_loop

	mov bl, byte [edi]
	mov al, bl
	; 1byte copy

	mov bx, dx
	and bx, 1
	; 최하위 1bit가 1이면 홀수 0이면 짝수
	cmp bx, 1
	jne .hex4bit

	inc edi
	; 다음 메모리 값 검사

	shl al, 4
.hex4bit:
	shr al, 4
	and al, 0x0F
	; 상위 4bit and mask

	mov bx, dx
	and bx, 1
	cmp bx, 1
	je .hex1byteSpace
	cmp dx, 0
	jbe .hex1byteSpace
	; di 값이 짝수라면 공백을 출력하지 않음

	mov byte [es:si], 0x20
	mov byte [es:si+1], 0x04
	; 공백 출력
	add si, 2
.hex1byteSpace:
	cmp al, 10
	jae .hex4bitAtoF

	add al, 0x30
	; 0 ~ 9
	jmp .hex4bitPrint
.hex4bitAtoF:
	add al, 0x37
	; 10 ~ 15
.hex4bitPrint:
	mov byte [es:si], al
	mov byte [es:si+1], 0x04

	add si, 2
	inc dx

	jmp .for_loop

.for_end:
	popa

	mov esp, ebp
	pop ebp
	ret 8

LineCounter32:	db 0
