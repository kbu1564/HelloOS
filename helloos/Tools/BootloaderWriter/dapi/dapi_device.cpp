#include "dapi_engine.h"

DAPI::CDevice::CDevice()
{
	// DAPI Engine Version
	this->lpcVer = L"DAPI_ENGINE_V.0.0.0";
	this->dwFPSCount = 0;
	this->dwFPSTimer = 0;
	this->dwSetTimer = 0;
	this->dwSetTryTimer = 0;
	this->bTryTimer = false;

	// NULL 값으로 초기화 된 공간 1개를 제외
	this->nWindowCount = 1;
	// 추후 NULL 값이 필요한 곳에 사용되기 위해 초기화
	ZeroMemory(&(this->dDeviceInfo), sizeof(this->dDeviceInfo));

	this->hInstance = GetModuleHandle(NULL);
	this->WinMain();

	// 초기화
	ZeroMemory(&(this->mMsg), sizeof(this->mMsg));
	this->mMsg.message = WM_NULL;
}

DAPI::CDevice::~CDevice()
{
}

/*
public

@brief  특정 인덱스에 해당하는 Device의 정보를 반환
@param  index 생성된 윈도우의 index 번호
@return 생성된 올바른 Device 정보, 올바르지 않은 혹은 존재하지 않은 윈도우 번호값 : NULL
*/
DAPI::DAPI_DeviceStruct * DAPI::CDevice::GetDeviceInfo(int index)
{
	if (this->GetDeviceStatus(index) == DAPI::D_INVALID) return NULL;

	return (this->dDeviceInfo + index);
}

