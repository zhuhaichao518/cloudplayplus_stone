import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'control_base.dart';
import 'control_event.dart';
import 'gamepad_keys.dart';
import 'dart:math';
import 'dart:async';

// ============================================================================
// 常量定义 - 避免魔法数字
// ============================================================================
class JoystickConstants {
  static const double thumbRadiusRatio = 0.2;
  static const double directionLineStartRatio = 0.3;
  static const double directionLineEndRatio = 0.8;
  static const double eightDirectionThresholdRatio = 0.4;
  static const double clickThreshold = 0.01;
  static const int clickButtonDelay = 32; // ms
}

// ============================================================================
// 枚举定义 - 类型安全
// ============================================================================
enum JoystickType { left, right }

extension JoystickTypeExtension on JoystickType {
  String toStringValue() => name;
  
  static JoystickType fromString(String value) {
    return JoystickType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JoystickType.left,
    );
  }
}

// ============================================================================
// 摇杆控制器 - 分离业务逻辑
// ============================================================================
class JoystickController {
  final ValueNotifier<Offset> offsetNotifier = ValueNotifier(Offset.zero);
  final JoystickType type;
  final void Function(ControlEvent) onEvent;
  
  Offset? _lastSentOffset;
  bool _isActive = false;
  
  JoystickController({
    required this.type,
    required this.onEvent,
  });
  
  void updatePosition(Offset offset, double radius) {
    offsetNotifier.value = offset;
    _sendJoystickEvent(offset, radius);
  }
  
  void reset() {
    offsetNotifier.value = Offset.zero;
    if (_isActive) {
      _sendResetEvent();
      _isActive = false;
    }
  }
  
  void performClick() {
    final button = type == JoystickType.left
        ? GamepadKeys.LEFT_STICK_BUTTON
        : GamepadKeys.RIGHT_STICK_BUTTON;
    
    // 触觉反馈
    HapticFeedback.lightImpact();
    
    onEvent(ControlEvent(
      eventType: ControlEventType.gamepad,
      data: GamepadButtonEvent(keyCode: button, isDown: true),
    ));
    
    Future.delayed(
      const Duration(milliseconds: JoystickConstants.clickButtonDelay),
      () {
        onEvent(ControlEvent(
          eventType: ControlEventType.gamepad,
          data: GamepadButtonEvent(keyCode: button, isDown: false),
        ));
      },
    );
  }
  
  void _sendJoystickEvent(Offset offset, double radius) {
    _isActive = true;
    final xValue = offset.dx / radius;
    final yValue = -offset.dy / radius;
    
    // 避免发送相同的值
    if (_lastSentOffset != null && 
        (_lastSentOffset!.dx - offset.dx).abs() < 0.001 &&
        (_lastSentOffset!.dy - offset.dy).abs() < 0.001) {
      return;
    }
    _lastSentOffset = offset;
    
    final xKey = type == JoystickType.left
        ? GamepadKey.leftStickX
        : GamepadKey.rightStickX;
    final yKey = type == JoystickType.left
        ? GamepadKey.leftStickY
        : GamepadKey.rightStickY;
    
    onEvent(ControlEvent(
      eventType: ControlEventType.gamepad,
      data: GamepadAnalogEvent(key: xKey, value: xValue),
    ));
    onEvent(ControlEvent(
      eventType: ControlEventType.gamepad,
      data: GamepadAnalogEvent(key: yKey, value: yValue),
    ));
  }
  
  void _sendResetEvent() {
    final xKey = type == JoystickType.left
        ? GamepadKey.leftStickX
        : GamepadKey.rightStickX;
    final yKey = type == JoystickType.left
        ? GamepadKey.leftStickY
        : GamepadKey.rightStickY;
    
    onEvent(ControlEvent(
      eventType: ControlEventType.gamepad,
      data: GamepadAnalogEvent(key: xKey, value: 0.0),
    ));
    onEvent(ControlEvent(
      eventType: ControlEventType.gamepad,
      data: GamepadAnalogEvent(key: yKey, value: 0.0),
    ));
    
    _lastSentOffset = null;
  }
  
