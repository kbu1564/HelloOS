; 특정 색상으로 배경을 덮어 씌워서 초기화 하는 함수
; void set_screen_clear(int rgbCode, sizeof(rgbCode));
_set_screen_clear:
	push ebp
	mov ebp, esp

	mov ecx, 1024*768*4
	; loop 횟수 셋팅

	mov ax, VGADescriptor
	mov es, ax
	; descriptor setting

	mov esi, 0
	mov eax, dword [ebp+8]
	mov ebx, dword [ebp+12]
.L1:
	mov dword [es:esi], eax
	; 화면 렌더링

	add esi, ebx
	loop .L1

	mov esp, ebp
	pop ebp
	ret 8
