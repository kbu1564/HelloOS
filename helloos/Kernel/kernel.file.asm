; 파일 관련 Kernel API

; Bios Parameter Block
SectorsPerCluster	 equ 0x7C03 + 10
ReservedSectors		 equ 0x7C03 + 11
TotalFATs			 equ 0x7C03 + 13
BigSectorsPerFAT	 equ 0x7C03 + 33
BootDiskNumber		 equ 0x7C03 + 61
ClusterBinaryData	 equ 0x4000
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
    mov word [DiskAddressPacket], 0x0010
    mov word [DiskAddressPacket + 2], cx
    ; 읽어들일 섹터 수 : 1 cluster
    mov word [DiskAddressPacket + 4], ClusterBinaryData
    mov word [DiskAddressPacket + 6], 0
    ; 읽은 데이터를 올릴 메모리 위치
    mov dword [DiskAddressPacket + 8], eax
    ; 읽을 섹터의 위치

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

	mov byte [bp + nLongEntry], al
	; si = al * 0x20
	mov cl, 0x20
	mul cl
	mov si, di
	add si, ax

    ; 최근 발견 위치 저장
    mov word [pTempFileEntry], si

	xor cx, cx
	mov cl, byte [bp + nLongEntry]
	xor ax, ax

	mov word [bp + nLongEntry], si
	push bp
	; LFE 다음 Entry Offset 저장
	.lname:
		sub si, 0x20

		mov di, si
		mov ax, 5
		.L1:
			mov dx, word [di + FirstLongFileName]
			mov word [bp + szFileName], dx

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
			mov byte [bp + szFileName], dl

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
			mov byte [bp + szFileName], dl

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
    add di, szFileName
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
    add di, szFileName

    ; 인자로 보낸 파일명과 일치하는 파일이 존재하는지 체크
    mov si, word [szSearachFileName]
    call _strcmp
    ; 이 비교 루틴이 정상 작동 안한다!!!

    ; 검색하려는 파일이 존재하지 않은 경우 다음 영역 검색
    test ax, ax
    jnz .notfound
.search_data:
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

    mov dx, word [pLoadAddress]
    mov word [DiskAddressPacket + 4], dx
    ; 읽은 데이터를 올릴 data 메모리 위치

    mov dx, word [pLoadAddress + 2]
    mov word [DiskAddressPacket + 6], dx
    ; 읽은 데이터를 올릴 segment 메모리 위치

    ; segment init
    xor ax, ax
    mov ds, ax

    mov si, DiskAddressPacket
    mov ah, 0x42
    mov dl, byte [BootDiskNumber]
    int 0x13
    ; 2014.10.24 - 알수 없는 문제 발생!!
    ; DAP 에는 문제 없지만 int 0x13에서 읽히지 않음
    jnc .find_to_end

    ; 만약 이 주석부분으로 제어가 넘어온다면
    ; 데이터 로드에 실패한 것이다.
.notfound:
    ; 찾고자 하는 파일명이 아닐 경우 이 위치로 바로 jmp
    pop di
.next:
    ; 다음 파일 엔트리 검색
    add di, 0x20
    jmp .read
.find_to_end:
    ; 파일의 데이터를 발견한 경우 종료
    pop di
.error_or_end:
    ; 오류 혹은 기타 상황에 의해 종료
    popa
	pop bp
    retn 4
