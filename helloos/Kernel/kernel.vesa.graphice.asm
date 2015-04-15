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

; push Y좌표
; push X좌표
; push 색상
; push 출력할 글자정보
; call _draw_font
; 한글자를 화면에 찍어주는 함수
_draw_font:
    push ebp
    mov ebp, esp
    pusha

    mov esi, dword [PhysicalBasePointer]
    mov eax, 4
    mul dword [ebp + 16]
    add esi, eax
    ; x position
    mov eax, 1024 * 4
    mul dword [ebp + 20]
    add esi, eax
    ; y position

    mov edi, dword [ebp + 8]
    mov eax, 16
    .draw_font:
        mov ecx, 8
        .loop_px:
            mov dx, 1
            shl dx, cl
            shr dx, 1

            test byte [edi], dl
            jz .end_px
            mov ebx, dword [ebp + 12]
            mov dword [esi], ebx
        .end_px:
            add esi, 4
            loop .loop_px

        add esi, 4 * (1024 - 8)
        dec eax
        inc edi

        cmp eax, 0
        jne .draw_font

    popa
    mov esp, ebp
    pop ebp
    ret 8
