; NULL 문자를 만날때 까지 출력합니다.
_print:
    push bp
    mov bp, sp
    pusha
    ; register push

    mov al, [bp+8]
    mov cl, 80*2
    mul cl

    mov si, ax
    mov di, [bp+4]
    mov ch, [bp+6]
    ; 초기화 작업 수행

    mov ax, 0xB800
    mov es, ax
.for_loop:
    cmp byte [di], 0
    je .for_end

    mov cl, byte [di]
    mov byte [es:si], cl
    ; 문자 1바이트를 비디오 메모리로 복사
    mov byte [es:si+1], ch

    add si, 2
    add di, 1

    jmp .for_loop
    ; 루프 순회
.for_end:
    popa
    mov sp, bp
    pop bp
    ret 6

; 화면 전체를 지우는 명령어
_print_cls:
    pusha

    mov si, 80*25*2
    ; 초기화 작업 수행

    mov ax, 0xB800
    mov es, ax
.for_loop:
    cmp si, 0
    je .for_end

    mov byte [es:si], 0

    sub si, 1
    jmp .for_loop
.for_end:
    popa
    ret
