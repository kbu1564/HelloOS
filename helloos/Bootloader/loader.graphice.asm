;-------------------------------------------------------
; VBE 존재 유무 체크
;-------------------------------------------------------
_get_vesa_version:
	mov cx, 0
	mov es, cx

	mov di, SuperVGAInfo
	mov ax, 0x4F00
	int 0x10
	; VBE 정보 / 존재 확인
	cmp ax, 0x004F
	jne .super_failure
	; 지원하지 않거나 상태정보 얻기에 실패한 경우

	mov ax, word [VersionNumber]
	; 버전 정보를 리턴
	jmp .end
.super_failure:
	xor ax, ax
.end:
	ret

;-------------------------------------------------------
; 화면 모드 지원 여부 및 정보 확인
;-------------------------------------------------------
_get_vesa_vga_info:
	mov di, VESASuperVGAInfo
	; 비디오 모드에 대한 정보를 얻기위한 구조체 주소 셋팅
	mov ax, 0x4F01
	; Support check
	int 0x10
	; VESA SuperVGA BIOS
	; Get SuperVGA Mode Information
	cmp ax, 0x004F
	jne .end
	; 지원하지 않거나 상태정보 얻기에 실패한 경우

	mov eax, dword [PhysBasePtr]
	mov word [si+2], ax
	shr eax, 16
	mov byte [si+4], al
	mov byte [si+7], ah
	; VGA memory Address Setting
	; VGA Descriptor 기준 주소 셋팅

	jmp .end
.error:
	mov word [si+2], 0
	mov byte [si+4], 0
	mov byte [si+7], 0
.end:
	ret

;-------------------------------------------------------
; 화면 모드 전환
;-------------------------------------------------------
_set_vesa_vga_mode:
	mov ax, 0x4F02
	; 그래픽 모드로 전환
	mov bx, cx
	int 0x10
	ret

; 해상도에 따른 모드값을 자동으로 검색하여 전환하는 함수
; si 값으로 구하고자 하는 해상도에 대한 정보가 담긴 구조체의 포인터 주소를 인자로 받는다.
;
; VirtualBox, VMWare, Machine 이 3가지 전부 그래픽 화면 모드의 값이 가지각색이므로
; 공통 부분을 제외한 나머지 모드값을 하나씩 증가시키면서 확인 후 일치 할 경우 모드를 전환 시킨다.
_auto_resolution_vesa_mode:
	;-------------------------------------------------------
	; VBE 존재 유무 체크
	;-------------------------------------------------------
	call _get_vesa_version
	; 버전 정보를 얻은 경우 ax 값에 해당 버전에 대한 값이 리턴
	; 지원하지 않거나 상태정보 얻기에 실패한 경우
	cmp ax, 0x0200
	jb .super_failure

	mov cx, 0x4100
	; 640*400,8bit LFB부터 검색 시작
.loop:
	;-------------------------------------------------------
	; 화면 모드 지원 여부 및 정보 확인
	;-------------------------------------------------------
	mov si, gdtr + 6 + VGADescriptor
	call _get_vesa_vga_info
	; 화면 모드 지원 여부 및 정보를 확인 후 성공한 경우
	; VGA 디스크립터 테이블에 메모리 기준주소를 업데이트 한다.
	inc cx
	; 찾고자 하는 해상도와 색상값이 아닌경우 다음 모드값을
	; 체크하기 위해 화면모드 값을 1 증가 시킨다.

	mov ax, word [VesaResolutionInfo.XResolution]
	cmp word [XResolution], ax
	jne .loop
	mov ax, word [VesaResolutionInfo.YResolution]
	cmp word [YResolution], ax
	jne .loop
	mov al, byte [VesaResolutionInfo.BitsPerPixel]
	cmp byte [BitsPerPixel], al
	jne .loop
	; 해상도, 색상값 일치여부 확인

	;-------------------------------------------------------
	; 화면 모드 전환
	;-------------------------------------------------------
	call _set_vesa_vga_mode
	; 그래픽 모드로 전환
	cmp ax, 0x004F
	jne .loop
	; 원하는 모드값을 찾은 경우
	; 화면모드 전환

	mov ax, 0x4F06
	xor bx, bx
	mov cx, word [VesaResolutionInfo.XResolution]
	int 0x10
	; 스캔 라인 길이(폭) 설정

	mov ax, 0x4F07
	xor bx, bx
	xor cx, cx
	xor dx, dx
	int 0x10
	; 디스플레이 스타트 설정

	jmp .end
.super_failure:
	push 1
	push 0x04
	push NotSuperVideoModeMessage
	call _print
	; VBE 2.0 이상 지원하지 않는 경우
.end:
	ret

