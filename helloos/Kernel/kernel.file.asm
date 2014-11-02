; 파일 관련 Kernel API

; Bios Parameter Block
SectorsPerCluster	 equ 0x7C03 + 10
ReservedSectors		 equ 0x7C03 + 11
TotalFATs			 equ 0x7C03 + 13
BigSectorsPerFAT	 equ 0x7C03 + 33
BootDiskNumber		 equ 0x7C03 + 61
ClusterBinaryData	 equ 0x6000
DiskAddressPacket	 equ 0x5000
; File Allocation Table
FileName             equ 0x00
FilenameExtension    equ 0x08
FileFlag             equ 0x0B
Unused               equ 0x0C
HightStartingCluster equ 0x14
Time                 equ 0x16
Date                 equ 0x18
LowStartingCluster   equ 0x1A
FileSize             equ 0x1C
; Long FileName Entry
FirstLongFileName	 equ 0x01
SecondLongFileName	 equ 0x0E
ThirdLongFileName	 equ 0x1C

; push 찾고자 하는 파일 이름
_load_library:
    szFileName          equ 100
	nLongEntry	        equ 100 + 255
    pLoadAddress        equ 0x5100
    pTempFileEntry      equ 0x5110
    szSearachFileName   equ 0x5200
    ; 파일 이름과 확장자 이름은 최대 255자 까지 가능하다.
	push bp
	mov bp, sp
    pusha

    ;mov word [0x5310], es
    ;mov word [0x5312], ds
    ;mov word [0x5314], fs
    ;mov word [0x5316], gs
    ;mov word [0x5318], ss
    ;mov word [0x531a], ax
    ;mov word [0x531c], bx
    ;mov word [0x531e], cx
    ;mov word [0x5320], dx
    ;mov word [0x5322], si
    ;mov word [0x5324], di
    ;push 10
    ;push 0
    ;push 22
    ;push 0x5310
    ;call _print_byte_dump
    ;jmp $

    ;---------------------------------------
    ; function's parameters
    ;---------------------------------------
    ; 검색 대상 파일명
    mov dx, word [bp + 4]
    mov word [szSearachFileName], dx

    ; 검색에 성공하 경우 로드될 메모리 주소
    mov dx, word [bp + 6]
    mov word [pLoadAddress], dx
    ; data memory address
    mov dx, word [bp + 8]
    mov word [pLoadAddress + 2], dx
    ; segment address
    ;---------------------------------------

    xor eax, eax
    mov al, byte [TotalFATs]
    ; FAT 의 개수 구하기

    ;-----------------------------------------------------------------------------------
    ; Root Directory Entry 시작 Sector 계산
    ; RootDirectoryEntry Sector = 예약된섹터 수 + FAT의 크기(Sector 단위) * FAT의 개수
    ;-----------------------------------------------------------------------------------
    mov edx, dword [BigSectorsPerFAT]
    mul edx
    ; FAT 의 크기 계산

    xor edx, edx
    mov dx, word [ReservedSectors]
    ; FAT 의 시작 위치 계산
    add eax, edx

    xor cx, cx
    mov cl, byte [SectorsPerCluster]
    ; 1클러스터 당 섹터 수

    ; RootDirectoryEntry는 1클러스터 단위로 존재
    mov word [DiskAddressPacket], 16
    ; 64bit 주소까지 
    mov word [DiskAddressPacket + 2], cx
    ; 읽어들일 섹터 수 : 1 cluster
    mov word [DiskAddressPacket + 4], ClusterBinaryData
    mov word [DiskAddressPacket + 6], 0
    ; 읽은 데이터를 올릴 메모리 위치
    mov dword [DiskAddressPacket + 8], eax
    ; 읽을 섹터의 위치

    xor ax, ax
    mov si, DiskAddressPacket
    mov ah, 0x42
    mov dl, byte [BootDiskNumber]
    int 0x13
    jc .error_or_end

    mov di, ClusterBinaryData
