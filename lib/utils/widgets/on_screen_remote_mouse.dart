import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class OnScreenRemoteMouseController extends ChangeNotifier {
  Offset _position = const Offset(100, 100);
  Uint8List? _cursorBuffer;
  double _deltax = 0;
  double _deltay = 0;

  Offset get position => _position;
  Uint8List? get cursorBuffer => _cursorBuffer;
  double get deltax => _deltax;
  double get deltay => _deltay;

  void setPosition(Offset position) {
    if (_position != position) {
      _position = position;
      notifyListeners();
    }
  }

  void setCursorBuffer(Uint8List? buffer) {
    if (_cursorBuffer != buffer) {
      _cursorBuffer = buffer;
      notifyListeners();
    }
  }

  void setDelta(double x, double y) {
    if (_deltax != x || _deltay != y) {
      _deltax = x;
      _deltay = y;
      notifyListeners();
    }
  }

  void moveDelta(double dx, double dy) {
    setDelta(_deltax + dx, _deltay + dy);
  }
}

class OnScreenRemoteMouse extends StatefulWidget {
  final OnScreenRemoteMouseController controller;
  final ValueChanged<Offset>? onPositionChanged;

  const OnScreenRemoteMouse({
    super.key,
    required this.controller,
    this.onPositionChanged,
  });

  @override
  State<OnScreenRemoteMouse> createState() => _OnScreenRemoteMouseState();
}

class _OnScreenRemoteMouseState extends State<OnScreenRemoteMouse> {
  late RenderRemoteMouse _renderObject;

  @override
  void initState() {
    super.initState();
    _renderObject = RenderRemoteMouse(
      position: widget.controller.position,
      cursorBuffer: widget.controller.cursorBuffer,
      deltax: widget.controller.deltax,
      deltay: widget.controller.deltay,
      onPositionChanged: widget.onPositionChanged,
    );
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    _renderObject
      ..position = widget.controller.position
      ..cursorBuffer = widget.controller.cursorBuffer
      ..deltax = widget.controller.deltax
      ..deltay = widget.controller.deltay;
  }

  @override
  Widget build(BuildContext context) {
    return _RemoteMouseRenderObjectWidget(
      renderObject: _renderObject,
    );
  }
}

class _RemoteMouseRenderObjectWidget extends SingleChildRenderObjectWidget {
  final RenderRemoteMouse renderObject;

  const _RemoteMouseRenderObjectWidget({
    required this.renderObject,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => renderObject;

  @override
  void updateRenderObject(BuildContext context, RenderRemoteMouse renderObject) {
    // 不需要更新，因为我们直接使用传入的 renderObject
  }
}

class RenderRemoteMouse extends RenderBox {
  RenderRemoteMouse({
    required Offset position,
    Uint8List? cursorBuffer,
    required double deltax,
    required double deltay,
    ValueChanged<Offset>? onPositionChanged,
  })  : _position = position,
        _cursorBuffer = cursorBuffer,
        _deltax = deltax,
        _deltay = deltay,
        _onPositionChanged = onPositionChanged;

  Offset _position;
  Offset get position => _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    _updatePositionPercentage();
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
    _deltax = _clampDelta(value, true);
    _updatePositionPercentage();
    markNeedsPaint();
  }

  double _deltay;
  double get deltay => _deltay;
  set deltay(double value) {
    if (_deltay == value) return;
    _deltay = _clampDelta(value, false);
    _updatePositionPercentage();
    markNeedsPaint();
  }

  ValueChanged<Offset>? _onPositionChanged;
  ValueChanged<Offset>? get onPositionChanged => _onPositionChanged;
  set onPositionChanged(ValueChanged<Offset>? value) {
    _onPositionChanged = value;
  }

  Offset _positionPercentage = Offset.zero;
  Offset get positionPercentage => _positionPercentage;

  void _updatePositionPercentage() {
    if (parent == null) return;
    
    final parentBox = parent as RenderBox;
    final parentSize = parentBox.size;
    
    final currentX = _position.dx + _deltax;
    final currentY = _position.dy + _deltay;
    
    final newPercentage = Offset(
      currentX / parentSize.width,
      currentY / parentSize.height,
    );
    
    if (_positionPercentage != newPercentage) {
      _positionPercentage = newPercentage;
      _onPositionChanged?.call(_positionPercentage);
    }
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

  // 限制移动范围
  double _clampDelta(double value, bool isX) {
    if (parent == null) return value;
    
    final parentBox = parent as RenderBox;
    final parentSize = parentBox.size;
    final currentPosition = isX ? _position.dx + value : _position.dy + value;
    final maxPosition = isX ? parentSize.width - size.width : parentSize.height - size.height;
    
    // 确保不会超出父控件范围
    if (currentPosition < 0) {
      return -_position.dx;
    } else if (currentPosition > maxPosition) {
      return maxPosition - _position.dx;
    }
    return value;
  }
}
