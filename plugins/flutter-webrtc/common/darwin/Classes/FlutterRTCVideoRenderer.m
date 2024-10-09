#import "FlutterRTCVideoRenderer.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CGImage.h>
#import <WebRTC/RTCYUVHelper.h>
#import <WebRTC/RTCYUVPlanarBuffer.h>
#import <WebRTC/WebRTC.h>

#import <objc/runtime.h>

#import "FlutterWebRTCPlugin.h"

@implementation FlutterRTCVideoRenderer {
  CGSize _frameSize;
  CGSize _renderSize;
  CVPixelBufferRef _pixelBufferRef;
  RTCVideoRotation _rotation;
  FlutterEventChannel* _eventChannel;
  bool _isFirstFrameRendered;
  //bool _directCVPixelBuffer;
}

@synthesize textureId = _textureId;
@synthesize registry = _registry;
@synthesize eventSink = _eventSink;

- (instancetype)initWithTextureRegistry:(id<FlutterTextureRegistry>)registry
                              messenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _isFirstFrameRendered = false;
    _frameSize = CGSizeZero;
    _renderSize = CGSizeZero;
    _rotation = -1;
    _registry = registry;
    _pixelBufferRef = nil;
    _eventSink = nil;
    _rotation = -1;
    _textureId = [registry registerTexture:self];
    /*Create Event Channel.*/
    _eventChannel = [FlutterEventChannel
        eventChannelWithName:[NSString stringWithFormat:@"FlutterWebRTC/Texture%lld", _textureId]
             binaryMessenger:messenger];
    [_eventChannel setStreamHandler:self];
  }
  return self;
}

- (void)dealloc {
  if (_pixelBufferRef) {
    //CVPixelBufferUnlockBaseAddress(_pixelBufferRef, kCVPixelBufferLock_ReadOnly);
    CVBufferRelease(_pixelBufferRef);
  }
}

- (CVPixelBufferRef)copyPixelBuffer {
  if (_pixelBufferRef != nil) {
    //TODO(haichao): Lock/Unlock is only needed when we directly get CVPixelBuffer from WebRTC.
    //However,lock does not work here and still conflict with decoder. Why?
    CVBufferRetain(_pixelBufferRef);
    //CVPixelBufferLockBaseAddress(_pixelBufferRef, kCVPixelBufferLock_ReadOnly);
    return _pixelBufferRef;
  }
  return nil;
}

- (void)dispose {
  [_registry unregisterTexture:_textureId];
}

- (void)setVideoTrack:(RTCVideoTrack*)videoTrack {
  RTCVideoTrack* oldValue = self.videoTrack;

  if (oldValue != videoTrack) {
    _isFirstFrameRendered = false;
    if (oldValue) {
      [oldValue removeRenderer:self];
    }
    _videoTrack = videoTrack;
    _frameSize = CGSizeZero;
    _renderSize = CGSizeZero;
    _rotation = -1;
    if (videoTrack) {
      [videoTrack addRenderer:self];
    }
  }
}

- (id<RTCI420Buffer>)correctRotation:(const id<RTCI420Buffer>)src
                        withRotation:(RTCVideoRotation)rotation {
  int rotated_width = src.width;
  int rotated_height = src.height;

  if (rotation == RTCVideoRotation_90 || rotation == RTCVideoRotation_270) {
    int temp = rotated_width;
    rotated_width = rotated_height;
    rotated_height = temp;
  }

  id<RTCI420Buffer> buffer = [[RTCI420Buffer alloc] initWithWidth:rotated_width
                                                           height:rotated_height];

  [RTCYUVHelper I420Rotate:src.dataY
                srcStrideY:src.strideY
                      srcU:src.dataU
                srcStrideU:src.strideU
                      srcV:src.dataV
                srcStrideV:src.strideV
                      dstY:(uint8_t*)buffer.dataY
                dstStrideY:buffer.strideY
                      dstU:(uint8_t*)buffer.dataU
                dstStrideU:buffer.strideU
                      dstV:(uint8_t*)buffer.dataV
                dstStrideV:buffer.strideV
                     width:src.width
                    height:src.height
                      mode:rotation];

  return buffer;
}

