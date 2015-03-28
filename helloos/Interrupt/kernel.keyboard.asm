; 키보드 디바이스 활성화 함수
_IHTKeyboardInitialize:
    push edx
    push ecx
    cli

    mov dl, 0x64
    mov al, 0xAE
    call _out_port_byte
    ; 키보드 디바이스 활성화 커멘드 전송

    mov ecx, 0xFFFF
.L1:
    call _IHTKeyboardInputBufferFull
    ; 커멘드 전송 체크
    test eax, eax
    jz .EL1

    loop .L1
.EL1:
    mov dl, 0x60
    mov al, 0xF4
    call _out_port_byte
    ; ACK 체크
    .kbd_ack_loop:
        mov ecx, 100
        push ecx
        ; 카운터값 저장

        ; 입력버퍼에 데이터의 존재여부 확인
        ; 추후 함수화 하는것이 좋을 것 같다.
        mov ecx, 0xFFFF
        .L2:
            call _IHTKeyboardOutputBufferFull
            ; 커멘드 전송 체크
            test eax, eax
            jnz .EL2

            loop .L2
        .EL2:

        pop ecx
        ; counter 값 복구

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
    sti
    pop ecx
    pop edx
    ret

; Output Buffer에 데이터가 존재하는지 체크
_IHTKeyboardOutputBufferFull:
    push edx

    xor eax, eax
    xor edx, edx
    mov dl, 0x64
    call _in_port_byte

    test al, 0x01
    ; 상태 레지스터로 부터 output buffer에 CPU Data가 존재하는지 체크
    ; 체크는 0x64 포트로 부터 1byte 읽어들인 뒤 0x01와 and 연산을 통해 해당
    ; 비트가 켜져있는지를 체크하는 방식으로 하면 된다.
    jz .false
    ; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.
.true:
    mov eax, 0x01
    jmp .end
.false:
    mov eax, 0x00
.end:
    pop edx
    ret

; Input Buffer에 데이터가 존재하는지 체크
_IHTKeyboardInputBufferFull:
    push edx

    xor eax, eax
    xor edx, edx
    mov dl, 0x64
    call _in_port_byte

    test al, 0x02
    ; 상태 레지스터로 부터 input buffer에 CPU Data가 존재하는지 체크
    ; 체크는 0x64 포트로 부터 1byte 읽어들인 뒤 0x02와 and 연산을 통해 해당
    ; 비트가 켜져있는지를 체크하는 방식으로 하면 된다.
    jz .false
    ; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.
.true:
    mov eax, 0x01
    jmp .end
.false:
    mov eax, 0x00
.end:
    pop edx
    ret

; 키보드 핸들러 함수
_IHTKeyboardHandler:
    xor eax, eax

    call _IHTKeyboardOutputBufferFull
    ; 커멘드 전송 체크
    test eax, eax
    jz .end

    mov dl, 0x64
    call _in_port_byte
    ; 상태 데이터 저장
    mov dh, al

    mov dl, 0x60
    call _in_port_byte

    test dh, 0x20
    jnz .end
    ; 키보드 데이터 인지 체크

    push 23
    push 0
    call _print32_gotoxy

    push 0x07
    push KeyboardCodeMessage
    call _print32

    push 23
    push 17
    push eax
    call _print_hex32
.end:
    ret

KeyboardCodeMessage db 'KeyCode Number : ', 0