VesaResolutionInfo:
; 그래픽 모드 전환시 셋팅될 해상도 정보 구조체
	.XResolution:	dw 0
	.YResolution:	dw 0
	.BitsPerPixel:	db 0

SuperVGAInfo					equ 0x8000
	Signature					equ SuperVGAInfo + 00h
	VersionNumber				equ SuperVGAInfo + 04h
	PointerToOEMName			equ SuperVGAInfo + 06h
	CapabilitiesFlags			equ SuperVGAInfo + 0Ah
	OEMVideoModes				equ SuperVGAInfo + 0Eh
	TotalAmount					equ SuperVGAInfo + 12h
	; VBE v1.x

	OEMVersion					equ SuperVGAInfo + 14h
	PointerToVendorName			equ SuperVGAInfo + 16h
	PointerToProductName		equ SuperVGAInfo + 1Ah
	PointerToProductRevision	equ SuperVGAInfo + 1Eh
	VBEversion					equ SuperVGAInfo + 22h
	SupportedVideoModes			equ SuperVGAInfo + 24h
	;times 216	db 0
	; 216bytes reserved for VBE implementation
	;times 256	db 0
	; 256bytes OEM scratchpad
	; VBE v2.0

VESASuperVGAInfo				equ 0x8200
	ModeAttributes				equ VESASuperVGAInfo + 00h
	WinAttributesA				equ VESASuperVGAInfo + 02h
	WinAttributesB				equ VESASuperVGAInfo + 03h
	WinGranularity				equ VESASuperVGAInfo + 04h
	WinSize						equ VESASuperVGAInfo + 06h
	WinSegmentA					equ VESASuperVGAInfo + 08h
	WinSegmentB					equ VESASuperVGAInfo + 0Ah
	WinFuncPtr					equ VESASuperVGAInfo + 0Ch
	BytesPerScanLine			equ VESASuperVGAInfo + 10h
	; All VBE revisions

	XResolution					equ VESASuperVGAInfo + 12h
	YResolution					equ VESASuperVGAInfo + 14h
	XCharSize					equ VESASuperVGAInfo + 16h
	YCharSize					equ VESASuperVGAInfo + 17h
	NumberOfPlanes				equ VESASuperVGAInfo + 18h
	BitsPerPixel				equ VESASuperVGAInfo + 19h
	NumberOfBanks				equ VESASuperVGAInfo + 1Ah
	MemoryModel					equ VESASuperVGAInfo + 1Bh
	BankSize					equ VESASuperVGAInfo + 1Ch
	NumberOfImagePages			equ VESASuperVGAInfo + 1Dh
	Reserved0					equ VESASuperVGAInfo + 1Eh
	; VBE 1.2 and above

	RedMaskSize					equ VESASuperVGAInfo + 1Fh
	RedFieldPosition			equ VESASuperVGAInfo + 20h
	GreenMaskSize				equ VESASuperVGAInfo + 21h
	GreenFieldPosition			equ VESASuperVGAInfo + 22h
	BlueMaskSize				equ VESASuperVGAInfo + 23h
	BlueFieldPosition			equ VESASuperVGAInfo + 24h
	RsvdMaskSize				equ VESASuperVGAInfo + 25h
	RsvdFieldPosition			equ VESASuperVGAInfo + 26h
	DirectColorModeInfo			equ VESASuperVGAInfo + 27h
	; Direct color fields

	PhysBasePtr					equ VESASuperVGAInfo + 28h
	Reserved1					equ VESASuperVGAInfo + 2Ch
	Reserved2					equ VESASuperVGAInfo + 30h
	; VBE 2.0 and above

	LinBytesPerScanLine			equ VESASuperVGAInfo + 32h
	BnkNumberOfImagePages		equ VESASuperVGAInfo + 34h
	LinNumberOfImagePages		equ VESASuperVGAInfo + 35h
	LinRedMaskSize				equ VESASuperVGAInfo + 36h
	LinRedFieldPosition			equ VESASuperVGAInfo + 37h
	LinGreenMaskSize			equ VESASuperVGAInfo + 38h
	LinGreenFieldPosition		equ VESASuperVGAInfo + 39h
	LinBlueMaskSize				equ VESASuperVGAInfo + 3Ah
	LinBlueFieldPosition		equ VESASuperVGAInfo + 3Bh
	LinRsvdMaskSize				equ VESASuperVGAInfo + 3Ch
	LinRsvdFieldPosition		equ VESASuperVGAInfo + 3Dh
	MaxPixelClock				equ VESASuperVGAInfo + 3Eh
	; VBE 3.0 and above

	Reserved3					equ VESASuperVGAInfo + 42h
	; 190bytes remainder of ModelInfoBlock
