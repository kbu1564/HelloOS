; NULL 문자를 만날때 까지 출력합니다.
; ENTER 즉 개행 문자를 \n 으로 정의 합니다.
_print32:
    push ebp
    mov ebp, esp
    pusha

    mov ax, VideoDescriptor
    mov es, ax

    mov edi, dword [_print32_location]
    mov esi, dword [ebp+8]
    mov ecx, dword [ebp+12]
    ; 초기화 작업 수행
.for_loop:
    mov dl, byte [esi]
    cmp dl, 0
    je .for_end
    ; NULL 문자 만나면 종료 처리

    cmp dl, 0x0A
    je .new_line

    mov byte [es:edi], dl
    ; 문자 1바이트를 비디오 메모리로 복사
    mov byte [es:edi+1], cl

    add edi, 2
    add esi, 1

    jmp .for_loop
    ; 루프 순회
.new_line:
    call _print32_nl
    mov edi, dword [_print32_location]
    ; 개행 처리
    add esi, 1
    jmp .for_loop
.for_end:
    ; 다음 출력 위치값 갱신
    mov dword [_print32_location], edi

    popa
    mov esp, ebp
    pop ebp
    ret 8

; 출력 포인터 값을 특정 위치로 이동시키는 함수
; void _print32_gotoxy(int x, int y);
_print32_gotoxy:
    push ebp
    mov ebp, esp
    push edi
    push eax

    mov edi, dword [ebp+12]
    mov eax, 80
    mul edi
    add eax, dword [ebp+8]
    shl eax, 1
    ; 지정된 위치값으로 포인터 위치 갱신

    mov dword [_print32_location], eax
    ; 위치 업데이트

    pop eax
    pop edi
    mov esp, ebp
    pop ebp
    ret 8

; 다음 행으로 개행 처리하는 함수
_print32_nl:
    push eax
    push ecx
    push edi

    mov edi, dword [_print32_location]
    shr edi, 1
    ; edi = edi / 2
    mov ecx, 0
    ; 현재 출력될 라인 수
.for_loop:
    cmp edi, 80
    jb .for_end

    sub edi, 80
    inc ecx
    jmp .for_loop
.for_end:
    mov eax, 80
    sub eax, edi
    ; 다음행으로 넘어가기 위해 필요한 글자 수 계산
    shl eax, 1
    ; 속성값 포함하여 2배 증가
    mov edi, dword [_print32_location]
    add edi, eax

    mov dword [_print32_location], edi

    pop edi
    pop ecx
    pop eax
    ret

_print32_location:  dd 0
; 다음 문자열이 출력될 위치