  void dispose() {
    offsetNotifier.dispose();
  }
}

// ============================================================================
// 摇杆控件
// ============================================================================
class JoystickControl extends ControlBase {
  final JoystickType joystickType;

  JoystickControl({
    required String id,
    required double centerX,
    required double centerY,
    required double size,
    required this.joystickType,
  }) : super(
          id: id,
          centerX: centerX,
          centerY: centerY,
          size: size,
          type: 'joystick',
        );

  factory JoystickControl.fromMap(Map<String, dynamic> map) {
    return JoystickControl(
      id: map['id'],
      centerX: map['centerX'],
      centerY: map['centerY'],
      size: map['size'],
      joystickType: JoystickTypeExtension.fromString(
        map['joystickType'] ?? 'left',
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'centerX': centerX,
      'centerY': centerY,
      'size': size,
      'joystickType': joystickType.toStringValue(),
    };
  }

  @override
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  }) {
    return _JoystickWidget(
      control: this,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      onEvent: onEvent,
    );
  }

  @override
  void handleEvent(ControlEvent event) {
    // 摇杆事件处理
  }
}

// 新增八方向摇杆控件
class EightDirectionJoystickControl extends ControlBase {
  EightDirectionJoystickControl({
    required String id,
    required double centerX,
    required double centerY,
    required double size,
  }) : super(
          id: id,
          centerX: centerX,
          centerY: centerY,
          size: size,
          type: 'eightDirectionJoystick',
        );

  factory EightDirectionJoystickControl.fromMap(Map<String, dynamic> map) {
    return EightDirectionJoystickControl(
      id: map['id'],
      centerX: map['centerX'],
      centerY: map['centerY'],
      size: map['size'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'centerX': centerX,
      'centerY': centerY,
      'size': size,
    };
  }

  @override
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  }) {
    return _EightDirectionJoystickWidget(
      control: this,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      onEvent: onEvent,
    );
  }

  @override
  void handleEvent(ControlEvent event) {
    // 八方向摇杆事件处理
  }
}

class _JoystickWidget extends StatefulWidget {
  final JoystickControl control;
  final double screenWidth;
  final double screenHeight;
  final Function(ControlEvent) onEvent;

  const _JoystickWidget({
    required this.control,
    required this.screenWidth,
    required this.screenHeight,
    required this.onEvent,
  });

