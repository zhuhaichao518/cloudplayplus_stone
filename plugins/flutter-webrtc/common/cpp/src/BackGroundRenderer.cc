#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")
//#pragma warning(disable:4819)
#include <dxgi1_6.h>
#include <d3d11_1.h>
#include <d3dcompiler.h>
#include "BackGroundRenderer.h"
#include <directxmath.h>
#include "DuplicationManager.h"

using namespace DirectX;

static HWND _child = 0;
static bool _need_resize = true;

LRESULT CALLBACK BackWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_SIZE:
    {
        //UINT width = LOWORD(lParam); 
        //UINT height = HIWORD(lParam); 
        /* if (_child) {
           SetWindowPos(_child, NULL, 0, 0, width, height, 0 /*SWP_NOZORDER | SWP_NOACTIVATE);
        }*/
        _need_resize = true;
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    //case WM_DESTROY:
        //PostQuitMessage(0);
       // return 0;
    default:
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}

//--------------------------------------------------------------------------------------
// Helper for compiling shaders with D3DCompile
//
// With VS 11, we could load up prebuilt .cso files instead...
//--------------------------------------------------------------------------------------
HRESULT CompileShaderFromFile(const WCHAR* szFileName,
                              LPCSTR szEntryPoint,
                              LPCSTR szShaderModel,
                              ID3DBlob** ppBlobOut) {
  HRESULT hr = S_OK;

  DWORD dwShaderFlags = D3DCOMPILE_ENABLE_STRICTNESS;
#ifdef _DEBUG
  // Set the D3DCOMPILE_DEBUG flag to embed debug information in the shaders.
  // Setting this flag improves the shader debugging experience, but still
  // allows the shaders to be optimized and to run exactly the way they will run
  // in the release configuration of this program.
  dwShaderFlags |= D3DCOMPILE_DEBUG;

  // Disable optimizations to further improve shader debugging
  dwShaderFlags |= D3DCOMPILE_SKIP_OPTIMIZATION;
#endif

  ID3DBlob* pErrorBlob = nullptr;
  hr = D3DCompileFromFile(szFileName, nullptr, nullptr, szEntryPoint,
                          szShaderModel, dwShaderFlags, 0, ppBlobOut,
                          &pErrorBlob);
  if (FAILED(hr)) {
    if (pErrorBlob) {
      OutputDebugStringA(
          reinterpret_cast<const char*>(pErrorBlob->GetBufferPointer()));
      pErrorBlob->Release();
    }
    return hr;
  }
  if (pErrorBlob)
    pErrorBlob->Release();

  return S_OK;
}