/*
public

@brief  윈도우 생성
@param  cpAppName 윈도우 제목
@param  width 윈도우 가로길이
@param  height 윈도우 세로 길이
@param  x 윈도우 x좌표
@param  y 윈도우 y좌표
@return 생성한 윈도우 인덱스 ID
        생성 실패시 -1 반환
*/
int DAPI::CDevice::CreateDevice(const LPCTSTR cpAppName, int width, int height, int x, int y)
{
	if (this->nWindowCount >= MAX_WINDOWS) return -1;

	int index = this->nWindowCount;
	DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;

	// Device 정보 셋팅
	deviceinfo->width = width;
	deviceinfo->height = height;
	deviceinfo->x = x;
	deviceinfo->y = y;

	deviceinfo->hWnd = CreateWindowEx(0, this->lpcVer, cpAppName, WS_OVERLAPPEDWINDOW, x, y, width, height, NULL, NULL, this->hInstance, &this->nWindowCount);
	SetWindowPos(deviceinfo->hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	//SetWindowLongPtr(deviceinfo->hWnd, GWL_STYLE, GetWindowLongPtr(deviceinfo->hWnd, GWL_STYLE) | WS_SYSMENU);
	//SetWindowLongPtr(deviceinfo->hWnd, GWL_EXSTYLE, GetWindowLongPtr(deviceinfo->hWnd, GWL_EXSTYLE) | WS_EX_ACCEPTFILES);

	if (deviceinfo->hWnd != NULL)
	{
		ShowWindow(deviceinfo->hWnd, SW_SHOW);
		UpdateWindow(deviceinfo->hWnd);
	}
	else
	{
		return -1;
	}
	return this->nWindowCount++;
}

/*
public

@brief  메시지 루프
@param  index
		0 == 생성된 모든 윈도우에 대해 처리
		0 <  index번째 생성된 윈도우에 대해 메시지 처리
@return 실행중 : TRUE, 종료 : FALSE
*/
int DAPI::CDevice::Run(int index)
{
	// 올바르지 않은 index 값 설정시 모든 프로세스 강제 종료
	if (this->GetDeviceStatus(index) == DAPI::D_INVALID) return FALSE;

	DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;
	if (PeekMessage(&(this->mMsg), deviceinfo->hWnd, NULL, NULL, PM_REMOVE))
	{
		TranslateMessage(&(this->mMsg));
		DispatchMessage(&(this->mMsg));
	}
	else
	{
		// CPU의 100% 사용을 방지
		Sleep(5);
	}
	return TRUE;
}

/*
public

@brief  초당 프레임 렌더링 횟수 지정
@param  frameCount 초당 렌더링 되는 횟수
@return 1개의 장면을 렌더링 하는데 필요한 시간을 계산하여 렌더링이 가능한 상태일 경우
		참(true), 불가능한 경우 거짓(false) 반환
*/
BOOL DAPI::CDevice::FPSCount(int frameCount)
{
	if (this->dwFPSTimer == 0) this->dwFPSTimer = GetTickCount();

	const DWORD fpsRenderTime = 1000 / frameCount;
	if (GetTickCount() > this->dwFPSTimer)
	{
		this->dwFPSTimer += fpsRenderTime;
		return TRUE;
	}
	return FALSE;
}

/*
public

@brief  특정 시간초를 주기로 TRUE 값을 반환하는 함수
@param  ms 다음 TRUE 값을 리턴할 시간(ms)
@param  ms 보여질 시간(ms)
@return 지정된 시간만큼 흘러갔다면 TRUE 아니라면 FALSE
*/
BOOL DAPI::CDevice::SetTimer(const DWORD startMS, const DWORD tryMS)
{
	if (this->dwSetTimer == 0) this->dwSetTimer = GetTickCount();

	if (startMS > 0 && this->bTryTimer == false && GetTickCount() - this->dwSetTimer > startMS)
	{
		this->dwSetTryTimer = GetTickCount();
		this->bTryTimer = true;

		return TRUE;
	}

	if (tryMS > 0 && this->bTryTimer == true && GetTickCount() - this->dwSetTryTimer > tryMS)
	{
		this->dwSetTimer = GetTickCount();
		this->bTryTimer = false;
	}

	if (tryMS > 0 && this->bTryTimer == true) return TRUE;
	return FALSE;
}

/*
public

@brief  특정 인덱스에 해당하는 Device의 상태를 반환하는 함수
@param  index 생성된 윈도우의 index 번호
@return 생성된 올바른 인덱스 번호 : D_OK, 올바르지 않은 혹은 존재하지 않은 윈도우 번호값 : D_INVALID
*/
DWORD DAPI::CDevice::GetDeviceStatus(int index)
{
	if (index >= this->nWindowCount)
	{
		return DAPI::D_INVALID;
	}

	if (index > 0)
	{
		DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;
		if (GetWindow(deviceinfo->hWnd, 0) == NULL)
		{
			return DAPI::D_INVALID;
		}
	}

	return DAPI::D_OK;
}

/*
public

@brief  장면 렌더링 시작
@param  index 생성된 윈도우의 index 번호
@return 장면 초기화 성공시 TRUE, 실패시 FALSE
*/
BOOL DAPI::CDevice::BeginScene(int index)
{
	if (this->GetDeviceStatus(index) == DAPI::D_INVALID) return FALSE;

	DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;

	// 장면 다시 그리기 WM_PAINT 호출
	if (!InvalidateRect(deviceinfo->hWnd, NULL, FALSE))
		return FALSE;

	deviceinfo->hDC = BeginPaint(deviceinfo->hWnd, &(this->ps));

	// 더블 버퍼링 초기화
	deviceinfo->hMemDC = CreateCompatibleDC(deviceinfo->hDC);

	deviceinfo->hBit = CreateCompatibleBitmap(deviceinfo->hDC, deviceinfo->width, deviceinfo->height);
	deviceinfo->hMemBit = (HBITMAP)SelectObject(deviceinfo->hMemDC, deviceinfo->hBit);

	return TRUE;
}

/*
public

@brief  장면 렌더링 종료
@param  index 생성된 윈도우의 index 번호
@return 성공시 TRUE, 실패시 FALSE
*/
BOOL DAPI::CDevice::EndScene(int index)
{
	if (this->GetDeviceStatus(index) == DAPI::D_INVALID) return FALSE;
	
	DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;
	
	// 더블 버퍼링 처리
	BitBlt(deviceinfo->hDC, 0, 0, deviceinfo->width, deviceinfo->height, deviceinfo->hMemDC, 0, 0, SRCCOPY);

	SelectObject(deviceinfo->hMemDC, deviceinfo->hMemBit);
	DeleteObject(deviceinfo->hBit);
	DeleteDC(deviceinfo->hMemDC);

	return EndPaint(deviceinfo->hWnd, &(this->ps));
}

/*
public

@brief  인자로 전달된 DC를 복사하여 렌더링
@param  index 생성된 윈도우의 index 번호
@param  hSrcDC 지정한 윈도우에 그려질 복사 대상이 되는 HDC 객체
@param  rectSize HDC 에서 그리게 될 영역에 대한 값
@param  x 윈도우 상에서 그려지게 될 X 좌표값
@param  y 윈도우 상에서 그려지게 될 Y 좌표값
@return 성공시 TRUE, 실패시 FALSE
*/
BOOL DAPI::CDevice::CopyDC(int index, const HDC hSrcDC, const RECT rectSize, int x, int y)
{
	if (this->GetDeviceStatus(index) == DAPI::D_INVALID) return FALSE;
	
	DAPI::DAPI_DeviceStruct * deviceinfo = this->dDeviceInfo + index;
	return BitBlt(deviceinfo->hMemDC, x, y, rectSize.right, rectSize.bottom, hSrcDC, rectSize.left, rectSize.top, SRCCOPY);
}

/*
public

@brief  특정 키의 상태값을 반환
@param  keyCode 상태값을 구할 키코드 값
@return DAPI_KeyStatus의 enum 형태로 반환
*/
DWORD DAPI::CDevice::GetKeyCodeState(int keyCode)
{
	if (GetAsyncKeyState(keyCode) & 0x8000)
		return DAPI::D_DOWN;

	return DAPI::D_UP;
}

/*
public

@brief  마우스 좌표값 얻는 함수
@return 마우스 좌표 객체
*/
POINTS DAPI::CDevice::GetMouseState()
{
	return DAPI::mMousePoint;
}

/*
public

@brief  해당영역 내부에 마우스의 커서가 위치했는지의 여부를 판단
@param  체크할 영역 위치
@return 위치한 경우 TRUE 아니면 FALSE
*/
BOOL DAPI::CDevice::IsMouseOver(LPRECT rec) const
{
	POINTS pMousePoints = const_cast<DAPI::CDevice*>(this)->GetMouseState();

	if (pMousePoints.x >= rec->left && pMousePoints.x <= rec->right)
		if (pMousePoints.y >= rec->top && pMousePoints.y <= rec->bottom)
			return TRUE;

	return FALSE;
}

/*
public

@brief  해당영역 내부에서 마우스를 클릭하였는지 여부를 판단(여러번 중첩 실행될 수 있음)
@param  체크할 영역 위치
@return 클릭한 경우 TRUE 아니면 FALSE
*/
BOOL DAPI::CDevice::IsMouseClick(LPRECT rec) const
{
	if (this->IsMouseOver(rec) && DAPI::wMouseClick != 0)
	{
		return TRUE;
	}
	return FALSE;
}

/*
public

@brief  해당영역 내부에서 마우스를 클릭하였는지 여부를 판단(단 한번만 실행)
@param  체크할 영역 위치
@return 클릭한 경우 TRUE 아니면 FALSE
*/
BOOL DAPI::CDevice::IsMouseClickOnce(LPRECT rec) const
{
	if (this->IsMouseOver(rec) && DAPI::wMouseClickOnce != 0)
	{
		DAPI::wMouseClickOnce = 0;
		return TRUE;
	}
	return FALSE;
}
/*
public

@brief  특정 이벤트 메시지 핸들러 함수 등록
@param  이벤트 번호값
@param  핸들러 함수 포인터
*/
void DAPI::CDevice::AddEventHandler(UINT uMsg, DAPI::WindowMessageFunc wmFunc)
{
	DAPI::mMsgMap[uMsg] = wmFunc;
}

/*
public

@brief  등록한 이벤트 핸들러 함수를 제거
@param  이벤트 번호값
*/
void DAPI::CDevice::DeleteEventHandler(UINT uMsg)
{
	DAPI::mMsgMap.erase(uMsg);
}

/*
private

@brief  WNDCLASS 등록
*/
void DAPI::CDevice::WinMain()
{
	WNDCLASS wc;
	
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
	wc.hInstance = this->hInstance;
	wc.lpfnWndProc = this->WinProc;
	wc.lpszClassName = this->lpcVer;
	wc.lpszMenuName = NULL;
	wc.style = CS_HREDRAW | CS_VREDRAW;

	RegisterClass(&wc);
}

/*
private

@brief  윈도우 메시지 처리
@param  hWnd
@param  uMsg
@param  wParam
@param  lParam
@return DefWindowProc() 반환값
*/
LRESULT CALLBACK DAPI::CDevice::WinProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// 만약 등록된 핸들러 함수가 존재할 경우 실행
	if (DAPI::mMsgMap[uMsg])
	{
		return DAPI::mMsgMap[uMsg](hWnd, wParam, lParam);
	}

	switch (uMsg)
	{
	case WM_MOUSEMOVE:
		DAPI::mMousePoint = MAKEPOINTS(lParam);
		break;
	case WM_LBUTTONDOWN:
		DAPI::wMouseClick = lParam;
		DAPI::wMouseClickOnce = 0;
		break;
	case WM_LBUTTONUP:
		DAPI::wMouseClick = 0;
		DAPI::wMouseClickOnce = lParam;
		break;
	}

	return DefWindowProc(hWnd, uMsg, wParam, lParam);
}
