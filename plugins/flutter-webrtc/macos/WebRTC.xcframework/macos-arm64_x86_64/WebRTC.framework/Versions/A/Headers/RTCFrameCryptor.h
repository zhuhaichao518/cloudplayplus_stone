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

@class RTC_OBJC_TYPE(RTCRtpSender);
@class RTC_OBJC_TYPE(RTCRtpReceiver);
@class RTC_OBJC_TYPE(RTCFrameCryptorKeyProvider);
@class RTC_OBJC_TYPE(RTCFrameCryptor);
@class RTC_OBJC_TYPE(RTCPeerConnectionFactory);

typedef NS_ENUM(NSUInteger, RTCCryptorAlgorithm) {
  RTCCryptorAlgorithmAesGcm = 0,
  RTCCryptorAlgorithmAesCbc,
};

typedef NS_ENUM(NSInteger, FrameCryptionState) {
  FrameCryptionStateNew = 0,
  FrameCryptionStateOk,
  FrameCryptionStateEncryptionFailed,
  FrameCryptionStateDecryptionFailed,
  FrameCryptionStateMissingKey,
  FrameCryptionStateKeyRatcheted,
  FrameCryptionStateInternalError,
};

RTC_OBJC_EXPORT
@protocol RTC_OBJC_TYPE
(RTCFrameCryptorDelegate)<NSObject>
    /** Called when the RTCFrameCryptor got errors. */
    - (void)frameCryptor
    : (RTC_OBJC_TYPE(RTCFrameCryptor) *)frameCryptor didStateChangeWithParticipantId
    : (NSString *)participantId withState : (FrameCryptionState)stateChanged;
@end

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (RTCFrameCryptor) : NSObject

@property(nonatomic, assign) BOOL enabled;

@property(nonatomic, assign) int keyIndex;

@property(nonatomic, readonly) NSString *participantId;

@property(nonatomic, weak, nullable) id<RTC_OBJC_TYPE(RTCFrameCryptorDelegate)> delegate;

- (nullable instancetype)initWithFactory:(RTC_OBJC_TYPE(RTCPeerConnectionFactory) *)factory
                               rtpSender:(RTC_OBJC_TYPE(RTCRtpSender) *)sender
                           participantId:(NSString *)participantId
                               algorithm:(RTCCryptorAlgorithm)algorithm
                             keyProvider:(RTC_OBJC_TYPE(RTCFrameCryptorKeyProvider) *)keyProvider;

- (nullable instancetype)initWithFactory:(RTC_OBJC_TYPE(RTCPeerConnectionFactory) *)factory
                             rtpReceiver:(RTC_OBJC_TYPE(RTCRtpReceiver) *)receiver
                           participantId:(NSString *)participantId
                               algorithm:(RTCCryptorAlgorithm)algorithm
                             keyProvider:(RTC_OBJC_TYPE(RTCFrameCryptorKeyProvider) *)keyProvider;

@end

NS_ASSUME_NONNULL_END
