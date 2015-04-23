; 이곳에 저장된 함수 포인터 들은
; HelloOS/helloos/Interrupt 경로에 소스가 저장되어 있다.
;
; Interrupt Handler Table 을 IHT 로 정의 한다.
; HelloOS 에서는 Interrupt Vector Table을 한번 더 추상화 함으로써
; 추후 다른 시스템에서는 이 IHT 테이블만 일치시켜주면 정상 작동하도록 한다.
DFT:
    .start db 0xFF
    .size  dd (DFT.end - DFT.start)

    ; 0 ~ 31번 까지의 인터럽트는 예외 처리에 사용되므로
    ; 32 ~ 47 ~ 255번까지를 사용한다.
    .table times 0xFF dd 0

    .end   db 0xFF

; edi : interrupt number
; esi : interrupt handler function pointer
; 특정 인터럽트 번호에 해당하는 핸들러 함수를 등록한다.
_kernel_set_interrupt_handler:
    pusha
    cli

    mov edx, DFT + 5
    shl edi, 2
    add edx, edi
    shr edi, 2
    mov dword [edx], esi

    sti
    popa
    ret

; edi : interrupt number
; 특정 인터럽트 번호에 해당하는 핸들러 함수를 등록 해제 한다.
_kernel_unset_interrupt_handler:
    pusha
    cli

    mov edx, DFT + 5
    shl edi, 2
    add edx, edi
    shr edi, 2
    mov dword [edx], 0

    sti
    popa
    ret
