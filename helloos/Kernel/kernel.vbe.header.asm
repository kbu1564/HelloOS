VbeGraphicModeStart             db 0x01
; 그래픽 모드 시작 여부
; 1 : 그래픽 모드
; 0 : 텍스트 모드
VbeInfoState                    equ 0x7000
VbeInfoLoadError                equ 0x004F

VbeInfoBlock                    equ 0x7E00
VbeSignature                    equ VbeInfoBlock
VbeVersion                      equ VbeInfoBlock + 4
OemStringPtr                    equ VbeInfoBlock + 6
Capabilities                    equ VbeInfoBlock + 10
VideoModePtr                    equ VbeInfoBlock + 14
TotalMemory                     equ VbeInfoBlock + 18

VbeInfoModeBlock                equ 0x7F00
;-----------------------------------------
; 모든 VBE 버전 공통
ModeAttr                        equ VbeInfoModeBlock + 0
WinAAttr                        equ VbeInfoModeBlock + 2
WinBAttr                        equ VbeInfoModeBlock + 3
WinGranulity                    equ VbeInfoModeBlock + 4
WinSize                         equ VbeInfoModeBlock + 6
WinASegment                     equ VbeInfoModeBlock + 8
WinBSegment                     equ VbeInfoModeBlock + 10
WinFuncPtr                      equ VbeInfoModeBlock + 12
BytePerScanLine                 equ VbeInfoModeBlock + 16
;-----------------------------------------
; VBE 1.2 이상 공통 부분
xResolution                     equ VbeInfoModeBlock + 18
yResolution                     equ VbeInfoModeBlock + 20
xCharSize                       equ VbeInfoModeBlock + 22
yCharSize                       equ VbeInfoModeBlock + 23
NumberOfPlane                   equ VbeInfoModeBlock + 24
BitsPerPixel                    equ VbeInfoModeBlock + 25
NumberOfBanks                   equ VbeInfoModeBlock + 26
MemoryModel                     equ VbeInfoModeBlock + 27
BankSize                        equ VbeInfoModeBlock + 28
NumberOfImagePages              equ VbeInfoModeBlock + 29
Reserved                        equ VbeInfoModeBlock + 30
; Direct Color 관련 필드
RedMaskSize                     equ VbeInfoModeBlock + 31
RedFieldPosition                equ VbeInfoModeBlock + 32
GreenMaskSize                   equ VbeInfoModeBlock + 33
GreenMaskPosition               equ VbeInfoModeBlock + 34
BlueMaskSize                    equ VbeInfoModeBlock + 35
BlueMaskPosition                equ VbeInfoModeBlock + 36
ReservedMaskSize                equ VbeInfoModeBlock + 37
ReservedMaskPosition            equ VbeInfoModeBlock + 38
DirectColorModeInfo             equ VbeInfoModeBlock + 39
;-----------------------------------------
; VBE 2.0 이상 공통 부분
PhysicalBasePointer             equ VbeInfoModeBlock + 40
Reserved1                       equ VbeInfoModeBlock + 44
Reserved2                       equ VbeInfoModeBlock + 48
;-----------------------------------------
; VBE 3.0 이상 공통 부분
LinearBytesPerScanLine          equ VbeInfoModeBlock + 52
BankNumberOfImagePages          equ VbeInfoModeBlock + 53
LinearNumberOfImagePages        equ VbeInfoModeBlock + 54
LinearRedMaskSize               equ VbeInfoModeBlock + 55
LinearRedFieldPosition          equ VbeInfoModeBlock + 56
LinearGreenMaskSize             equ VbeInfoModeBlock + 57
LinearGreenFieldPosition        equ VbeInfoModeBlock + 58
LinearBlueMaskSize              equ VbeInfoModeBlock + 59
LinearBlueFieldPosition         equ VbeInfoModeBlock + 60
LinearReservedMaskSize          equ VbeInfoModeBlock + 61
LinearReservedFieldPosition     equ VbeInfoModeBlock + 62
MaxPixelClock                   equ VbeInfoModeBlock + 63

VbeMode:
    .640x400x8                  equ 0x100
    .640x480x8                  equ 0x101
    .800x600x4                  equ 0x102
    .800x600x8                  equ 0x103
    .1024x768x4                 equ 0x104
    .1024x768x8                 equ 0x105
    .1280x1024x4                equ 0x106
    .1280x1024x8                equ 0x107
    .80x60                      equ 0x108
    .132x25                     equ 0x109
    .132x43                     equ 0x10A
    .132x50                     equ 0x10B
    .132x60                     equ 0x10C
    .320x200x16@32              equ 0x10D
    .320x200x16@64              equ 0x10E
    .320x200x24                 equ 0x10F
    .640x480x16@32              equ 0x110
    .640x480x16@64              equ 0x111
    .640x480x24                 equ 0x112
    .800x600x16@32              equ 0x113
    .800x600x16@64              equ 0x114
    .800x600x24                 equ 0x115
    .1024x768x16@32             equ 0x116
    .1024x768x16@64             equ 0x117
    .1024x768x24                equ 0x118
    .1280x1024x16@32            equ 0x119
    .1280x1024x16@64            equ 0x11A
    .1280x1024x24               equ 0x11B
