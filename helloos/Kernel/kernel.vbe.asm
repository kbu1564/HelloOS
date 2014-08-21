; VbeInfoBlock    equ 0x7E00
;
VbeInfoState      dw 0
_get_vbe_info:
	mov ax, 0
	mov es, ax

	mov di, 0x7E00
	mov ax, 0x4F00
    int 0x10

    mov word [VbeInfoState], ax

    ret
