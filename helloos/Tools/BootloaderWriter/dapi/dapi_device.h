#ifndef _DAPI_DEVICE_H_
#define _DAPI_DEVICE_H_

// 최대 생성가능한 다중 윈도우 개수
const int MAX_WINDOWS = 5;

namespace DAPI
{
	enum DAPI_DeviceStatus { D_OK, D_INVALID };
	enum DAPI_KeyStatus { D_DOWN, D_UP };

	// 변수형 재 정의
	typedef DWORD DAPI_KeyCode;
	typedef LRESULT(*WindowMessageFunc)(HWND hWnd, WPARAM wParam, LPARAM lParam);

	static std::map<UINT, WindowMessageFunc> mMsgMap;
	static POINTS mMousePoint;
	static LPARAM wMouseClick;
	static LPARAM wMouseClickOnce;

	struct DAPI_DeviceStruct
	{
		HWND hWnd;

		HDC hDC;
		HDC hMemDC;
		HBITMAP hBit;
		HBITMAP hMemBit;

		int width;
		int height;
		int x;
		int y;
		
		DWORD keyState;
		int   keyCode;
	};

	class CDevice
	{
	private:
		MSG mMsg;
		PAINTSTRUCT ps;
		HINSTANCE hInstance;

		DWORD dwFPSCount;
		DWORD dwFPSTimer;
		DWORD dwSetTimer;
		DWORD dwSetTryTimer;
		bool bTryTimer;

		int nWindowCount;
	protected:
		DAPI_DeviceStruct dDeviceInfo[MAX_WINDOWS];

		LPCTSTR lpcVer;

	public:
		CDevice();
		virtual ~CDevice();

		DAPI_DeviceStruct * GetDeviceInfo(int index);
		int CreateDevice(const LPCTSTR cpAppName, int width, int height, int x, int y);
		int Run(int index = 0);

		// 초당 렌더링 될 프레임 수 제한
		BOOL FPSCount(int frameCount);
		// 특정 시간초를 주기로 TRUE 값 반환
		BOOL SetTimer(const DWORD startMS, const DWORD tryMS = 0);
		
		DWORD GetDeviceStatus(int index);
		BOOL  BeginScene(int index);
		BOOL  EndScene(int index);
		BOOL  CopyDC(int index, const HDC hSrcDC, const RECT rectSize, int x, int y);

		DWORD GetKeyCodeState(int keyCode);
		POINTS GetMouseState();

		BOOL IsMouseOver(LPRECT rec) const;
		BOOL IsMouseClick(LPRECT rec) const;
		BOOL IsMouseClickOnce(LPRECT rec) const;

		static LRESULT CALLBACK WinProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

		void AddEventHandler(UINT uMsg, WindowMessageFunc wmFunc);
		void DeleteEventHandler(UINT uMsg);
	private:
		// 의도적인 컴파일 오류를 통한 복사 방지
		CDevice(const CDevice & device);

		void WinMain();
	};
	typedef CDevice DAPI_DEVICE;
	typedef CDevice * LPDAPI_DEVICE;
};

#endif
