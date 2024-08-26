#include "flutter_data_channel.h"

#include <vector>
#include <unordered_set>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <sstream>
//
// Optional depending on your use case
//
#include <Xinput.h>

//
// The ViGEm API
//
#include <ViGEm/Client.h>

//
// Link against SetupAPI
//
#pragma comment(lib, "setupapi.lib")

namespace flutter_webrtc_plugin {

FlutterRTCDataChannelObserver::FlutterRTCDataChannelObserver(
    scoped_refptr<RTCDataChannel> data_channel,
    BinaryMessenger* messenger,
    const std::string& channelName)
    : event_channel_(EventChannelProxy::Create(messenger, channelName)),
      data_channel_(data_channel) {
  data_channel_->RegisterObserver(this);
}

FlutterRTCDataChannelObserver::~FlutterRTCDataChannelObserver() {}

void FlutterDataChannel::CreateDataChannel(
    const std::string& peerConnectionId,
    const std::string& label,
    const EncodableMap& dataChannelDict,
    RTCPeerConnection* pc,
    std::unique_ptr<MethodResultProxy> result) {
  RTCDataChannelInit init;
  init.id = GetValue<int>(dataChannelDict.find(EncodableValue("id"))->second);
  init.ordered =
      GetValue<bool>(dataChannelDict.find(EncodableValue("ordered"))->second);

  if (dataChannelDict.find(EncodableValue("maxRetransmits")) !=
      dataChannelDict.end()) {
    init.maxRetransmits = GetValue<int>(
        dataChannelDict.find(EncodableValue("maxRetransmits"))->second);
  }

  std::string protocol = "sctp";

  if (dataChannelDict.find(EncodableValue("protocol")) ==
      dataChannelDict.end()) {
    protocol = GetValue<std::string>(
        dataChannelDict.find(EncodableValue("protocol"))->second);
  }

  init.protocol = protocol;

  init.negotiated = GetValue<bool>(
      dataChannelDict.find(EncodableValue("negotiated"))->second);

  scoped_refptr<RTCDataChannel> data_channel =
      pc->CreateDataChannel(label.c_str(), &init);

  std::string uuid = base_->GenerateUUID();
  std::string event_channel =
      "FlutterWebRTC/dataChannelEvent" + peerConnectionId + uuid;

  std::unique_ptr<FlutterRTCDataChannelObserver> observer(
      new FlutterRTCDataChannelObserver(data_channel, base_->messenger_,
                                        event_channel));

  base_->lock();
  base_->data_channel_observers_[uuid] = std::move(observer);
  base_->unlock();

  EncodableMap params;
  params[EncodableValue("id")] = EncodableValue(init.id);
  params[EncodableValue("label")] =
      EncodableValue(data_channel->label().std_string());
  params[EncodableValue("flutterId")] = EncodableValue(uuid);
  result->Success(EncodableValue(params));
}

void SerializeCursorInfo(CURSORINFO ) {
  CURSORINFO cursorInfo = {sizeof(CURSORINFO)};
  if (GetCursorInfo(&cursorInfo)) {
    ICONINFO iconInfo;
    if (GetIconInfo(cursorInfo.hCursor, &iconInfo)) {

    }
  }
}

static std::map<RTCDataChannel*, HWINEVENTHOOK> hookedchannels;
static std::map<RTCDataChannel*, std::unordered_set<uint32_t>> cachedcursors;
//static std::map<uint32_t*, HWINEVENTHOOK> hookedchannels;

//static std::map<RTCDataChannel*, HWINEVENTHOOK> hookedchannels;

//static std::map<RTCDataChannel*, std::list<int>> hookedchannels;

HANDLE GetCursorHandle(HCURSOR hCursor) {
  static HCURSOR hArrow = LoadCursor(NULL, IDC_ARROW);
  if (hCursor == hArrow)
    return IDC_ARROW;

  static HCURSOR hIBeam = LoadCursor(NULL, IDC_IBEAM);
  if (hCursor == hIBeam)
    return IDC_IBEAM;

  static HCURSOR hWait = LoadCursor(NULL, IDC_WAIT);
  if (hCursor == hWait)
    return IDC_WAIT;

  static HCURSOR hCross = LoadCursor(NULL, IDC_CROSS);
  if (hCursor == hCross)
    return IDC_CROSS;

  static HCURSOR hUpArrow = LoadCursor(NULL, IDC_UPARROW);
  if (hCursor == hUpArrow)
    return IDC_UPARROW;

  // IDC_SIZE and IDC_ICON are out of date
  static HCURSOR hSize = LoadCursor(NULL, IDC_SIZE);
  if (hCursor == hSize)
    return IDC_SIZE;

  static HCURSOR hIcon = LoadCursor(NULL, IDC_ICON);
  if (hCursor == hIcon)
    return IDC_ICON;

  static HCURSOR hSizeNWSE = LoadCursor(NULL, IDC_SIZENWSE);
  if (hCursor == hSizeNWSE)
    return IDC_SIZENWSE;

  static HCURSOR hSizeNESW = LoadCursor(NULL, IDC_SIZENESW);
  if (hCursor == hSizeNESW)
    return IDC_SIZENESW;

  static HCURSOR hSizeWE = LoadCursor(NULL, IDC_SIZEWE);
  if (hCursor == hSizeWE)
    return IDC_SIZEWE;

  static HCURSOR hSizeNS = LoadCursor(NULL, IDC_SIZENS);
  if (hCursor == hSizeNS)
    return IDC_SIZENS;

  static HCURSOR hSizeAll = LoadCursor(NULL, IDC_SIZEALL);
  if (hCursor == hSizeAll)
    return IDC_SIZEALL;

  static HCURSOR hNo = LoadCursor(NULL, IDC_NO);
  if (hCursor == hNo)
    return IDC_NO;

#if (WINVER >= 0x0500)
  static HCURSOR hHand = LoadCursor(NULL, IDC_HAND);
  if (hCursor == hHand)
    return IDC_HAND;
#endif

  static HCURSOR hAppStarting = LoadCursor(NULL, IDC_APPSTARTING);
  if (hCursor == hAppStarting)
    return IDC_APPSTARTING;

#if (WINVER >= 0x0400)
  static HCURSOR hHelp = LoadCursor(NULL, IDC_HELP);
  if (hCursor == hHelp)
    return IDC_HELP;
#endif

#if (WINVER >= 0x0606)
  static HCURSOR hPin = LoadCursor(NULL, IDC_PIN);
  if (hCursor == hPin)
    return IDC_PIN;

  static HCURSOR hPerson = LoadCursor(NULL, IDC_PERSON);
  if (hCursor == hPerson)
    return IDC_PERSON;
#endif

  return NULL;
}

// DesktopFrame objects always hold BGRA data.
static const int kBytesPerPixel = 4;

bool HasAlphaChannel(const uint32_t* data, int stride, int width, int height) {
  const RGBQUAD* plane = reinterpret_cast<const RGBQUAD*>(data);
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      if (plane->rgbReserved != 0)
        return true;
      plane += 1;
    }
    plane += stride - width;
  }

  return false;
}

