[bits	16]
[org	0x8000]

jmp _entry
nop
; nop 명령어를 통해 올바른 커널인지 아닌지를 체크하므로
; 커널 데이터의 3byte 부분의 값은 무조건 nop 명령어 코드가
; 위치해야 한다.

_entry:
	jmp _start
	; 이 부분에 각종 라이브러리 함수 파일들이 include 된다.

	%include "../Bootloader/loader.print.asm"
	%include "../Bootloader/loader.debug.dump.asm"
	; 기본 라이브러리의 경우 부트로더쪽의 함수를 그대로 가져와 사용한다.
	%include "../Bootloader/loader.graphice.asm"
	; vesa 관련 bios 함수 라이브러리
	%include "../Bootloader/loader.vesa.mode.asm"
	; vesa 비디오 모드 상수 정의
	; 커널 라이브러리
_start:
	; Kernel Entry Point
	push 0
	push 0x0A
	push KernelLoadingMessage
	call _print

	; 전환할 해상도 정보 셋팅
	mov word [VesaResolutionInfo.XResolution], 1024
	mov word [VesaResolutionInfo.YResolution], 768
	mov byte [VesaResolutionInfo.BitsPerPixel], 32

	;call _auto_resolution_vesa_mode
	; 그래픽 모드로 해상도 변경

	cli
	; 이 부분에서 32bit Protected Mode 로 전환할 준비를 한다.

	lgdt [gdtr]
	; GDT 정보 로드

	;-------------------------------------------
	; 컨트롤 Register Setting
	; PG, CD, NW, AM, WP, NE, ET, TS, EM, MP, PE
	;  0   1   0   0   0   1   1   1   0   1   1
	;-------------------------------------------
	mov eax, cr0
	or eax, 0x00000001
	;mov eax, 0x4000003B
	mov cr0, eax
	; 보호모드로 전환

	jmp $+2
	nop
	nop
	; 혹시 남아 있을지 모를 16bit 명령어들을 제거

	jmp dword CodeDescriptor:_protect_entry

.super_failure:
	push 1
	push 0x04
	push NotSuperVideoModeMessage
	call _print
	; VBE 2.0 이상 지원하지 않는 경우
.end_loader:
	hlt
	jmp .end_loader

;----------------------------------------------
; 보호모드 진입
;----------------------------------------------
[bits	32]
[org	0x8000]

_library:
	%include "kernel.print.asm"
	%include "kernel.debug.dump.asm"
	; 화면 출력 함수
	%include "kernel.gdt.asm"
	; gdt table 정의
	;%include "kernel.file.asm"
	; 파일경로를 인자로 하여 해당 파일의 내용을 리턴하는 함수
	%include "kernel.vesa.graphice.asm"
	; 32bit 커널용 그래픽 모드 전환 라이브러리
	; 비디오 카드 표준에 관한 VESA 처리에 대한 라이브러리
	%include "kernel.a20.mode.asm"
	; 32bit 에서 64KB 까지의 메모리만 접근 가능한 제한을 풀기 위한
	; A20 기능 활성화 라이브러리
	%include "kernel.mmu.asm"
	; 메모리 관련 함수(페이징 처리)
	%include "kernel.interrupt.asm"
	; 인터럽트 관련 처리 함수
	%include "kernel.pic.asm"
	; pic 관련 함수 라이브러리

_global_variables:
	;------------------------------------------------------------------------------------
	; 변수 처리
	KernelLoadingMessage:			db 'Kernel Load Success', 0
	; 커널 로딩 완료 메시지
	KernelProtectModeMessage:		db 'Switching Kernel Protected Mode', 0
	; 커널 보호모드 진입 완료 메시지
	NotSuperVideoModeMessage:		db 'This computer doesn`t support VBE 2.0.', 0
	; 해당 해상도의 비디오 모드 지원 불가 메시지
	A20SwitchingFailureMessage:		db 'A20 Switching failure', 0
	A20SwitchingSuccessMessage:		db 'A20 Switching success', 0
	; A20 스위칭 성공 여부에 따른 메시지
	EnoughMemoryFailureMessage:		db '64MiB Physical Memory check failure', 0
	EnoughMemorySuccessMessage:		db '64MiB Physical Memory check success', 0
	; 최소 64MiB 이상의 물리메모리인가에 따른 메시지
	Paging32SuccessMessage:			db '32bit None-PAE Paging Success', 0
	; 32bit 페이징 처리 완료 메시지
	;------------------------------------------------------------------------------------

