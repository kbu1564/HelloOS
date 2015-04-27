; 마우스의 경우 키보드와 동일한 특수 목적 레지스터를 사용한다.
;
; 마우스 디바이스 활성화 함수
_IHTMouseInitialize:
    pusha
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
    popa
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
    pusha
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

    ;----------------------------------------------------
    ; 데이터 처리
    ;----------------------------------------------------
    push dword [MouseDataQueue]
    push eax
    call _queue_push

    ; 후처리
    inc byte [MousePositionCount]
    cmp byte [MousePositionCount], 3
    jne .end
    ; 3바이트가 모여서 하나의 패킷이 완성된다

    ;--------------------------------------------------
    ; Mouse input data
    ;--------------------------------------------------
    ; 참고 : http://wiki.osdev.org/Mouse_Input
    ;--------------------------------------------------

    push dword [MouseDataQueue]
    call _queue_pop
    ; 마우스 상태값
    mov edx, eax
    ; 상태값 백업

    mov byte [MouseLeftButtonDown], 0x00
    mov byte [MouseRightButtonDown], 0x00
    ; 상태값 초기화
.left_btn_check:
    test edx, 0x01
    jz .right_btn_check

    mov byte [MouseLeftButtonDown], 0x01
    ; left button 상태 표시
.right_btn_check:
    test edx, 0x02
    jz .xsigned_check

    mov byte [MouseRightButtonDown], 0x01
    ; right button 상태 표시

.xsigned_check:
    push dword [MouseDataQueue]
    call _queue_pop
    ; x 좌표값
    and eax, 0xFF

    test edx, 0x10
    ; x 음수 체크
    jz .xsigned

    ; 음수 일 경우 수행되는 코드
    mov ecx, eax
    mov eax, 256
    sub eax, ecx

    sub word [MousePaintPosition.x], ax
    ; x 좌표 셋팅

    jmp .ysigned_check
.xsigned:
    ; 양수 일 경우 수행되는 코드
    add word [MousePaintPosition.x], ax
    ; x 좌표 셋팅

.ysigned_check:
    push dword [MouseDataQueue]
    call _queue_pop
    ; y 좌표값
    and eax, 0xFF

    test edx, 0x20
    ; y 음수 체크
    jz .ysigned

    ; 음수 일 경우 수행되는 코드
    mov ecx, eax
    mov eax, 256
    sub eax, ecx

    add word [MousePaintPosition.y], ax
    ; y 좌표 셋팅

    jmp .draw_cursor
.ysigned:
    ; 양수 일 경우 수행되는 코드
    sub word [MousePaintPosition.y], ax
    ; y 좌표 셋팅

    ;--------------------------------------------------
    ; 2015-04-27
    ; 아직 x축에 대한 처리가 완벽하지 않음
    ;--------------------------------------------------
    ; 마우스가 화면 영역 밖으로 넘어가지 않도록 처리
    ; 최상위 비트가 1인경우 음수로 간주한다.
.outside_x:
; x좌표 처리
    cmp word [MousePaintPosition.x], 0x8000
    ja .draw_outside_x
    jmp .outside_y
.draw_outside_x:
    mov word [MousePaintPosition.x], 0

.outside_y:
; y좌표 처리
    cmp word [MousePaintPosition.y], 0x8000
    ja .draw_outside_y
    jmp .draw_cursor
.draw_outside_y:
    mov word [MousePaintPosition.y], 0

.draw_cursor:
    xor eax, eax
    mov ax, word [MouseClearPosition.y]
    push eax
    mov ax, word [MouseClearPosition.x]
    push eax
    push 0xFFFFFF
    push cursor.default
    call _draw_cursor
    ; 이전 위치 그리기 정보 제거

    xor eax, eax
    mov ax, word [MousePaintPosition.y]
    push eax
    mov ax, word [MousePaintPosition.x]
    push eax
    push 0x000000
    push cursor.default
    call _draw_cursor
    ; 새로운 위치에 마우스 그리기

    ; 좌표 백업
    mov ax, word [MousePaintPosition.x]
    mov word [MouseClearPosition.x], ax
    mov ax, word [MousePaintPosition.y]
    mov word [MouseClearPosition.y], ax

    mov byte [MousePositionCount], 0
    ; 패킷 체크용 변수 초기화
.end:
    popa
    ret

; 디버깅용 메시지
MouseLeftButtonDown  db 0x00
MouseRightButtonDown db 0x00
; 마우스 디바이스 드라이버 관련 주요 변수
MouseDataQueue       dd 0x00804000
MousePositionCount   db 0x00

MouseClearPosition:
; 움직이기 바로 직전 좌표
          .x  dw 0x0000
          .y  dw 0x0000
MousePaintPosition:
; 움직인 좌표
          .x  dw 0x0000
          .y  dw 0x0000
