[bits 16]
[org 0x0600]

;-----------------------------------------
; 8 GB USB 기준으로 작성됨
;-----------------------------------------
; 여러 용량의 USB를 지원하기 위해서는
; 별도의 Setup 파일이 필요할 것으로 보임
;-----------------------------------------

CurMBRAddress       equ 0x7C00
NewMBRAddress       equ 0x0600

;-----------------------------------------
; Bootloader Main Function
;-----------------------------------------
copylow:            cli
                    xor ax, ax
                    mov es, ax
                    mov ds, ax
                    mov ss, ax
                    mov fs, ax
                    mov gs, ax
                    mov sp, 0xFFF8

                    mov cx, 0x0100
                    mov si, CurMBRAddress
                    mov di, NewMBRAddress
                    rep movsw
                    jmp 0:main

main:               sti
                    mov byte [BootDiskNumber], dl

                    mov cx, 4
                    mov bx, PartitionTable

.looppt:            xor edx, edx
                    mov dl, byte [bx]
                    ; bootable(7bit)가 set 되어있으면 부팅가능
                    test dl, 0x80
                    jz .nextpt

                    mov eax, dword [bx + 8]       ; start sector of partition
                    mov dword [StartSector], eax  ; set start sector

                    ; 디스크의 데이터를 읽어오기 위해 인터럽트를 호출한다.
                    mov ah, 0x42
                    mov dl, byte [BootDiskNumber]
                    mov si, DiskAddressPacket
                    int 0x13
                    jc .failed

                    ; check MBR Signature
                    cmp word [0x7DFE], 0xAA55
                    jne .failed
                    jmp CurMBRAddress

.nextpt:            add bx, 16                    ; next partition entry
                    loop .looppt

.failed:            mov ax, 0xB800
                    mov es, ax
                    mov si, ErrorMsg
                    mov di, 0

.print:             mov al, byte [si]
                    cmp al, 0
                    je .shutdown

                    mov byte [es:di], al
                    add di, 1
                    mov byte [es:di], 0x04
                    add di, 1
                    add si, 1
                    jmp .print

.shutdown:          hlt
                    jmp .shutdown

;-----------------------------------------
; Etc Datas
;-----------------------------------------
ErrorMsg            db "Cound not boot to the drive...", 0
BootDiskNumber      db 0

;-----------------------------------------
; Disk Address Packet
;-----------------------------------------
DiskAddressPacket   db 0x10
                    db 0                          ; 구조체 크기
                    dw 1                          ; 읽고자 하는 섹터의 개수
                    dw CurMBRAddress              ; offset
                    dw 0x0000                     ; segment
StartSector         dq 0

times 436-($-$$)    db 0
DiskID     times 10 db 0

;-----------------------------------------
; Partition Table
;-----------------------------------------
PartitionTable:                                   ; Booting Partition
                    db 0x80                       ; bootable
                    db 0xFE, 0xFF, 0xFF           ; start CHS
                    db 0x0B                       ; type
                    db 0xFE, 0xFF, 0xFF           ; last CHS
                    dd 0x00000002                 ; first sector LBA
                    dd 0x00F007FD                 ; partition size(sector)

                    db 0x00                       ; bootable
                    db 0x00, 0x00, 0x00           ; start CHS
                    db 0x00                       ; type
                    db 0x00, 0x00, 0x00           ; last CHS
                    dd 0x00000000                 ; first sector LBA
                    dd 0x00000000                 ; partition size(sector)

                    db 0x00                       ; bootable
                    db 0x00, 0x00, 0x00           ; start CHS
                    db 0x00                       ; type
                    db 0x00, 0x00, 0x00           ; last CHS
                    dd 0x00000000                 ; first sector LBA
                    dd 0x00000000                 ; partition size(sector)

                    db 0x00                       ; bootable
                    db 0x00, 0x00, 0x00           ; start CHS
                    db 0x00                       ; type
                    db 0x00, 0x00, 0x00           ; last CHS
                    dd 0x00000000                 ; first sector LBA
                    dd 0x00000000                 ; partition size(sector)

                    dw 0xAA55