#define RGBA(r, g, b, a)                                   \
  ((((a) << 24) & 0xff000000) | (((b) << 16) & 0xff0000) | \
   (((g) << 8) & 0xff00) | ((r)&0xff))

// Pixel colors used when generating cursor outlines.
const uint32_t kPixelRgbaBlack = RGBA(0, 0, 0, 0xff);
const uint32_t kPixelRgbaWhite = RGBA(0xff, 0xff, 0xff, 0xff);
const uint32_t kPixelRgbaTransparent = RGBA(0, 0, 0, 0);

const uint32_t kPixelRgbWhite = RGB(0xff, 0xff, 0xff);

// Expands the cursor shape to add a white outline for visibility against
// dark backgrounds.
void AddCursorOutline(int width, int height, uint32_t* data) {
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // If this is a transparent pixel (bgr == 0 and alpha = 0), check the
      // neighbor pixels to see if this should be changed to an outline pixel.
      if (*data == kPixelRgbaTransparent) {
        // Change to white pixel if any neighbors (top, bottom, left, right)
        // are black.
        if ((y > 0 && data[-width] == kPixelRgbaBlack) ||
            (y < height - 1 && data[width] == kPixelRgbaBlack) ||
            (x > 0 && data[-1] == kPixelRgbaBlack) ||
            (x < width - 1 && data[1] == kPixelRgbaBlack)) {
          *data = kPixelRgbaWhite;
        }
      }
      data++;
    }
  }
}

// Premultiplies RGB components of the pixel data in the given image by
// the corresponding alpha components.
void AlphaMul(uint32_t* data, int width, int height) {
  static_assert(sizeof(uint32_t) == kBytesPerPixel,
                "size of uint32 should be the number of bytes per pixel");

  for (uint32_t* data_end = data + width * height; data != data_end; ++data) {
    RGBQUAD* from = reinterpret_cast<RGBQUAD*>(data);
    RGBQUAD* to = reinterpret_cast<RGBQUAD*>(data);
    to->rgbBlue =
        (static_cast<uint16_t>(from->rgbBlue) * from->rgbReserved) / 0xff;
    to->rgbGreen =
        (static_cast<uint16_t>(from->rgbGreen) * from->rgbReserved) / 0xff;
    to->rgbRed =
        (static_cast<uint16_t>(from->rgbRed) * from->rgbReserved) / 0xff;
  }
}

