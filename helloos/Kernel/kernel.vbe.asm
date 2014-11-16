_get_vbe_info:
	mov ax, 0
	mov es, ax

	mov di, VbeInfoBlock
	mov ax, 0x4F00
    int 0x10

    mov word [VbeInfoState], ax

    ret
