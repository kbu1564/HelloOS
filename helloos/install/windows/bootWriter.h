#ifndef _BOOTWRITER_H_
#define _BOOTWRITER_H_

// Windows 버전
#include <Windows.h>

class BootWriter {
    HANDLE m_hDevice;

public:
    BootWriter() {}
    ~BootWriter() {
        if (m_hDevice != INVALID_HANDLE_VALUE)
            this->Close();
    }

    BYTE* ReadFileContents(const char* filename, const int size);

    bool  Open(const char* devicePath);
    BYTE* Read(const int nStartSector, const int nSectorCount);
    bool  Write(const int nStartSector, BYTE* data, const int dataLength);
    bool  Close();

    int   GetLastError();
private:
    int __GetPhysicalDriveNumber(const char* deviceName);
};

#endif
