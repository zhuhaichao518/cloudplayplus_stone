// gamepad_detector.dart
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';

@JS('navigator.getGamepads')
external dynamic _getGamepads();

List<GamepadController> getGamepads() {
  List<GamepadController> controllers = [];
  final gamepads = _getGamepads(); // 获取游戏手柄列表
  // 动态获取实际连接的游戏手柄数量
  for (int i = 0; i < gamepads.length; i++) {
    final gamepad = getProperty(gamepads, i.toString()); // 使用js_util来获取属性
    if (gamepad != null) {
      // 确保这里的id和name的使用与你的GamepadController构造函数期望的一致
      controllers.add(
          GamepadController(id: gamepad.index.toString(), name: gamepad.id));
    }
  }
  return controllers;
}

List<dynamic> getGamepadList() {
  return _getGamepads();
}
