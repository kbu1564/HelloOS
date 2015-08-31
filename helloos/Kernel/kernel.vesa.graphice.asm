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
    ret 16

; 폰트 그리기 테스트
_draw_font_test:
    mov ecx, 0
.font_test:
    mov esi, font
    mov eax, 16
    mul ecx
    add esi, eax
    ; 다음 그릴 폰트

    mov eax, 8
    mul ecx
    ; x 좌표 위치

    push 0
    push eax
    push 0xFFFFFFFF
    push esi
    call _draw_font

    inc ecx
    cmp ecx, 62
    jne .font_test

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

            ; Masking
            mov edx, 16
            sub edx, ecx
            add edx, dword [ebp + 16]

            cmp word [xResolution], dx
            jbe .end_px

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
    ret 16

; Call Vector Table 에 등록될 GUI 모드에서의 print 함수
; _print32_gui 함수와 호환성을 마추기 위한 디버깅용
_call_print32_gui:
    push ebp
    mov ebp, esp
    pusha

    mov eax, dword [ebp+20]
    shl eax, 4
    push eax

    mov eax, dword [ebp+16]
    shl eax, 3
    push eax
    push dword [ebp+12]
    push dword [ebp+8]
    call _print32_gui

    popa
    mov esp, ebp
    pop ebp
    ret 16

; NULL 문자를 만날때 까지 출력합니다.
; ENTER 즉 개행 문자를 \n 으로 정의 합니다.
; void print32_gui(const char* str, int colorCode, int x, int y);
_print32_gui:
    push ebp
    mov ebp, esp
    pusha

    mov edi, dword [ebp+8]
    ; 출력할 메시지
    mov esi, dword [ebp+16]
    ; 출력 x 좌표
    mov ecx, 16
    ; 폰트 크기
.loop:
    xor eax, eax
    mov al, byte [edi]
    test al, al
    jz .end
    ; NULL 체크후 종료

    cmp al, '&'
    jae .chk
.chk:
    cmp al, 'z'
    ja .endloop

    sub al, '&'
    mul ecx
    add eax, font.26h

    push dword [ebp+20]
    push esi
    push dword [ebp+12]
    push eax
    call _draw_font
.endloop:
    add esi, 8
    inc edi
    ; 글씨 크기만큼 다음 위치로 이동
    jmp .loop

.end:
    popa
    mov esp, ebp
    pop ebp
    ret 16
