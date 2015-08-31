;----------------------------------
; Call Vector Table
;----------------------------------
; 함수에 대한 코드를 추상화하여
; 필수 구성요소별 함수들을 관리
;----------------------------------
_cvt:
    .clear      dd _clear
    .print      dd _print32
    .print_nl   dd _print32_nl

_call_clear:
    jmp dword [_cvt.clear]
_call_print:
    jmp dword [_cvt.print]
_call_print_nl:
    jmp dword [_cvt.print_nl]

