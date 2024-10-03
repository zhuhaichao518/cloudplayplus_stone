import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart_webrtc/dart_webrtc.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

import 'rtc_video_renderer_impl.dart';

class RTCVideoView extends StatefulWidget {
  RTCVideoView(
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

  @override
  RTCVideoViewState createState() => RTCVideoViewState();
}

class RTCVideoViewState extends State<RTCVideoView> {
  RTCVideoViewState();

  RTCVideoRenderer get videoRenderer => widget._renderer;

  @override
  void initState() {
    super.initState();
    videoRenderer.addListener(_onRendererListener);
    videoRenderer.mirror = widget.mirror;
    videoRenderer.objectFit =
        widget.objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
            ? 'contain'
            : 'cover';
  }

  void _onRendererListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
  }

  @override
  void didUpdateWidget(RTCVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    Timer(
        Duration(milliseconds: 10), () => videoRenderer.mirror = widget.mirror);
    if (widget.setAspectRatio != null) {
      widget.setAspectRatio!(
          videoRenderer.videoWidth / videoRenderer.videoHeight);
    }
    videoRenderer.objectFit =
        widget.objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
            ? 'contain'
            : 'cover';
  }

  Widget buildVideoElementView() {
    if (widget.setAspectRatio != null) {
      widget.setAspectRatio!(
          videoRenderer.videoWidth / videoRenderer.videoHeight);
    }
    return HtmlElementView(viewType: videoRenderer.viewType);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (widget.onRenderBoxUpdated!= null){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onRenderBoxUpdated!(context.findRenderObject() as RenderBox);
          });
        }
        return Center(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: widget._renderer.renderVideo
                ? buildVideoElementView()
                : widget.placeholderBuilder?.call(context) ?? Container(),
          ),
        );
      },
    );
  }
}