  @override
  State<_JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<_JoystickWidget> {
  late JoystickController _controller;
  late double _joystickRadius;
  late double _thumbRadius;
  late Offset _localCenter;
  bool _isClick = false;

  @override
  void initState() {
    super.initState();
    _controller = JoystickController(
      type: widget.control.joystickType,
      onEvent: widget.onEvent,
    );
    _updateSizes();
  }

  @override
  void didUpdateWidget(_JoystickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenWidth != widget.screenWidth ||
        oldWidget.screenHeight != widget.screenHeight ||
        oldWidget.control.size != widget.control.size) {
      _updateSizes();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSizes() {
    _joystickRadius = widget.screenWidth * widget.control.size / 2;
    _thumbRadius = _joystickRadius * JoystickConstants.thumbRadiusRatio;
    _localCenter = Offset(_joystickRadius, _joystickRadius);
  }

  Offset _constrainOffset(Offset offset) {
    final distance = offset.distance;
    if (distance > _joystickRadius) {
      return Offset(
        offset.dx * _joystickRadius / distance,
        offset.dy * _joystickRadius / distance,
      );
    }
    return offset;
  }

  void _handlePanStart(DragStartDetails details) {
    _isClick = true;
    final offset = _constrainOffset(details.localPosition - _localCenter);
    _controller.updatePosition(offset, _joystickRadius);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final offset = _constrainOffset(details.localPosition - _localCenter);
    
    // 检查是否移动足够取消点击
    final normalized = offset / _joystickRadius;
    if (normalized.distance > JoystickConstants.clickThreshold) {
      _isClick = false;
    }
    
    _controller.updatePosition(offset, _joystickRadius);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isClick) {
      _controller.performClick();
    }
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.screenWidth * widget.control.centerX - _joystickRadius,
      bottom: widget.screenHeight * (1 - widget.control.centerY) - _joystickRadius,
      child: RepaintBoundary( // 隔离重绘边界
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Container(
            width: _joystickRadius * 2,
            height: _joystickRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.3),
            ),
            child: ValueListenableBuilder<Offset>(
              valueListenable: _controller.offsetNotifier,
              builder: (context, offset, child) {
                return Center(
                  child: Transform.translate(
                    offset: offset,
                    child: Container(
                      width: _thumbRadius * 2,
                      height: _thumbRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 八方向配置 - 配置驱动
// ============================================================================
@immutable
class DirectionConfig {
  final double minAngle;
  final double maxAngle;
  final Offset target;
  final String name;

  const DirectionConfig({
    required this.minAngle,
    required this.maxAngle,
    required this.target,
    required this.name,
  });
}

// ============================================================================
// 八方向控制器
// ============================================================================
class EightDirectionController {
  static const List<DirectionConfig> _directions = [
    DirectionConfig(minAngle: 337.5, maxAngle: 22.5, target: Offset(1, 0.5), name: '右'),
    DirectionConfig(minAngle: 22.5, maxAngle: 67.5, target: Offset(1, 0), name: '右上'),
    DirectionConfig(minAngle: 67.5, maxAngle: 112.5, target: Offset(0.5, 0), name: '上'),
    DirectionConfig(minAngle: 112.5, maxAngle: 157.5, target: Offset(0, 0), name: '左上'),
    DirectionConfig(minAngle: 157.5, maxAngle: 202.5, target: Offset(0, 0.5), name: '左'),
    DirectionConfig(minAngle: 202.5, maxAngle: 247.5, target: Offset(0, 1), name: '左下'),
    DirectionConfig(minAngle: 247.5, maxAngle: 292.5, target: Offset(0.5, 1), name: '下'),
    DirectionConfig(minAngle: 292.5, maxAngle: 337.5, target: Offset(1, 1), name: '右下'),
  ];

  final ValueNotifier<Offset> offsetNotifier = ValueNotifier(Offset.zero);
  final void Function(ControlEvent) onEvent;
  
  Offset? _lastTarget;
  
  EightDirectionController({required this.onEvent});
  
  void updatePosition(Offset offset, double threshold) {
    offsetNotifier.value = offset;
    
    if (offset.distance > threshold) {
      final target = _getDirectionTarget(offset);
      if (target != _lastTarget) {
        _lastTarget = target;
        onEvent(ControlEvent(
          eventType: ControlEventType.mouseMove,
          data: MouseMoveEvent(
            deltaX: target.dx,
            deltaY: target.dy,
            isAbsolute: true,
          ),
        ));
      }
    }
  }
  
  void reset() {
    offsetNotifier.value = Offset.zero;
    _lastTarget = null;
    onEvent(ControlEvent(
      eventType: ControlEventType.mouseMove,
      data: MouseMoveEvent(deltaX: 0.5, deltaY: 0.5, isAbsolute: true),
    ));
  }
  
  Offset _getDirectionTarget(Offset offset) {
    final angle = (atan2(-offset.dy, offset.dx) * 180 / pi + 360) % 360;
    
    for (final dir in _directions) {
      if (dir.minAngle < dir.maxAngle) {
        if (angle >= dir.minAngle && angle < dir.maxAngle) {
          return dir.target;
        }
      } else {
        // 跨越0度的情况（如右方向：337.5-22.5）
        if (angle >= dir.minAngle || angle < dir.maxAngle) {
          return dir.target;
        }
      }
    }
    
    return const Offset(0.5, 0.5);
  }
  
  void dispose() {
    offsetNotifier.dispose();
  }
}

// ============================================================================
// 八方向摇杆 Widget
// ============================================================================
class _EightDirectionJoystickWidget extends StatefulWidget {
  final EightDirectionJoystickControl control;
  final double screenWidth;
  final double screenHeight;
  final Function(ControlEvent) onEvent;

  const _EightDirectionJoystickWidget({
    required this.control,
    required this.screenWidth,
    required this.screenHeight,
    required this.onEvent,
  });

  @override
  State<_EightDirectionJoystickWidget> createState() => _EightDirectionJoystickWidgetState();
}

class _EightDirectionJoystickWidgetState extends State<_EightDirectionJoystickWidget> {
  late EightDirectionController _controller;
  late double _joystickRadius;
  late double _thumbRadius;
  late double _threshold;
  late Offset _localCenter;

  @override
  void initState() {
    super.initState();
    _controller = EightDirectionController(onEvent: widget.onEvent);
    _updateSizes();
  }

  @override
  void didUpdateWidget(_EightDirectionJoystickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenWidth != widget.screenWidth ||
        oldWidget.screenHeight != widget.screenHeight ||
        oldWidget.control.size != widget.control.size) {
      _updateSizes();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSizes() {
    _joystickRadius = widget.screenWidth * widget.control.size / 2;
    _thumbRadius = _joystickRadius * JoystickConstants.thumbRadiusRatio;
    _threshold = _joystickRadius * JoystickConstants.eightDirectionThresholdRatio;
    _localCenter = Offset(_joystickRadius, _joystickRadius);
  }

  Offset _constrainOffset(Offset offset) {
    final distance = offset.distance;
    if (distance > _joystickRadius) {
      return Offset(
        offset.dx * _joystickRadius / distance,
        offset.dy * _joystickRadius / distance,
      );
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.screenWidth * widget.control.centerX - _joystickRadius,
      bottom: widget.screenHeight * (1 - widget.control.centerY) - _joystickRadius,
      child: RepaintBoundary( // 隔离重绘边界
        child: GestureDetector(
          onPanStart: (details) {
            final offset = _constrainOffset(details.localPosition - _localCenter);
            _controller.updatePosition(offset, _threshold);
          },
          onPanUpdate: (details) {
            final offset = _constrainOffset(details.localPosition - _localCenter);
            _controller.updatePosition(offset, _threshold);
          },
          onPanEnd: (_) => _controller.reset(),
          child: Container(
            width: _joystickRadius * 2,
            height: _joystickRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.3),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 阈值圆圈
                Center(
                  child: Container(
                    width: _threshold * 2,
                    height: _threshold * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                  ),
                ),
                // 方向指示线
                ..._buildDirectionLines(),
                // 摇杆
                ValueListenableBuilder<Offset>(
                  valueListenable: _controller.offsetNotifier,
                  builder: (context, offset, child) {
                    return Center(
                      child: Transform.translate(
                        offset: offset,
                        child: Container(
                          width: _thumbRadius * 2,
                          height: _thumbRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDirectionLines() {
    return List.generate(8, (index) {
      final angle = index * 45.0 * pi / 180;
      final startRatio = JoystickConstants.directionLineStartRatio;
      final endRatio = JoystickConstants.directionLineEndRatio;
      
      return Positioned(
        left: 0,
        top: 0,
        child: CustomPaint(
          size: Size(_joystickRadius * 2, _joystickRadius * 2),
          painter: DirectionLinePainter(
            startX: _joystickRadius + cos(angle) * (_joystickRadius * startRatio),
            startY: _joystickRadius + sin(angle) * (_joystickRadius * startRatio),
            endX: _joystickRadius + cos(angle) * (_joystickRadius * endRatio),
            endY: _joystickRadius + sin(angle) * (_joystickRadius * endRatio),
          ),
        ),
      );
    });
  }
}

class DirectionLinePainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  DirectionLinePainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
