[org 0x7c00]
[bits 16]

jmp _start
nop

%include "loader.fat32.4GB.asm"

_start:
  xor ax, ax
  mov es, ax
  mov ds, ax
  mov ss, ax
  mov fs, ax
  mov gs, ax

  ; boot(0x7c00) -> booting!!
  ; video memory(0xb8000) 여기서 일정 크기만큼의 공간의
  ; 메모리의 값을 화면에 지속적으로 출력!! - GPU
  ; ---------------
  ; | char | attr |
  ; ---------------

  ; c++ idiom, 아키텍쳐 패턴
  ; RootDir = FAT의개수 * FAT의크기 + 예약영역의크기
  ;    ax   =    cx   *    eax  +   bx
  ; 4GB USB의 경우 일반적으로 : 0x4000 sector

  ;                eax
  ;-----------------------------------
  ;                 |       ax
  ;-----------------------------------
  ;                 |   ah   |   al   
  mov eax, 0
  mov ebx, 0
  mov ecx, 0
.loader:
  mov cl, byte [TotalFATs]
  mov eax, dword [BigSectorsPerFAT]
  mov bx, word [ReservedSectors]
  mul ecx
  ; dx:ax = ax * r16
  ; edx:eax = eax * r32
  add eax, ebx
  ; ax = ax + r16
  ;----------------------------------
  ; RootDir의 위치 : eax
  mov dword [StartSector], eax

  ; 디스크의 데이터를 읽어오기 위해 인터럽트를 호출한다.
  mov ah, 0x42
  mov dl, byte [BootDiskNumber]
  mov si, DiskAddressPacket
  int 0x13
  jc .shutdown
  ; RootDirEntry의 내용이 구해짐(폴더에 뭐있는지에 대한 목록이 구해짐)
  ; 0x8000 -> loader.sys 파일을 찾아야되 -> 데이터가 저장된 위치를 찾고
  ; -> 찾은 위치를 int 0x13 이용해서 0x8000번지 메모리에 적재 -> jmp 0x8000

  ; 읽은 RootDirEntry로 부터 loader.sys파일을 찾는다
  mov di, 0x8000
.find:
  ; 만약 첫번째 바이트가 0xE5 ?? => 삭제된 파일
  ; 삭제된게 아닐경우 파일이름 비교
  mov cl, byte [di]
  cmp cl, 0xE5
  je .next

  ; 이 부분이 실행된다는 것은 삭제된 파일이 아니라는 것이다.
  mov cx, 8
  mov bx, LoaderName
  mov si, di
.compare:
  ; dx의 1바이트가 si의 1바이트와 같으면 루프 계속 다르면 다음 파일정보 찾기
  ; 주소 지정용 레지스터 : bx, si, di, bp, sp
  mov al, byte [bx]
  cmp al, byte [si]
  jne .next

  add bx, 1
  add si, 1
  loop .compare
  ; for (int i = ??; i > 0; i--) { ... }
  jmp .video

.next:
  add di, 0x20
  jmp .find

.video:
  xor eax, eax
  ; 이 시점에 위치한 상태인 경우 원하는 파일을 찾은 상태이다.
  mov ax, word [di + 20]
  shl eax, 16
  mov ax, word [di + 26]
  sub eax, 2
  ; 이때의 eax 값이 파일 정보가 저장된 클러스터 위치 값이다.
  mov ecx, 0
  mov cl, byte [SectorsPerCluster]
  mul ecx

  add eax, dword [StartSector]
  mov dword [StartSector], eax

  ; 디스크의 데이터를 읽어오기 위해 인터럽트를 호출한다.
  mov ah, 0x42
  mov dl, byte [BootDiskNumber]
  mov si, DiskAddressPacket
  int 0x13
  jc .shutdown

  ; 16bit -> 0xFFFF
  mov ax, 0xb800
  mov es, ax

  ; 0xb8000 -> (char)'H' -> 1bite 쓰여짐!!
  ; *((char*)0xb8000) = 'H';
  ; 0xb8001 -> (char)0x04 -> 1bite 쓰여짐!!
  ; *((char*)0xb8001) = 0x04;
  mov si, HelloMsg

  mov di, 0
.print:
  ; cx = ch + cl
  mov cl, byte [si]
  cmp cl, 0
  je .success

  mov byte [es:di], cl
  add di, 1
  mov byte [es:di], 0x04
  add di, 1
  add si, 1
  jmp .print

.success:
  mov ax, 0
  mov ds, ax
  mov es, ax

  mov si, 0x8000
  jmp si

.shutdown:
  jmp .shutdown

HelloMsg   db 'Hello, World!!', 0
LoaderName db 'KERNEL  ', 'SYS'

;-----------------------------------------
DiskAddressPacket:
             db 0x10, 0 ; 구조체 크기
             dw 8       ; 읽고자 하는 섹터의 개수
             dw 0x8000
             dw 0x0000
StartSector: dq 0
;-----------------------------------------

times 510-($-$$) db 0x00
db 0x55
db 0xaa

