; I/O Port 함수
;
; o port byte
_out_port_byte:
	out dx, al
	ret

; o port word
_out_port_word:
	out dx, ax
	ret

; i port byte
_in_port_byte:
	in al, dx
	ret

; i port word
_in_port_word:
	in ax, dx
	ret

; PIC 관련 Master와 Slave를 초기화 셋팅하는 함수
_init_pic:
	mov dl, 0x20
	mov al, 0x11
	call _out_port_byte
	; LTIM : 0, SNGL : 0, IC4 : 1
	mov dl, 0x21
	mov al, 0x20
	call _out_port_byte
	; 0 ~ 31은 시스템에서 예외 처리에 사용하려 예약된 벡터 이므로
	; 32번 이후 부터 등록
	mov dl, 0x21
	mov al, 0x04
	call _out_port_byte
	; 슬레이브 컨트롤러 -> 마스터 컨트롤러 PIC 2번에 연결
	mov dl, 0x21
	mov al, 0x01
	call _out_port_byte
	; uPM : 1

	mov dl, 0xA0
	mov al, 0x11
	call _out_port_byte
	; LTIM : 0, SNGL : 0, IC4 : 1
	mov dl, 0xA1
	mov al, 0x20 + 8
	call _out_port_byte
	; 인터럽트 백터를 40번부터 할당
	mov dl, 0xA1
	mov al, 0x02
	call _out_port_byte
	; 슬레이브 컨트롤러 -> 마스터 컨트롤러 PIC 2번에 연결
	mov dl, 0xA1
	mov al, 0x01
	call _out_port_byte
	; uPM : 1
	ret

; 특정 인터럽트를 발생시키지 않도록 셋팅하는 함수
; eax : maks_int_num
_mask_pic:
	mov dl, 0x21
	call _out_port_byte
	; IRQ 0 ~ IRQ 7 까지 마스크 셋팅
	; 해당 비트에 1이 셋팅된 경우 인터럽트가 호출되지 않는다.
	; Master PIC

	shr ax, 8
	mov dl, 0xA1
	call _out_port_byte
	; IRQ 8 ~ IRQ 15
	; Slave PIC
	ret

; EOI 처리용 함수
; eoi : end of interrupt
; void send_eoi_to_pic(int eoi_int_num);
_send_eoi_to_pic:
	push ebp
	mov ebp, esp
	pusha

	mov eax, dword [ebp+8]

	mov dl, 0x20
	mov al, 0x20
	call _out_port_byte
	; Master PIC에게 EOI 전송

	cmp eax, 8
	jb .end
	; IRQ 번호가 8이상일 경우 슬레이브 PIC 인터럽트 이므로 슬레이브 PIC에게도
	; EOI 전송

	mov dl, 0xA0
	mov al, 0x20
	call _out_port_byte
	; Master PIC에게 EOI 전송
.end:
	popa
	mov esp, ebp
	pop ebp
	ret 4
