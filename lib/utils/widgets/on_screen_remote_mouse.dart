import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';

class OnScreenRemoteMouseController extends ChangeNotifier {
  Offset _position = const Offset(100, 100);
  Uint8List? _cursorBuffer;
  double _deltax = 0;
  double _deltay = 0;
  double aspectRatio = 1.6;
  bool _showCursor = true;
  bool _hasMoved = false;
  Offset _positionPercentage = Offset.zero;

  Offset get position => _position;
  Uint8List? get cursorBuffer => _cursorBuffer;
  double get deltax => _deltax;
  double get deltay => _deltay;
  bool get showCursor => _showCursor && _hasMoved; // 只有在移动过且showCursor为true时才显示
  Offset get positionPercentage => _positionPercentage;

  void setPosition(Offset position) {
    if (_position != position) {
      _position = position;
      notifyListeners();
    }
  }

  void setAspectRatio(double ratio) {
    aspectRatio = ratio;
    notifyListeners();
  }

  void setCursorBuffer(Uint8List? buffer) {
    _deltax = 0;
    _deltay = 0;
    _cursorBuffer = buffer;
    notifyListeners();
  }

  void setHasMoved(bool value) {
    _hasMoved = value;
    notifyListeners();
  }

  void setShowCursor(bool value) {
    _showCursor = value;
    notifyListeners();
  }

  void setDelta(double x, double y) {
    //if (_deltax != x || _deltay != y) {
      _deltax = x;
      _deltay = y;
      // We don't want to update the position from percentage when setting delta
      _positionPercentage = const Offset(-1, -1);
      notifyListeners();
    //}
  }

  void moveDelta(double dx, double dy) {
    //第一次移动之前不显示
    if (!_hasMoved) {
      _hasMoved = true;
    }
    setDelta(dx, dy);
  }

  /// 移动指针到绝对位置
  /// [xPercent] X轴百分比位置 (0.0 - 1.0)
  /// [yPercent] Y轴百分比位置 (0.0 - 1.0)
  void moveAbsl(double xPercent, double yPercent) {
    // 确保百分比在有效范围内
    xPercent = xPercent.clamp(0.0, 1.0);
    yPercent = yPercent.clamp(0.0, 1.0);
    
    //第一次移动之前不显示
    if (!_hasMoved) {
      _hasMoved = true;
    }
    
    // 设置绝对位置百分比
    setAbsolutePosition(xPercent, yPercent);
    notifyListeners();
  }

  void setAbsolutePosition(double xPercent, double yPercent) {
    // 清除 delta 值，因为我们要设置绝对位置
    _deltax = 0;
    _deltay = 0;
    
    // 设置绝对位置百分比
    _positionPercentage = Offset(xPercent, yPercent);
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
      ..deltax += widget.controller.deltax
      ..deltay += widget.controller.deltay
      ..aspectRatio = widget.controller.aspectRatio
      ..showCursor = widget.controller.showCursor
      ..controllerPositionPercentage = widget.controller.positionPercentage;
  }

  @override
  Widget build(BuildContext context) {
    /*return Center(
      child: AspectRatio(
        aspectRatio: widget.controller.aspectRatio,
        child: _RemoteMouseRenderObjectWidget(
          renderObject: _renderObject,
        ),
      ),
    );*/
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
        _showCursor = true,
        _aspectRatio = 1.6,
        _onPositionChanged = onPositionChanged;

  Offset _position;
  Offset get position => _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    _updatePositionPercentage();
    markNeedsPaint();
  }

  double _aspectRatio;
  double get aspectRatio => _aspectRatio;
  set aspectRatio(double value) {
    if (_aspectRatio == value) return;
    _aspectRatio = value;
    markNeedsPaint();
    _updateCachedValues();
  }