- (void)copyI420ToCVPixelBuffer:(CVPixelBufferRef)outputPixelBuffer
                      withFrame:(RTCVideoFrame*)frame {
  id<RTCI420Buffer> i420Buffer = [self correctRotation:[frame.buffer toI420]
                                          withRotation:frame.rotation];
  CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);

  const OSType pixelFormat = CVPixelBufferGetPixelFormatType(outputPixelBuffer);
  if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    // NV12
    uint8_t* dstY = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
    const size_t dstYStride = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 0);
    uint8_t* dstUV = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
    const size_t dstUVStride = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 1);

    [RTCYUVHelper I420ToNV12:i420Buffer.dataY
                  srcStrideY:i420Buffer.strideY
                        srcU:i420Buffer.dataU
                  srcStrideU:i420Buffer.strideU
                        srcV:i420Buffer.dataV
                  srcStrideV:i420Buffer.strideV
                        dstY:dstY
                  dstStrideY:(int)dstYStride
                       dstUV:dstUV
                 dstStrideUV:(int)dstUVStride
                       width:i420Buffer.width
                      height:i420Buffer.height];

  } else {
    uint8_t* dst = CVPixelBufferGetBaseAddress(outputPixelBuffer);
    const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(outputPixelBuffer);

    if (pixelFormat == kCVPixelFormatType_32BGRA) {
      // Corresponds to libyuv::FOURCC_ARGB

      [RTCYUVHelper I420ToARGB:i420Buffer.dataY
                    srcStrideY:i420Buffer.strideY
                          srcU:i420Buffer.dataU
                    srcStrideU:i420Buffer.strideU
                          srcV:i420Buffer.dataV
                    srcStrideV:i420Buffer.strideV
                       dstARGB:dst
                 dstStrideARGB:(int)bytesPerRow
                         width:i420Buffer.width
                        height:i420Buffer.height];

    } else if (pixelFormat == kCVPixelFormatType_32ARGB) {
      // Corresponds to libyuv::FOURCC_BGRA
      [RTCYUVHelper I420ToBGRA:i420Buffer.dataY
                    srcStrideY:i420Buffer.strideY
                          srcU:i420Buffer.dataU
                    srcStrideU:i420Buffer.strideU
                          srcV:i420Buffer.dataV
                    srcStrideV:i420Buffer.strideV
                       dstBGRA:dst
                 dstStrideBGRA:(int)bytesPerRow
                         width:i420Buffer.width
                        height:i420Buffer.height];
    }
  }

  CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
}

