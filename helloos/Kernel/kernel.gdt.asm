_kernel_init_gdt_table:
    mov ax, DataDescriptor
    mov es, ax

    mov esi, dword [gdtr_addr]
    mov word [esi], 0
    mov dword [esi+2], 0

    push NullDescriptor
    push 0x00000000
    push 0x00000000
    push 000000000000b
    call _kernel_set_gdt

    push CodeDescriptor
    push 0x000FFFFF
    push 0x00000000
    push 110010011010b
    call _kernel_set_gdt

    push DataDescriptor
    push 0x000FFFFF
    push 0x00000000
    push 110010010010b
    call _kernel_set_gdt

    push VideoDescriptor
    push 0x000FFFFF
    push 0x000B8000
    push 010010010010b
    call _kernel_set_gdt

    push VGADescriptor
    push 0x000FFFFF
    push dword [PhysicalBasePointer]
    push 110010010011b
    call _kernel_set_gdt
    ; VGA memory Address Setting
    ; VGA Descriptor 기준 주소 셋팅

    push TSSDescriptor
    push 0x000FFFFF
    push 0x00400500
    push 100010001001b
    call _kernel_set_gdt

    ret

; void kernel_set_gdt(BYTE segment_number, DWORD size, DWORD base_addr, WORD options);
_kernel_set_gdt:
    push ebp
    mov ebp, esp
    pusha

    mov ax, DataDescriptor
    mov es, ax

    mov esi, dword [gdtr_addr]
    mov di, word [esi]
    add di, 8
    mov word [esi], di
    ; GDT SIZE 갱신
    ; GDT Entry Size 만큼 더함으로써 전체 크기를 증가 시킨다.
    mov eax, esi
    add eax, 6
    mov dword [esi+2], eax
    ; GDT 시작 주소 갱신
    add esi, 6
    ; esi를 GDT 시작 부분으로 주소값 갱신
    mov eax, dword [ebp+20]
    ; 추가하려는 GDT 엔트리 구조의
    ; 메모리 저장 위치 주소값 얻기
    add esi, eax

    mov eax, dword [ebp+16]
    ; segment size
    mov word [esi], ax
    shr eax, 16
    and al, 0x0F
    ; segment size 상위 4비트 설정
    mov byte [esi+6], al

    mov eax, dword [ebp+12]
    mov word [esi+2], ax
    ; base addr 하위 2바이트
    shr eax, 16
    mov byte [esi+4], al
    mov byte [esi+7], ah
    ; base addr 상위 각각 1바이트씩 셋팅
    mov eax, dword [ebp+8]
    mov byte [esi+5], al
    mov al, byte [esi+6]
    ; P DPL S TYPE : al
    shl ah, 4
    ; 하위 4비트 -> 상위 4비트로 이동
    or ah, al
    mov byte [esi+6], ah
    ; G D/B L AVL : ah
    ; 옵션 셋팅

    popa
    mov esp, ebp
    pop ebp
    ret 16

; GDT 테이블 등록
_kernel_load_gdt:
    mov esi, dword [gdtr_addr]
    lgdt [esi]
    ret

; TSS 세그먼트 셋팅
_kernel_load_tss:
    ltr di
    ret
