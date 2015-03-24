; 특정 메모리 주소의 CX바이트 영역의 메모리 HEX 값을
; 덤프하는 함수
; push 출력할 Y좌표 값
; push 출력할 X좌표 값
; push 출력할 바이트 수
; push 출력할 메모리 주소
_print_byte_dump:
    push bp
    mov bp, sp
    pusha
    push es

    ; 라인수 계산하기
    mov dl, byte [bp+10]
    mov al, 80 * 2
    mul dl
	add ax, word [bp+8]

    inc dl
    ; 라인수 계산
    mov si, ax

    xor dx, dx
    xor ax, ax
    mov di, [bp+4]
    ; init

    mov cx, [bp+6]
    add cx, cx
    ; cx = cx * 2

    mov ax, 0xB800
    mov es, ax
    ; video memory
.for_loop:
    cmp dx, cx
    je .for_end
    ; break for_loop

    mov bl, byte [di]
    mov al, bl
    ; 1byte copy

    mov bx, dx
    and bx, 1
    ; 최하위 1bit가 1이면 홀수 0이면 짝수
    cmp bx, 1
    jne .hex4bit

    inc di
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
    jmp .hex4bitPrint
.hex4bitPrint:
    mov byte [es:si], al
    mov byte [es:si+1], 0x04

    add si, 2
    inc dx

    jmp .for_loop
.for_end:
    pop es
    popa
    mov sp, bp
    pop bp
    ret 8