_protect_entry:
	; 32bit Protected Mode 시작 엔트리 포인트 지점
	push 1
	push 0x0A
	push KernelProtectModeMessage
	call _print32
	; 보호모드 전환 성공 메시지

	;-------------------------------------------------------------
	; A20 활성화 및 메모리 체크
	;-------------------------------------------------------------
	call _set_a20_mode
	; A20 기능을 활성화 한다.

	call _test_a20_mode
	; 이 부분에서 A20 기능의 활성화 여부를 테스트

	cmp ax, 0
	je .a20_switching_failure
	; A20 전환 실패 혹은 메모리 부족으로 인한 실패인 경우 이므로
	; 시스템을 종료 시킨다.

	push 2
	push 0x0A
	push A20SwitchingSuccessMessage
	call _print32
	; A20 스위칭 처리 성공

	call _kernel_is_enough_memory
	; OS 실행에 필요한 최소한의 64MB 메모리가 존재하는지 체크

	cmp ax, 0
	je .mem_enough_failure
	; A20 전환 실패 혹은 메모리 부족으로 인한 실패인 경우 이므로
	; 시스템을 종료 시킨다.
	
	push 3
	push 0x0A
	push EnoughMemorySuccessMessage
	call _print32
	; 64MiB 이상의 메모리가 확보되어 있음

	call _init_pic
	; pic 초기화 수행

	;-------------------------------------------------------------
	; GDT, TSS 초기화
	;-------------------------------------------------------------
	call _kernel_init_gdt_table
	; GDT 새로운 메모리 주소에 등록

	call _kernel_load_gdt
	; GDT 로드

	;-------------------------------------------------------------
	; 페이징 및 인터럽트 초기화
	;-------------------------------------------------------------
	call _kernel_init_idt_table
	; 인터럽트 테이블을 초기화 처리 해 준다.

	mov esi, dword [idtr]
	call _kernel_load_idt
	; 인터럽트 디스크립터 테이블 등록

	call _kernel_init_paging
	; 페이징 초기화, 활성화
	; 이놈이 실행된 순간 모든 주소는 논리주소로 해석됨...

	mov ax, 0
	call _mask_pic
	; 모든 PIC 활성화

	sti
	; 인터럽트 활성화

	mov di, TSSDescriptor
	call _kernel_load_tss
	; TSS 설정

	;-------------------------------------------------------------
	; 인터럽트 발생 테스트
	; 여러가지 인터럽트 예외를 강제적으로 발생시킨다.
	;-------------------------------------------------------------
	; devide error!!
	mov eax, 10
	mov ecx, 0
	div ecx

	; page fault!!
	;mov ecx, 0x12345678
	;mov dword [0xF0000000], ecx
	;-------------------------------------------------------------

	;push 4
	;push 0x00FF0000
	;call _set_screen_clear
	; 화면을 전부 빨강으로 초기화 함
.end_kernel:
	hlt
	jmp .end_kernel

.a20_switching_failure:
	push 2
	push 0x04
	push A20SwitchingFailureMessage
	call _print32
	; A20 전환 실패 혹은 메모리 부족으로 인한 실패
	jmp .end_kernel

.mem_enough_failure:
	push 3
	push 0x04
	push EnoughMemoryFailureMessage
	call _print32
	; 물리메모리가 최소 64MiB가 되지 않음
	jmp .end_kernel
	