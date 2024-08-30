import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../base/logging.dart';

// 定义一个 GlobalKey
final GlobalKey<RTCVideoOverlayWidgetState> rtcvideoKey =
    GlobalKey<RTCVideoOverlayWidgetState>();

class RTCVideoOverlayWidget extends StatefulWidget {
  const RTCVideoOverlayWidget({super.key});

  @override
  State<RTCVideoOverlayWidget> createState() => RTCVideoOverlayWidgetState();
}

class RTCVideoOverlayWidgetState extends State<RTCVideoOverlayWidget> {
  bool _isVisible = false;
  bool _hasVideo = false;

  RTCVideoRenderer? _videoRenderer;

  double _overlayLeft = 0.0;
  double _overlayTop = 0.0;
  double _overlayWidth = 100.0;
  double _overlayHeight = 100.0;

  void updateRenderBox(RenderBox renderBox) {
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() {
      _overlayLeft = position.dx;
      _overlayTop = position.dy;
      _overlayWidth = size.width;
      _overlayHeight = size.height;
    });
  }

  void updateVideoRenderer(String mediatype, MediaStream stream) {
    setState(() {
      _videoRenderer ??= RTCVideoRenderer();
      _videoRenderer?.initialize().then((data) {
        _videoRenderer!.srcObject = stream;
        _hasVideo = true;
        _isVisible = true;
      }).catchError((error) {
        VLOG0('Error: failed to create RTCVideoRenderer');
      });
    });
  }

  void putVisible(bool visible) {
    setState(() {
      _isVisible = visible;
    });
  }

  double aspectRatio = 1920 / 1080;
  void setAspectRatio(double ratio) {
    aspectRatio = ratio;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) return Container();

    return Positioned(
      left: _overlayLeft,
      top: _overlayTop,
      width: _overlayWidth,
      height: _overlayHeight,
      child: _isVisible
          ? RTCVideoView(_videoRenderer!, setAspectRatio: setAspectRatio)
          : Container(),
    );
  }
}
