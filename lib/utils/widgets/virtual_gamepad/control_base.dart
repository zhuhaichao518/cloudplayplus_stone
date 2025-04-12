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
