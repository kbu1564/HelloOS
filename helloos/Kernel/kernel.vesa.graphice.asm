; cx : color
; si : x
; di : y
; set pixel_16bit rgb
_pixel_16:
	push ebp
	mov ebp, esp
	pusha

	mov esi, dword [PhysicalBasePointer]
	;mov ecx, dword [ebp + 8]
	; color
	;mov esi, dword [ebp + 12]
	; x
	;mov edi, dword [ebp + 16]
	; y
	mov eax, dword [BytePerScanLine]
	; a = x + y * (BytePerScanLine / 2)
	shr eax, 1
	mul dword [ebp + 16]
	add eax, dword [ebp + 12]

	shl eax, 1
	; convert short offset

	add esi, eax
	; move offset

	mov ecx, dword [ebp + 8]
	mov dword [esi], ecx
	; write color

	popa
	mov esp, ebp
	pop ebp
	ret 12

