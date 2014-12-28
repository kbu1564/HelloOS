#ifdef  _DAPI_ENGINE_H_
#ifndef _DAPI_USB_H_
#define _DAPI_USB_H_

#include "bpb.h"

namespace DAPI
{
	class UsbLibrary
	{
	protected:
		const int GENERIC_VALID_FLAGS = GENERIC_WRITE | GENERIC_READ;
		const int FILE_SHARE_VALID_FLAGS = FILE_SHARE_WRITE | FILE_SHARE_READ;
	private:
		HANDLE mDeviceHandle;

		DISK_GEOMETRY_EX mDiskGeoMetryEx;
		fat_extBS_32_t* mBPB;
	public:
		UsbLibrary(std::string strDevicePath)
		{
			strDevicePath = "\\\\.\\" + strDevicePath;
			this->open(strDevicePath);

			this->mBPB = this->getBiosParameterBlock();
		}
		~UsbLibrary() { this->close(); }

		bool isVolumeDevice()
		{
			if (this->mBPB == nullptr) return false;
			return true;
		}

		bool isUsbDevice()
		{
			if (this->mDiskGeoMetryEx.Geometry.MediaType == MEDIA_TYPE::RemovableMedia)
				return true;

			return false;
		}

		long long getDeviceSize()
		{
			return this->mDiskGeoMetryEx.DiskSize.QuadPart;
		}

		bool writeMasterBootRecord(fat_extBS_32_t* installMBR)
		{
			if (this->mBPB == nullptr) return false;
			if (this->mDeviceHandle == nullptr) return false;

			// jmp Code copy
			memcpy(this->mBPB->bootjmp, installMBR->bootjmp, sizeof(installMBR->bootjmp));
			// machine Code copy
			memcpy(this->mBPB->machine_code, installMBR->machine_code, sizeof(installMBR->machine_code));
			
			// MBR Write
			DWORD dwBytePerSector = sizeof(fat_extBS_32_t);
			DWORD dwWriteBytes = 0;

			if (SetFilePointer(this->mDeviceHandle, 0 * dwBytePerSector, 0, FILE_BEGIN) != INVALID_SET_FILE_POINTER)
			{
				BOOL isInstalled = WriteFile(this->mDeviceHandle, this->mBPB, dwBytePerSector, &dwWriteBytes, 0);
				if (isInstalled == FALSE) return false;
				return true;
			}
			return false;
		}

		std::string getVolumeLabel()
		{
			if (this->mBPB == nullptr) return "";

			char labelName[12] = { 0, };
			strncpy_s(labelName, (char*)this->mBPB->volume_label, 11);

			return labelName;
		}

		std::string getFileSystemLabel()
		{
			if (this->mBPB == nullptr) return "";

			char fileSystem[12] = { 0, };
			strncpy_s(fileSystem, (char*)this->mBPB->fat_type_label, 8);

			return fileSystem;
		}
	private:
		void open(std::string strDevicePath)
		{
			this->mDeviceHandle = CreateFileA(strDevicePath.c_str(), GENERIC_VALID_FLAGS, FILE_SHARE_VALID_FLAGS, 0, OPEN_EXISTING, 0, 0);
		}

		void close()
		{
			if (this->mBPB != nullptr) delete this->mBPB;
			if (this->mDeviceHandle != nullptr)
				CloseHandle(this->mDeviceHandle);
		}

		fat_extBS_32_t* getBiosParameterBlock()
		{
			if (this->mDeviceHandle == nullptr) return nullptr;

			DWORD dwJunk = 0;
			// IOCTL을 이용하여 해당 디바이스의 속성값들 얻어오기
			if (DeviceIoControl(this->mDeviceHandle,
				IOCTL_DISK_GET_DRIVE_GEOMETRY_EX,
				NULL, 0,
				&this->mDiskGeoMetryEx, sizeof(DISK_GEOMETRY_EX),
				&dwJunk, (LPOVERLAPPED)NULL))
			{
				DWORD dwBytesPerSector = this->mDiskGeoMetryEx.Geometry.BytesPerSector;
				DWORD dwReadBytes = 0;

				BYTE* bMasterBootRecord = new BYTE[dwBytesPerSector];
				ReadFile(this->mDeviceHandle, bMasterBootRecord, dwBytesPerSector, &dwReadBytes, 0);

				return (fat_extBS_32_t*)bMasterBootRecord;
			}
			return nullptr;
		}
	};
};

#endif
#endif