  bool _showCursor;
  bool get showCursor => _showCursor;
  set showCursor(bool value) {
    if (_showCursor == value) return;
    _showCursor = value;
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
  
  Offset _controllerPositionPercentage = Offset.zero;
  Offset get controllerPositionPercentage => _controllerPositionPercentage;
  set controllerPositionPercentage(Offset value) {
    if (value == const Offset(-1,-1)) return;
    _controllerPositionPercentage = value;
    _updatePositionFromPercentage();
    markNeedsPaint();
  }

  // 添加缓存变量
  Size? _cachedParentSize;
  Rect? _cachedDisplayRect;
  double _cachedAspectRatio = 0;

  void _updateCachedValues() {
    if (parent == null) return;
    
    final parentBox = parent as RenderBox;
    if (!parentBox.hasSize) return;
    final parentSize = parentBox.size;
    
    // 如果父容器尺寸没变，不需要重新计算
    if (_cachedParentSize == parentSize && _cachedAspectRatio == _aspectRatio) return;
    
    _cachedParentSize = parentSize;
    _cachedAspectRatio = _aspectRatio;
    
    // 计算实际显示区域
    double displayWidth = parentSize.width;
    double displayHeight = parentSize.height;
    
    // 根据宽高比计算实际显示区域
    if (displayWidth / displayHeight > _aspectRatio) {
      // 如果父容器太宽，需要左右留白
      displayWidth = displayHeight * _aspectRatio;
    } else {
      // 如果父容器太高，需要上下留白
      displayHeight = displayWidth / _aspectRatio;
    }
    
    // 确保显示区域不会超出父容器
    final finalDisplayWidth = displayWidth.clamp(0.0, parentSize.width);
    final finalDisplayHeight = displayHeight.clamp(0.0, parentSize.height);
    
    // 重新计算偏移量，确保完全居中
    final finalOffsetX = (parentSize.width - finalDisplayWidth) / 2;
    final finalOffsetY = (parentSize.height - finalDisplayHeight) / 2;

    _cachedDisplayRect = Rect.fromLTWH(finalOffsetX, finalOffsetY, finalDisplayWidth, finalDisplayHeight);
  }

  void _updatePositionPercentage() {
    if (parent == null) return;
    
    //_updateCachedValues();
    if (_cachedDisplayRect == null) return;
    
    final currentX = _position.dx + _deltax;
    final currentY = _position.dy + _deltay;
    
    // 将坐标转换为相对于显示区域的百分比
    // currentX + _hotX才是指针实际位置
    final newPercentage = Offset(
      (currentX/* + _hotX*/ - _cachedDisplayRect!.left) / _cachedDisplayRect!.width,
      (currentY/* + _hotY*/ - _cachedDisplayRect!.top) / _cachedDisplayRect!.height,
    );
    
    if (_positionPercentage != newPercentage) {
      _positionPercentage = newPercentage;
      _controllerPositionPercentage = newPercentage;
      _onPositionChanged?.call(_positionPercentage);
    }
  }
  
  void _updatePositionFromPercentage() {
    if (parent == null) return;
    
    _updateCachedValues();
    if (_cachedDisplayRect == null) return;
    
    // 如果控制器设置了百分比位置（非零），则使用该位置
    if (_controllerPositionPercentage != const Offset(-1,-1)) {
      // 将百分比转换为实际像素位置
      final targetX = _cachedDisplayRect!.left + (_controllerPositionPercentage.dx * _cachedDisplayRect!.width);
      final targetY = _cachedDisplayRect!.top + (_controllerPositionPercentage.dy * _cachedDisplayRect!.height);
      
      // 计算新的 delta 值（相对于原始 _position 的偏移）
      _deltax = targetX - _position.dx;
      _deltay = targetY - _position.dy;
      
      // 更新百分比位置
      final newPercentage = _controllerPositionPercentage;
      if (_positionPercentage != newPercentage) {
        _positionPercentage = newPercentage;
        //对于自绘鼠标，百分比移动仅用于同步位置，不涉及位置改变回调
        //_onPositionChanged?.call(_positionPercentage);
      }
    }
  }
  
  static Map<int, Offset> _cursorOffset = {};
  static Map<int, ui.Image> _cursorImages = {};

  int _width = 32;  // 默认值
  int _height = 32; // 默认值
  int _hotX = 16;   // 默认值
  int _hotY = 16;   // 默认值
  int _hash = 0;

  void _decodeCursorBuffer() {
    if (_cursorBuffer![0] == 10) {
      ByteData byteData = ByteData.sublistView(_cursorBuffer!);
        int message = byteData.getInt32(1);
        int msgInfo = byteData.getInt32(5);
        if (message == HardwareSimulator.CURSOR_UPDATED_CACHED) {
          if (_cursorImages.containsKey(msgInfo)) {
            _hash = msgInfo;
            markNeedsPaint();
          }
        } 
      return;
    }

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
    _hash = hash;

    // 获取图像数据
    final imageData = _cursorBuffer!.sublist(21);
    
    // 保存当前值
    final currentHash = _hash;
    final currentHotX = _hotX;
    final currentHotY = _hotY;
    
    // 将图像数据转换为ui.Image
    ui.decodeImageFromPixels(
      imageData,
      _width,
      _height,
      ui.PixelFormat.bgra8888,
      (ui.Image image) {
        _cursorOffset[currentHash] = Offset(-currentHotX.toDouble(), -currentHotY.toDouble());
        _cursorImages[currentHash] = image;
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
    if (!_showCursor) return;
    if (!_cursorImages.containsKey(_hash)) {
      // 如果没有图像，绘制一个默认的箭头
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(size.width / 3, size.height);
      path.lineTo(size.width, size.height / 3);
      path.close();

      _hotY = 0;
      _hotX = 0;

      final finalX = offset.dx + _position.dx + _deltax;
      final finalY = offset.dy + _position.dy + _deltay;

      context.canvas.save();
      context.canvas.translate(finalX, finalY);
      context.canvas.drawPath(path, paint);
      context.canvas.restore();
    } else {
      final finalX = offset.dx + _position.dx + _deltax;
      final finalY = offset.dy + _position.dy + _deltay;

      context.canvas.save();
      context.canvas.translate(finalX, finalY);
      // 应用缩放
      final scale = StreamingSettings.cursorScale / 100.0;
      context.canvas.scale(scale, scale);
      // offset不需要缩放
      /*final scaledOffset = Offset(
        _cursorOffset[_hash]!.dx / scale,
        _cursorOffset[_hash]!.dy / scale
      );*/
      context.canvas.drawImage(_cursorImages[_hash]!, _cursorOffset[_hash]!, Paint());
      context.canvas.restore();
    }
  }

  double _clampDelta(double value, bool isX) {
    if (parent == null) return value;
    
    _updateCachedValues();
    if (_cachedDisplayRect == null) return value;
    
    final currentPosition = isX ? _position.dx + value : _position.dy + value;
    
    if (isX) {
      // 确保热点不会超出左边界
      if (currentPosition < _cachedDisplayRect!.left) {
        return _cachedDisplayRect!.left - _position.dx;
      }
      // 确保热点不会超出右边界
      if (currentPosition > _cachedDisplayRect!.right) {
        return _cachedDisplayRect!.right - _position.dx;
      }
    } else {
      // 确保热点不会超出上边界
      if (currentPosition < _cachedDisplayRect!.top) {
        return _cachedDisplayRect!.top - _position.dy;
      }
      // 确保热点不会超出下边界
      if (currentPosition> _cachedDisplayRect!.bottom) {
        return _cachedDisplayRect!.bottom - _position.dy;
      }
    }
    return value;
  }
}
