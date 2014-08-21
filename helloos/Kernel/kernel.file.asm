; 파일 관련 Kernel API
; si : 확장자를 제외한 라이브러리 파일 이름 OffsetAddress
SectorsPerCluster equ 0x7C03 + 10
ReservedSectors   equ 0x7C03 + 11
TotalFATs         equ 0x7C03 + 13
BigSectorsPerFAT  equ 0x7C03 + 33
BootDiskNumber    equ 0x7C03 + 61
ClusterBinaryData equ 0x4000
DiskAddressPacket equ 0x5000

_load_library:
    szFileName    equ 10
    szFileExt     equ 265
    pusha

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
    mov dx, 0x0016
    mov word [DiskAddressPacket], dx
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
    cmp byte [di], 0xE5
    jne .find

    add di, 0x20
    jmp .read
.find:
; 유효한 파일 발견
    push di
    ; 최근 발견 위치 저장

    mov cx, 8
    mov si, di
    mov di, sp
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

    mov di, sp
    add di, szFileName

    push bx
    push 0x07
    push di
    call _print
    ; 구한 파일명 출력
    inc bx

    pop di
    add di, 0x20

    jmp .read
.error_or_end:
    jmp $

    popa
    ret

; use this!!
; mov cx, 8
; mov si, srcString
; mov di, dstString
; call _back_trim
; srcString 주소를 기준으로 8만큼의 크기의 문자의 뒷쪽
; 공백을 제거한 뒤, dstString 주소를 기준으로 뒷쪽 공백이 제거된 문자열이 저장됩니다.
; 공백이 제거된 문자열의 길이값이 ax register에 저장되어 리턴됩니다.
; 해당 함수는 공백을 제거한뒤 문자열 맨 마지막에 NULL 문자를 삽입합니다.
_back_trim:
    push si
    push di
    push cx
    push dx

    xor dx, dx
    ; 뒷부분 공백을 제거
    add si, cx
    dec si
    ; void* src
    add di, cx
    dec di
    ; void* dst
    mov byte [di + 1], 0
.copy:
    mov al, byte [si]
    mov byte [di], 0

    cmp al, 0x20
    je .copy_end

    inc dx
    mov byte [di], al
.copy_end:
    dec di
    dec si
    loop .copy

    mov ax, dx
    pop dx
    pop cx
    pop di
    pop si
    ret
