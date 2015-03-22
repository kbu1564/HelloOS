; 인자값 : 
; si : x resolution
; di : y resolution
; dl : pixels
;
; 리턴값 : 
; ax : 해상도에 해당하는 모드 번호
_get_vbe_mode:
	; register backup
    push cx

    mov cx, 0x4100
    ; Linear Frame Buffer Mode 옵션을 켠 상태로 시작
.search:
    call _get_vbe_mode_info
    ; 해당 모드번호의 정보를 구하는데 실패한 경우 continue
    cmp word [VbeInfoState], 0x004F
    jne .continue

    mov ax, word [ModeAttr]
    and ax, 0x90
    cmp ax, 0x90
    jne .continue

    mov al, byte [MemoryModel]
    mov ah, al
    xor al, 0x04
    jz .check
    xor ah, 0x06
    jnz .continue
    ; if (al != 0x04 && ah != 0x06) continue;
.check:
    ; 해상도 체크 부분
    mov ax, word [xResolution]
    xor ax, si
    jnz .continue
    mov ax, word [yResolution]
    xor ax, di
    jnz .continue
    mov al, byte [BitsPerPixel]
    xor al, dl
    jnz .continue

    ; 찾고자 하는 해상도의 모드번호를 발견한 경우
    mov ax, cx
    jmp .end
    ; 모드번호를 dx 레지스터에 저장 후 종료

.continue:
    inc cx
    jmp .search
.end:
    pop cx
	ret

; 그래픽 컨트롤러의 정보를 얻는 함수
_get_vbe_info:
    push ax
    push di

	xor ax, ax
	mov es, ax

	mov di, VbeInfoBlock
	mov ax, 0x4F00
    int 0x10

    mov word [VbeInfoState], ax
    ; VBE status :
    ;  AL == 4Fh: Function is supported
    ;  AL != 4Fh: Function is not supported
    ;  AH == 00h: Function call successful
    ;  AH == 01h: Function call failed
    ;  AH == 02h: Software supports this function, but the hardware does not
    ;  AH == 03h: Function call invalid in current video mode

    pop di
    pop ax
    ret

; 특정 모드의 정보를 얻는 함수
; cx : Mode Number
_get_vbe_mode_info:
    push ax
    push di
    xor ax, ax
    mov es, ax

    mov di, VbeInfoModeBlock
    mov ax, 0x4F01
    int 0x10

    mov word [VbeInfoState], ax

    pop di
    pop ax
    ret

; 해상도를 해당 모드 번호로 설정하는 함수
; bx : ModeNumber
_set_vbe_mode:
    push ax
    push bx

    ; flag setting
    mov ax, 0x4F02
    int 0x10

    mov word [VbeInfoState], ax

    xor ax, 0x004F
    jnz .end
    ; Display Setting Error!!

    ; 참고 : http://qlibdos32.sourceforge.net/tutor/tutor-vesa.php#appendix_c
    ; 폭 & 시작 지점 설정
    call _set_logical_scanline_length
    call _set_display_start
.end:
    pop bx
    pop ax
    ret

; Scan-line 길이(폭) 설정
_set_logical_scanline_length:
    push ax
    push bx
    push cx

    ; ax    = 4f06h
    ; bl    = 0 - set scan-line length in pixels
    ;         1 - get scan-line length
    ;         2 - set scan-line length in bytes  (VBE 2.0+ only)
    ;         3 - get maximum scan-line length   (VBE 2.0+ only)
    mov bl, 0
    mov cx, word [xResolution]
    mov ax, 0x4F06
    int 0x10

    mov word [VbeInfoState], ax

    pop cx
    pop bx
    pop ax
    ret

; 시작되는 display 지점 설정
_set_display_start:
    push ax
    push bx

    ; ax    = 4f07h
    ; bh    = 0 (reserved and must be 0)
    ; bl    = 0 - Set display start
    ;         1 - get display start  (VBE 2.0+ only)
    ;         80h - set display start during vertical retrace (VBE 2.0+ only)
    xor bx, bx
    ; set display start
    xor cx, cx
    ; 가장 왼쪽의 Scan-line pixel
    xor dx, dx
    ; 첫번째 Scan-line pixel
    mov ax, 0x4F07
    int 0x10

    mov word [VbeInfoState], ax

    pop bx
    pop ax
    ret
    