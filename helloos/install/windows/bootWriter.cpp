#include "typedef.h"
#include "bootWriter.h"
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <map>
using namespace std;

BYTE* BootWriter::ReadFileContents(const char* filename, const int filesize) {
    BYTE* data = new BYTE[filesize];
    DWORD dwRead = 0;
    // device open
    HANDLE hDevice = CreateFile(filename, 
        GENERIC_READ, 
        FILE_SHARE_READ, 
        NULL, 
        OPEN_EXISTING, 
        FILE_ATTRIBUTE_NORMAL, 
        NULL
    );
    // file open error
    if (hDevice == INVALID_HANDLE_VALUE) {
        cout << "File Opening ErrorCode : " << GetLastError() << endl;
        delete[] data;
        return nullptr;
    }

    BOOL result = ReadFile(hDevice, data, filesize, &dwRead, NULL);
    if (result != INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR) {
        delete[] data;
        return nullptr;
    }
    CloseHandle(hDevice);

    return data;
}

bool BootWriter::Open(const char* deviceName) {
    // Save MBR or VBR bootCode
    char devicePath[40];
    int physicalNumber = this->__GetPhysicalDriveNumber(deviceName);
    if (physicalNumber < 0)
        return -1;

    // get physical drive handle
    sprintf(devicePath, "\\\\.\\PhysicalDrive%d", physicalNumber);

    m_hDevice = CreateFile(devicePath, 
        GENERIC_READ | GENERIC_WRITE, 
        FILE_SHARE_READ | FILE_SHARE_WRITE, 
        NULL, 
        OPEN_EXISTING, 
        0, 
        NULL
    );
    // device open error
    if (m_hDevice == INVALID_HANDLE_VALUE) {
        return false;
    }

    return true;
}

BYTE* BootWriter::Read(const int nStartSector, const int nSectorCount) {
    BYTE* data = new BYTE[nSectorCount * 512];
    BOOL result = FALSE;
    DWORD dwRead = 0;
    DWORD dwLow = nStartSector * 512;
    result = SetFilePointer(m_hDevice, dwLow, NULL, FILE_BEGIN);
    if (result != INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR) {
        delete[] data;
        return nullptr;
    }
    result = ReadFile(m_hDevice, data, nSectorCount * 512, &dwRead, NULL);
    if (result != INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR) {
        delete[] data;
        return nullptr;
    }
    return data;
}

bool BootWriter::Write(const int nStartSector, BYTE* data, const int dataLength) {
    BOOL result = FALSE;
    DWORD dwRead = 0, dwWrite = 0;
    DWORD dwLow = nStartSector * 512;
    result = SetFilePointer(m_hDevice, dwLow, NULL, FILE_BEGIN);
    if (result != INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
        return false;

    result = WriteFile(m_hDevice, data, dataLength, &dwWrite, NULL);
    if (result != INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
        return false;

    return true;
}

bool BootWriter::Close() {
    if (m_hDevice != INVALID_HANDLE_VALUE) {
        CloseHandle(m_hDevice);
    }
    return true;
}

int BootWriter::GetLastError() {
    return ::GetLastError();
}

int BootWriter::__GetPhysicalDriveNumber(const char* deviceName) {
    VOLUME_DISK_EXTENTS pstVolumeData;
    char devicePath[40];
    sprintf(devicePath, "\\\\.\\%s", deviceName);

    // device open
    HANDLE hDevice = CreateFile(devicePath, 
        GENERIC_READ | GENERIC_WRITE, 
        FILE_SHARE_READ | FILE_SHARE_WRITE, 
        NULL, 
        OPEN_EXISTING, 
        FILE_ATTRIBUTE_NORMAL, 
        NULL
    );
    // device open error
    if (hDevice == INVALID_HANDLE_VALUE)
        return -1;

    DWORD dwOut;
    BOOL result = DeviceIoControl(hDevice, 
        IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS,
        NULL, 
        0, 
        &pstVolumeData, 
        sizeof(pstVolumeData), 
        &dwOut, 
        NULL
    );

    if (result == FALSE || pstVolumeData.NumberOfDiskExtents < 1)
        return -1;

    // device close
    CloseHandle(hDevice);

    return pstVolumeData.Extents[0].DiskNumber;
}
