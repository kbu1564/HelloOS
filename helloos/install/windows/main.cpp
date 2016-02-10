#include "typedef.h"
#include "bootWriter.h"
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <map>
using namespace std;

// supported command list
// key : { active, need }
map< string, command_status > comlist = {
    { COMMAND_DEVICE_NAME, { true, true } },
    { COMMAND_MBR_NAME,    { true, true } },
    { COMMAND_VBR_NAME,    { true, true } },
};

// standard
// CommandLine으로 넘어온 옵션값을 파싱하여 map object로 리턴
map<string, string> parseOption(int argc, char* argv[]) {
    map<string, string> opts;
    for (int i = 1; i < argc; i++) {
        string optValue = argv[i] + 1;
        size_t idx = optValue.find('=');
        if (idx != string::npos) {
            opts.insert(pair<string, string>(optValue.substr(0, idx), optValue.substr(idx + 1, -1)));
        }
    }
    return opts;
}

int main(int argc, char* argv[]) {
    BootWriter bootStream;
    map<string, string> opts = parseOption(argc, argv);

    // 옵션 상태값 체크
    cout << "<< Option Status >>" << endl;
    for (auto iter = opts.begin(); iter != opts.end(); iter++) {
        // check : not supported options
        if (comlist[iter->first].active == false) {
            cout << "'" << iter->first << "' option is not supported!!" << endl;
            return -1;
        }
        cout << iter->first << ": " << iter->second << endl;
    }
    cout << endl;

    // 필수 옵션 값 존재여부 체크
    for (auto iter = comlist.begin(); iter != comlist.end(); iter++) {
        if (iter->second.need == true && opts[iter->first] == "") {
            cout << "'" << iter->first << "' option is not exists!!" << endl;
            return -1;
        }
    }

    // MBR or VBR 에서 기계어 코드부분 추출
    gpt_status* mbrArea = (gpt_status*)bootStream.ReadFileContents(opts[COMMAND_MBR_NAME].c_str(), 512);
    bpb_fat32* vbrArea  = (bpb_fat32*)bootStream.ReadFileContents(opts[COMMAND_VBR_NAME].c_str(), 512);

    if (mbrArea == nullptr || vbrArea == nullptr) {
        cout << "MBR or VBR was analysis failure!!" << endl;
        return -1;
    }
    if (mbrArea->MBRSignature != 0xAA55 || vbrArea->VBRSignature != 0xAA55) {
        cout << "MBR or VBR was analysis failure!!" << endl;
        return -1;
    }
    // MBR or VBR BootCode : 'mbrArea->byteCode' or 'vbrArea->byteCode'

    if (bootStream.Open(opts[COMMAND_DEVICE_NAME].c_str()) == false) {
        cout << "Device Opening ErrorCode : " << GetLastError() << endl;
        return -1;
    }

    // get 0 sector
    BYTE* sectorMBR = bootStream.Read(0, 1);
    if (sectorMBR != nullptr) {
        // get Bios Parameter Block
        bpb_fat32* bpb = (bpb_fat32*)sectorMBR;
        if (bpb->JumpCode[2] == 0x90 && bpb->VBRSignature == 0xAA55) {
            // MBR
            char systemID[9] = { 0, };
            strncpy(systemID, (char*)bpb->SystemID, 8);
            cout << "<< MBR(" << sizeof(bpb_fat32) << ") Entry >>" << endl;

            printf("VolumeID   : 0x%08X\n", bpb->VolumeID);
            printf("SystemID   : %s\n", systemID);
            printf("DeviceSize : %.02fGB\n", bpb->TotalSectors / 1024.0 * bpb->BytesPerSector / 1024.0 / 1024.0);

            //--------------------------------------------------------------------------------
            // Write to MBR BootCode
            //--------------------------------------------------------------------------------
            cout << "<< Change BootCode(" << sizeof(bpb->byteCode) << ") >>" << endl;
            // bootCode Copy
            memcpy(bpb->byteCode, vbrArea->byteCode, sizeof(bpb->byteCode));
            // write to ByteCode
            if (bootStream.Write(0, (BYTE*)bpb, sizeof(bpb_fat32)) == false) {
                cout << "Write MBR BootSector: Error(" << GetLastError() << ")" << endl;
            } else {
                cout << "Write MBR BootSector: Success!!" << endl;
            }
            //--------------------------------------------------------------------------------
        } else {
            // GPT
            gpt_status* gpt = (gpt_status*)sectorMBR;
            gpt_entry* gptEntry = gpt->gpt;
            // bootCode Copy
            memcpy(gpt->byteCode, mbrArea->byteCode, sizeof(gpt->byteCode));
            
            cout << "<< GPT Entry(" << sizeof(gpt_status) << ") >>" << endl << endl;

            //--------------------------------------------------------------------------------
            // Write to GPT BootCode
            //--------------------------------------------------------------------------------
            cout << "<< Change GPT ByteCode(" << sizeof(gpt->byteCode) << ") >>" << endl;
            if (bootStream.Write(0, (BYTE*)gpt, sizeof(gpt_status)) == false) {
                cout << "Write GPT BootSector: Error(" << GetLastError() << ")" << endl;
            } else {
                cout << "Write GPT BootSector: Success!!" << endl;
            }
            cout << endl;
            //--------------------------------------------------------------------------------

            for (int i = 0; i < 4; i++) {
                // bootable
                printf("Partition Entry #%d Bootable : 0x%02X\n", i + 1, (short)gptEntry[i].BootIndicator);

                // check chs or lba type disk
                if ((gptEntry[i].BootIndicator & 1) == 0) {
                    // CHS type
                    printf("Partition Entry #%d Type     : CHS\n", i + 1);
                    printf("Partition Entry #%d Start    : 0x%02X\n", i + 1, (short)gptEntry[i].type.chs.RelativeSector);

                    // read volume boot record
                    if ((short)gptEntry[i].type.chs.StartingSector > 0) {
                        // move partition master boot record
                        BYTE* sectorVBR = bootStream.Read((int)gptEntry[i].type.chs.RelativeSector, 512);
                        if (sectorVBR == nullptr)
                            break;

                        bpb = (bpb_fat32*)sectorVBR;
                        if (bpb->JumpCode[2] == 0x90 && bpb->VBRSignature == 0xAA55) {
                            char systemID[9] = { 0, };
                            strncpy(systemID, (char*)bpb->SystemID, 8);
                            cout << "  << Partition #" << i + 1 << " VBR(" << sizeof(bpb_fat32) << ") Entry >>" << endl;
                            // MBR
                            printf("  Partition Entry #%d VolumeID   : 0x%08X\n", i + 1, bpb->VolumeID);
                            printf("  Partition Entry #%d SystemID   : %s\n", i + 1, systemID);
                            printf("  Partition Entry #%d DeviceSize : %.02fGB\n", i + 1, (bpb->TotalSectors / 1024.0 * bpb->BytesPerSector / 1024.0 / 1024.0));

                            // calc root directory number
                            int rootdirectory = bpb->TotalFATs * bpb->BigSectorsPerFAT + bpb->ReservedSectors + bpb->HiddenSectors;
                            printf("  Partition Root Directory Entry : %d\n", rootdirectory);

                            //--------------------------------------------------------------------------------
                            // Write to MBR BootCode
                            //--------------------------------------------------------------------------------
                            cout << "  << Change BootCode(" << sizeof(bpb->byteCode) << ") >>" << endl;
                            // bootCode Copy
                            memcpy(bpb->byteCode, vbrArea->byteCode, sizeof(bpb->byteCode));
                            // write to ByteCode
                            if (bootStream.Write((int)gptEntry[i].type.chs.RelativeSector, (BYTE*)bpb, sizeof(bpb_fat32)) == false) {
                                cout << "  Write MBR BootSector: Error(" << GetLastError() << ")" << endl;
                            } else {
                                cout << "  Write MBR BootSector: Success!!" << endl;
                            }
                            //--------------------------------------------------------------------------------
                        }
                        delete[] sectorVBR;
                    }
                } else {
                    // LBA type
                    printf("Partition Entry #%d Type  : LBA\n", i + 1);
                    printf("Partition Entry #%d Start : 0x%02X\n", i + 1, (short)gptEntry[i].type.lba.PartitionStartLow);
                }
                cout << endl;
            }
        }
        delete[] sectorMBR;
    }
    // device close
    bootStream.Close();
    
    return 0;
}
