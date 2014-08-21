; 숫자값을 hex 형태로 출력하는 함수
; void _print_hex32(int y, int x, DWORD register);
; push 출력할 Y좌표 값
; push 출력할 X좌표 값
; push 출력할 DWORD 크기의 데이터
_print_hex32:
    push ebp
    mov ebp, esp
    pusha

    mov ax, VideoDescriptor
    mov es, ax
    ; video memory

    mov eax, [ebp+16]
    mov ecx, 80
    mul ecx
    add eax, [ebp+12]
    shl eax, 1
    mov esi, eax
    ; 라인수 계산하기

    mov dword [es:esi], 0x04780430
    ; 0x 출력
    mov ah, 0x04
    ; 색상값 셋팅
    mov ecx, 8
    mov edi, ebp
    add edi, 11
.hex4bitLoop:
    mov al, byte [edi]

    ;test ecx, 1
    mov edx, ecx
    and edx, 1
    cmp edx, 1
    ; 최하위 1bit가 1이면 홀수 0이면 짝수
    jne .hex4bit

    dec edi
    ; 다음 메모리 값 검사
    shl al, 4
.hex4bit:
    shr al, 4
    and al, 0x0F
    ; 상위 4bit and mask

    add al, 0x30
    ; 0 ~ 9
    cmp al, 0x3A
    jb .hex4bitPrint

    add al, 0x07
    ; 10 ~ 15
.hex4bitPrint:
    mov word [es:esi+4], ax
    add esi, 2
    loop .hex4bitLoop

    popa
    mov esp, ebp
    pop ebp
    ret 12

; 특정 메모리 주소의 CX바이트 영역의 메모리 HEX 값을
; 덤프하는 함수
; push 출력할 Y좌표 값
; push 출력할 X좌표 값
; push 출력할 바이트 수
; push 출력할 메모리 주소
_print_byte_dump32:
    push ebp
    mov ebp, esp
    pusha

    mov ax, es
    push ax
    ; descriptor 백업

    mov eax, [ebp+20]
    mov ecx, 80
    mul ecx
    add eax, [ebp+16]
    shl eax, 1
    mov esi, eax
    ; 라인수 계산하기

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

    mov byte [es:esi], 0x20
    mov byte [es:esi+1], 0x04
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
    mov byte [es:esi], al
    mov byte [es:esi+1], 0x04

    add si, 2
    inc dx

    jmp .for_loop

.for_end:
    pop ax
    mov es, ax
    ; descriptor 복구

    popa
    mov esp, ebp
    pop ebp
    ret 16

LineCounter32:  db 0
