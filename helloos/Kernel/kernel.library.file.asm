; HardDisk Information
HddInformation:
    .configuation                    dw 0

    .numberOfCylinder                dw 0
    .reserved1                       dw 0

    .numberOfHead                    dw 0
    .unformattedBytesPerTrack        dw 0
    .unformattedBytesPerSector       dw 0

    .numberOfSectorPerCylinder       dw 0
    .interSectorGap                  dw 0
    .bytesInPhaseLock                dw 0
    .numberOfVendorUniqueStatusWord  dw 0

    .serialNumber          times 10  dw 0
    .controllerType                  dw 0
    .bufferSize                      dw 0
    .numberOfECCBytes                dw 0
    .firmwareRevision      times 4   dw 0

    .modelNumber           times 20  dw 0
    .reserved2             times 13  dw 0

    .totalSectors                    dd 0
    .reserved3             times 196 dw 0

_get_hdd_info:
    mov dx, 0x1F0 + 0x206
    mov al, 0
    call _out_port_byte
    ; 1st PATA digital register

    mov dx, 0x1F0 + 0x07
    mov al, 0xEC
    call _out_port_byte
    ; send command

    mov edi, HddInformation
    xor ecx, ecx
.for1:
    cmp ecx, 512 / 2
    jae .endfor1

    mov dx, 0x1F0 + 0x00
    call _in_port_word

    mov word [edi], ax
    add edi, 2
    add ecx, 1
    jmp .for1
.endfor1:

    ; swap string of modelNumber
    mov edi, HddInformation.modelNumber
    xor ecx, ecx
.for2:
    cmp ecx, 20
    jae .endfor2

    mov dx, word [edi]
    mov ah, dl
    mov al, dh
    mov word [edi], ax

    add edi, 2
    add ecx, 1
    jmp .for2
.endfor2:
    mov cx, 20
    mov si, HddInformation.modelNumber
    mov di, si
    call _back_trim

    retn

; void open(char* filepath);
_open:
    retn

; void* read(int size);
_read:
    retn

; void* read_entry(char* dirpath);
; push 디렉토리 경로
; call _read_entry
_read_entry:
    retn

; void close();
_close:
    retn

