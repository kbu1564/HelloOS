; push Queue StartAddress
; call _queue_init
; 인자로 전달된 주소를 큐배열 영역으로 초기화 하는 함수
_queue_init:
    push ebp
    mov ebp, esp
    pusha

    mov esi, dword [ebp + 12]
    ; start address
    mov dword [esi], 0
    ; front
    mov dword [esi+4], 0
    ; rear

    popa
    mov esp, ebp
    pop ebp
    ret 4

; push Queue StartAddress
; push Input Data
; call _queue_push
; 초기화된 큐 배열로 부터 데이터를 push하는 함수
_queue_push:
    push ebp
    mov ebp, esp
    pusha

    mov esi, dword [ebp + 12]
    mov edi, esi
    ; start address

    mov eax, dword [esi]
    mov ecx, 4
    mul ecx
    ; front 계산

    add edi, eax
    add edi, 8
    ; 다음 값이 저장될 위치 구하기

    mov edx, dword [ebp + 8]
    ; input data
    mov dword [edi], edx
    inc dword [esi]
    ; 값 push 후 front++

    popa
    mov esp, ebp
    pop ebp
    ret 8

; push Queue StartAddress
; call _queue_pop
; 초기화된 큐 배열로 부터 데이터 pop 하는 함수
; eax : return
_queue_pop:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx
    push edx

    xor eax, eax
    push dword [ebp + 8]
    call _queue_is_empty
    ; 큐가 꺼낼 수 있는 상태인지를 체크

    test eax, eax
    jnz .end
    ; 큐가 빈 상태인 경우 함수 종료

    mov esi, dword [ebp + 8]
    mov edi, esi
    ; start address

    mov eax, dword [esi + 4]
    mov ecx, 4
    mul ecx

    add edi, eax
    add edi, 8
    ; 다음 값이 꺼내질 위치 구하기

    mov eax, dword [edi]
    inc dword [esi + 4]
    ; 데이터 pop
.end:
    pop edx
    pop ecx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 4

; push Queue StartAddress
; call _queue_is_empty
; 초기화된 큐 배열로 부터 데이터 비어있는지를 체크하는 함수
; eax : return
_queue_is_empty:
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov esi, dword [ebp + 8]
    ; start address
    mov edi, dword [esi]
    ; front

    xor eax, eax
    cmp edi, dword [esi + 4]
    ; if (rear != front) not empty!!
    jne .not_empty

    mov eax, 1
.not_empty:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 4
