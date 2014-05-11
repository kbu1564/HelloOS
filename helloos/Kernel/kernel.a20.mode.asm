; 1MB 이상의 메모리 영역에 접근하기 위해
; A20 기능을 On 하여 20번째 비트를 사용한다.
_set_a20_mode:
	call _wait_to_buffer_cpu
	; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.
	
	mov dx, 0x64
	mov al, 0xD0
	out dx, al
	; 0x64 port의 값을 0x60 레지스터에 기록한다.
	; 추후 0xD1 명령을 통해 이 레지스터의 값을 사용할 수 있다.

	mov dx, 0x60
	in al, dx
	or al, 0x02
	; enable A20
	; 0x60 포트의 값으로 부터 값을 읽은 뒤 2번째 비트를 1로 셋팅하는 것으로
	; A20 기능을 작동 시킬 수 있다.
	mov ah, al
	; A20 데이터 임시 저장

	call _wait_to_buffer_cpu
	; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.

	mov dx, 0x64
	mov al, 0xD1
	out dx, al
	; 실제 out port에 적용 되는것은 이 명령을 사용한 직후 0x60에 데이터를 썻을 경우에 적용된다.
	; 0x60에 저장된 값을 0x64 포트에 적용시킨다.
	; 이로 인해 윗 부분에서 A20을 사용하기 위해
	; 2번째 비트를 1로 셋팅한것을 0x64포트에 적용 시킬 수 있다.

	call _wait_to_buffer_cpu
	; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.

	mov dx, 0x60
	mov al, ah
	out dx, al
	; A20 기능에 관한 데이터를 실제로 0x64포트에 적용
	
	call _wait_to_buffer_cpu
	; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.
	ret

; CPU가 input buffer에 DATA를 사용하는 중인지
; 체크하여 사용중이 아닐때 까지 무한 대기 시킨다.
_wait_to_buffer_cpu:
.L1:
	mov dx, 0x64
	in al, dx
	test al, 0x20
	; 상태 레지스터로 부터 input buffer에 CPU Data가 존재하는지 체크
	; 체크는 0x60 포트로 부터 1byte 읽어들인 뒤 0x20와 and 연산을 통해 해당
	; 비트가 켜져있는지를 체크하는 방식으로 하면 된다.
	jnz .L1
	; CPU가 데이터사용을 끝낼때 까지 대기 시킨다.
	ret

; A20 기능의 정상 동작 여부를 확인하여 
; 작동이 불가능 한 경우 ax 값에 0 값을 반환 시키고
; 작동이 가능한 경우 ax 값에 1 값을 반환 시킨다.
;
; 또한 운영체제가 실행되는데 필요한 최소 64MB의 메모리가 여유공간으로
; 존재하는지를 함께 검사한다.
_kernel_is_enough_memory:
	; 0 ~ 64MB
	; 0 ~ 0x04000000 까지
	mov ax, DataDescriptor
	mov ds, ax

	; 모든 범위의 주소공간에 접근을 가능하도록 하기 위한
	; 데이터 디스크립트 설정

	; 만약 1MB 이상의 메모리에 접근이 불가능 한 상황이라면
	; 1MB 이상의 주소에 값을 대입후 다시 읽어 비교하게 되면
	; 다른 값이 나오게 된다.
	;
	; 이는 1MB 이상의 영역 접근 실패시 0x00000000 주소를 참조하기 때문이다.
	mov ecx, 63
	; 1 ~ 64MB 영역에 접근이 가능한지 체크한다.
	mov edi, 0x00100000
	; 시작 부분을 1MB 영역으로 잡는다
	mov ax, 1
	; 일단 리턴값을 성공값으로 셋팅
.a20_check_while:
	mov dword [ds:edi], 0x12345678
	cmp dword [ds:edi], 0x12345678
	jne .error
	; 오류 발생

	add edi, 0x00100000
	; 오류 발생하지 않은 경우 다음 1MB 영역을 검사
	loop .a20_check_while
	jmp .end
	; 오류 발생 안함
.error:
	mov ax, 0
	; 이 부분이 실행된 경우 A20 기능이 동작하지 않는 것 이므로
	; 0값을 리턴한다.
.end:
	ret
