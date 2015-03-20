; 페이지 디렉토리 테이블과 페이지 테이블 앤트리의 자료 구조 공간을 전부 초기화 시킨다.
_kernel_init_pdpt:
    ;-----------------------------------------------------------
    ; Page Directory init - 0x00402000
    ;-----------------------------------------------------------
    mov edi, dword [PageDirectory]
    ; 페이지 디렉토리가 위치할 메모리 주소
    mov eax, 0
    ; 관리레벨, 읽기/쓰기, 존재여부
    mov ecx, 1024 * 1024 * 4 + 1024 * 4
    ; 페이지 개수
.pd_pt_init:
    mov dword [es:edi], eax
    add edi, 4
    ; 다음 인덱스를 가리키도록 한다.
    loop .pd_pt_init

    ret

; esi에 설정된 논리주소에 대한 페이지 디렉토리 엔트리에 해당하는
; 페이지 테이블의 위치 주소값을 계산 하여 디렉토리 앤트리 값을 설정한 후
; 해당 페이지 테이블을 초기화 한다
;
; 이 함수는 커널권한의 메모리를 확보합니다.
; 요청한 주소로 부터 지정된 크기의 커널 메모리를 할당 받습니다.
;
; 함수 형태:
; A의 논리 주소부터 B만큼의 공간을 실제 물리메모리의 C에 매핑합니다.
; void _kernel_alloc(void* A, void* C, size_t B);
;
; 주의:
; 이 함수는 메모리의 사용여부와 관계없이 지정된 값만큼의 메모리를 무조건 매핑시킵니다.
;
; push 커널 페이지를 할당할 논리 메모리 시작 주소
; push 매핑할 실제 물리 메모리 시작 주소
; push 할당할 메모리의 크기(4KB의 배수단위로 생성)
_kernel_alloc:
    push ebp
    mov ebp, esp
    pusha

    mov ax, DataDescriptor
    mov es, ax
    ;----------------------------------------------

    mov eax, dword [ebp+16]
    shr eax, 22
    mov ebx, eax
    ; 페이지 디렉토리 엔트리 10bit 구하기
    shl eax, 2
    ; eax = eax * 4;

    mov esi, dword [PageDirectory]
    add esi, eax
    ; PageDirectory Entry 찾기
    ;----------------------------------------------

    mov eax, ebx
    mov edx, 0x1000
    mul edx
    ; Page Table 생성 위치
    ; 페이지 옵션 설정
    add eax, dword [PageDirectory]
    add eax, 0x1000
    mov edi, eax
    or eax, 0x01
    mov dword [esi], eax
    ; Page Table 위치 셋팅
    ;----------------------------------------------

    mov esi, dword [ebp+16]
    shl esi, 10
    shr esi, 22
    ; 페이지 테이블 앤트리 구하기
    shl esi, 2
    ; esi = esi * 4;
    add esi, edi
    mov edi, dword [ebp+12]
    or edi, 0x01
    mov ecx, dword [ebp+8]
.page_alloc_loop:
    mov dword [esi], edi

    add edi, 0x1000
    add esi, 4
    loop .page_alloc_loop
    ; 지정된 크기만큼만 물리메모리에 대응시키기

    popa
    mov esp, ebp
    pop ebp
    ret 12

; 페이징 초기화 함수
_kernel_init_paging:
    mov ax, DataDescriptor
    mov es, ax

    call _kernel_init_pdpt
    ; 페이징 자료구조 영역 초기화

    ;-----------------------------------------------------------
    ; 커널 영역 할당 0x00000000 ~ 0x00100000
    ;-----------------------------------------------------------
    push 0x00000000
    push 0x00000000
    push (0x00100000-0x00000000)/0x1000
    call _kernel_alloc

    ;-----------------------------------------------------------
    ; 커널 영역 할당 0x00400000 ~ 0x00800000
    ;-----------------------------------------------------------
    push 0x00400000
    push 0x00400000
    push (0x00800000-0x00400000)/0x1000
    call _kernel_alloc

    ;-----------------------------------------------------------
    ; 커널 영역 할당 0x00800000 ~ 0x00805000
    ;-----------------------------------------------------------
    push 0x00800000
    push 0x00800000
    push (0x00805000-0x00800000)/0x1000
    call _kernel_alloc

    test byte [VbeGraphicModeStart], 0x01
    jz .enable_paging
    ; 그래픽 모드로 시작하지 않는 경우 그래픽 영역 메모리를 활성화 하지 않는다.

    ;-----------------------------------------------------------------------
    ; 비디오 영역 할당 0x00900000 ~ 0x00D00000
    ;-----------------------------------------------------------------------
    xor eax, eax
    xor ecx, ecx
    mov ax, word [xResolution]
    mov cx, word [yResolution]
    mul ecx
    ; x * y
    xor ecx, ecx
    mov cl, byte [BitsPerPixel]
    mul ecx
    ; x * y * px
    mov ecx, 0x1000
    div ecx
    ; 4KiB 단위로 필요한 용량 표현

    push dword [PhysicalBasePointer]
    push 0x00900000
    push eax
    call _kernel_alloc
.enable_paging:
    mov eax, dword [PageDirectory]
    mov cr3, eax
    ; 페이지 디렉토리 시작 주소를 등록

    ;-------------------------------------------
    ; 컨트롤 Register Setting
    ; PG, CD, NW, AM, WP, NE, ET, TS, EM, MP, PE
    ;  1   ?   ?   ?   1   ?   ?   ?   ?   ?   0
    ;-------------------------------------------
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    ; 페이징을 시작하기 위해 컨트롤 레지스터에서
    ; 최상위 비트를 1로 셋팅

    ret

; 운영체제가 실행되는데 필요한 최소 64MB의 메모리가 여유공간으로
; 존재하는지를 함께 검사한다.
; 작동이 불가능 한 경우 ax 값에 0 값을 반환 시키고
; 작동이 가능한 경우 ax 값에 1 값을 반환 시킨다.
_kernel_is_enough_memory:
    ; 0 ~ 64MB
    ; 0 ~ 0x04000000 까지
    mov ax, DataDescriptor
    mov ds, ax

    ; 모든 범위의 주소공간에 접근을 가능하도록 하기 위한
    ; 데이터 디스크립트 설정

    ; 만약 1MB 이상의 메모리에 접근이 불가능 한 상황이라면
    ; 1MB 이상의 주소에 값을 대입후 다시 읽어 비교하게 되면
    ; 다른 값이 나오게 된다.
    ;
    ; 이는 1MB 이상의 영역 접근 실패시 0x00000000 주소를 참조하기 때문이다.
    mov ecx, 63
    ; 1 ~ 64MB 영역에 접근이 가능한지 체크한다.
    mov edi, 0x00100000
    ; 시작 부분을 1MB 영역으로 잡는다
    mov ax, 1
    ; 일단 리턴값을 성공값으로 셋팅
.mem_check_while:
    mov dword [ds:edi], 0x12345678
    cmp dword [ds:edi], 0x12345678
    jne .error
    ; 오류 발생

    add edi, 0x00100000
    ; 오류 발생하지 않은 경우 다음 1MB 영역을 검사
    loop .mem_check_while
    jmp .end
    ; 오류 발생 안함
.error:
    mov ax, 0
    ; 이 부분이 실행된 경우 최소 64MiB의 물리 메모리가 존재하지 않는 것 이므로
    ; 0값을 리턴한다.
.end:
    ret

PageDirectory:          dd 0x00402000
; 페이지 디렉토리
