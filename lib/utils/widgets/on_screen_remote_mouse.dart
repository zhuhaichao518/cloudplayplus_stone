import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class OnScreenRemoteMouse extends LeafRenderObjectWidget {
  final Offset position;
  final Uint8List? cursorBuffer;
  final double deltax;
  final double deltay;

  const OnScreenRemoteMouse({
    super.key,
    this.position = const Offset(100, 100),
    this.cursorBuffer,
    this.deltax = 0,
    this.deltay = 0,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRemoteMouse(
      position: position,
      cursorBuffer: cursorBuffer,
      deltax: deltax,
      deltay: deltay,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderRemoteMouse renderObject) {
    renderObject
      ..position = position
      ..cursorBuffer = cursorBuffer
      ..deltax = deltax
      ..deltay = deltay;
  }
}

class RenderRemoteMouse extends RenderBox {
  RenderRemoteMouse({
    required Offset position,
    Uint8List? cursorBuffer,
    required double deltax,
    required double deltay,
  })  : _position = position,
        _cursorBuffer = cursorBuffer,
        _deltax = deltax,
        _deltay = deltay;

  Offset _position;
  Offset get position => _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    markNeedsPaint();
  }

  Uint8List? _cursorBuffer;
  Uint8List? get cursorBuffer => _cursorBuffer;
  set cursorBuffer(Uint8List? value) {
    if (_cursorBuffer == value) return;
    _cursorBuffer = value;
    _decodeCursorBuffer();
    markNeedsPaint();
  }

  double _deltax;
  double get deltax => _deltax;
  set deltax(double value) {
    if (_deltax == value) return;
    _deltax = value;
    markNeedsPaint();
  }

  double _deltay;
  double get deltay => _deltay;
  set deltay(double value) {
    if (_deltay == value) return;
    _deltay = value;
    markNeedsPaint();
  }

  ui.Image? _cursorImage;
  int _width = 32;  // 默认值
  int _height = 32; // 默认值
  int _hotX = 16;   // 默认值
  int _hotY = 16;   // 默认值

  void _decodeCursorBuffer() {
    if (_cursorBuffer == null || _cursorBuffer![0] != 9) return;

    // 解析宽度
    _width = 0;
    for (int i = 1; i < 5; i++) {
      _width = _width * 256 + _cursorBuffer![i];
    }

    // 解析高度
    _height = 0;
    for (int i = 5; i < 9; i++) {
      _height = _height * 256 + _cursorBuffer![i];
    }

    // 解析热点x坐标
    _hotX = 0;
    for (int i = 9; i < 13; i++) {
      _hotX = _hotX * 256 + _cursorBuffer![i];
    }

    // 解析热点y坐标
    _hotY = 0;
    for (int i = 13; i < 17; i++) {
      _hotY = _hotY * 256 + _cursorBuffer![i];
    }

    // 解析hash值（这里我们不需要使用）
    int hash = 0;
    for (int i = 17; i < 21; i++) {
      hash = hash * 256 + _cursorBuffer![i];
    }

    // 获取图像数据
    final imageData = _cursorBuffer!.sublist(21);
    
    // 将图像数据转换为ui.Image
    ui.decodeImageFromPixels(
      imageData,
      _width,
      _height,
      ui.PixelFormat.bgra8888,
      (ui.Image image) {
        _cursorImage = image;
        markNeedsPaint();
      },
    );
  }

  @override
  void performLayout() {
    size = Size(_width.toDouble(), _height.toDouble());
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_cursorImage == null) {
      // 如果没有图像，绘制一个默认的箭头
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(size.width / 3, size.height);
      path.lineTo(size.width, size.height / 3);
      path.close();

      context.canvas.save();
      context.canvas.translate(
        offset.dx + _position.dx + _deltax,
        offset.dy + _position.dy + _deltay,
      );
      context.canvas.drawPath(path, paint);
      context.canvas.restore();
    } else {
      context.canvas.save();
      context.canvas.translate(
        offset.dx + _position.dx + _deltax,
        offset.dy + _position.dy + _deltay,
      );
      context.canvas.drawImage(_cursorImage!, Offset.zero, Paint());
      context.canvas.restore();
    }
  }
}
