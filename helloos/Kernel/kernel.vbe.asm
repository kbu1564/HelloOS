_get_vbe_info:
	mov ax, 0
	mov es, ax

	mov di, VbeInfoBlock
	mov ax, 0x4F00
    int 0x10

    mov word [VbeInfoState], ax

    ret

; cx : Mode Number
_get_vbe_mode_info:
    mov ax, 0
    mov es, ax

    mov di, VbeInfoModeBlock
    mov ax, 0x4F01
    int 0x10

    mov word [VbeInfoState], ax

    ret

; bx : ModeNumber
_set_vbe_mode:
    ; flag setting
    xor bh, 01000000b
    ; 선형 프레임 버퍼 모델
    mov ax, 0x4F02
    int 0x10

    mov word [VbeInfoState], ax

    ret
