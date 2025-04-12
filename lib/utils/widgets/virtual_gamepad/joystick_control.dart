import 'package:flutter/material.dart';
import 'control_base.dart';
import 'control_event.dart';
import 'gamepad_keys.dart';

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
    final thumbRadius = joystickRadius * 0.4;

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
