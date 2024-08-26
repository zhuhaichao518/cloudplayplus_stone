#ifndef _BACKGROUNDRENDERER_H_
#define _BACKGROUNDRENDERER_H_
#include <d3d11_1.h>
class BackGroundRenderer {
public:
	BackGroundRenderer(ID3D11Device* device, HWND child);
    void RenderTexture(ID3D11Texture2D* texture, int width, int height);
    void Release();
    ~BackGroundRenderer();

private:
	ID3D11Device* m_device = nullptr;
    ID3D11Device1* m_device1 = nullptr;
	ID3D11DeviceContext* g_pImmediateContext = nullptr;
	ID3D11DeviceContext1* g_pImmediateContext1 = nullptr;
	IDXGISwapChain* g_pSwapChain = nullptr;
	IDXGISwapChain1* g_pSwapChain1 = nullptr;
    D3D_DRIVER_TYPE g_driverType = D3D_DRIVER_TYPE_NULL;
    D3D_FEATURE_LEVEL g_featureLevel = D3D_FEATURE_LEVEL_11_0;
    ID3D11RenderTargetView* g_pRenderTargetView = nullptr;
    ID3D11VertexShader* g_pVertexShader = nullptr;
    ID3D11PixelShader* g_pPixelShader = nullptr;
    ID3D11InputLayout* g_pVertexLayout = nullptr;
    ID3D11Buffer* g_pVertexBuffer = nullptr;

	HWND m_hwnd;
	int m_width, m_height;
	HRESULT AttachToWindowAsBackGround(HWND hwnd);
    HRESULT InitDevice();
    //void RenderPixel(uint8_t * buffer, int width, int height);
	//~BackGroundRenderer();
};

#endif