std::unique_ptr<uint32_t[]> CreateMouseCursorFromHCursor(HDC dc,
                                                         HCURSOR cursor,
                                                         int* final_width,
                                                         int* final_height,
                                                         int* hotspot_x,
                                                         int* hotspot_y) {
  ICONINFO iinfo;
  if (!GetIconInfo(cursor, &iinfo)) {
    //LOG_F(LS_ERROR) << "Unable to get cursor icon info. Error = "
    //                << GetLastError();
    return NULL;
  }

  
  *hotspot_x = iinfo.xHotspot;
  *hotspot_y = iinfo.yHotspot;

  // Make sure the bitmaps will be freed.
  //win::ScopedBitmap scoped_mask(iinfo.hbmMask);
  //win::ScopedBitmap scoped_color(iinfo.hbmColor);
  bool is_color = iinfo.hbmColor != NULL;
  // Get |scoped_mask| dimensions.
  BITMAP bitmap_info;
  if (!GetObject(iinfo.hbmMask, sizeof(bitmap_info), &bitmap_info)) {
    //LOG_F(LS_ERROR) << "Unable to get bitmap info. Error = " << GetLastError();
    return NULL;
  }
  int width = bitmap_info.bmWidth;
  int height = bitmap_info.bmHeight;
  std::unique_ptr<uint32_t[]> mask_data(new uint32_t[width * height]);
  // Get pixel data from |scoped_mask| converting it to 32bpp along the way.
  // GetDIBits() sets the alpha component of every pixel to 0.
  BITMAPV5HEADER bmi = {0};
  bmi.bV5Size = sizeof(bmi);
  bmi.bV5Width = width;
  bmi.bV5Height = -height;  // request a top-down bitmap.
  bmi.bV5Planes = 1;
  bmi.bV5BitCount = kBytesPerPixel * 8;
  bmi.bV5Compression = BI_RGB;
  bmi.bV5AlphaMask = 0xff000000;
  bmi.bV5CSType = LCS_WINDOWS_COLOR_SPACE;
  bmi.bV5Intent = LCS_GM_BUSINESS;
  if (!GetDIBits(dc, iinfo.hbmMask, 0, height, mask_data.get(),
                 reinterpret_cast<BITMAPINFO*>(&bmi), DIB_RGB_COLORS)) {
    //LOG_F(LS_ERROR) << "Unable to get bitmap bits. Error = " << GetLastError();
    return NULL;
  }
  uint32_t* mask_plane = mask_data.get();
  //std::unique_ptr<DesktopFrame> image(
  //    new BasicDesktopFrame(DesktopSize(width, height)));
  bool has_alpha = false;
  std::unique_ptr<uint32_t[]> color_data(new uint32_t[width * height * 4]);
  //std::vector<uint8_t> colorData(width * height * kBytesPerPixel);
  //std::vector<uint8_t> maskData(bmpMask.bmWidth * bmpMask.bmHeight);
  if (is_color) {
    //image.reset(new BasicDesktopFrame(DesktopSize(width, height)));
    // Get the pixels from the color bitmap.
    if (!GetDIBits(dc, iinfo.hbmColor, 0, height, color_data.get(),
                   reinterpret_cast<BITMAPINFO*>(&bmi), DIB_RGB_COLORS)) {
      //LOG_F(LS_ERROR) << "Unable to get bitmap bits. Error = "
      //                << GetLastError();
      return NULL;
    }
    // GetDIBits() does not provide any indication whether the bitmap has alpha
    // channel, so we use HasAlphaChannel() below to find it out.
    has_alpha = HasAlphaChannel(color_data.get(),
                                width, width, height);
  } else {
    // For non-color cursors, the mask contains both an AND and an XOR mask and
    // the height includes both. Thus, the width is correct, but we need to
    // divide by 2 to get the correct mask height.
    height /= 2;
    //image.reset(new BasicDesktopFrame(DesktopSize(width, height)));
    // The XOR mask becomes the color bitmap.
    //memcpy(image->data(), mask_plane + (width * height),
    //       image->stride() * height);

    //TODO(Haichao): Maybe image->stride() is width * 4 *height?
    color_data = std::unique_ptr<uint32_t[]>(new uint32_t[width * height * 4]);
    memcpy(color_data.get(), mask_plane + (width * height), width * height);
  }
  // Reconstruct transparency from the mask if the color image does not has
  // alpha channel.
  if (!has_alpha) {
    bool add_outline = false;
    uint32_t* dst = reinterpret_cast<uint32_t*>(color_data.get());
    uint32_t* mask = mask_plane;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // The two bitmaps combine as follows:
        //  mask  color   Windows Result   Our result    RGB   Alpha
        //   0     00      Black            Black         00    ff
        //   0     ff      White            White         ff    ff
        //   1     00      Screen           Transparent   00    00
        //   1     ff      Reverse-screen   Black         00    ff
        //
        // Since we don't support XOR cursors, we replace the "Reverse Screen"
        // with black. In this case, we also add an outline around the cursor
        // so that it is visible against a dark background.
        if (*mask == RGB(0xff, 0xff, 0xff) /* kPixelRgbWhite*/) {
          if (*dst != 0) {
            add_outline = true;
            *dst = RGBA(0, 0, 0, 0xff); /* kPixelRgbaBlack*/;
          } else {
            *dst = RGBA(0, 0, 0, 0); /* kPixelRgbaTransparent*/
            ;
          }
        } else {
          *dst = RGBA(0, 0, 0, 0xff) /* kPixelRgbaBlack*/ ^ *dst;
        }
        ++dst;
        ++mask;
      }
    }
    /*TODO(Haichao):Check if we need this.*/
    if (add_outline) {
      AddCursorOutline(width, height,
                       reinterpret_cast<uint32_t*>(color_data.get()));
    }
  }
  // Pre-multiply the resulting pixels since MouseCursor uses premultiplied
  // images.
  AlphaMul(color_data.get(), width, height);
  if (iinfo.hbmColor) {
    DeleteObject(iinfo.hbmColor);
  }
  if (iinfo.hbmMask) {
    DeleteObject(iinfo.hbmMask);
  }

  *final_width = width;
  *final_height = height;
  //return new MouseCursor(image.release(), DesktopVector(hotspot_x, hotspot_y));
  return std::move(color_data);
}

