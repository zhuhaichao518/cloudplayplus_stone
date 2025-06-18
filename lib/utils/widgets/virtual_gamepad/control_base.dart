import 'package:flutter/material.dart';
import 'button_control.dart';
import 'joystick_control.dart';
import 'control_event.dart';

abstract class ControlBase {
  final String id;
  final double centerX; // 位置比例 (0.0-1.0)
  final double centerY; // 位置比例 (0.0-1.0)
  final double size; // 大小比例 (0.0-1.0)
  final String type; // 控件类型标识

  ControlBase({
    required this.id,
    required this.centerX,
    required this.centerY,
    required this.size,
    required this.type,
  });

  // 转换为Map用于序列化
  Map<String, dynamic> toMap();

  // 从Map创建控件
  static ControlBase fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'joystick':
        return JoystickControl.fromMap(map);
      case 'button':
        return ButtonControl.fromMap(map);
      case 'mouseModeButton':
        return MouseModeButtonControl.fromMap(map);
      default:
        throw Exception('Unknown control type: $type');
    }
  }

  // 构建控件对应的Widget
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  });

  // 处理控件事件
  void handleEvent(ControlEvent event);
}

class MouseModeButtonControl extends ControlBase {
  final List<MouseMode> enabledModes;
  final Color color;
  MouseMode _currentMode;
  bool _isPressed = false; // 添加按下状态跟踪

  MouseModeButtonControl({
    required super.id,
    required super.centerX,
    required super.centerY,
    required super.size,
    required this.enabledModes,
    this.color = Colors.blue,
  }) : _currentMode = enabledModes.first,
       super(type: 'mouseModeButton');

  @override
  void handleEvent(ControlEvent event) {
    // 鼠标模式按钮不需要处理外部事件
  }

  @override
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  }) {
    return Positioned(
      left: centerX * screenWidth - (size * screenWidth) / 2,
      top: centerY * screenHeight - (size * screenHeight) / 2,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          _isPressed = true; // 设置按下状态
          final currentIndex = enabledModes.indexOf(_currentMode);
          final nextIndex = (currentIndex + 1) % enabledModes.length;
          _currentMode = enabledModes[nextIndex];
          
          // 触发界面重建
          if (context.mounted) {
            (context as Element).markNeedsBuild();
          }
          onEvent(ControlEvent(
            eventType: ControlEventType.mouseMode,
            data: MouseModeEvent(
              //enabledModes: enabledModes,
              currentMode: _currentMode,
              isUnique: (enabledModes.length == 1),
              isDown: true
            ),
          ));
        },
        onTapUp:(TapUpDetails details) {
          _isPressed = false; // 重置按下状态
          if (context.mounted) {
            (context as Element).markNeedsBuild();
          }
          if (enabledModes.length == 1) {
            onEvent(ControlEvent(
              eventType: ControlEventType.mouseMode,
              data: MouseModeEvent(
                //enabledModes: enabledModes,
                currentMode: _currentMode,
                isUnique: true,
                isDown: false
              ),
            ));
          }
        },
        onTapCancel: () {
          _isPressed = false; // 重置按下状态
          if (context.mounted) {
            (context as Element).markNeedsBuild();
          }
          if (enabledModes.length == 1) {
            onEvent(ControlEvent(
              eventType: ControlEventType.mouseMode,
              data: MouseModeEvent(
                //enabledModes: enabledModes,
                currentMode: _currentMode,
                isUnique: true,
                isDown: false
              ),
            ));
          }
        },
        child: Container(
          width: size * screenWidth,
          height: size * screenHeight,
          decoration: BoxDecoration(
            color: _isPressed ? color.withOpacity(0.8) : color.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getModeLabel(_currentMode),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * screenWidth * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getModeLabel(MouseMode mode) {
    switch (mode) {
      case MouseMode.leftClick:
        return '左';
      case MouseMode.rightClick:
        return '右';
      case MouseMode.move:
        return '移';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'mouseModeButton',
      'id': id,
      'centerX': centerX,
      'centerY': centerY,
      'size': size,
      'enabledModes': enabledModes.map((m) => m.toString()).toList(),
      'color': color.value,
    };
  }

  factory MouseModeButtonControl.fromMap(Map<String, dynamic> map) {
    return MouseModeButtonControl(
      id: map['id'] as String,
      centerX: map['centerX'] as double,
      centerY: map['centerY'] as double,
      size: map['size'] as double,
      enabledModes: (map['enabledModes'] as List)
          .map((m) => MouseMode.values.firstWhere(
              (e) => e.toString() == m,
              orElse: () => MouseMode.leftClick))
          .toList(),
      color: Color(map['color'] as int),
    );
  }
}
