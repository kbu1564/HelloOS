; mov si, srcString
; mov di, dstString
; call _strcmp
; srcString 주소를 기준으로 dstString 의 문자열이 완벽히 일치하는 경우
; ax register에 0이 저장됨
_strcmp:
    push dx

    ; push 10
    ; push 0x04
    ; push si
    ; call _print
    ; src 출력
    
    ; push 11
    ; push 0x04
    ; push di
    ; call _print
    ; dist 출력

    xor dx, dx
    xor ax, ax
    mov ds, ax
    mov es, ax
    .L1:
        mov dh, byte [di]
        cmp dh, byte [si]
        jne .notsame

        ; null check
        cmp byte [si], 0
        je .L1END
        cmp byte [di], 0
        je .L1END

        inc si
        inc di
        jmp .L1
    .L1END:
    jmp .end
.notsame:
    ; 두 문자열은 같지 않음
    mov ax, 1
.end:
    pop dx
    ret

; use this!!
; mov cx, 8
; mov si, srcString
; mov di, dstString
; call _back_trim
; srcString 주소를 기준으로 8만큼의 크기의 문자의 뒷쪽
; 공백을 제거한 뒤, dstString 주소를 기준으로 뒷쪽 공백이 제거된 문자열이 저장됩니다.
; 공백이 제거된 문자열의 길이값이 ax register에 저장되어 리턴됩니다.
; 해당 함수는 공백을 제거한뒤 문자열 맨 마지막에 NULL 문자를 삽입합니다.
_back_trim:
    push si
    push di
    push cx
    push dx

    xor dx, dx
    ; 뒷부분 공백을 제거
    add si, cx
    dec si
    ; void* src
    add di, cx
    dec di
    ; void* dst
    mov byte [di + 1], 0
.copy:
    mov al, byte [si]
    mov byte [di], 0

    cmp al, 0x20
    je .copy_end

    inc dx
    mov byte [di], al
.copy_end:
    dec di
    dec si
    loop .copy

    mov ax, dx
    pop dx
    pop cx
    pop di
    pop si
    ret
