[bits	16]
[org	0x7C00]

jmp _entry
nop

; USB 용량별 BPB 종류
%include "loader.fat32.8GB.asm"
;%include "loader.fat32.16GB.asm"

_entry:
	jmp _start
	%include "loader.print.asm"
	; 화면 출력용 함수
	;%include "loader.debug.dump.asm"
	; 디버깅 함수 소스파일
	; 소스의 길이가 커널을 로드하는 소스의 양과 비슷하여
	; Bootloader에서 사용하기엔 알맞지 않다.
	; 순수 디버깅 용도로만 사용할 경우 주석 해제후 내부 함수를 사용하면 된다.
	%include "loader.disk.asm"
	; 디스크로 부터 커널 파일을 로드하는 소스 파일
_start:
	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0xFFFF
	; 스택 초기화 루틴

	mov byte [BootDiskNumber], dl
	; 부팅 디스크 번호 저장

	push KernelFileName
	call _disk_load_kernel_data_to_memory
	; 부팅 장치로 부터 kernel 이라는 이름의 파일을
	; 커널정보로 인식하여 메모리로 데이터를 로드한다

	mov ax, word [DAPSegment]
	mov ds, ax
	mov di, word [DAPOffset]
	; 로드에 성공한 경우 커널 데이터 메모리 주소를 설정한다

	;jmp $
	; 현재위치 점프
	mov cl, byte [di + 2]
	cmp cl, 0x90
	jne .kernel_load_error
	; 올바른 커널 데이터 인지 체크
	
	; 커널데이터 위치로 점프
	jmp di

.kernel_load_error:
	push 0
	push 0x04
	push KernelLoadError
	call _print

.end_bootloader:
	hlt
	jmp .end_bootloader

KernelFileName:		db 'KERNEL  ', 'SYS', 0
; 로드할 커널 파일의 이름
; 확장자 포함
; Only 8byte(filename) + Only 3byte(확장자)
; Only Upper Case
; 공백은 space(0x20)으로 처리된다
; 확장자 포함 11글자보다 작은 커널 파일 이름인 경우 0 문자 까지와 일치하는
; 파일 명을 커널 파일로 인식

times 510 - ($ - $$)	db 0x00
dw 0xAA55
; Bootloader Signature
