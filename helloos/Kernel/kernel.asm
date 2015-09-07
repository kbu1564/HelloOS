[bits   16]
[org    0x8000]

jmp _entry
; 32bit로 전환되기 전에 32bit에서 필요한 중요 라이브러리를
; 메모리로 로드시킨다.
nop
; nop 명령어를 통해 올바른 커널인지 아닌지를 체크하므로
; 커널 데이터의 3byte 부분의 값은 무조건 nop 명령어 코드가
; 위치해야 한다.
KernelMode db 16
; 위의 값을 이용하여 커널 버전을 판단한다.

_entry:
    jmp _start
    ; 이 부분에 각종 라이브러리 함수 파일들이 include 된다.

    %include "../Bootloader/loader.print.asm"
    %include "../Bootloader/loader.debug.dump.asm"
    ; 기본 라이브러리의 경우 부트로더쪽의 함수를 그대로 가져와 사용한다.

    ; Kernel Library
    %include "kernel.library.print.asm"
    %include "kernel.library.string.asm"
    ; string library
    %include "kernel.vbe.asm"
    %include "kernel.vbe.header.asm"
    ; Vedio BIOS Extension Library
    %include "kernel.gdt.header.asm"
    ; gdt table 정의
    %include "kernel.file.asm"
    ; Call Functions LoadLibrary

    %include "kernel.call.table.asm"
_global_filename:
    KernelProtectModeMemoryArea  equ 0x9000
    KernelProtectModeLoadingFail db  'kernel.protectmode(32bit) Loading Failure', 0
    KernelGraphicsModeFail       db  'Graphic Mode Starting Failure', 0
    KernelProtectModeFileName    db  'kernel.protectmode.sys', 0
    ; 로드할 커널 파일 이름
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
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax
    mov sp, 0xffff
    ; segment init

    push 0x0000
    push KernelProtectModeMemoryArea
    push KernelProtectModeFileName
    call _load_library
    ; ProtectedMode Kernel File Loading

    mov cx, word [KernelProtectModeMemoryArea + 2]
    cmp cx, 0x2090
    jne .error_loader
    ; Check to Kernel.protectmode.sys file

    call _get_vbe_info
    ; load graphics information(vbe)

    test byte [VbeGraphicModeStart], 0x01
    jz .skip_graphic_mode
    ; 그래픽 모드로 시작하는 경우가 아니라면
    ; 그래픽 전환 작업을 하지 않는다.

    ; ax : 해상도에 해당하는 모드 번호
    mov si, VbeGraphicModeXResolution
    mov di, VbeGraphicModeYResolution
    mov dl, VbeGraphicModeColorBits
    call _get_vbe_mode
    ; 특정 해상도의 모드 번호를 구한다.

    mov bx, ax
    call _set_vbe_mode
    ; 구한 모드 번호로 해상도를 변경
.skip_graphic_mode:
    cli
    ; 이 부분에서 32bit Protected Mode 로 전환할 준비를 한다.

    ;-------------------------------------------
    ; 컨트롤 Register Setting
    ; PG, CD, NW, AM, WP, NE, ET, TS, EM, MP, PE
    ;  0   1   0   0   0   1   1   1   0   1   1
    ;-------------------------------------------
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax
    ; 보호모드로 전환

    lgdt [gdtr]

    jmp $+2
    nop
    nop
    ; CPU는 명령어를 해석하기 위해 여러 절차에 따라
    ; 다음 명령어를 해석 준비하는 작업을 수행하므로 비록 실행은 되지 않지만
    ; 아무런 기능을 수행하지 않는 작업을 수행시킴으로써 남아있을지 모를 16bit 명령어들을
    ; 제거하는 역할을 한다.

    jmp dword CodeDescriptor:KernelProtectModeMemoryArea

.error_loader:
    push 0
    push 0x04
    push KernelProtectModeLoadingFail
    call _print
    jmp .end_loader

.error_graphics:
    push 0
    push 0x04
    push KernelGraphicsModeFail
    call _print
    jmp .end_loader

.end_loader:
    hlt
    jmp .end_loader
