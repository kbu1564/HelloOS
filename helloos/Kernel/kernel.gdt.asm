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
	push 0x00000000
	push 110010010010b
	call _kernel_set_gdt

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
	and ah, 0xF0
	; 하위 4비트 제거
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

;--------------------------------------------------------
; Global Descriptor Table
;--------------------------------------------------------
gdtr_addr:		dd 0x00400000
gdtr:
	dw gdtEnd - gdt - 1	; GDT Table 전체 Size
	dd gdt				; GDT Table 의 실제 시작 주소
gdt:
	NullDescriptor equ 0x00
		dd 0, 0

	CodeDescriptor equ 0x08
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10011010b
		db 11001111b
		db 0x00

	DataDescriptor equ 0x10
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10010010b	; P DPL S TYPE
		db 11001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00

	VideoDescriptor equ 0x18
	; 비디오 세그먼트
		dw 0xFFFF
		dw 0x8000
		db 0x0B
		db 10010010b	; P DPL S TYPE
		db 01001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00

	VGADescriptor equ 0x20
	; 그래픽(VGA) 세그먼트
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10010010b	; P DPL S TYPE
		db 11001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00

	TSSDescriptor equ 0x28
	; TSS 세그먼트 번호 선언
	; 구조 등록은 추후 _kernel_init_gdt_table(); 함수를 이용하여
	; 다시 재 등록한다.
gdtEnd:
;-------------------------------------------------------------------
; {{Descriptor Description}}
;
; dw 0xFFFF
; [SEGMENT SIZE]
; 1111 1111 1111 1111
; 이 부분의 값과 아래 SEGMENT SIZE 의 4bit 값을 합하여
; 총 20bit로 세그먼트의 크기를 나타낸다
; [G] : 0 -> 0 byte ~ 1 Mbyte
; [G] : 1 -> 0 byte ~ 4 Gbyte ( * 4 Kbyte)

; dw 0x0000
; 기준주소 하위 16 bit

; db 0x00
; 기준주소 상위 8 bit

; db 10011010b
; [P] [DPL] [S] [TYPE]
;  1   00    1   1 010
; 유효 / 슈퍼권한 / 세그먼트 / 코드:실행,읽기

; db 11001111b
; [G] [D/B] [L] [AVL] [SEGMENT SIZE]
;  1    1    0    0        1111
; [G] : 주소 범위를 0 ~ 4 Gbyte까지 확장
; [D/B] : 32 bit Segment
; [AVL] : 64 bit Mode 에서 32 bit 호환 Segment 임을 의미
; [SEGMENT SIZE] : 세그먼트 크기의 상위 4 bit

; db 0x00
; 기준 주소 최상위 8 bit
;-------------------------------------------------------------------
