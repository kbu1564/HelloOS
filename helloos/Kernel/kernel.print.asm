; NULL 문자를 만날때 까지 출력합니다.
; dx : 출력할 문자열의 시작 address
; ch : 출력할 문자열의 색상 옵션값을 설정 합니다.
; al : 출력할 문자열의 라인 수
_print32:
	push ebp
	mov ebp, esp
	pusha

	mov ax, VideoDescriptor
	mov es, ax

	mov eax, [ebp+16]
	mov ecx, 80*2
	mul ecx

	mov edi, eax
	mov esi, dword [ebp+8]
	mov ecx, dword [ebp+12]
	; 초기화 작업 수행
.for_loop:
	mov dl, byte [esi]

	cmp dl, 0
	je .for_end

	mov byte [es:edi], dl
	; 문자 1바이트를 비디오 메모리로 복사
	mov byte [es:edi+1], cl

	add edi, 2
	add esi, 1

	jmp .for_loop
	; 루프 순회
.for_end:
	popa
	mov esp, ebp
	pop ebp
	ret 12
