;--------------------------------------------------------
; Global Descriptor Table
;--------------------------------------------------------
gdtr:
	dw gdtEnd - gdt - 1	; GDT Table 전체 Size
	dd gdt				; GDT Table 의 실제 시작 주소
gdt:
	NullDescriptor equ 0x00
		dd 0, 0

	CodeDescriptor equ 0x08
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10011010b
		db 11001111b
		db 0x00

	DataDescriptor equ 0x10
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10010010b	; P DPL S TYPE
		db 11001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00

	VideoDescriptor equ 0x18
	; 비디오 세그먼트
		dw 0xFFFF
		dw 0x8000
		db 0x0B
		db 10010010b	; P DPL S TYPE
		db 01001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00

	VGADescriptor equ 0x20
	; 그래픽(VGA) 세그먼트
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 10010010b	; P DPL S TYPE
		db 11001111b	; G D/B L AVL SEGMENT_SIZE
		db 0x00
gdtEnd:
;-------------------------------------------------------------------
; {{Descriptor Description}}
;
; dw 0xFFFF
; [SEGMENT SIZE]
; 1111 1111 1111 1111
; 이 부분의 값과 아래 SEGMENT SIZE 의 4bit 값을 합하여
; 총 20bit로 세그먼트의 크기를 나타낸다
; [G] : 0 -> 0 byte ~ 1 Mbyte
; [G] : 1 -> 0 byte ~ 4 Gbyte ( * 4 Kbyte)

; dw 0x0000
; 기준주소 하위 16 bit

; db 0x00
; 기준주소 상위 8 bit

; db 10011010b
; [P] [DPL] [S] [TYPE]
;  1   00    1   1 010
; 유효 / 슈퍼권한 / 세그먼트 / 코드:실행,읽기

; db 11001111b
; [G] [D/B] [L] [AVL] [SEGMENT SIZE]
;  1    1    0    0        1111
; [G] : 주소 범위를 0 ~ 4 Gbyte까지 확장
; [D/B] : 32 bit Segment
; [AVL] : 64 bit Mode 에서 32 bit 호환 Segment 임을 의미
; [SEGMENT SIZE] : 세그먼트 크기의 상위 4 bit

; db 0x00
; 기준 주소 최상위 8 bit
;-------------------------------------------------------------------
