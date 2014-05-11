#include <Windows.h>
#include <stdio.h>
#include <iostream>
#include <string>

// 개발자 전용
using namespace std;

const int FILE_SHARE_VALID_FLAGS = FILE_SHARE_WRITE | FILE_SHARE_READ;
const int SECTORSIZE = 512;

short ReadSector(const char* _dsk, BYTE* &_buff, UINT _nsect)
{
	DWORD dwRead = 0;
	HANDLE hDisk = NULL;

	hDisk = CreateFile(_dsk, GENERIC_WRITE | GENERIC_READ, FILE_SHARE_VALID_FLAGS, 0, OPEN_EXISTING, 0, 0);
	if (hDisk == INVALID_HANDLE_VALUE)
	{
		cout << "`" << _dsk << "` is INVALID_HANDLE_VALUE!!" << endl;
		CloseHandle(hDisk);

		return 1;
	}
	if (SetFilePointer(hDisk, _nsect * SECTORSIZE, 0, FILE_BEGIN) != INVALID_SET_FILE_POINTER)
	{
		if (ReadFile(hDisk, _buff, SECTORSIZE, &dwRead, 0) == FALSE)
		{
			int _errno = GetLastError();
			if (_errno == 5)
				cout << "ReadSector Denied Access!!" << endl;
			else
			{
				printf("ReadSector Error: %d\n", _errno);
			}
		}
	}
	CloseHandle(hDisk);

	return 0;
}

short WriteSector(const char* _dsk, BYTE* _buff, UINT _nsect)
{
	DWORD dwWrite = 0;
	HANDLE hDisk = NULL;

	hDisk = CreateFile(_dsk, GENERIC_WRITE | GENERIC_READ, FILE_SHARE_VALID_FLAGS, 0, OPEN_EXISTING, 0, 0);
	if (hDisk == INVALID_HANDLE_VALUE)
	{
		cout << "`" << _dsk << "` is INVALID_HANDLE_VALUE!!" << endl;
		CloseHandle(hDisk);

		return 1;
	}
	if (SetFilePointer(hDisk, _nsect * SECTORSIZE, 0, FILE_BEGIN) != INVALID_SET_FILE_POINTER)
	{
		if (WriteFile(hDisk, _buff, SECTORSIZE, &dwWrite, 0) == FALSE)
		{
			int _errno = GetLastError();
			if (_errno == 5)
				cout << "WriteSector Denied Access!!" << endl;
			else
			{
				printf("WriteSector Error: %d\n", _errno);
			}
		}
		else
		{
			cout << "WriteSector Success!!" << endl;
		}
	}
	CloseHandle(hDisk);

	return 0;
}

int main(int argc, char* argv[])
{
	char yesno = 'Y';
	string strDriveNumber, strFilePath;
	string strDisk = "\\\\.\\PhysicalDrive";

	// 드라이브 번호 읽기
	if (argc == 1)
	{
		cout << "주의 ! : USB의 최소 용량이 16GB이어야 하며 포벳된 상태 이어야 합니다" << endl;
		cout << "USB DriverNumber: ";
		cin >> strDriveNumber;
		cout << "USB Install FilePath: ";
		cin >> strFilePath;
	}
	else
	{
		strDriveNumber = argv[1];
		strFilePath = argv[2];
	}

	if (strDriveNumber.compare("0") == 0)
	{
		cout << "주의 !" << endl;
		cout << "해당 드라이브는 로컬 HDD 이므로 부트로더 업로드시" << endl;
		cout << "부팅이 불가능 할 수 있습니다." << endl << endl;

		cout << "작업을 계속 진행 하시겠습니까?(Y/n): ";
		cin >> yesno;
	}

	if (yesno == 'Y')
	{
		// 드라이브 셋팅
		strDisk += strDriveNumber;
		strDisk = "\\\\.\\F:";

		// 설치 파일 읽어들이기
		FILE* fp = NULL;
		int _errno = fopen_s(&fp, strFilePath.c_str(), "rb");
		if (_errno == 0)
		{
			BYTE* sectorData = new BYTE[SECTORSIZE];

			fread_s(sectorData, sizeof(BYTE)* SECTORSIZE, SECTORSIZE, 1, fp);
			fclose(fp);

			// Bootloader 체크
			if (sectorData[510] == 0x55 && sectorData[511] == 0xAA)
			{
				cout << "Bootloader Checking OK!!" << endl;
				// Bootloader Read!!
				WriteSector(strDisk.c_str(), sectorData, 0);
				//WriteSector(strDisk.c_str(), sectorData, 6);
			}
			else
			{
				// Bootloader 가 아닌경우 설치를 실패시킨다.
				cout << "Bootloader Install Failure!!" << endl;
				cout << "`" << strFilePath << "` is Not Bootloader!!" << endl;
			}

			delete[] sectorData;
		}
		else
		{
			cout << "`" << strFilePath << "` is not exists!!" << endl;
		}
	}
	else
	{
		cout << "작업을 취소합니다." << endl;
	}
	return 0;
}
