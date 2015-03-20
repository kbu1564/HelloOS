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

    mov cx, 0xFFFF
.search:
    call _get_vbe_mode_info
    ; 해당 모드번호의 정보를 구하는데 실패한 경우 continue
    cmp word [VbeInfoState], 0x004F
    jne .continue

    mov ax, word [ModeAttr]
    and ax, 0x90
    cmp ax, 0x0090
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
    loop .search
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
    xor bh, 01000000b
    ; 선형 프레임 버퍼 모델
    mov ax, 0x4F02
    int 0x10

    mov word [VbeInfoState], ax

    pop bx
    pop ax
    ret
