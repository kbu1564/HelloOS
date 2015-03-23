; 그래픽 전용 라이브러리 함수
; 2015-03-23

; 비디오 화면 지우기
; ebx : ColorCode ARGB
_vga_clear_screen:
    push esi
    push eax
    push ecx

    mov esi, dword [PhysicalBasePointer]

    xor eax, eax
    xor ecx, ecx
    mov ax, word [xResolution]
    mov cx, word [yResolution]
    mul ecx
    ; x * y

    mov ecx, eax
    .clear_loop:
        mov dword [esi], ebx
        add esi, 4
        loop .clear_loop

    pop ecx
    pop eax
    pop esi
    ret