.read:
    cmp di, ClusterBinaryData + 0x1000
    jae .error_or_end

    ; 삭제된 파일인지 체크
    cmp byte [di + FileName], 0xE5
    je .next
    ; 파일 명의 맨 처음 1바이트가 0xE5 or 0x00 인 경우 사용하지 않는 File Entry
    cmp byte [di + FileName], 0x00
    je .next

    jmp .find
.long:
	xor ax, ax
    ; 긴 파일 이름 얻기
	mov bp, sp

    mov al, byte [di + FileName]
    test al, 0x40
	jz .lname
	; LFE 개수 얻기
	and al, 10111111b
	; When the data of seventh bit on first bytes is set,
	; it is last entry of LFE(Long File Name Entry).
	; LFE의 첫번째 바이트에서 7번째 비트가 1 인 경우
	; LFE의 마지막 엔트리이다.

	mov byte [bp - nLongEntry], al
	; si = al * 0x20
	mov cl, 0x20
	mul cl
	mov si, di
	add si, ax

    ; 최근 발견 위치 저장
    mov word [pTempFileEntry], si

	xor cx, cx
	mov cl, byte [bp - nLongEntry]
	xor ax, ax

	mov word [bp - nLongEntry], si
	push bp
	; LFE 다음 Entry Offset 저장

    ; 여기에서의 인터럽트는 작동을 잘한다..
    ; 그럼 아래에서 무언가가 0x0000 ~ 0x03ff 번지에 영향을 끼친다는 소리가 된다.

	.lname:
		sub si, 0x20

		mov di, si
		mov ax, 5
		.L1:
			mov dx, word [di + FirstLongFileName]
			mov word [bp - szFileName], dx

			cmp dx, 0xFFFF
			je .ENDL1

			add di, 2
			add bp, 1

			dec ax
			test ax, ax
			jnz .L1
		.ENDL1:

		mov di, si
		mov ax, 6
		.L2:
			mov dx, word [di + SecondLongFileName]
			mov byte [bp - szFileName], dl

			cmp dx, 0xFFFF
			je .ENDL2

			add di, 2
			add bp, 1

			dec ax
			test ax, ax
			jnz .L2
		.ENDL2:

		mov di, si
		mov ax, 2
		.L3:
			mov dx, word [di + ThirdLongFileName]
			mov byte [bp - szFileName], dl

			cmp dx, 0xFFFF
			je .ENDL3

			add di, 2
			add bp, 1

			dec ax
			test ax, ax
			jnz .L3
		.ENDL3:

		loop .lname

	pop bp
    ; 이 시점을 기준으로 인터럽트의 작동이 비정상 적으로 변한다.
    ; 의심되는 부분은 스택 메모리 부분이다.
    ;
    ; 해결 완료!!
    ; 문제는 위의 소스 코드에서 real mode idt 부분의 메모리를 참조하는 것에 있었다.

	pop di
	push word [bp + nLongEntry]

    jmp .print
.find:
; 유효한 파일 발견
    push di
    ; 최근 발견 위치 저장
    mov word [pTempFileEntry], di

	xor ax, ax
    mov ah, byte [di + FileFlag]
    test ah, 0x0F
    jnz .long
    ; 긴 이름의 파일 체크
    ;
    ; 파일 Flag 값의 3번째 비트의 값이 1이면
    ; 긴파일 이름

	mov cx, 8
    mov si, di
    mov di, bp
    sub di, szFileName
    call _back_trim

    add di, ax
    mov byte [di], 0x2E
    mov byte [di + 1], 0
    inc di
    ; `.`을 기준으로 파일명과 확장자가 나뉘므로
    ; `.`를 추가

    mov cx, 3
    add si, 8
    call _back_trim
.print:
    mov di, bp
    sub di, szFileName

    ; 인자로 보낸 파일명과 일치하는 파일이 존재하는지 체크
    mov si, word [szSearachFileName]
    call _strcmp
    ; 함수 작동 루틴 수정 완료
    ; 2014.10.23 - 정상 작동

    ; 검색하려는 파일이 존재하지 않은 경우 다음 영역 검색
    test ax, ax
    jnz .notfound
