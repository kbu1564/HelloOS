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
    .loop_draw:
        mov ecx, 8
        .loop_px:
            mov edx, 1
            shl edx, cl
            shr edx, 1

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
        jne .loop_draw

    popa
    mov esp, ebp
    pop ebp
    ret 8

; 문자 렌더링 함수
_draw_text:
  push ebp
  mov ebp, esp
  pusha

  popa
  mov esp, ebp
  pop ebp
  ret

; push Y좌표
; push X좌표
; push 색상
; push 그릴 커서 종류
; call _draw_font
; 화면에 마우스 커서를 찍어주는 함수
_draw_cursor:
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
    .loop_draw:
        mov ecx, 16
        .loop_px:
            mov edx, 1
            shl edx, cl
            shr edx, 1

            test word [edi], dx
            jz .end_px
            mov ebx, dword [ebp + 12]
            mov dword [esi], ebx
        .end_px:
            add esi, 4
            loop .loop_px

        add esi, 4 * (1024 - 16)
        dec eax
        add edi, 2

        cmp eax, 0
        jne .loop_draw

    popa
    mov esp, ebp
    pop ebp
    ret 8
