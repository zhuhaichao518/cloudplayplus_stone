#ifndef LIB_WEBRTC_RTC_DESKTOP_DEVICE_HXX
#define LIB_WEBRTC_RTC_DESKTOP_DEVICE_HXX

#include "rtc_types.h"

namespace libwebrtc {

class MediaSource;
class RTCDesktopCapturer;
class RTCDesktopMediaList;

class RTCDesktopDevice : public RefCountInterface {
 public:
  virtual scoped_refptr<RTCDesktopCapturer> CreateDesktopCapturer(
      scoped_refptr<MediaSource> source) = 0;
  // It is tricky here we define as pure virtual here but not in
  // libwebrtc because it is used by other places and we do not
  // want to change that.
  virtual scoped_refptr<RTCDesktopCapturer> CreateDesktopCapturer(
      scoped_refptr<MediaSource> source,
      bool has_cursor) = 0;
  virtual scoped_refptr<RTCDesktopMediaList> GetDesktopMediaList(
      DesktopType type) = 0;

 protected:
  virtual ~RTCDesktopDevice() {}
};

}  // namespace libwebrtc

#endif  // LIB_WEBRTC_RTC_VIDEO_DEVICE_HXX