#pragma mark - RTCVideoRenderer methods
- (void)renderFrame:(RTCVideoFrame*)frame {
    CVPixelBufferRef pixelBuffer = [frame.buffer toCVPixelBuffer];
    if (pixelBuffer) {
/* ### old implementation
// I tried to direct use the buffer from decoder, but it seems has confilct with decoder.
        CVPixelBufferRetain(pixelBuffer);
        if (_pixelBufferRef) {
            CVPixelBufferRelease(_pixelBufferRef);
        }
        _pixelBufferRef = pixelBuffer;
 ### end of old implementation*/
 //理论上这个拷贝可以省掉 但是old implementation 在flutter渲染一段时间会报bad access。
 //怀疑是decoder在复用这个buffer。我没找到好的方案
 //即使在copyPixelBuffer中 retain和 CVPixelBufferLockBaseAddress也不行。
 //目前这里就拷贝一下，本身性能影响也比较有限。
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferLockBaseAddress(_pixelBufferRef, 0);

        // YUV格式需要对齐 否则会出现绿线
        // 获取 Y 平面的基地址和尺寸
        void *srcBaseAddressY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        void *dstBaseAddressY = CVPixelBufferGetBaseAddressOfPlane(_pixelBufferRef, 0);

        size_t srcBytesPerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        size_t dstBytesPerRowY = CVPixelBufferGetBytesPerRowOfPlane(_pixelBufferRef, 0);
        size_t heightY = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);

        // 拷贝 Y 平面
        for (size_t row = 0; row < heightY; row++) {
            memcpy((char *)dstBaseAddressY + row * dstBytesPerRowY,
                   (char *)srcBaseAddressY + row * srcBytesPerRowY,
                   srcBytesPerRowY);
        }

        // 获取 CbCr 平面的基地址和尺寸
        void *srcBaseAddressCbCr = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        void *dstBaseAddressCbCr = CVPixelBufferGetBaseAddressOfPlane(_pixelBufferRef, 1);

        size_t srcBytesPerRowCbCr = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        size_t dstBytesPerRowCbCr = CVPixelBufferGetBytesPerRowOfPlane(_pixelBufferRef, 1);
        size_t heightCbCr = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);

        // 拷贝 CbCr 平面
        for (size_t row = 0; row < heightCbCr; row++) {
            memcpy((char *)dstBaseAddressCbCr + row * dstBytesPerRowCbCr,
                   (char *)srcBaseAddressCbCr + row * srcBytesPerRowCbCr,
                   srcBytesPerRowCbCr);
        }

        // 解锁源和目标缓冲区
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferUnlockBaseAddress(_pixelBufferRef, 0);
    } else {
        // no hardware acceleration implemented yet. fallback to software.
        [self copyI420ToCVPixelBuffer:_pixelBufferRef withFrame:frame];
    }
    
  __weak FlutterRTCVideoRenderer* weakSelf = self;
  if (_renderSize.width != frame.width || _renderSize.height != frame.height) {
    dispatch_async(dispatch_get_main_queue(), ^{
      FlutterRTCVideoRenderer* strongSelf = weakSelf;
      if (strongSelf.eventSink) {
        postEvent( strongSelf.eventSink, @{
          @"event" : @"didTextureChangeVideoSize",
          @"id" : @(strongSelf.textureId),
          @"width" : @(frame.width),
          @"height" : @(frame.height),
        });
      }
    });
    _renderSize = CGSizeMake(frame.width, frame.height);
  }

  if (frame.rotation != _rotation) {
    dispatch_async(dispatch_get_main_queue(), ^{
      FlutterRTCVideoRenderer* strongSelf = weakSelf;
      if (strongSelf.eventSink) {
        postEvent( strongSelf.eventSink,@{
          @"event" : @"didTextureChangeRotation",
          @"id" : @(strongSelf.textureId),
          @"rotation" : @(frame.rotation),
        });
      }
    });

    _rotation = frame.rotation;
  }

  // Notify the Flutter new pixelBufferRef to be ready.
  dispatch_async(dispatch_get_main_queue(), ^{
    FlutterRTCVideoRenderer* strongSelf = weakSelf;
    [strongSelf.registry textureFrameAvailable:strongSelf.textureId];
    if (!strongSelf->_isFirstFrameRendered) {
      if (strongSelf.eventSink) {
        postEvent(strongSelf.eventSink, @{@"event" : @"didFirstFrameRendered"});
        strongSelf->_isFirstFrameRendered = true;
      }
    }
  });
}

/**
 * Sets the size of the video frame to render.
 *
 * @param size The size of the video frame to render.
 */
- (void)setSize:(CGSize)size {
  if (_pixelBufferRef == nil ||
      (size.width != _frameSize.width || size.height != _frameSize.height)) {
    if (_pixelBufferRef) {
      CVBufferRelease(_pixelBufferRef);
    }
    NSDictionary* pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, //kCVPixelFormatType_32BGRA,
        //TODO:(Haichao): this is used in RTCVideoDecoderH264.mm. Check other formats.
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                        (__bridge CFDictionaryRef)(pixelAttributes), &_pixelBufferRef);

    _frameSize = size;
  }
}

#pragma mark - FlutterStreamHandler methods

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)sink {
  _eventSink = sink;
  return nil;
}
@end

@implementation FlutterWebRTCPlugin (FlutterVideoRendererManager)

- (FlutterRTCVideoRenderer*)createWithTextureRegistry:(id<FlutterTextureRegistry>)registry
                                            messenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  return [[FlutterRTCVideoRenderer alloc] initWithTextureRegistry:registry messenger:messenger];
}

- (void)rendererSetSrcObject:(FlutterRTCVideoRenderer*)renderer stream:(RTCVideoTrack*)videoTrack {
  renderer.videoTrack = videoTrack;
}
@end