//--------------------------------------------------------------------------------------
// Create Direct3D device and swap chain
//--------------------------------------------------------------------------------------
HRESULT BackGroundRenderer::InitDevice()
{
    HRESULT hr = S_OK;

    UINT createDeviceFlags = 0;
#ifdef _DEBUG
    createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
#endif

    D3D_DRIVER_TYPE driverTypes[] =
    {
        D3D_DRIVER_TYPE_HARDWARE,
        D3D_DRIVER_TYPE_WARP,
        D3D_DRIVER_TYPE_REFERENCE,
    };
    UINT numDriverTypes = ARRAYSIZE(driverTypes);

    D3D_FEATURE_LEVEL featureLevels[] =
    {
        D3D_FEATURE_LEVEL_11_1,
        D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0,
    };
    UINT numFeatureLevels = ARRAYSIZE(featureLevels);

/*
    IDXGIFactory6* pFactory = nullptr;
    hr = CreateDXGIFactory1(IID_PPV_ARGS(&pFactory));

    if (FAILED(hr)) {
        return -1;
    }

    IDXGIAdapter* pAdapter = nullptr;

    pFactory->EnumAdapterByGpuPreference(0, DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE, __uuidof(IDXGIAdapter), (void**)(&pAdapter));
    
    pFactory->Release();
    if (pAdapter == nullptr) {
        //std::cout << "Dedicated GPU not found." << std::endl;
        return -1;
    }
*/

    for (UINT driverTypeIndex = 0; driverTypeIndex < numDriverTypes; driverTypeIndex++)
    {
        g_driverType = driverTypes[driverTypeIndex];
        hr = D3D11CreateDevice(nullptr, /*D3D_DRIVER_TYPE_UNKNOWN */ g_driverType, nullptr, createDeviceFlags, featureLevels, numFeatureLevels,
            D3D11_SDK_VERSION, &m_device, &g_featureLevel, &g_pImmediateContext);

        if (hr == E_INVALIDARG)
        {
            // DirectX 11.0 platforms will not recognize D3D_FEATURE_LEVEL_11_1 so we need to retry without it
            hr = D3D11CreateDevice(nullptr, g_driverType, nullptr, createDeviceFlags, &featureLevels[1], numFeatureLevels - 1,
                D3D11_SDK_VERSION, &m_device, &g_featureLevel, &g_pImmediateContext);
        }

        if (SUCCEEDED(hr))
            break;
    }
    if (FAILED(hr))
        return hr;

    // Obtain DXGI factory from device (since we used nullptr for pAdapter above)
    IDXGIFactory1* dxgiFactory = nullptr;
    {
        IDXGIDevice* dxgiDevice = nullptr;
        hr = m_device->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&dxgiDevice));
        if (SUCCEEDED(hr))
        {
            IDXGIAdapter* adapter = nullptr;
            hr = dxgiDevice->GetAdapter(&adapter);
            if (SUCCEEDED(hr))
            {
                hr = adapter->GetParent(__uuidof(IDXGIFactory1), reinterpret_cast<void**>(&dxgiFactory));
                adapter->Release();
            }
            dxgiDevice->Release();
        }
    }
    if (FAILED(hr))
        return hr;

    // Create swap chain
    IDXGIFactory2* dxgiFactory2 = nullptr;
    hr = dxgiFactory->QueryInterface(__uuidof(IDXGIFactory2), reinterpret_cast<void**>(&dxgiFactory2));
    if (dxgiFactory2)
    {
        // DirectX 11.1 or later
        hr = m_device->QueryInterface(__uuidof(ID3D11Device1), reinterpret_cast<void**>(&m_device1));
        if (SUCCEEDED(hr))
        {
            (void)g_pImmediateContext->QueryInterface(__uuidof(ID3D11DeviceContext1), reinterpret_cast<void**>(&g_pImmediateContext1));
        }

        DXGI_SWAP_CHAIN_DESC1 sd = {};
        sd.Width = m_width;
        sd.Height = m_width;
        sd.Format = DXGI_FORMAT_B8G8R8A8_UNORM;//DXGI_FORMAT_R8G8B8A8_UNORM;
        sd.SampleDesc.Count = 1;
        sd.SampleDesc.Quality = 0;
        sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        // Haichao: compare setting this to 1 and remove the scaling, etc.
        sd.BufferCount = 2;
        
        
        sd.Scaling =  DXGI_SCALING_STRETCH;//DXGI_SCALING_NONE;//DXGI_SCALING_STRETCH;
        sd.AlphaMode = DXGI_ALPHA_MODE_UNSPECIFIED;
        //flip discard seems adds latency?
        sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD; //DXGI_SWAP_EFFECT_FLIP_DISCARD;//DXGI_SWAP_EFFECT_DISCARD;
        sd.Flags = 0;
        hr = dxgiFactory2->CreateSwapChainForHwnd(m_device, m_hwnd, &sd, nullptr, nullptr, &g_pSwapChain1);
        if (SUCCEEDED(hr))
        {
            hr = g_pSwapChain1->QueryInterface(__uuidof(IDXGISwapChain), reinterpret_cast<void**>(&g_pSwapChain));
        }

        dxgiFactory2->Release();
    }
    else
    {
        // DirectX 11.0 systems
        DXGI_SWAP_CHAIN_DESC sd = {};
        sd.BufferCount = 1;
        sd.BufferDesc.Width = m_width;
        sd.BufferDesc.Height = m_height;
        sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        sd.BufferDesc.RefreshRate.Numerator = 60;
        sd.BufferDesc.RefreshRate.Denominator = 1;
        sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        sd.OutputWindow = m_hwnd;
        sd.SampleDesc.Count = 1;
        sd.SampleDesc.Quality = 0;
        sd.Windowed = TRUE;

        hr = dxgiFactory->CreateSwapChain(m_device, &sd, &g_pSwapChain);
    }

    // Note this tutorial doesn't handle full-screen swapchains so we block the ALT+ENTER shortcut
    // dxgiFactory->MakeWindowAssociation(g_hWnd, DXGI_MWA_NO_ALT_ENTER);

    dxgiFactory->Release();

    if (FAILED(hr))
        return hr;

    return S_OK;
}

