; CD는 1 sector = 2048 byte
; System Area = 16 sector
; CD Signature = CD001
_disk_load_kernel_data_to_memory:
    push bp
    mov bp, sp
    pusha

    xor eax, eax
    mov es, ax
    mov al, byte [TotalFATs]
    ; FAT 의 개수 구하기

    ;-----------------------------------------------------------------------------------
    ; Root Directory Entry 시작 Sector 계산
    ; RootDirectoryEntry Sector = 예약된섹터 수+FAT의 크기(Sector 단위) * FAT의 개수
    ;-----------------------------------------------------------------------------------
    mov edx, dword [BigSectorsPerFAT]
    mul edx
    ; FAT 의 크기 계산

    xor edx, edx
    mov dx, word [ReservedSectors]
    ; FAT 의 시작 위치 계산
    add eax, edx
    ; RootDirectory 의 시작 위치 계산
    mov dword [DAPReadSector], eax
    ;-----------------------------------------------------------------------------------

    mov si, DAP
    mov ah, 0x42
    mov dl, byte [BootDiskNumber]
    int 0x13
    jc .end
    ; 오류 발생한 경우 함수 종료
    ; 오류 없이 성공적으로 섹터 읽기에 성공한 경우
.success:
    ; 읽기에 성공하게 되면 메모리에
    ; RootDirectory Sector Data 가 존재하게 된다
    mov ax, word [DAPSegment]
    mov es, ax

    mov di, word [DAPOffset]
.loop_remove_check:
;-------------------------------------------------
; 파일 삭제 여부 체크 루틴
; info!) 이 루틴에서 삭제된 파일정보는 건너 뛴다.
;-------------------------------------------------
    ; 첫 바이트가 0xE5 인 경우 삭제된 영역
    mov dl, byte [es:di]
    cmp dl, 0xE5
    jne .dir_entry_check
    ; 삭제된 파일명인지 체크

    add di, 0x20
    ; 다음 RootDirectory 체크
    jmp .loop_remove_check

;-------------------------------------------------
.dir_entry_check:
    ; Long Directory Entry Check
    mov cl, byte [es:di+11]
    test cl, 0x40
    jnz .loop_not_found

    ; short dir entry : filename 8byte
    cmp byte [es:di], 0
    je .end

    mov si, di
    mov bx, word [bp+4]

    xor ax, ax
.loop_copy:
    mov ah, byte [ds:bx]
    ;cmp ah, 0
    ;je .loop_end
    test ah, ah
    jz .loop_end
    ; 위 조건이 만족하는 경우
    ; 비교 대상이 NULL 문자가 나온경우
    ; 일치한 문자열을 찾은경우

    cmp ah, byte [es:si]
    jne .loop_not_found

    inc si
    inc bx
    jmp .loop_copy
.loop_not_found:
    add di, 0x20
    jmp .loop_remove_check
    ; 커널 소스 파일이 아닐 경우 다음 DirectoryEntry 비교
.loop_end:
    ; 인자로 받은 파일명과 동일한 파일명인지 체크

    mov al, byte [es:di+11]
    and al, 0x20
    cmp al, 0x20
    jne .loop_not_found
    ; 파일인지 폴더인지 체크
    ; 폴더인 경우 다음 Directory Entry 검색

    ; 이 부분이 실행이 된다면 커널소스 파일과 동일한 파일을 발견한 경우 이다.

    mov dx, word [es:di+26]
    sub dx, 2
    ; RootDirectoryEntry가 2 Cluster 이므로 2를 빼준다

    xor eax, eax
    mov al, byte [SectorsPerCluster]
    mul dx
    ; 커널 파일 로드의 경우 dword 까지는 필요 없으므로
    ; 하위 word 만 사용한다

    mov ebx, dword [DAPReadSector]
    add eax, ebx
    mov dword [DAPReadSector], eax
    ; 파일 데이터 섹터 = RootDirectoryEntry 시작 섹터 + 파일 클러스터 번호 * 8sector(1cluster)

    mov word [DAPReadSectorSize], 8 + 4
    ; 1cluster read!!

    mov si, DAP
    mov ah, 0x42
    mov dl, byte [BootDiskNumber]
    int 0x13
    jnc .end
    ; 커널 데이터 메모리 로드
.end:
    popa

    mov sp, bp
    pop bp
    ret 2

; LAB
; Disk Address Packet
DAP:
                    db 0x10, 0    ; Size of packet (10h or 18h)
DAPReadSectorSize:  dw 8        ; Sectors to read
DAPOffset:          dw 0x8000   ; Offset
DAPSegment:         dw 0        ; Segment
DAPReadSector:      dq 1

;KernelAddress:     equ 0x8000

;DiskResetError:    db 'DiskReset Error', 0
;DiskReadError:     db 'DiskRead Error', 0
KernelLoadError:    db 'Kernel Loading Failure', 0
