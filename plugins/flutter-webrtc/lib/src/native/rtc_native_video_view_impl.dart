import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webrtc_interface/webrtc_interface.dart';
import 'package:flutter/services.dart'; // Added for MethodChannel

import 'rtc_video_renderer_impl.dart';

class RTCNativeVideoView {
  static RTCVideoRenderer? _currentRenderer;
  static bool _isActive = false;
  
  /// 设置当前的视频渲染器
  static void setVideoRenderer(RTCVideoRenderer renderer) {
    _currentRenderer = renderer;
  }
  
  /// 获取当前的视频渲染器
  static RTCVideoRenderer? getCurrentRenderer() {
    return _currentRenderer;
  }
  
  /// 启动原生视频渲染 Activity
  static Future<void> start() async {
    if (_currentRenderer == null) {
      throw Exception('No video renderer set. Call setVideoRenderer() first.');
    }
    
    try {
      // 调用原生方法启动 Activity
      const platform = MethodChannel('flutter_webrtc_native_video');
      await platform.invokeMethod('startNativeVideoActivity');
      _isActive = true;
    } catch (e) {
      throw Exception('Failed to start native video activity: $e');
    }
  }
  
  /// 停止原生视频渲染 Activity
  static Future<void> stop() async {
    if (!_isActive) {
      return;
    }
    
    try {
      // 调用原生方法停止 Activity
      const platform = MethodChannel('flutter_webrtc_native_video');
      await platform.invokeMethod('stopNativeVideoActivity');
      _isActive = false;
    } catch (e) {
      throw Exception('Failed to stop native video activity: $e');
    }
  }
  
  /// 检查是否正在显示原生视频
  static bool get isActive => _isActive;
  
  /// 清理资源
  static void dispose() {
    _currentRenderer = null;
    _isActive = false;
  }
}

class RTCNativeVideoViewImpl extends StatelessWidget {
  RTCNativeVideoViewImpl(
    this._renderer, {
    this.setAspectRatio,
    super.key,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.mirror = false,
    this.filterQuality = FilterQuality.low,
    this.placeholderBuilder,
    this.onRenderBoxUpdated,
  });

  final RTCVideoRenderer _renderer;
  final RTCVideoViewObjectFit objectFit;
  final bool mirror;
  final FilterQuality filterQuality;
  final WidgetBuilder? placeholderBuilder;
  final Function(double)? setAspectRatio;
  final Function(RenderBox)? onRenderBoxUpdated;

  RTCVideoRenderer get videoRenderer => _renderer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            _buildNativeVideoView(context, constraints));
  }

  Widget _buildNativeVideoView(BuildContext context, BoxConstraints constraints) {
    return Center(
      child: Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: FittedBox(
          clipBehavior: Clip.hardEdge,
          fit: objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
              ? BoxFit.contain
              : BoxFit.cover,
          child: Center(
            child: ValueListenableBuilder<RTCVideoValue>(
              valueListenable: videoRenderer,
              builder:
                  (BuildContext context, RTCVideoValue value, Widget? child) {
                if (onRenderBoxUpdated != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onRenderBoxUpdated!(
                        context.findRenderObject() as RenderBox);
                  });
                }
                if (setAspectRatio != null) {
                  setAspectRatio!(value.aspectRatio);
                }
                return SizedBox(
                  width: constraints.maxHeight * value.aspectRatio,
                  height: constraints.maxHeight,
                  child: child,
                );
              },
              child: Transform(
                transform: Matrix4.identity()..rotateY(mirror ? -pi : 0.0),
                alignment: FractionalOffset.center,
                child: videoRenderer.renderVideo
                    ? _NativeVideoTexture(
                        textureId: videoRenderer.textureId!,
                        filterQuality: filterQuality,
                      )
                    : placeholderBuilder?.call(context) ?? Container(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NativeVideoTexture extends StatelessWidget {
  final int textureId;
  final FilterQuality filterQuality;

  const _NativeVideoTexture({
    required this.textureId,
    required this.filterQuality,
  });

  @override
  Widget build(BuildContext context) {
    // 这里会启动原生 Activity 来渲染视频
    // 通过 MethodChannel 与原生代码通信
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          '原生视频渲染',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
} 