#include "dapi_engine.h"

DAPI::CFont::CFont()
{
	DAPI_InitlizeObject(&(this->pDevice));

	this->nFontCount = 0;
}

DAPI::CFont::~CFont()
{
	for (int i = 0; i < this->nFontCount; i++)
	{
		if (this->hFont[i] != NULL) DeleteObject(this->hFont[i]);
	}
}

/*
public

@brief  글꼴 파일을 로드하는 함수
@param  name 글꼴 이름
@param  size 글꼴 크기
@param  style 글꼴 속성
@return 생성한 글꼴의 index
*/
int DAPI::CFont::LoadFont(const LPCTSTR name, int size, int style)
{
	this->hFont[this->nFontCount] = CreateFont(size, 0, 0, 0, style, FALSE, FALSE, FALSE, 
		ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, 
		VARIABLE_PITCH | FF_ROMAN, name);

	return this->nFontCount++;
}

/*
public

@brief  화면에 글씨를 출력하는 함수
@param  wndIndex 출력할 윈도우 index
@param  fontIndex 출력할 글꼴 속성 index
@param  text 출력할 텍스트
@param  x 출력할 텍스트 x 좌표
@param  y 출력할 텍스트 y 좌표
@param  rgbFont 글씨 색상
@param  rgbBackColor 글씨 배경 색상
@return TRUE
*/
BOOL DAPI::CFont::Text(int wndIndex, int fontIndex, const LPCTSTR text, int x, int y, COLORREF rgbFont, COLORREF rgbBackColor)
{
	if (this->pDevice->GetDeviceStatus(wndIndex) == DAPI::D_INVALID) return FALSE;

	DAPI::DAPI_DeviceStruct * deviceinfo = this->pDevice->GetDeviceInfo(wndIndex);
	HFONT hOldFont = (HFONT)SelectObject(deviceinfo->hMemDC, this->hFont[fontIndex]);

	SetTextColor(deviceinfo->hMemDC, rgbFont);
	SetBkColor(deviceinfo->hMemDC, rgbBackColor);
	TextOut(deviceinfo->hMemDC, x, y, text, _tcsclen(text));
	SelectObject(deviceinfo->hMemDC, hOldFont);

	return TRUE;
}
