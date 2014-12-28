/*
DAPI Engine (윈도우 2D 그래픽 처리 엔진)

개발자 : 김병욱 (quddnr145@naver.com)
주  소 : http://www.pj-room.com/
링  크 : http://cafe.naver.com/mmorpgs
*/
#ifndef _DAPI_ENGINE_H_
#define _DAPI_ENGINE_H_

#include "dapi_global.h"
#include "dapi_device.h"
#include "dapi_font.h"

namespace DAPI
{
	// 싱글톤 패턴용 객체 생성
	static DAPI_DEVICE * pDevice = NULL;
	static DAPI_FONT * pFont = NULL;

	/*
	@brief  Device 객체 생성
	@param  pObject DAPI_DEVICE객체의 NULL 포인터
	@return 생성된 DAPI_DEVICE 객체 반환
	*/
	void DAPI_InitlizeObject(LPDAPI_DEVICE * pObject);
	
	/*
	@brief  Font 객체 생성
	@param  pObject DAPI_FONT객체의 NULL 포인터
	@return 생성된 DAPI_FONT 객체 반환
	*/
	void DAPI_InitlizeObject(LPDAPI_FONT * pObject);
	
	/*
	@brief  생성된 모든 DAPI 객체 메모리 반환
	*/
	void DAPI_DeleteObject();
};

#endif
