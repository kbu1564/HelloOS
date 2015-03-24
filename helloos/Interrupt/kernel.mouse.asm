; 마우스의 경우 키보드와 동일한 특수 목적 레지스터를 사용한다.
;
; 마우스 디바이스 활성화 함수
_IHTMouseInitialize:
    push edx
    push ecx
    cli

    mov dl, 0x64
    mov al, 0xA8
    call _out_port_byte
    ; 마우스 디바이스 활성화 커멘드 전송
    mov dl, 0x64
    mov al, 0xD4
    call _out_port_byte
    ; ACK 체크

    mov ecx, 0xFFFF
.L1:
    call _IHTMouseInputBufferFull
    ; 커멘드 전송 체크
    test eax, eax
    jz .EL1

    loop .L1
.EL1:
    mov dl, 0x60
    mov al, 0xF4
    call _out_port_byte
    ; 마우스 활성화 코드 전송

    .mus_ack_loop:
        mov ecx, 100
        push ecx
        ; 카운터값 저장

        ; 입력버퍼에 데이터의 존재여부 확인
        ; 추후 함수화 하는것이 좋을 것 같다.
        mov ecx, 0xFFFF
        .L2:
            call _IHTMouseOutputBufferFull
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

        loop .mus_ack_loop
        ; 다른 키가 입력 될 수 있으니 최대 100개 까지의 입력을 체크

.error:
    mov eax, 0x00
    jmp .end
.success:
    mov eax, 0x01
    call _IHTMouseEnableInterrupt
    ; 마우스 인터럽트 활성화

.end:
    sti
    pop ecx
    pop edx
    ret

; 마우스 인터럽트 활성화 함수
_IHTMouseEnableInterrupt:
    pusha

    mov dl, 0x64
    mov al, 0x20
    call _out_port_byte
    ; 키보드의 커멘드 바이트 읽기
    mov ecx, 0xFFFF
.L1:
    call _IHTMouseOutputBufferFull
    ; 커멘드 전송 체크
    test eax, eax
    jnz .EL1

    loop .L1
.EL1:

    mov dl, 0x60
    call _in_port_byte

    or al, 0x02
    ; 마우스 인터럽트 활성화 비트 셋팅
    mov dh, al
    ; 데이터 백업

    mov dl, 0x64
    mov al, 0x60
    call _out_port_byte
    ; 키보드의 커멘드 바이트 쓰기
    mov ecx, 0xFFFF
.L2:
    call _IHTMouseInputBufferFull
    ; 커멘드 전송 체크
    test eax, eax
    jz .EL2

    loop .L2
.EL2:

    mov dl, 0x60
    mov al, dh
    call _out_port_byte
    ; 마우스 인터럽트가 1로 셋팅된 값을 전송

    popa
    ret

; Output Buffer에 데이터가 존재하는지 체크
_IHTMouseOutputBufferFull:
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
_IHTMouseInputBufferFull:
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

; 마우스 디바이스 핸들러 함수
_IHTMouseHandler:
    xor eax, eax

    mov dl, 0x64
    call _in_port_byte
    ; 상태 데이터 저장
    mov dh, al

    mov dl, 0x60
    call _in_port_byte

    test dh, 0x20
    jz .end
    ; 마우스 데이터 인지 체크

    push 22
    push 0
    call _print32_gotoxy

    push 0x07
    push MouseCodeMessage
    call _print32

    push 22
    push 17
    push eax
    call _print_hex32
.end:
    ret

MouseCodeMessage db 'MouseCode Number : ', 0
