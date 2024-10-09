// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html show window;
import 'dart:js_util';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/method_channel_interface.dart';
import 'package:js/js.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gamepad_detector.dart';

abstract class GamepadsPlatformInterface extends PlatformInterface {
  static final Object _token = Object();

  GamepadsPlatformInterface() : super(token: _token);

  /// The default instance of [GamepadsPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelGamepadsPlatformInterface].
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [GamepadsPlatformInterface] when they register
  /// themselves.
  static GamepadsPlatformInterface instance = GamepadsWeb();

  Future<List<GamepadController>> listGamepads();

  Stream<GamepadEvent> get gamepadEventsStream;

  List<String> getGamepadStatesListString() {
    return [];
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  int gamepad_count = 0;
  Timer? _gamepadPollingTimer;
  void _startPollingGamepads() {
    _gamepadPollingTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      // Replace this with your method for checking gamepad state
      getGamepadStatesListString();
    });
  }

  /// Constructs a GamepadsWeb
  GamepadsWeb() {
    /*html.window.addEventListener('gamepadconnected', (event) {
      _startPollingGamepads();
      getGamepadStatesListString();
    });

    html.window.addEventListener('gamepaddisconnected', (event) {
      gamepad_count--;
      if (gamepad_count == 0){
        _gamepadPollingTimer?.cancel();
      }
    });*/
  }

  @override
  Future<List<GamepadController>> listGamepads() async {
    return getGamepads();
  }

  @override
  List<String> getGamepadStatesListString() {
    List<String> result = [];
    final gamepads = getGamepadList(); // 获取游戏手柄列表
    // 动态获取实际连接的游戏手柄数量
    for (int i = 0; i < gamepads.length; i++) {
      final gamepad = getProperty(gamepads, i.toString()); // 使用js_util来获取属性
      if (gamepad != null) {
        // 确保这里的id和name的使用与你的GamepadController构造函数期望的一致
        //controllers.add(GamepadController(id: gamepad.index.toString(), name: gamepad.id));
        //访问变量的方式：gamepad.index.toString(), name: gamepad.id
        //print(gamepad.toString());
        int buttoncount = gamepad.buttons.length;
        //XBOX controller WORD param
        //https://luser.github.io/gamepadtest/
        int word = 0;
        //if (buttoncount == 17){
        if (gamepad.buttons[12].pressed) word |= 0x0001;
        if (gamepad.buttons[13].pressed) word |= 0x0002;
        if (gamepad.buttons[14].pressed) word |= 0x0004;
        if (gamepad.buttons[15].pressed) word |= 0x0008;
        if (gamepad.buttons[9].pressed) word |= 0x0010;
        if (gamepad.buttons[8].pressed) word |= 0x0020;
        if (gamepad.buttons[10].pressed) word |= 0x0040;
        if (gamepad.buttons[11].pressed) word |= 0x0080;
        if (gamepad.buttons[4].pressed) word |= 0x0100;
        if (gamepad.buttons[5].pressed) word |= 0x0200;
        if (gamepad.buttons[0].pressed) word |= 0x1000;
        if (gamepad.buttons[1].pressed) word |= 0x2000;
        if (gamepad.buttons[2].pressed) word |= 0x4000;
        if (gamepad.buttons[3].pressed) word |= 0x8000;
        //}
        //LT,0-255
        int bLeftTrigger = gamepad.buttons[6].value * 255; //LT,0-255
        int bRightTrigger = gamepad.buttons[7].value * 255;

        int sThumbLX = (gamepad.axes[0] * 32767).toInt(); //-32768 to 32767
        int sThumbLY = -(gamepad.axes[1] * 32767).toInt();
        int sThumbRX = (gamepad.axes[2] * 32767).toInt();
        int sThumbRY = -(gamepad.axes[3] * 32767).toInt();
        //int axiscount = gamepad.axes.length;
        //print("xinput: $word $bLeftTrigger $bRightTrigger $sThumbLX $sThumbLY $sThumbRX $sThumbRY ");
        result.add(
            "xinput: $word $bLeftTrigger $bRightTrigger $sThumbLX $sThumbLY $sThumbRX $sThumbRY ");
      }
    }
    return result;
  }

  static void registerWith(Registrar registrar) {
    //no need for this.
    //GamepadsPlatformInterface.instance = GamepadsWeb();
  }

  Future<void> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onGamepadEvent':
        emitGamepadEvent(GamepadEvent.parse(call.args));
        break;
    }
  }

  void emitGamepadEvent(GamepadEvent event) {
    _gamepadEventsStreamController.add(event);
  }

  final StreamController<GamepadEvent> _gamepadEventsStreamController =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get gamepadEventsStream =>
      _gamepadEventsStreamController.stream;

  @mustCallSuper
  Future<void> dispose() async {
    _gamepadEventsStreamController.close();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = html.window.navigator.userAgent;
    return version;
  }
}
