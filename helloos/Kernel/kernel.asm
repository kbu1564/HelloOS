[bits   16]
[org    0x8000]

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
    ; 커널 라이브러리
_start:
    ; Kernel Entry Point

    ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ; 실제 머신상에서 세그먼트 초기화 작업을 수행하지 않을 경우
    ; int 0x0D #13 General protection fault 오류를 발생 시킨다.
    ; 이는 GDT 정보가 로드되면서 세그먼트들이 기존의 gs, fs 등의 세그먼트를 참조하면서
    ; 등록되지 않은 GDT 정보를 참조하기에 발생되는 예외들이다.
    ;
    ; 이 경우 초기화 작업을 수행시켜 주면 된다.
    ; 참고 : http://www.joinc.co.kr/modules/moniwiki/wiki.php/%BA%B8%C8%A3%B8%F0%B5%E5
    ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    xor eax, eax
    mov es, eax
    mov ds, eax
    mov fs, eax
    mov gs, eax
    ; segment init

    ; 그래픽 모드 전환 부분
    ;int 0x10

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
    mov cr0, eax
    ; 보호모드로 전환

    jmp $+2
    nop
    nop
    ; 혹시 남아 있을지 모를 16bit 명령어들을 제거

    jmp dword CodeDescriptor:_protect_entry

.end_loader:
    hlt
    jmp .end_loader

;----------------------------------------------
; 보호모드 진입
;----------------------------------------------
[bits   32]
[org    0x8000]

_library:
    %include "kernel.print.asm"
    %include "kernel.debug.dump.asm"
    ; 화면 출력 함수
    %include "kernel.gdt.asm"
    ; gdt table 정의
    ;%include "kernel.file.asm"
    ; 파일경로를 인자로 하여 해당 파일의 내용을 리턴하는 함수
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
    InfoTrueMessage:            db ' O K ', 0
    InfoFalseMessage:           db 'FALSE', 0
    ; TRUE/ FALSE
    KernelProtectModeMessage:   db 'Switching Kernel Protected Mode -- [     ]', 0x0A, 0
    ; 커널 보호모드 진입 완료 메시지
    A20SwitchingCheckMessage:   db 'A20 Switching Check -------------- [     ]', 0x0A, 0
    ; A20 스위칭 성공 여부에 따른 메시지
    EnoughMemoryCheckMessage:   db '64MiB Physical Memory Check ------ [     ]', 0x0A, 0
    ; 최소 64MiB 이상의 물리메모리인가에 따른 메시지
    Paging32ModeMessage:        db '32bit None-PAE Paging Mode ------- [     ]', 0x0A, 0
    ; 32bit 페이징 처리 완료 메시지
    ;------------------------------------------------------------------------------------

_protect_entry:
    ; 32bit Protected Mode 시작 엔트리 포인트 지점
    push 0x07
    push KernelProtectModeMessage
    call _print32
    ; 보호모드 전환 메시지

    mov esi, 0
    mov edi, .chk_pm_true
    jmp .info_true
.chk_pm_true:
    ; 보호모드 전환 성공

    ;-------------------------------------------------------------
    ; A20 활성화 및 메모리 체크
    ;-------------------------------------------------------------
    call _set_a20_mode
    ; A20 기능을 활성화 한다.

    call _test_a20_mode
    ; 이 부분에서 A20 기능의 활성화 여부를 테스트

    push 0x07
    push A20SwitchingCheckMessage
    call _print32
    ; A20 스위칭 처리 메시지

    mov esi, 1
    cmp ax, 0
    je .info_false
    ; A20 전환 실패인 경우 이므로
    ; 시스템을 종료 시킨다.

    mov edi, .chk_a20_true
    jmp .info_true
.chk_a20_true:
    ; A20 기능이 활성화 되어있음

    call _kernel_is_enough_memory
    ; OS 실행에 필요한 최소한의 64MB 메모리가 존재하는지 체크

    push 0x07
    push EnoughMemoryCheckMessage
    call _print32

    mov esi, 2
    cmp ax, 0
    je .info_false
    ; 메모리 부족으로 인한 실패인 경우 이므로
    ; 시스템을 종료 시킨다.

    mov edi, .chk_mem_true
    jmp .info_true
.chk_mem_true:
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
    ; 실행된 순간 모든 주소는 논리주소로 해석됨...

    push 0x07
    push Paging32ModeMessage
    call _print32
    ; 페이징 관련 메시지

    mov esi, 3
    mov edi, .chk_paging_true
    jmp .info_true
.chk_paging_true:
    ; 페이징 기능 활성화 완료

    mov ax, 0
    call _mask_pic
    ; 모든 PIC 활성화

    sti
    ; 인터럽트 활성화

    mov di, TSSDescriptor
    call _kernel_load_tss
    ; TSS 설정

;   ;-------------------------------------------------------------
;   ; 인터럽트 발생 테스트
;   ; 여러가지 인터럽트 예외를 강제적으로 발생시킨다.
;   ;-------------------------------------------------------------
;   ; devide error!!
;   mov eax, 10
;   mov ecx, 0
;   div ecx

;   ;-----------------------------------------------------------------------
;   ; 0xF0000000의 논리 주소를 0x01000000의 물리 메모리 주소로 Mapping
;   ; 커널 메모리 할당 테스트
;   ;-----------------------------------------------------------------------
;   push 0xF0000000
;   push 0x01000000
;   push (0xF0001000-0xF0000000)/0x1000
;   call _kernel_alloc
;
;   ; page fault!!
;   mov ecx, 0x12345678
;   mov dword [0xF0000000], ecx
    ;-------------------------------------------------------------

;   push 0xE0000000
;   push 0x00900000
;   push (0xE0001000-0xE0000000)/0x1000
;   call _kernel_alloc
;   ; 커널 영역의 비디오 메모리 할당
;
;   mov ecx, 0x12345678
;   mov dword [0xE0000000], ecx
.end_kernel:
    hlt
    jmp .end_kernel

.info_false:
    push esi
    push 36
    call _print32_gotoxy

    push 0x04
    push InfoFalseMessage
    call _print32
    jmp .end_kernel

.info_true:
    push esi
    push 36
    call _print32_gotoxy

    push 0x0A
    push InfoTrueMessage
    call _print32

    inc esi
    push esi
    push 0
    call _print32_gotoxy
    ; 다음줄로 포인터 이동
    jmp edi
