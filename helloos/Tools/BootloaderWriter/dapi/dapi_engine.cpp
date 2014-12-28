#include "dapi_engine.h"

/*
@brief  Device 按眉 积己
@param  pObject DAPI_DEVICE按眉狼 NULL 器牢磐
@return 积己等 DAPI_DEVICE 按眉 馆券
*/
void DAPI::DAPI_InitlizeObject(LPDAPI_DEVICE * pObject)
{
	if (DAPI::pDevice == NULL) DAPI::pDevice = new DAPI::DAPI_DEVICE;
	*pObject = DAPI::pDevice;
}
	
/*
@brief  Font 按眉 积己
@param  pObject DAPI_FONT按眉狼 NULL 器牢磐
@return 积己等 DAPI_FONT 按眉 馆券
*/
void DAPI::DAPI_InitlizeObject(LPDAPI_FONT * pObject)
{
	if (DAPI::pFont == NULL) DAPI::pFont = new DAPI::DAPI_FONT;
	*pObject = DAPI::pFont;
}
	
/*
@brief  积己等 葛电 DAPI 按眉 皋葛府 馆券
*/
void DAPI::DAPI_DeleteObject()
{
	if (DAPI::pDevice != NULL) delete DAPI::pDevice;
	if (DAPI::pFont != NULL) delete DAPI::pFont;
}