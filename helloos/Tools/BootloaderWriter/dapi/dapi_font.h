#ifndef _DAPI_FONT_H_
#define _DAPI_FONT_H_

// 최대 생성 가능한 글꼴 객체 개수
const int MAX_FONTS = 20;

namespace DAPI
{
	class CFont
	{
	private:
		HFONT hFont[MAX_FONTS];
		DAPI_DEVICE * pDevice;

		int nFontCount;
	public:
		CFont();
		virtual ~CFont();

		int LoadFont(const LPCTSTR name, int size, int style);
		BOOL Text(int wndIndex, int fontIndex, const LPCTSTR text, int x, int y, COLORREF rgbFont = RGB(255, 255, 255), COLORREF rgbBackColor = TRANSPARENT);
	};
	typedef CFont DAPI_FONT;
	typedef CFont * LPDAPI_FONT;
};

#endif
