#import <Foundation/Foundation.h>

#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCVideoEncoderFactory.h>

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (RTCVideoEncoderFactorySimulcast) : NSObject <RTC_OBJC_TYPE(RTCVideoEncoderFactory)>

- (instancetype)initWithPrimary:(id<RTC_OBJC_TYPE(RTCVideoEncoderFactory)>)primary
                       fallback:(id<RTC_OBJC_TYPE(RTCVideoEncoderFactory)>)fallback;

@end

NS_ASSUME_NONNULL_END
