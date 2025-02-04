/*
 * Copyright 2022 LiveKit
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

#import <WebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTCIODeviceType) {
  RTCIODeviceTypeOutput,
  RTCIODeviceTypeInput,
};

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE(RTCIODevice) : NSObject

+ (instancetype)defaultDeviceWithType: (RTCIODeviceType)type;
- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, readonly) BOOL isDefault;
@property(nonatomic, readonly) RTCIODeviceType type;
@property(nonatomic, copy, readonly) NSString *deviceId;
@property(nonatomic, copy, readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