HWND hwnd_ = NULL;

//For test
void DrawBufferToHWND(const uint32_t* buffer,
                      int width,
                      int height,
                      HWND hWnd) {
  HDC hdc = GetDC(hWnd);

  HDC memDC = CreateCompatibleDC(hdc);
  if (memDC == NULL) {
    ReleaseDC(hWnd, hdc);
    return;
  }

  HBITMAP hBitmap = CreateCompatibleBitmap(hdc, width, height);
  if (hBitmap == NULL) {
    DeleteDC(memDC);
    ReleaseDC(hWnd, hdc);
    return;
  }
  HBITMAP hOldBitmap = (HBITMAP)SelectObject(memDC, hBitmap);

  BITMAPINFO bmi = {0};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  SetDIBits(memDC, hBitmap, 0, height, buffer, &bmi, DIB_RGB_COLORS);

  BitBlt(hdc, 0, 0, width, height, memDC, 0, 0, SRCCOPY);

  SelectObject(memDC, hOldBitmap);
  DeleteObject(hBitmap);
  DeleteDC(memDC);
  ReleaseDC(hWnd, hdc);
}

LRESULT CALLBACK WindowProc(HWND hwnd,
                            UINT uMsg,
                            WPARAM wParam,
                            LPARAM lParam) {
  switch (uMsg) {
    case WM_CLOSE:
      DestroyWindow(hwnd);
      break;
    case WM_DESTROY:
      PostQuitMessage(0);
      break;
    default:
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
  return 0;
}

void GetCursorImageData(HCURSOR hCursor) {
  HDC hdc = GetDC(nullptr);
  int width=0, height=0,hotX=0,hotY=0;
  std::unique_ptr<uint32_t[]> image = std::move(CreateMouseCursorFromHCursor(hdc, hCursor, &width,
                                                           &height,&hotX,&hotY));
  if (hwnd_ == NULL) {
    WNDCLASS wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = NULL;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.lpszClassName = L"SampleWindowClass";

    RegisterClass(&wc);

    hwnd_ = CreateWindowEx(
        0, L"SampleWindowClass", L"Sample Window", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600, NULL, NULL, NULL, NULL);

    if (!hwnd_) {
      return;
    }

    ShowWindow(hwnd_, 5);
    UpdateWindow(hwnd_);
  }

  DrawBufferToHWND(image.get(), width, height, hwnd_);


  ReleaseDC(nullptr, hdc);
  /* ICONINFO iconInfo;
  GetIconInfo(hCursor, &iconInfo);

  BITMAP bmpColor;
  GetObject(iconInfo.hbmColor, sizeof(BITMAP), &bmpColor);

  BITMAP bmpMask;
  GetObject(iconInfo.hbmMask, sizeof(BITMAP), &bmpMask);

  std::vector<uint8_t> colorData(bmpColor.bmWidth * bmpColor.bmHeight * 4);
  std::vector<uint8_t> maskData(bmpMask.bmWidth * bmpMask.bmHeight);

  BITMAPINFOHEADER bi;
  bi.biSize = sizeof(BITMAPINFOHEADER);
  bi.biWidth = bmpColor.bmWidth;
  bi.biHeight = bmpColor.bmHeight;
  bi.biPlanes = 1;
  bi.biBitCount = 32;
  bi.biCompression = BI_RGB;
  bi.biSizeImage = 0;
  bi.biXPelsPerMeter = 0;
  bi.biYPelsPerMeter = 0;
  bi.biClrUsed = 0;
  bi.biClrImportant = 0;
  */
  //HDC hdc = GetDC(nullptr);
  //GetDIBits(hdc, iconInfo.hbmColor, 0, bmpColor.bmHeight, &colorData[0],
  //          (BITMAPINFO*)&bi, DIB_RGB_COLORS);
  //GetDIBits(hdc, iconInfo.hbmMask, 0, bmpMask.bmHeight, &maskData[0],
  //          (BITMAPINFO*)&bi, DIB_RGB_COLORS);
  //ReleaseDC(nullptr, hdc);

  //DeleteObject(iconInfo.hbmColor);
  //DeleteObject(iconInfo.hbmMask);

  //for (size_t i = 0; i < maskData.size(); ++i) {
    //colorData[i * 4 + 3] = maskData[i];
  //}

  //return colorData;
}

 uint32_t JSHash(const uint32_t* buffer, int size) {
  uint32_t hash = 1315423911;

  for (std::size_t i = 0; i < size; i++) {
    hash ^= ((hash << 5) + buffer[i] + (hash >> 2));
  }

  return (hash & 0x7FFFFFFF);
}

unsigned char test_endian(void) {
  int test_var = 1;
  unsigned char* test_endian = reinterpret_cast<unsigned char*>(&test_var);
  return (test_endian[0] == 0);
}

std::vector<uint8_t> ConvertUint32ToUint8(const uint32_t* inputArray,
                                          uint32_t width,
                                          uint32_t height,
                                          uint32_t hotx,
                                          uint32_t hoty,
                                          uint32_t hash) {
  std::vector<uint8_t> outputArray;
  outputArray.reserve(width*height * sizeof(uint32_t) + sizeof(hash)*3 +
                      1);

  // 0 means it is cursor data.
  outputArray.push_back(static_cast<uint8_t>(0));

  // Add size mark
  uint8_t* wBytes = reinterpret_cast<uint8_t*>(&width);
  if (test_endian()) {
    // Little endian system
    for (size_t i = 0; i < sizeof(width); ++i) {
      outputArray.push_back(wBytes[i]);
    }
  } else {
    // Big endian system
    for (size_t i = sizeof(width); i > 0; --i) {
      outputArray.push_back(wBytes[i - 1]);
    }
  }

    // Add size mark
  uint8_t* hBytes = reinterpret_cast<uint8_t*>(&height);
  if (test_endian()) {
    // Little endian system
    for (size_t i = 0; i < sizeof(height); ++i) {
      outputArray.push_back(hBytes[i]);
    }
  } else {
    // Big endian system
    for (size_t i = sizeof(height); i > 0; --i) {
      outputArray.push_back(hBytes[i - 1]);
    }
  }


  uint8_t* hxBytes = reinterpret_cast<uint8_t*>(&hotx);
  if (test_endian()) {
    // Little endian system
    for (size_t i = 0; i < sizeof(hotx); ++i) {
      outputArray.push_back(hxBytes[i]);
    }
  } else {
    // Big endian system
    for (size_t i = sizeof(hotx); i > 0; --i) {
      outputArray.push_back(hxBytes[i - 1]);
    }
  }

  uint8_t* hyBytes = reinterpret_cast<uint8_t*>(&hoty);
  if (test_endian()) {
    // Little endian system
    for (size_t i = 0; i < sizeof(hoty); ++i) {
      outputArray.push_back(hyBytes[i]);
    }
  } else {
    // Big endian system
    for (size_t i = sizeof(hoty); i > 0; --i) {
      outputArray.push_back(hyBytes[i - 1]);
    }
  }

  // Add hash bytes
  uint8_t* hashBytes = reinterpret_cast<uint8_t*>(&hash);
  if (test_endian()) {
    for (size_t i = 0; i < sizeof(hash); ++i) {
      outputArray.push_back(hashBytes[i]);
    }
  } else {
    for (size_t i = sizeof(hash); i > 0; --i) {
      outputArray.push_back(hashBytes[i - 1]);
    }
  }

  // Add uint32_t values
  for (size_t i = 0; i < width * height; ++i) {
    uint32_t value = inputArray[i];
    uint8_t* bytes = reinterpret_cast<uint8_t*>(&value);

    if (test_endian()) {
      for (size_t j = sizeof(uint32_t); j > 0; --j) {
        outputArray.push_back(bytes[j - 1]);
      }
    } else {
      for (size_t j = 0; j < sizeof(uint32_t); ++j) {
        outputArray.push_back(bytes[j]);
      }
    }
  }

  return outputArray;
}


void CursorChangedEventProc(HWINEVENTHOOK hook2,
                           DWORD event,
                           HWND hwnd,
                           LONG idObject,
                           LONG idChild,
                           DWORD idEventThread,
                           DWORD time) {
  if (hwnd == nullptr && idObject == OBJID_CURSOR && idChild == CHILDID_SELF) {
    std::string str;
    switch (event) {
      case EVENT_OBJECT_HIDE:
        str = "csrhide";
        for (auto hookedchannel : hookedchannels) {
          hookedchannel.first->Send(reinterpret_cast<const uint8_t*>(str.c_str()),
                              static_cast<uint32_t>(str.length()), false);
        }
        break;
      case EVENT_OBJECT_SHOW:
        str = "csrshow";
        for (auto hookedchannel : hookedchannels) {
          hookedchannel.first->Send(
              reinterpret_cast<const uint8_t*>(str.c_str()),
                               static_cast<uint32_t>(str.length()), false);
        }
        break;
      case EVENT_OBJECT_NAMECHANGE:
        str = "csrchaged";
        CURSORINFO ci = {sizeof(ci)};
        GetCursorInfo(&ci);
        HANDLE h = GetCursorHandle(ci.hCursor);
        if (h != NULL) {
          str = "csrid: " + std::to_string(reinterpret_cast<intptr_t>(h));
          for (auto hookedchannel : hookedchannels) {
            hookedchannel.first->Send(
                reinterpret_cast<const uint8_t*>(str.c_str()),
                                 static_cast<uint32_t>(str.length()), false);
          }
        } else {
          //std::vector<uint8_t> cursorImageData = std::move(GetCursorImageData(ci.hCursor));
          // for test
         //GetCursorImageData(ci.hCursor);
          HDC hdc = GetDC(nullptr);
          int width = 0, height = 0, hotX = 0, hotY = 0;
          std::unique_ptr<uint32_t[]> image = std::move(
              CreateMouseCursorFromHCursor(hdc, ci.hCursor, &width, &height, &hotX, &hotY));
          ReleaseDC(nullptr, hdc);

          unsigned int hash = JSHash(image.get(), width * height);
          for (auto hookedchannel : hookedchannels) {
            bool remote_cached = false;
            auto it = cachedcursors.find(hookedchannel.first);
            if (it != cachedcursors.end()) {
              if (cachedcursors[hookedchannel.first].find(hash) !=
                  cachedcursors[hookedchannel.first].end()) {
                remote_cached = true;
              } else {
                cachedcursors[hookedchannel.first].insert(hash);
              }
            } else {
              std::unordered_set<uint32_t> keySet = {hash};
              cachedcursors[hookedchannel.first] = keySet;
            }
            if (remote_cached) {
              str = "csrchachedid: " + std::to_string(hash);
              hookedchannel.first->Send(
                  reinterpret_cast<const uint8_t*>(str.c_str()),
                  static_cast<uint32_t>(str.length()), false);
            } else {
              std::vector<uint8_t> datawith8bitbytes =
                  ConvertUint32ToUint8(image.get(), width, height, hotX,hotY, hash);
              //str = "nextcsrbinaryid: " + std::to_string(hash);
              //hookedchannel.first->Send(
              //    reinterpret_cast<const uint8_t*>(str.c_str()),
              //    static_cast<uint32_t>(str.length()), false);
              hookedchannel.first->Send(&datawith8bitbytes[0],
                  static_cast<uint32_t>(datawith8bitbytes.size()),
                                        true);
            }
          }
        }
        break;
    }
  }
}

static HWINEVENTHOOK Global_HOOK;

static bool vigem_init_fail = false;
static bool vigem_inited = false;
static PVIGEM_CLIENT vigem_clent;
//static std::map<RTCDataChannel*, PVIGEM_TARGET> virtualcontrols;
static std::vector<PVIGEM_TARGET> virtualcontrols;
    //static std::map<PVIGEM_TARGET, DWORD> pktnums;


void FlutterDataChannel::DataChannelSend(
    RTCDataChannel* data_channel,
    const std::string& type,
    const EncodableValue& data,
    std::unique_ptr<MethodResultProxy> result) {
  bool is_binary = type == "binary";
  if (is_binary && TypeIs<std::vector<uint8_t>>(data)) {
    std::vector<uint8_t> buffer = GetValue<std::vector<uint8_t>>(data);
    data_channel->Send(buffer.data(), static_cast<uint32_t>(buffer.size()),
                       true);
  } else {
    std::string str = GetValue<std::string>(data);
    // It is ugly to implement here, but actually we should bind a cursorchange to a data channel.
    // So we implement it here for convenience.

    if (str == "csrhook") {
      if (hookedchannels.size() == 0) {
        Global_HOOK = SetWinEventHook(
            EVENT_OBJECT_SHOW, EVENT_OBJECT_NAMECHANGE,
                                    nullptr, CursorChangedEventProc, 0, 0,
                                    WINEVENT_OUTOFCONTEXT);
        hookedchannels[data_channel] = Global_HOOK;
      } else {
        hookedchannels[data_channel] = Global_HOOK;
      }
    } 
    else if (str == "xboxinit" && !vigem_inited && !vigem_init_fail) {
      if (!vigem_inited && !vigem_init_fail) {
        vigem_clent = vigem_alloc();

        if (vigem_clent == nullptr) {
          std::cerr << "Uh, not enough memory to do that?!" << std::endl;
          vigem_init_fail = true;
          return;
        }
        const auto retval = vigem_connect(vigem_clent);

        if (!VIGEM_SUCCESS(retval)) {
          vigem_init_fail = true;
          std::cerr << "ViGEm Bus connection failed with error code: 0x"
                    << std::hex << retval << std::endl;
          return;
        }
        vigem_inited = true;
      }

      if (vigem_init_fail)
        return;
      //
      // Allocate handle to identify new pad
      //
      const auto pad = vigem_target_x360_alloc();
      virtualcontrols.push_back(pad);
      //pktnums[pad] = 0;

      //
      // Add client to the bus, this equals a plug-in event
      //
      const auto pir = vigem_target_add(vigem_clent, pad);

      //
      // Error handling
      //
      if (!VIGEM_SUCCESS(pir)) {
        std::cerr << "Target plugin failed with error code: 0x" << std::hex
                  << pir << std::endl;
        vigem_init_fail = true;
        return;
      }

    } else if (str == "xboxuninit") {
      vigem_target_remove(vigem_clent, virtualcontrols[0]);
      vigem_target_free(virtualcontrols[0]);
      virtualcontrols.erase(virtualcontrols.begin());
    }else
    {
      data_channel->Send(reinterpret_cast<const uint8_t*>(str.c_str()),
                       static_cast<uint32_t>(str.length()), false);
    }
  }
  result->Success();
}

void FlutterDataChannel::DataChannelClose(
    RTCDataChannel* data_channel,
    const std::string& data_channel_uuid,
    std::unique_ptr<MethodResultProxy> result) {
  if (hookedchannels.find(data_channel) != hookedchannels.end()) {
    if (hookedchannels.size() == 1)
      UnhookWinEvent(hookedchannels[data_channel]);
    hookedchannels.erase(hookedchannels.find(data_channel));
    if (cachedcursors.find(data_channel) != cachedcursors.end()) {
      cachedcursors.erase(cachedcursors.find(data_channel));
    }
  }

  if (vigem_inited) {
    vigem_target_remove(vigem_clent, virtualcontrols[0]);
    vigem_target_free(virtualcontrols[0]);
    virtualcontrols.erase(virtualcontrols.begin());
    vigem_inited = false;
    vigem_init_fail = false;
  }

  data_channel->Close();
  auto it = base_->data_channel_observers_.find(data_channel_uuid);
  if (it != base_->data_channel_observers_.end())
    base_->data_channel_observers_.erase(it);
  result->Success();
}

RTCDataChannel* FlutterDataChannel::DataChannelForId(const std::string& uuid) {
  auto it = base_->data_channel_observers_.find(uuid);

  if (it != base_->data_channel_observers_.end()) {
    FlutterRTCDataChannelObserver* observer = it->second.get();
    scoped_refptr<RTCDataChannel> data_channel = observer->data_channel();
    return data_channel.get();
  }
  return nullptr;
}

static const char* DataStateString(RTCDataChannelState state) {
  switch (state) {
    case RTCDataChannelConnecting:
      return "connecting";
    case RTCDataChannelOpen:
      return "open";
    case RTCDataChannelClosing:
      return "closing";
    case RTCDataChannelClosed:
      return "closed";
  }
  return "";
}

void FlutterRTCDataChannelObserver::OnStateChange(RTCDataChannelState state) {
  EncodableMap params;
  params[EncodableValue("event")] = EncodableValue("dataChannelStateChanged");
  params[EncodableValue("id")] = EncodableValue(data_channel_->id());
  params[EncodableValue("state")] = EncodableValue(DataStateString(state));
  auto data = EncodableValue(params);
  event_channel_->Success(data);
}

_XINPUT_GAMEPAD parseStringToGamepad(const std::string& str) {
  std::istringstream iss(str);

  std::string temp;
  _XINPUT_GAMEPAD gamepad;

  std::getline(iss, temp, ' ');  // 跳过"xinput:"
  std::getline(iss, temp, ' ');  // 跳过"WORD(buttons)"

  iss >> gamepad.bLeftTrigger;
  iss >> gamepad.bRightTrigger;
  iss >> gamepad.sThumbLX;
  iss >> gamepad.sThumbLY;
  iss >> gamepad.sThumbRX;
  iss >> gamepad.sThumbRY;

  return gamepad;
}

void FlutterRTCDataChannelObserver::OnMessage(const char* buffer,
                                              int length,
                                              bool binary) {
  if (!binary && buffer[0]) {
    std::string str(buffer, length);
    //"xinput: WORD(buttons) bLeftTrigger bRightTrigger sThumbLX sThumbLY sThumbRX sThumbRY"
    if (str.find("xinput:") == 0) {
      if (!vigem_inited || vigem_init_fail) {
        return;
      }
      //XINPUT_STATE state;

      //
      // Grab the input from a physical X36ß pad in this example
      //
      // XInputGetState(0, &state);

      //
      // The XINPUT_GAMEPAD structure is identical to the XUSB_REPORT
      // structure so we can simply take it "as-is" and cast it.
      //
      // Call this function on every input state change e.g. in a loop polling
      // another joystick or network device or thermometer or... you get the
      // idea.
      //
    
      //state.dwPacketNumber = pktnums[virtualcontrols[data_channel_.get()]];
      //pktnums[virtualcontrols[data_channel_.get()]]++;

      std::istringstream iss(str);

      _XINPUT_GAMEPAD gamepad;

      std::string command;
      iss >> command;
      
      iss >> gamepad.wButtons;
      int nextparam;
      iss >> nextparam;
      gamepad.bLeftTrigger = (BYTE)nextparam;
      iss >> nextparam;
      gamepad.bRightTrigger = (BYTE)nextparam;
      //iss >> gamepad.bRightTrigger;
      iss >> gamepad.sThumbLX;
      iss >> gamepad.sThumbLY;
      iss >> gamepad.sThumbRX;
      iss >> gamepad.sThumbRY;
      /*
      state.Gamepad.wButtons = 0;
      state.Gamepad.bLeftTrigger = 0;
      state.Gamepad.bRightTrigger = 0;
      state.Gamepad.sThumbLX = 0;
      state.Gamepad.sThumbLY = 0;
      state.Gamepad.sThumbRX = 0;
      state.Gamepad.sThumbRY = 0;
      */
      VIGEM_ERROR hr = vigem_target_x360_update(
          vigem_clent, virtualcontrols[0],
                               *reinterpret_cast<XUSB_REPORT*>(&gamepad));
      std::cerr << "Uh, not enough memory to do that?!" << hr << std::endl;
      return;
    }
  }
  
  EncodableMap params;
  params[EncodableValue("event")] = EncodableValue("dataChannelReceiveMessage");

  params[EncodableValue("id")] = EncodableValue(data_channel_->id());
  params[EncodableValue("type")] = EncodableValue(binary ? "binary" : "text");
  std::string str(buffer, length);
  params[EncodableValue("data")] =
      binary ? EncodableValue(std::vector<uint8_t>(str.begin(), str.end()))
             : EncodableValue(str);

  auto data = EncodableValue(params);
  event_channel_->Success(data);
}
}  // namespace flutter_webrtc_plugin
