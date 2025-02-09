/*
 * Copyright 2023 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <WebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT @protocol RTC_OBJC_TYPE(RTCAudioRenderer)<NSObject>

- (void)renderSampleBuffer: (CMSampleBufferRef)sampleBuffer NS_SWIFT_NAME(render(sampleBuffer:));

@end

NS_ASSUME_NONNULL_END
