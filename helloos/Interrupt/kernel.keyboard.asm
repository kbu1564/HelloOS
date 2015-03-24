_IHTKeyboardInitialize:
    push edx
    push ecx

    mov dl, 0x64
    mov al, 0xAE
    call _out_port_byte
    ; 키보드 디바이스 활성화 커멘드 전송
    call _wait_to_buffer_cpu
    ; 커멘드 전송 체크

    .kbd_ack:
        mov dl, 0x60
        mov al, 0xF4
        call _out_port_byte
        ; ACK 체크
    .kbd_ack_loop:
        mov cx, 100
        ; 입력버퍼에 데이터의 존재여부 확인
        ; 추후 함수화 하는것이 좋을 것 같다.
        call _wait_to_buffer_cpu
        ; 커멘드 전송 체크

        mov dl, 0x60
        call _in_port_byte

        xor al, 0xFA
        jz .success

        loop .kbd_ack_loop
        ; 다른 키가 입력 될 수 있으니 최대 100개 까지의 입력을 체크

.error:
    mov eax, 0x00
    jmp .end

.success:
    mov eax, 0x01

.end:
    pop ecx
    pop edx
    ret

_IHTKeyboardHandler:
    xor eax, eax

    push 23
    push 0
    call _print32_gotoxy

    push 0x07
    push KeyboardCodeMessage
    call _print32

    call _wait_to_buffer_cpu

    mov dl, 0x60
    call _in_port_byte

    push 23
    push 17
    push eax
    call _print_hex32

    ret

KeyboardCodeMessage db 'KeyCode Number : ', 0
