OEM_ID:             db "HELLOOS "
BytesPerSector:     dw 0x0200
SectorsPerCluster:  db 0x08
ReservedSectors:    dw 0x03BE
TotalFATs:          db 0x02
MaxRootEntries:     dw 0x0000
NumberOfSectors:    dw 0x0000
MediaDescriptor:    db 0xF8
SectorsPerFAT:      dw 0x0000
SectorsPerTrack:    dw 0x003F
SectorsPerHead:     dw 0x00FF
HiddenSectors:      dd 0x00000000
TotalSectors:       dd 0x0078C000
BigSectorsPerFAT:   dd 0x00001E21
Flags:              dw 0x0000
FSVersion:          dw 0x0000
RootDirectoryStart: dd 0x00000002
FSInfoSector:       dw 0x0001
BackupBootSector:   dw 0x0006

Reserved1:          dd 0
Reserved2:          dd 0
Reserved3:          dd 0

BootDiskNumber:     db 0x80
Reserved4:          db 0
Signature:          db 0x29
VolumeID:           dd 0xFFFFFFFF
VolumeLabel:        db "OSUSB      "
SystemID:           db "FAT32   "