struct SimpleVertex {
  XMFLOAT3 Pos;
  XMFLOAT2 Tex;  // 添加纹理坐标
};


DWORD WINAPI ThreadFunc(LPVOID lpParam) {
    // 创建窗口类
    WNDCLASS wc = {0};
    wc.lpfnWndProc = DefWindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = TEXT("MyWindowClass");

    if (!RegisterClass(&wc)) {
        // 处理错误
        return 1;
    }

    // 创建窗口
    HWND hwnd = CreateWindowEx(
        WS_EX_TOOLWINDOW,
        wc.lpszClassName,
        TEXT("子线程窗口"),
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL,
        NULL,
        wc.hInstance,
        NULL);

    if (!hwnd) {
        // 处理错误
        return 1;
    }

    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    // 消息循环
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

DUPLICATIONMANAGER* DuplMgr;
// 构造函数
BackGroundRenderer::BackGroundRenderer(ID3D11Device* device, HWND child)
    : m_device(device) {

    // Register & create window
    WNDCLASS wc = {};
    wc.lpfnWndProc = BackWindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = L"CloudPlayPlusRenderer";

    RegisterClass(&wc);

    //LONG style = GetWindowLong(child, GWL_STYLE);
    //style = (style & ~WS_OVERLAPPEDWINDOW) | WS_CHILD;
    //SetWindowLong(child, GWL_STYLE, style);

    RECT childRect;
    GetWindowRect(child, &childRect);

    // adjust and remove title bar
    DWORD windowStyle = WS_POPUP;//WS_OVERLAPPEDWINDOW; //| */WS_POPUP; //| WS_THICKFRAME;

    // 计算child窗口的宽度和高度
    int childWidth = childRect.right - childRect.left;
    int childHeight = childRect.bottom - childRect.top;

    m_width = childWidth;
    m_height = childHeight;
    // 创建窗口
    m_hwnd = CreateWindowEx(
        0,                              // Optional window styles.
        L"CloudPlayPlusRenderer", // Window class
        L"CloudPlayPlus Renderer",      // Window text
        windowStyle,                    // Window style - WS_POPUP for no title bar

        // Position and size to match the child window
        //0, 0, childRect.right, childRect.bottom,
        childRect.left, childRect.top, childWidth, childHeight,
        NULL,       // Parent window    
        NULL,       // Menu
        GetModuleHandle(NULL),  // Instance handle
        NULL        // Additional application data
    );

    if (m_hwnd == NULL) {
        // handle creation fail
        return;
    }

    HRESULT hr;

    if (m_device) {
        m_device->GetImmediateContext(&g_pImmediateContext);
    } else {
        InitDevice();
    }

/*
    D3D11_VIEWPORT viewport;
    viewport.Width = static_cast<float>(childWidth);  // 使用捕获的帧宽度
    viewport.Height = static_cast<float>(childHeight); // 使用捕获的帧高度
    viewport.MinDepth = 0.0f;
    viewport.MaxDepth = 1.0f;
    viewport.TopLeftX = 0;
    viewport.TopLeftY = 0;

    g_pImmediateContext->RSSetViewports(1, &viewport);
*/

    // Compile the vertex shader
    ID3DBlob* pVSBlob = nullptr;
    hr = CompileShaderFromFile(L"SimpleShader.fxh", "VS", "vs_4_0", &pVSBlob);
    if (FAILED(hr))
    {
        MessageBox(nullptr,
            L"The FX file cannot be compiled.  Please run this executable from the directory that contains the FX file.", L"Error", MB_OK);
        return;
    }

    // Create the vertex shader
    hr = m_device->CreateVertexShader(pVSBlob->GetBufferPointer(), pVSBlob->GetBufferSize(), nullptr, &g_pVertexShader);
    if (FAILED(hr))
    {
        pVSBlob->Release();
        return;
    }

    // Define the input layout
    D3D11_INPUT_ELEMENT_DESC layout[] =
    {
        { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
        { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0 }, 
    };
    UINT numElements = ARRAYSIZE(layout);

    // Create the input layout
    hr = m_device->CreateInputLayout(layout, numElements, pVSBlob->GetBufferPointer(),
        pVSBlob->GetBufferSize(), &g_pVertexLayout);
    pVSBlob->Release();
    if (FAILED(hr)) {
      MessageBox(nullptr,
                 L"Create Input Layout failed "
                 L".",
                 L"Error", MB_OK);
      return; 
    }

    // Set the input layout
    g_pImmediateContext->IASetInputLayout(g_pVertexLayout);

    // Compile the pixel shader
    ID3DBlob* pPSBlob = nullptr;
    hr = CompileShaderFromFile(L"SimpleShader.fxh", "PS", "ps_4_0", &pPSBlob);
    if (FAILED(hr))
    {
        MessageBox(nullptr,
            L"The FX file cannot be compiled.  Please run this executable from the directory that contains the FX file.", L"Error", MB_OK);
        return;
    }

    // Create the pixel shader
    hr = m_device->CreatePixelShader(pPSBlob->GetBufferPointer(), pPSBlob->GetBufferSize(), nullptr, &g_pPixelShader);
    pPSBlob->Release();
    if (FAILED(hr))
        return;

    // Create vertex buffer
    SimpleVertex vertices[] =
    {
        { XMFLOAT3(-1.0f, 1.0f, 0.0f), XMFLOAT2(0.0f, 0.0f) },
        { XMFLOAT3(1.0f, 1.0f, 0.0f), XMFLOAT2(1.0f, 0.0f) },
        { XMFLOAT3(-1.0f, -1.0f, 0.0f), XMFLOAT2(0.0f, 1.0f) }, 

        // 第二个三角形
        { XMFLOAT3(1.0f, -1.0f, 0.0f), XMFLOAT2(1.0f, 1.0f) },
        { XMFLOAT3(-1.0f, -1.0f, 0.0f), XMFLOAT2(0.0f, 1.0f) }, 
        { XMFLOAT3(1.0f, 1.0f, 0.0f), XMFLOAT2(1.0f, 0.0f) },   
    };

    D3D11_BUFFER_DESC bd = {};
    bd.Usage = D3D11_USAGE_DEFAULT;
    bd.ByteWidth = sizeof(SimpleVertex) * 6;
    bd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
    bd.CPUAccessFlags = 0;

    D3D11_SUBRESOURCE_DATA InitData = {};
    InitData.pSysMem = vertices;
    hr = m_device->CreateBuffer(&bd, &InitData, &g_pVertexBuffer);
    if (FAILED(hr))
        return;

    // Set vertex buffer
    UINT stride = sizeof(SimpleVertex);
    UINT offset = 0;
    g_pImmediateContext->IASetVertexBuffers(0, 1, &g_pVertexBuffer, &stride, &offset);

    // Set primitive topology
    g_pImmediateContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

    g_pImmediateContext->VSSetShader(g_pVertexShader, nullptr, 0);
    g_pImmediateContext->PSSetShader(g_pPixelShader, nullptr, 0);


    ShowWindow(m_hwnd, SW_SHOW);

    //SetParent(child, m_hwnd);
    //set owner to let the visibility follow the main flutter window.
    SetWindowLongPtr(child, GWLP_HWNDPARENT, reinterpret_cast<LONG_PTR> (m_hwnd));

    // 将_child客户区左上角的坐标转换为屏幕坐标
    POINT topLeft = { childRect.left, childRect.top };
    ClientToScreen(child, &topLeft);

    // 同样地，转换右下角的坐标，以确保使用正确的宽度和高度
    //POINT bottomRight = { childRect.right, childRect.bottom };
    //ClientToScreen(child, &bottomRight);

    // 调整m_hwnd的位置和大小，以匹配_child的客户区
    // 并确保m_hwnd显示在_child下面

    SetWindowPos(m_hwnd, HWND_NOTOPMOST, topLeft.x, topLeft.y,
                              childWidth, childHeight, SWP_NOACTIVATE);
    //SetWindowLongPtr(child, GWL_STYLE, WS_POPUP | WS_VISIBLE);
    //SetWindowPos(child, HWND_NOTOPMOST, 0, 0, m_width, m_height,
    //            SWP_SHOWWINDOW | SWP_NOMOVE | SWP_NOSIZE/*SWP_NOZORDER | SWP_NOACTIVATE*/);

        //::SetWindowLong(child, GWL_STYLE,
        //            ::GetWindowLong(child, GWL_STYLE) &
        //                (0xFFFFFFFF ^ WS_SYSMENU));
    DuplMgr = new DUPLICATIONMANAGER();
    DuplMgr->InitDupl(m_device,0);

    _child = child;
}

HRESULT BackGroundRenderer::AttachToWindowAsBackGround(HWND hwnd) {

    return S_OK; //
}

// 
void BackGroundRenderer::RenderTexture(ID3D11Texture2D* texture, int width, int height) {
    HRESULT hr;
    // 先获取_child窗口客户区的尺寸
    RECT childRect;
    GetClientRect(_child, &childRect);

    // 将_child客户区左上角的坐标转换为屏幕坐标
    POINT topLeft = { childRect.left, childRect.top };
    ClientToScreen(_child, &topLeft);

    // 同样地，转换右下角的坐标，以确保使用正确的宽度和高度
    POINT bottomRight = { childRect.right, childRect.bottom };
    ClientToScreen(_child, &bottomRight);

    // 计算宽度和高度
    int childWidth = bottomRight.x - topLeft.x;
    int childHeight = bottomRight.y - topLeft.y;

    // 调整m_hwnd的位置和大小，以匹配_child的客户区
    // 并确保m_hwnd显示在_child下面
    hr = SetWindowPos(m_hwnd, HWND_NOTOPMOST, topLeft.x, topLeft.y,
                              childWidth, childHeight, SWP_NOACTIVATE);
    //hr = SetWindowPos(_child, HWND_NOTOPMOST, topLeft.x, topLeft.y, childWidth,
    //                  childHeight, SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE); */
    //SetForegroundWindow(_child);

    //if (hr == 0) {
    //  hr = GetLastError();
    //}

    if (texture == nullptr) {
        FRAME_DATA CurrentData;
        bool TimeOut;
        int Ret = DuplMgr->GetFrame(&CurrentData, &TimeOut);
        if (Ret != DUPL_RETURN_SUCCESS)
        {
            // An error occurred getting the next frame drop out of loop which
            // will check if it was expected or not
            return;
        }

        // Check for timeout
        if (TimeOut)
        {
            // No new frame at the moment
            return;
        }
        //Clear the back buffer 
        //float bgColor[4] = { 0.0f, 0.0f, 0.0f, 1.0f }; // RGBA
        //g_pImmediateContext->ClearRenderTargetView(g_pRenderTargetView, bgColor);
        
        if (_need_resize) {
            g_pImmediateContext->OMSetRenderTargets(0, 0, 0);

            // Release all outstanding references to the swap chain's buffers.
            if (g_pRenderTargetView) {
                g_pRenderTargetView->Release();
                g_pRenderTargetView = nullptr;
            }

            // Preserve the existing buffer count and format.
            // Automatically choose the width and height to match the client rect for HWNDs.
            hr = g_pSwapChain->ResizeBuffers(0, 0, 0, DXGI_FORMAT_UNKNOWN, 0);

            // Perform error handling here!

            // Get buffer and create a render-target-view.
            ID3D11Texture2D* pBuffer;
            hr = g_pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D),
                (void**)&pBuffer);
            // Perform error handling here!

            hr = m_device->CreateRenderTargetView(pBuffer, NULL,
                &g_pRenderTargetView);
            // Perform error handling here!
            pBuffer->Release();

            g_pImmediateContext->OMSetRenderTargets(1, &g_pRenderTargetView, NULL);
            _need_resize = false;
        }
        
        //set again? Haichao: remove?
        g_pImmediateContext->VSSetShader(g_pVertexShader, nullptr, 0);
        g_pImmediateContext->PSSetShader(g_pPixelShader, nullptr, 0);
 
        D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc = {};
        srvDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM; //
        srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
        srvDesc.Texture2D.MostDetailedMip = (UINT)0;  // detal mip
        srvDesc.Texture2D.MipLevels = (UINT)-1;       // all mip

        ID3D11ShaderResourceView* pShaderResourceView = nullptr;
        hr = m_device->CreateShaderResourceView(
            CurrentData.Frame,
            &srvDesc,
            &pShaderResourceView
        );
        if (hr != S_OK) {
          return;
        }

        D3D11_SAMPLER_DESC sampDesc = {};
        sampDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        sampDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
        sampDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        sampDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
        sampDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;
        sampDesc.MinLOD = 0;
        sampDesc.MaxLOD = D3D11_FLOAT32_MAX;
        ID3D11SamplerState* pSamplerState = nullptr;
        m_device->CreateSamplerState(&sampDesc, &pSamplerState);
        g_pImmediateContext->PSSetSamplers(0, 1, &pSamplerState);

        g_pImmediateContext->PSSetShaderResources(0u, 1u, &pShaderResourceView);


        ID3D11Texture2D* pFrameTexture = CurrentData.Frame;

        D3D11_TEXTURE2D_DESC descFrame;
        pFrameTexture->GetDesc(&descFrame);

        RECT rc;
        GetClientRect(m_hwnd, &rc);
        float targetAspectRatio = (float)(rc.right - rc.left) / (float)(rc.bottom - rc.top);
        float contentAspectRatio = (float)descFrame.Width / (float)descFrame.Height; 

        UINT vpWidth, vpHeight;
        float offsetX = 0, offsetY = 0;
        if (targetAspectRatio > contentAspectRatio) {
            vpHeight = rc.bottom - rc.top;
            vpWidth = (UINT)(vpHeight * contentAspectRatio);
            offsetX = float((rc.right - rc.left - vpWidth) / 2.0);
        }
        else {
            vpWidth = rc.right - rc.left;
            vpHeight = (UINT)(vpWidth / contentAspectRatio);
            offsetY = float((rc.bottom - rc.top - vpHeight) / 2.0);
        }

        D3D11_VIEWPORT viewport;
        viewport.Width = (FLOAT)vpWidth;
        viewport.Height = (FLOAT)vpHeight;
        viewport.MinDepth = 0.0f;
        viewport.MaxDepth = 1.0f;
        viewport.TopLeftX = offsetX;
        viewport.TopLeftY = offsetY;

        g_pImmediateContext->RSSetViewports(1, &viewport);

        g_pImmediateContext->Draw(6, 0);
        pSamplerState->Release();

        DuplMgr->DoneWithFrame();

        if (pShaderResourceView)
        {
            pShaderResourceView->Release();
            pShaderResourceView = nullptr;
        }

        //-haichao

        // Present the information rendered to the back buffer to the front buffer (the screen)
        g_pSwapChain->Present(0, 0);        
    }
}

void BackGroundRenderer::Release(){
    //DuplMgr->DoneWithFrame();
    delete DuplMgr;
    if (m_device) {
        m_device->Release();
    }
    if (m_device1) {
        m_device1->Release();
    }

    if (g_pImmediateContext)
      g_pImmediateContext->ClearState();
    if (g_pImmediateContext) {
        g_pImmediateContext->Release();
    }
    if (g_pImmediateContext1) {
        g_pImmediateContext1->Release();
    }

    if (g_pVertexBuffer)
      g_pVertexBuffer->Release();
    if (g_pVertexLayout)
      g_pVertexLayout->Release();
    if (g_pVertexShader)
      g_pVertexShader->Release();
    if (g_pPixelShader)
      g_pPixelShader->Release();
    if (g_pRenderTargetView)
      g_pRenderTargetView->Release();
    if (g_pSwapChain1)
      g_pSwapChain1->Release();
    if (g_pSwapChain)
      g_pSwapChain->Release();
    if (m_hwnd) {
      SetWindowLongPtr(_child, GWLP_HWNDPARENT,
                       reinterpret_cast<LONG_PTR>(nullptr));
      DestroyWindow(m_hwnd);
    }
}


BackGroundRenderer::~BackGroundRenderer() {
  Release();
}
