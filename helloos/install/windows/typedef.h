#ifndef _TYPEDEF_H_
#define _TYPEDEF_H_

#define COMMAND_DEVICE_NAME  "device-path"
#define COMMAND_MBR_NAME     "mbr-path"
#define COMMAND_VBR_NAME     "vbr-path"

typedef struct { bool active, need; } command_status;
typedef struct {
    unsigned char  JumpCode[3];
    unsigned char  OemID[8];
    unsigned short BytesPerSector;
    unsigned char  SectorsPerCluster;
    unsigned short ReservedSectors;
    unsigned char  TotalFATs;
    unsigned short MaxRootEntries;
    unsigned short NumberOfSectors;
    unsigned char  MediaDescriptor;
    unsigned short SectorsPerFAT;
    unsigned short SectorsPerTrack;
    unsigned short SectorsPerHead;
    unsigned int   HiddenSectors;
    unsigned int   TotalSectors;
    unsigned int   BigSectorsPerFAT;
    unsigned short Flags;
    unsigned short FSVersion;
    unsigned int   RootDirectoryStart;
    unsigned short FSInfoSector;
    unsigned short BackupBootSector;

    unsigned int   Reserved1;
    unsigned int   Reserved2;
    unsigned int   Reserved3;

    unsigned char  BootDiskNumber;
    unsigned char  Reserved4;
    unsigned char  Signature;
    unsigned int   VolumeID;
    unsigned char  VolumeLabel[11];
    unsigned char  SystemID[8];

    unsigned char  byteCode[420];
    unsigned short VBRSignature;
} __attribute__((packed)) bpb_fat32;

typedef struct {
    unsigned char  BootIndicator;
    union {
        struct {
            unsigned char  StartingHead;
            unsigned short StartingSector : 6;
            unsigned short StartCylinder  : 10;
            unsigned char  SystemID;
            unsigned char  EndingHead;
            unsigned short EndingSector   : 6;
            unsigned short EndingCylinder : 10;
            unsigned int   RelativeSector;
            unsigned int   totalSectors;
        } __attribute__((packed)) chs;

        struct {
            unsigned char  Signature1;
            unsigned short PartitionStartHigh;
            unsigned char  SystemID;
            unsigned char  Signature2;
            unsigned short PartitionLengthHigh;
            unsigned int   PartitionStartLow;
            unsigned int   PartitionLengthLow;
        } __attribute__((packed)) lba;
    } type;
} __attribute__((packed)) gpt_entry;

typedef struct {
    unsigned char  byteCode[446];
    gpt_entry      gpt[4];
    unsigned short MBRSignature;
} __attribute__((packed)) gpt_status;

#endif
