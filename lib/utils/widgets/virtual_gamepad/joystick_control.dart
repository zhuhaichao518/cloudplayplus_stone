import 'package:flutter/material.dart';
import 'control_base.dart';
import 'control_event.dart';
import 'gamepad_keys.dart';
import 'dart:math';
import 'dart:async';

class JoystickControl extends ControlBase {
  final String joystickType; // 摇杆类型：left 或 right

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
      joystickType: map['joystickType'] ?? 'left',
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
      'joystickType': joystickType,
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
  Offset _joystickOffset = Offset.zero;
  bool _isJoystickActive = false;
  bool isClick = false;

  @override
  Widget build(BuildContext context) {
    // 在build方法中直接计算大小
    final joystickRadius = widget.screenWidth * widget.control.size / 2;
    final thumbRadius = joystickRadius * 0.2;

    return Positioned(
      left: widget.screenWidth * widget.control.centerX - joystickRadius,
      bottom:
          widget.screenHeight * (1 - widget.control.centerY) - joystickRadius,
      child: GestureDetector(
        onPanStart: (_) {
          isClick = true;
          setState(() => _isJoystickActive = true);
        },
        onPanUpdate: (details) {
          setState(() {
            _joystickOffset += details.delta;
            final distance = _joystickOffset.distance;
            if (distance > joystickRadius) {
              _joystickOffset = Offset(
                _joystickOffset.dx * joystickRadius / distance,
                _joystickOffset.dy * joystickRadius / distance,
              );
            }
          });

          // 发送摇杆位置更新事件
          final xValue = _joystickOffset.dx / joystickRadius;
          final yValue = -_joystickOffset.dy / joystickRadius; // 反转Y轴方向

          if (xValue.abs() > 0.01 || yValue.abs() > 0.01) {
            isClick = false;
          }

          // 根据摇杆类型发送不同的事件
          if (widget.control.joystickType == 'left') {
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.leftStickX,
                value: xValue,
              ),
            ));
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.leftStickY,
                value: yValue,
              ),
            ));
          } else {
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.rightStickX,
                value: xValue,
              ),
            ));
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.rightStickY,
                value: yValue,
              ),
            ));
          }
        },
        onPanEnd: (_) {
          setState(() {
            _joystickOffset = Offset.zero;
            _isJoystickActive = false;
          });

          //perform a click if user does not move.
          if (isClick) {
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadButtonEvent(
                keyCode: widget.control.joystickType == 'left'
                    ? GamepadKeys.LEFT_STICK_BUTTON
                    : GamepadKeys.RIGHT_STICK_BUTTON,
                isDown: true,
              ),
            ));
            Future.delayed(const Duration(milliseconds: 32), () {
              widget.onEvent(ControlEvent(
                eventType: ControlEventType.gamepad,
                data: GamepadButtonEvent(
                  keyCode: widget.control.joystickType == 'left'
                      ? GamepadKeys.LEFT_STICK_BUTTON
                      : GamepadKeys.RIGHT_STICK_BUTTON,
                  isDown: false,
                ),
              ));
            });
          }

          // 发送归零事件
          if (widget.control.joystickType == 'left') {
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.leftStickX,
                value: 0.0,
              ),
            ));
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.leftStickY,
                value: 0.0,
              ),
            ));
          } else {
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.rightStickX,
                value: 0.0,
              ),
            ));
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.gamepad,
              data: GamepadAnalogEvent(
                key: GamepadKey.rightStickY,
                value: 0.0,
              ),
            ));
          }
        },
        child: Container(
          width: joystickRadius * 2,
          height: joystickRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.3),
          ),
          child: Center(
            child: Transform.translate(
              offset: _joystickOffset,
              child: Container(
                width: thumbRadius * 2,
                height: thumbRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  Offset _joystickOffset = Offset.zero;
  double lastReportX = 0;
  double lastReportY = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final joystickRadius = widget.screenWidth * widget.control.size / 2;
    final thumbRadius = joystickRadius * 0.2;
    final threshold = joystickRadius * 0.4; // 跳转阈值

    return Positioned(
      left: widget.screenWidth * widget.control.centerX - joystickRadius,
      bottom: widget.screenHeight * (1 - widget.control.centerY) - joystickRadius,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _joystickOffset = Offset.zero;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _joystickOffset += details.delta;
            final distance = _joystickOffset.distance;
            if (distance > joystickRadius) {
              _joystickOffset = Offset(
                _joystickOffset.dx * joystickRadius / distance,
                _joystickOffset.dy * joystickRadius / distance,
              );
            }
          });

          // 检查是否超过阈值且未跳转
          if (_joystickOffset.distance > threshold) {
            
            // 计算八方向
            final xValue = _joystickOffset.dx / joystickRadius;
            final yValue = -_joystickOffset.dy / joystickRadius; // 反转Y轴方向

            // 计算角度
            final angle = (atan2(yValue, xValue) * 180 / pi + 360) % 360;
            
            // 八方向映射到屏幕角落
            double targetX = 0.5; // 默认屏幕中心
            double targetY = 0.5;
            
            if (angle >= 337.5 || angle < 22.5) {
              // 右
              targetX = 1;
              targetY = 0.5;
            } else if (angle >= 22.5 && angle < 67.5) {
              // 右上
              targetX = 1;
              targetY = 0;
            } else if (angle >= 67.5 && angle < 112.5) {
              // 上
              targetX = 0.5;
              targetY = 0;
            } else if (angle >= 112.5 && angle < 157.5) {
              // 左上
              targetX = 0;
              targetY = 0;
            } else if (angle >= 157.5 && angle < 202.5) {
              // 左
              targetX = 0;
              targetY = 0.5;
            } else if (angle >= 202.5 && angle < 247.5) {
              // 左下
              targetX = 0;
              targetY = 1;
            } else if (angle >= 247.5 && angle < 292.5) {
              // 下
              targetX = 0.5;
              targetY = 1;
            } else if (angle >= 292.5 && angle < 337.5) {
              // 右下
              targetX = 1;
              targetY = 1;
            }

            if (lastReportX == targetX && lastReportY == targetY) {
              return;
            }
            lastReportX = targetX;
            lastReportY = targetY;

            // 发送鼠标绝对位置跳转事件
            widget.onEvent(ControlEvent(
              eventType: ControlEventType.mouseMove,
              data: MouseMoveEvent(
                deltaX: targetX,
                deltaY: targetY,
                isAbsolute: true, // 标记为绝对位置跳转
              ),
            ));
          }
        },
        onPanEnd: (_) {
          setState(() {
            _joystickOffset = Offset.zero;
          });
          lastReportX = 0.5;
          lastReportY = 0.5;
          widget.onEvent(ControlEvent(
            eventType: ControlEventType.mouseMove,
            data: MouseMoveEvent(
              deltaX: 0.5,
              deltaY: 0.5,
              isAbsolute: true, // 标记为绝对位置跳转
            ),
          ));
        },
        child: Container(
          width: joystickRadius * 2,
          height: joystickRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),
            //border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Stack(
            clipBehavior: Clip.none, // 允许子组件超出边界
            children: [
              // 绘制阈值圆圈
              Center(
                child: Container(
                  width: threshold * 2,
                  height: threshold * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.2),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                ),
              ),
              // 绘制八个方向的指示线
              ...List.generate(8, (index) {
                final angle = index * 45.0 * pi / 180;
                final startX = joystickRadius + cos(angle) * (joystickRadius * 0.3);
                final startY = joystickRadius + sin(angle) * (joystickRadius * 0.3);
                final endX = joystickRadius + cos(angle) * (joystickRadius * 0.8);
                final endY = joystickRadius + sin(angle) * (joystickRadius * 0.8);
                
                return Positioned(
                  left: 0,
                  top: 0,
                  child: CustomPaint(
                    size: Size(joystickRadius * 2, joystickRadius * 2),
                    painter: DirectionLinePainter(
                      startX: startX,
                      startY: startY,
                      endX: endX,
                      endY: endY,
                    ),
                  ),
                );
              }),
              // 中心摇杆 - 使用与原版摇杆相同的布局
              Center(
                child: Transform.translate(
                  offset: _joystickOffset,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.5),
                      //border: Border.all(color: Colors.orange, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
