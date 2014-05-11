; NULL 문자를 만날때 까지 출력합니다.
; dx : 출력할 문자열의 시작 address
; ch : 출력할 문자열의 색상 옵션값을 설정 합니다.
; al : 출력할 문자열의 라인 수
_print32:
	push ebp
	mov ebp, esp
	pusha
	; register push

	mov al, [ebp+16]
	mov cl, 80*2
	mul cl

	mov si, ax
	mov di, [ebp+8]
	mov ch, [ebp+12]
	; 초기화 작업 수행

	mov ax, VideoDescriptor
	mov es, ax
.for_loop:
	cmp byte [di], 0
	je .for_end

	mov cl, byte [di]
	mov byte [es:si], cl
	; 문자 1바이트를 비디오 메모리로 복사
	mov byte [es:si+1], ch

	add si, 2
	add di, 1

	jmp .for_loop
	; 루프 순회
.for_end:
	popa
	mov esp, ebp
	pop ebp
	ret 12