.search_data:
    pop di
    ; 찾고자 하는 파일인 경우
    ; 해당 파일을 발견 하였으므로 원하는 처리를 수행한다.
    ; push bx
    ; push 0x07
    ; push di
    ; call _print
    ; inc bx
    mov di, word [pTempFileEntry]

    ; 구한 파일의 데이터 영역 계산
    ; 파일 데이터 섹터 = RootDirectoryEntry 시작 섹터 + 파일 클러스터 번호 * 8sector(1cluster)
    xor eax, eax
    mov ax, word [di + HightStartingCluster]
    shl ax, 16
    add ax, word [di + LowStartingCluster]
    sub ax, 2
    ; RootDirectoryEntry가 2 Cluster 이므로 2를 빼준다
    ; eax = Cluster Number
    xor cx, cx
    mov cl, byte [SectorsPerCluster]
    mul cx
    ; eax = 파일 클러스터 번호 * 8sector(1cluster)
    add eax, dword [DiskAddressPacket + 8]
    ; 파일 데이터 섹터
    mov dword [DiskAddressPacket + 8], eax
    ; 읽을 섹터의 위치

    ;------------------------------------------------
    ; 추후 이 부분을 파일 데이터
    ; 용량에 알맞게 읽어들이도록 수정해야함
    ;------------------------------------------------
    mov word [DiskAddressPacket + 2], 8
    ; 읽어들일 섹터 수 : 1 cluster(임시)
    ;------------------------------------------------

    ;mov dx, word [pLoadAddress]
    ;mov word [DiskAddressPacket + 4], dx
    ; 읽은 데이터를 올릴 data 메모리 위치

    ;mov dx, word [pLoadAddress + 2]
    ;mov word [DiskAddressPacket + 6], dx
    ; 읽은 데이터를 올릴 segment 메모리 위치

    ;-----------------------------------------------
    mov edx, dword [pLoadAddress]
    mov dword [DiskAddressPacket + 4], edx
    ; 읽은 데이터를 올릴 data 메모리 위치
    ; word 단위로 2번쪼개서 넣는거랑 위 구문이랑 같다.
    ;-----------------------------------------------

    xor eax, eax
    mov si, DiskAddressPacket
    mov ah, 0x42
    mov dl, byte [BootDiskNumber]
    int 0x13
    ; 2014.10.24 - 알수 없는 문제 발생!!
    ; DAP 에는 문제 없지만 int 0x13에서 읽히지 않음
    ; 2014.11.02 - 해결!!
    ; C에서는 로컬변수의 경우 스택공간에 빼는 형식으로 구현되는데 이를 더함으로써
    ; Overflow가 되면서 0번지를 참조하게 되는 문제점이 존재 하였다.

    jnc .error_or_end
    ; 2014.10.24 1) StackPointer 상의 문제는 없는것 같음
    ; 2014.10.25 2) 함수 초기 부분에 int 0x10 호출후에
    ;               함수의 정지현상은 멈추었지만 올바른 작동X
    ; 2014.11.02 3) 이 부분에서는 다른 인터럽트도 작동이 되지 않는다.
    ;               flags register를 점검하여 IF 플래그를 체크하였지만 정상
    ; 해결 완료!!
    ; 원인 : Real Mode 에서의 IDT는 0 ~ 0x3ff 까지이다.
    ;        또한 스택에 값을 저장할 시 초기값이 0xffff 인 상태임에도 불구하고
    ;        100이상의 크기를 요구하는 local variables 의 메모리 위치를 더함으로써
    ;        Overflow 가 발생하여 스택공간이 0 번지를 참조함으로써 최종적으로 IDT를 수정
    ;        하게 되는 것 이였다.

    ; 만약 이 주석부분으로 제어가 넘어온다면
    ; 데이터 로드에 실패한 것이다.
.notfound:
    ; 찾고자 하는 파일명이 아닐 경우 이 위치로 바로 jmp
    pop di
.next:
    ; 다음 파일 엔트리 검색
    add di, 0x20
    jmp .read
.error_or_end:
    ; 오류 혹은 기타 상황에 의해 종료
    popa
	pop bp
    retn 4
