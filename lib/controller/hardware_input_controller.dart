import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudplayplus/base/logging.dart';
import 'package:cloudplayplus/controller/gamepad_controller.dart';
import 'package:cloudplayplus/controller/platform_key_map.dart';
import 'package:cloudplayplus/controller/smooth_mouse_controller.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:cloudplayplus/utils/widgets/cursor_change_widget.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_remote_mouse.dart';
import 'package:custom_mouse_cursor/custom_mouse_cursor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:hardware_simulator/hardware_simulator_platform_interface.dart';
import 'dart:ui' as ui show Image, decodeImageFromPixels, PixelFormat;
import '../entities/messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';

typedef CursorUpdatedCallback = void Function(MouseCursor newcursor);

enum TVControllerMode {
  mouse,
  keyboard,
  gamepad,
}
class InputController {
  static StreamSubscription<GamepadEvent>? _subscription;
  static late final OnScreenRemoteMouseController mouseController;
  static SmoothMouseController? _smoothMouseController;

  final Map<String, bool> buttonInputs = {};
  static void init() async {
    if (AppPlatform.isMobile) {
      mouseController = OnScreenRemoteMouseController();
      _smoothMouseController = SmoothMouseController(mouseController);
      HardwareSimulator.addCursorMoved(cursorMovedCallbackMobile);
      HardwareSimulator.addCursorPressed(cursorPressedCallbackMobile);
      HardwareSimulator.addCursorWheel(cursorWheelCallbackMobile);
      if (AppPlatform.isAndroid) {
        HardwareSimulator.addKeyboardPressed(keyboardPressedCallbackAndroid);
      }
    }
    // We don't use Gamepads for windows.
    if (AppPlatform.isWindows) return;
    var gamepads = await Gamepads.list();
    if (gamepads.isNotEmpty && gamepads[0].name == "uinput-goodix") {
      // For xiaomi, there is always a virtual uinput-goodix reported.
      CGamepadController.ignore_first = true;
    }
    CGamepadController.gamepads = gamepads;
    _subscription = Gamepads.events.listen((event) {
      CGamepadController.onEvent(event);
    });
  }

  static void dispose() {
    _smoothMouseController?.dispose();
    _subscription?.cancel();
  }

  double lastx = 1;
  double lasty = 1;
  RTCDataChannel channel;
  bool reliable;
  int screenId = 0;

  InputController(this.channel, this.reliable, this.screenId);

  int outSequenceID = 0;

  // latest handled sequence id.
  int lastHandledSequenceID = 0;

  // reliable = true的时候 处理类似tcp over udp。主要问题是datachannel在丢包时 要等很久才会触发要求重发
  // 方案1 每个控制消息发送后 发送三个空包。如果丢包就会立即触发重发请求
  static bool sendEmptyPacket = true;
  static int resendCount = 3;
  // 方案2 每个控制消息发送（3）次 不管丢包的消息 发送三次（同一个seq id） 基本上能保证顺序？
  // Map<int, RTCDataChannelMessage> messagesToHandle = {};
  // 方案3.接到一个消息的时候 outSequenceID.
  // 如果刚好 = lastHandledSequenceID + 1, 完美, handle这个消息，并且继续处理待处理列表中的消息
  // 如果 <= lastHandledSequenceID, 丢掉这个消息
  // 否则加入待处理列表（如果ID重复则直接丢弃）,等待lastHandledSequenceID + 1的消息进来，最多等（20ms）。
  // 假如时间到了lastHandledSequenceID + 1还没来, 直接处理完待处理列表。

  static RTCDataChannelMessage emptyMessage =
      RTCDataChannelMessage.fromBinary(Uint8List.fromList([LP_EMPTY]));

  static bool blockCursorMove = false;
  // 远程鼠标位置被同步到本地时，由于鼠标被移动到指定位置会生成一个移动事件，阻止该事件。
  static int blockNextAbsl = 0;
  static int lastAbslMoveTime = 0;


  void requestMoveMouseAbsl(double x, double y, int tempScreenId) async {
    if (blockCursorMove) {
      return;
    }
    if (blockNextAbsl > 0) {
      blockNextAbsl--;
      return;
    }

    lastAbslMoveTime = DateTime.now().millisecondsSinceEpoch;

    // Cursor moved out of scope when tempScreenId = -1
    // print("${x} ${y}");
    if (tempScreenId == -1) {
      x = lastx;
      y = lasty;
      bool shouldSend = false;
      if (lasty < 0.15) {
        shouldSend = true;
        y = 0;
      }
      if (lasty > 0.85) {
        shouldSend = true;
        y = 1;
      }
      if (lastx < 0.15) {
        shouldSend = true;
        x = 0;
      }
      if (lastx > 0.85) {
        shouldSend = true;
        x = 1;
      }
      if (!shouldSend) {
        return;
      }
    } else {
      lastx = x;
      lasty = y;
    }
    // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
    if (reliable) {
      ByteData byteData = ByteData(10);
      byteData.setUint8(0, LP_MOUSEMOVE_ABSL);
      byteData.setUint8(1, screenId);

      // 将dx, dy转换为浮点数并存储
      byteData.setFloat32(2, x, Endian.little);
      byteData.setFloat32(6, y, Endian.little);

      // 转换ByteData为Uint8List
      Uint8List buffer = byteData.buffer.asUint8List();

      // 发送消息
      channel.send(RTCDataChannelMessage.fromBinary(buffer));

      if (sendEmptyPacket) {
        for (int i = 0; i < resendCount / 2; i++) {
          channel.send(emptyMessage);
        }
      }
    } else {
      ByteData byteData = ByteData(14);
      byteData.setUint8(0, LP_MOUSEMOVE_ABSL);
      byteData.setInt32(1, outSequenceID);
      byteData.setUint8(5, screenId);

      // 将dx, dy转换为浮点数并存储
      byteData.setFloat32(6, x, Endian.little);
      byteData.setFloat32(10, y, Endian.little);

      // 转换ByteData为Uint8List
      Uint8List buffer = byteData.buffer.asUint8List();

      channel.send(RTCDataChannelMessage.fromBinary(buffer));

      if (sendEmptyPacket) {
        for (int i = 0; i < resendCount / 2; i++) {
          channel.send(emptyMessage);
        }
      }
    }
  }

  void handleMoveMouseAbsl(RTCDataChannelMessage message) {
    if (!AppPlatform.isDeskTop) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);

    int screenId = byteData.getUint8(1);
    double x = byteData.getFloat32(2, Endian.little);
    double y = byteData.getFloat32(6, Endian.little);
    HardwareSimulator.mouse.performMouseMoveAbsl(x, y, screenId);
  }

  // maybe we don't need screenId?
  void requestMoveMouseRelative(double x, double y, int screenId) async {
    if (blockCursorMove) {
      return;
    }
    // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
    ByteData byteData = ByteData(10);
    byteData.setUint8(0, LP_MOUSEMOVE_RELATIVE);
    byteData.setUint8(1, screenId);

    // 将dx, dy转换为浮点数并存储
    byteData.setFloat32(2, x, Endian.little);
    byteData.setFloat32(6, y, Endian.little);

    // 转换ByteData为Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  
    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount / 2; i++) {
        WebrtcService.currentRenderingSession?.inputController?.channel
            .send(emptyMessage);
      }
    }
  }

  void handleMoveMouseRelative(RTCDataChannelMessage message) {
    if (!AppPlatform.isDeskTop) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    int screenId = byteData.getUint8(1);
    double dx = byteData.getFloat32(2, Endian.little);
    double dy = byteData.getFloat32(6, Endian.little);

    HardwareSimulator.mouse.performMouseMoveRelative(dx, dy, screenId);
  }

  void requestMouseClick(int buttonId, bool isDown) async {
    // 创建一个 ByteData 足够存储 LP_MOUSEBUTTON, buttonId, isDown
    ByteData byteData = ByteData(3);
    byteData.setUint8(0, LP_MOUSEBUTTON); // 操作符，用于指示鼠标按键操作
    byteData.setUint8(1, buttonId); // 鼠标按键 ID，例如 1 表示左键，3 表示右键
    byteData.setUint8(2, isDown ? 1 : 0); // isDown，1 表示按下，0 表示松开

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));

    // 保证鼠标按下能立即发送到
    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount; i++) {
        channel.send(emptyMessage);
      }
    }
  }

  void handleMouseClick(RTCDataChannelMessage message) {
    if (!AppPlatform.isDeskTop) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);

    // 获取 buttonId 和 isDown 信息
    int buttonId = byteData.getUint8(1); // 第2个字节存储了 buttonId
    bool isDown = byteData.getUint8(2) == 1; // 第3个字节存储了 isDown (1 表示按下, 0 表示松开)

    // 调用模拟点击的方法
    HardwareSimulator.mouse.performMouseClick(buttonId, isDown);
  }

  void requestMouseScroll(double? dx, double? dy) async {
    dx ??= 0;
    dy ??= 0;
    if (StreamingSettings.revertCursorWheel) {
      dy = -dy;
    }
    // 创建一个 ByteData 足够存储 LP_MOUSEBUTTON, buttonId, isDown
    ByteData byteData = ByteData(9);
    byteData.setUint8(0, LP_MOUSE_SCROLL);
    // 将dx, dy转换为浮点数并存储
    byteData.setFloat32(1, dx, Endian.little);
    byteData.setFloat32(5, dy, Endian.little);

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  void handleMouseScroll(RTCDataChannelMessage message) {
    if (!AppPlatform.isDeskTop) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    double dx = byteData.getFloat32(1, Endian.little);
    double dy = byteData.getFloat32(5, Endian.little);

    HardwareSimulator.mouse.performMouseScroll(dx, dy);
  }

  void requestTouchButton(double x, double y, int touchId, bool isDown) async {
    // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
    //print("touch button ${touchId} ${x},${y},${isDown}");
    ByteData byteData = ByteData(15);
    byteData.setUint8(0, LP_TOUCH_BUTTON);
    //set screen id to 0
    byteData.setUint8(1, 0);

    // 将dx, dy转换为浮点数并存储
    byteData.setFloat32(2, x, Endian.little);
    byteData.setFloat32(6, y, Endian.little);

    byteData.setInt32(10, touchId, Endian.little);
    byteData.setUint8(14, isDown ? 1 : 0);

    // 转换ByteData为Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));

    // 保证触摸按下能立即发送到
    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount; i++) {
        channel.send(emptyMessage);
      }
    }
  }

  void handleTouchButton(RTCDataChannelMessage message) {
    if (!AppPlatform.isWindows) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    double x = byteData.getFloat32(2, Endian.little);
    double y = byteData.getFloat32(6, Endian.little);
    int id = byteData.getInt32(10, Endian.little);
    bool isDown = byteData.getUint8(14) == 1;

    HardwareSimulator.performTouchEvent(x, y, id, isDown, screenId);
  }

  void requestTouchMove(double x, double y, int touchId) async {
    //print("touch move ${touchId} ${x},${y}");
    ByteData byteData = ByteData(13);
    byteData.setUint8(0, LP_TOUCH_MOVE_ABSL);
    byteData.setFloat32(1, x, Endian.little);
    byteData.setFloat32(5, y, Endian.little);
    byteData.setInt32(9, touchId, Endian.little);

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));

    // 保证鼠标按下能立即发送到
    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount / 2; i++) {
        channel.send(emptyMessage);
      }
    }
  }

  void handleTouchMove(RTCDataChannelMessage message) {
    if (!AppPlatform.isWindows) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    double x = byteData.getFloat32(1, Endian.little);
    double y = byteData.getFloat32(5, Endian.little);
    int id = byteData.getInt32(9, Endian.little);

    HardwareSimulator.performTouchMove(x, y, id, screenId);
  }

  void requestKeyEvent(int? keyCode, bool isDown) async {
    if (keyCode == null) return;
    // VLOG0("sending key event code {$keyCode} isDown {$isDown}");
    // 创建一个 ByteData 足够存储 LP_MOUSEBUTTON, buttonId, isDown
    ByteData byteData = ByteData(3);
    byteData.setUint8(0, LP_KEYPRESSED); // 操作符，用于指示鼠标按键操作
    byteData.setUint8(1, keyCode); // 鼠标按键 ID，例如 0 表示左键，1 表示右键
    byteData.setUint8(2, isDown ? 1 : 0); // isDown，1 表示按下，0 表示松开

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));

    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount; i++) {
        channel.send(emptyMessage);
      }
    }
  }

  void handleKeyEvent(RTCDataChannelMessage message) {
    if (!AppPlatform.isDeskTop) return;
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);

    // 获取 buttonId 和 isDown 信息
    int keyCode = byteData.getUint8(1); // 第2个字节存储了 buttonId
    bool isDown = byteData.getUint8(2) == 1; // 第3个字节存储了 isDown (1 表示按下, 0 表示松开)

    // 调用模拟点击的方法
    HardwareSimulator.keyboard.performKeyEvent(keyCode, isDown);
  }

  void requestGamePadEvent(String id, String event) {
    Map<String, dynamic> mapData = {
      'gamepad': {
        'id': id,
        'event': event,
      },
    };
    channel.send(RTCDataChannelMessage(jsonEncode(mapData)));

    if (sendEmptyPacket) {
      for (int i = 0; i < resendCount; i++) {
        channel.send(emptyMessage);
      }
    }
  }

  static int controllerCount = 0;
  static List<GameController> controllers = [];
  //"gamepad: id message"
  void handleGamePadEvent(dynamic message) async {
    int id = int.parse(message['id']);
    VLOG0("simulating game controller: $id ${message['event']}");
    if (!AppPlatform.isWindows) return;
    if (controllerCount <= id) {
      //提前增加 防止同时来多个消息导致多生成控制器
      controllerCount++;
      var controller = await HardwareSimulator.createGameController();
      if (controller != null) {
        controllers.add(controller);
      }
    }
    if (controllers.length > id) {
      controllers[id].simulate(message['event']);
    }
  }

  static Map<int, MouseCursor> cachedCursors = {};

  static Future<ui.Image> rawBGRAtoImage(
      Uint8List bytes, int width, int height) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      bytes,
      width,
      height,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        return completer.complete(img);
      },
    );
    return completer.future;
  }

  static Future<MouseCursor> registerIncomingCursor(int width, int height,
      Uint8List data, int hotx, int hoty, int hash) async {
    final ui.Image cursorimage = await rawBGRAtoImage(data, width, height);
    MouseCursor imageCursor = await CustomMouseCursor.image(cursorimage,
        hotX: hotx,
        hotY: hoty,
        thisImagesDevicePixelRatio: 1.0,
        finalizeForCurrentDPR: false);
    return imageCursor;
  }

  /* we use bloc istead of callback.
  static CursorUpdatedCallback? _cursorUpdatedCallback;

  static void updateCursorUpdatedCallback(CursorUpdatedCallback callback){
    _cursorUpdatedCallback = callback;
  }*/

  static BuildContext? _cursorContext;
  static void setCursorContext(BuildContext context) {
    _cursorContext = context;
  }

  static void removeCursorContext(BuildContext context) {
    //check if the cursorcontext to remove is the current active one.
    if (_cursorContext == context) {
      _cursorContext = null;
    }
  }

  // these callbacks should only for the current rendering session.
  static CursorMovedCallback cursorMovedCallback = (deltax, deltay) {
    if (isCursorLocked) {
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMoveMouseRelative(deltax, deltay, 0);
    }
  };

  static CursorPressedCallback cursorPressedCallback = (button, isDown) {
    if (isCursorLocked) {
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(button, isDown);
    }
  };

  static CursorWheelCallback cursorWheelCallback = (deltax, deltay) {
    if (isCursorLocked) {
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseScroll(deltax, deltay);
    }
  };

  // Mobile callbacks
  static CursorMovedCallback cursorMovedCallbackMobile = (deltax, deltay) {
    if (isCursorLocked) {
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMoveMouseRelative(deltax, deltay, 0);
    } else {
      mouseController.moveDelta(deltax, deltay);
    }
  };

  static CursorPressedCallback cursorPressedCallbackMobile = (button, isDown) {
    WebrtcService.currentRenderingSession?.inputController
        ?.requestMouseClick(button, isDown);
  };

  static CursorWheelCallback cursorWheelCallbackMobile = (deltax, deltay) {
    // 蓝牙鼠标的上报很怪 滚一下只有0.01几 两下只有1.几 3下5.几 多滚才有几十
    if (deltax == 0 && deltay == 0) return;
    if (deltax < 0 && deltax > -20) deltax = -20;
    if (deltax > 0 && deltax < 20) deltax = 20;
    if (deltay < 0 && deltay > -20) deltay = -20;
    if (deltay > 0 && deltay < 20) deltay = 20;
    WebrtcService.currentRenderingSession?.inputController
        ?.requestMouseScroll(deltax, deltay);
  };

  static TVControllerMode controllerMode = TVControllerMode.mouse;
  //Android TV Dpad controll mouse speed
  static double speedx = 0, speedy = 0;
  
  // OK键连续点击跟踪
  static int _okButtonClickCount = 0;
  static DateTime? _lastOkButtonClick;
  static const Duration _okButtonTimeout = Duration(milliseconds: 1000); // 1秒内需要完成3次点击
  
  // 测试用的getter和setter
  static int get okButtonClickCount => _okButtonClickCount;
  static DateTime? get lastOkButtonClick => _lastOkButtonClick;
  static Duration get okButtonTimeout => _okButtonTimeout;
  static void resetOkButtonState() {
    _okButtonClickCount = 0;
    _lastOkButtonClick = null;
  }
  static void setOkButtonClickCount(int count) {
    _okButtonClickCount = count;
  }
  static void setLastOkButtonClick(DateTime? time) {
    _lastOkButtonClick = time;
  }

  static KeyboardPressedCallback keyboardPressedCallbackAndroid = (keycode, isDown) {
    if (AppPlatform.isAndroidTV) {
      if (keycode == 4) {
        // Android TV go back. quit the streaming context.
        if (_cursorContext != null) {
          Navigator.pop(_cursorContext!);
          _cursorContext = null;
        }
        return;
      }
      if (keycode == 1082) {
        // Android TV Dpad Menu button.
        if (controllerMode == TVControllerMode.mouse) {
          // right button
          WebrtcService.currentRenderingSession?.inputController?.requestMouseClick(3, isDown);
        } else if (controllerMode == TVControllerMode.keyboard && isDown){
          // Show all apps
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.metaLeft],
                  true);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.tab],
                  true);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.tab],
                  false);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.metaLeft],
                  false);
        }
        return;
      }
      // This current work on Android TV but we can keep this logic.
      if (keycode == 1024) {
        // Android TV Volume UP button.
        //if (controllerMode == TVControllerMode.mouse) {
          // right button
        //  WebrtcService.currentRenderingSession?.inputController?.requestMouseClick(2, isDown);
        //} else if (controllerMode == TVControllerMode.keyboard){
          // 打开屏幕软键盘
          // TODO: 改为cloudplayplus自带软键盘
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.metaLeft],
                  true);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.controlLeft],
                  true);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.keyO],
                  true);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.keyO],
                  false);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.controlLeft],
                  false);
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.metaLeft],
                  false);
        //}
        return;
      }
      if (keycode == 1025) {
        // Android TV Volume Down button.
        if (controllerMode == TVControllerMode.mouse) {
          // right button
          controllerMode = TVControllerMode.keyboard;
          if (_cursorContext != null) {
            ScaffoldMessenger.of(_cursorContext!).showSnackBar(
              const SnackBar(
                content: Text('遥控器已切换到键盘模式'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else {
          controllerMode = TVControllerMode.mouse;
          if (_cursorContext != null) {
            ScaffoldMessenger.of(_cursorContext!).showSnackBar(
              const SnackBar(
                content: Text('遥控器已切换到鼠标模式'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        return;
      }
      if (keycode == 1019) {
        // Android TV Dpad Up button.
        if (controllerMode == TVControllerMode.mouse) {
          if (isDown) {
            _smoothMouseController?.onDirectionKeyDown(keycode);
          } else {
            _smoothMouseController?.onDirectionKeyUp(keycode);
          }
        } else {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.arrowUp],
                  isDown);
        }
        return;
      }
      if (keycode == 1020) {
        // Android TV Dpad Down button.
        if (controllerMode == TVControllerMode.mouse) {
          if (isDown) {
            _smoothMouseController?.onDirectionKeyDown(keycode);
          } else {
            _smoothMouseController?.onDirectionKeyUp(keycode);
          }
        } else {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.arrowDown],
                  isDown);
        }
        return;
      }
      if (keycode == 1021) {
        // Android TV Dpad Left button.
        if (controllerMode == TVControllerMode.mouse) {
          if (isDown) {
            _smoothMouseController?.onDirectionKeyDown(keycode);
          } else {
            _smoothMouseController?.onDirectionKeyUp(keycode);
          }
        } else {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.arrowLeft],
                  isDown);
        }
        return;
      }
      if (keycode == 1022) {
        // Android TV Dpad Right button.
        if (controllerMode == TVControllerMode.mouse) {
          if (isDown) {
            _smoothMouseController?.onDirectionKeyDown(keycode);
          } else {
            _smoothMouseController?.onDirectionKeyUp(keycode);
          }
        } else {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.arrowRight],
                  isDown);
        }
        return;
      }
      if (keycode == 1023) {
        // Android TV Dpad OK button.
        if (isDown) {
          // 处理连续点击逻辑
          final now = DateTime.now();
          
          // 如果距离上次点击超过超时时间，重置计数
          if (_lastOkButtonClick == null || 
              now.difference(_lastOkButtonClick!) > _okButtonTimeout) {
            _okButtonClickCount = 0;
          }
          
          _okButtonClickCount++;
          _lastOkButtonClick = now;
          
          // 如果连续点击了3次，切换模式
          if (_okButtonClickCount >= 3) {
            if (controllerMode == TVControllerMode.mouse) {
              controllerMode = TVControllerMode.keyboard;
              if (_cursorContext != null) {
                ScaffoldMessenger.of(_cursorContext!).showSnackBar(
                  const SnackBar(
                    content: Text('方向键已切换到键盘模式'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            } else {
              controllerMode = TVControllerMode.mouse;
              if (_cursorContext != null) {
                ScaffoldMessenger.of(_cursorContext!).showSnackBar(
                  const SnackBar(
                    content: Text('方向键已切换到鼠标模式'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            }
            
            // 重置计数
            _okButtonClickCount = 0;
            _lastOkButtonClick = null;
            return;
          }
        }
        
        // 正常的OK键功能
        if (controllerMode == TVControllerMode.mouse) {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestMouseClick(
                  1,
                  isDown);
        } else {
          WebrtcService.currentRenderingSession?.inputController
              ?.requestKeyEvent(
                  physicalToWindowsKeyMap[
                      PhysicalKeyboardKey.enter],
                  isDown);
        }
        return;
      }
    }
    if (androidToWindowsKeyMap.containsKey(keycode)) {
      WebrtcService.currentRenderingSession?.inputController
        ?.requestKeyEvent(androidToWindowsKeyMap[keycode], isDown);
    }
  };

  static bool isCursorLocked = false;
  static bool isCursorLockedbySyncMouse = false;
  //控制端能控制看不见的屏幕
  static bool canControlOtherMonitors = true;

  static Function(double xPercent, double yPercent)? cursorPositionCallback;
  static int id = 0;
  void handleCursorUpdate(RTCDataChannelMessage msg) async {
    Uint8List buffer = msg.binary;
    if (AppPlatform.isMobile) {
      ByteData byteData = ByteData.sublistView(buffer);
      int message = byteData.getInt32(1);
      if (message == HardwareSimulator.CURSOR_INVISIBLE &&
          StreamingSettings.autoHideLocalCursor) {
          mouseController.setShowCursor(false);
          isCursorLocked = true;
      } else if (message == HardwareSimulator.CURSOR_VISIBLE &&
          StreamingSettings.autoHideLocalCursor){
          if (!isCursorLocked) {
            return;
          }
          isCursorLocked = false;
          // buffer.length > 10 used to be compatible with old version.
          if (buffer.length > 10) {
            blockCursorMove = true;
            int msgscreenId = byteData.getInt32(5);
            if (buffer.length > 10 && screenId == msgscreenId) {
              double xPercent = byteData.getFloat32(9, Endian.little);
              double yPercent = byteData.getFloat32(13, Endian.little);
              mouseController.setAbsolutePosition(xPercent, yPercent);
              mouseController.setShowCursor(true);
            } else {
              mouseController.setShowCursor(false);
            }
            Timer(const Duration(milliseconds: 200), () {
              blockCursorMove = false;
            });
          } else {
            mouseController.setShowCursor(true);
          }
      } else if (message == HardwareSimulator.CURSOR_POSITION_CHANGED) {
          //TODO: 有些时候单点触屏收不到对应消息 不知道为什么
          if (!isCursorLocked && DateTime.now().millisecondsSinceEpoch - lastAbslMoveTime > 1000) {
            int msgscreenId = byteData.getInt32(5);
            double xPercent = byteData.getFloat32(9, Endian.little);
            double yPercent = byteData.getFloat32(13, Endian.little);
            if (screenId == msgscreenId) {
              mouseController.setShowCursor(true);
              mouseController.moveAbsl(xPercent, yPercent);
            } else {
              if ((xPercent < 0.98 && xPercent > 0.02) && (yPercent < 0.98 && yPercent > 0.02)) {
                mouseController.setShowCursor(false);
              }
            }
          }
      } else {
        //cursor image changed.
        mouseController.setCursorBuffer(buffer);
      }
      return;
    }
    if (buffer[0] == LP_MOUSECURSOR_CHANGED_WITHBUFFER) {
      //cursor hash: 0 + size + hash + data
      int width = 0;
      int height = 0;
      int hash = 0;
      int hotx = 0;
      int hoty = 0;
      //We may use the 0 bit for future use to indicate some image type.
      if (buffer[0] == 9) {
        //cursor bitmap
        for (int i = 1; i < 5; i++) {
          width = width * 256 + buffer[i];
        }
        for (int i = 5; i < 9; i++) {
          height = height * 256 + buffer[i];
        }
        for (int i = 9; i < 13; i++) {
          hotx = hotx * 256 + buffer[i];
        }
        for (int i = 13; i < 17; i++) {
          hoty = hoty * 256 + buffer[i];
        }
        for (int i = 17; i < 21; i++) {
          hash = hash * 256 + buffer[i];
        }
        MouseCursor newcursor = await registerIncomingCursor(
            width, height, buffer.sublist(21), hotx, hoty, hash);
        cachedCursors[hash] = newcursor;
        _cursorContext?.read<MouseStyleBloc>().setCursor(newcursor);
      }
    } else {
      ByteData byteData = ByteData.sublistView(buffer);
      int message = byteData.getInt32(1);
      int msgInfo = byteData.getInt32(5);
      if (message == HardwareSimulator.CURSOR_UPDATED_CACHED) {
        if (cachedCursors.containsKey(msgInfo)) {
          _cursorContext
              ?.read<MouseStyleBloc>()
              .setCursor(cachedCursors[msgInfo]!);
        }
      } else if (message == HardwareSimulator.CURSOR_UPDATED_DEFAULT) {
        MouseCursor remotecursor;
        switch (msgInfo) {
          //324开头的是mac有但是window没有的指针样式，和插件对应
          case 32401:
            remotecursor = SystemMouseCursors.grabbing;
            break;
          case 32402:
            remotecursor = SystemMouseCursors.grab;
            break;
          case 32403:
            remotecursor = SystemMouseCursors.resizeUp;
            break;
          case 32404:
            remotecursor = SystemMouseCursors.resizeDown;
            break;
          case 32405:
            remotecursor = SystemMouseCursors.resizeLeft;
            break;
          case 32406:
            remotecursor = SystemMouseCursors.resizeRight;
            break;
          case 32407:
            remotecursor = SystemMouseCursors.disappearing;
            break;
          case 32408:
            remotecursor = SystemMouseCursors.contextMenu;
            break;
          case 32409:
            remotecursor = SystemMouseCursors.alias;
            break;
          case 32410:
            remotecursor = SystemMouseCursors.copy;
            break;
          case 32411:
            remotecursor = SystemMouseCursors.verticalText;
            break;
          case 32512: // IDC_ARROW
            remotecursor = SystemMouseCursors.basic;
            break;
          case 32513: // IDC_IBEAM
            remotecursor = SystemMouseCursors.text;
            break;
          case 32514: // IDC_WAIT
            remotecursor = SystemMouseCursors.wait;
            break;
          case 32515: // IDC_CROSS
            remotecursor = SystemMouseCursors.precise;
            break;
          case 32516: // IDC_UPARROW
            remotecursor = SystemMouseCursors.resizeUpDown;
            break;
          case 32640: // IDC_SIZE (OBSOLETE)
            // Use an appropriate cursor or the default one
            remotecursor = SystemMouseCursors.basic;
            break;
          case 32642: // IDC_SIZENWSE
            if (AppPlatform.isMacos) {
              //macos的对角缩放指针没有写文档 所以flutter未支持。加载本地该资源。
              if (cachedCursors.containsKey(32642)) {
                remotecursor = cachedCursors[32642]!;
              } else {
                cachedCursors[32642] = await CustomMouseCursor.asset(
                    'assets/cursors/resizenorthwestsoutheast.png',
                    hotX: 16,
                    hotY: 16);
                remotecursor = cachedCursors[32642]!;
              }
            } else {
              remotecursor = SystemMouseCursors.resizeUpLeftDownRight;
            }
            break;
          case 32643: // IDC_SIZENESW
            if (AppPlatform.isMacos) {
              if (cachedCursors.containsKey(32643)) {
                remotecursor = cachedCursors[32643]!;
              } else {
                cachedCursors[32643] = await CustomMouseCursor.asset(
                    'assets/cursors/resizenortheastsouthwest.png',
                    hotX: 16,
                    hotY: 16);
                remotecursor = cachedCursors[32643]!;
              }
            } else {
              remotecursor = SystemMouseCursors.resizeUpRightDownLeft;
            }
            break;
          case 32644: // IDC_SIZEWE
            remotecursor = SystemMouseCursors.resizeLeftRight;
            break;
          case 32645: // IDC_SIZENS
            remotecursor = SystemMouseCursors.resizeUpDown;
            break;
          case 32646: // IDC_SIZEALL
            remotecursor = SystemMouseCursors.allScroll;
            break;
          case 32648: // IDC_NO
            remotecursor = SystemMouseCursors.forbidden;
            break;
          case 32649: // IDC_HAND (Windows 5.0+)
            remotecursor = SystemMouseCursors.click;
            break;
          case 32650: // IDC_APPSTARTING
            remotecursor = SystemMouseCursors.progress;
            break;
          case 32651: // IDC_HELP (Windows 4.0+)
            remotecursor = SystemMouseCursors.help;
            break;
          case 32671: // IDC_PIN (Windows 6.6+)
            // Use an appropriate cursor or the default one
            remotecursor = SystemMouseCursors.basic;
            break;
          case 32672: // IDC_PERSON (Windows 6.6+)
            // Use an appropriate cursor or the default one
            remotecursor = SystemMouseCursors.basic;
            break;
          default:
            // Handle unknown cursor
            remotecursor = SystemMouseCursors.basic;
        }
        _cursorContext?.read<MouseStyleBloc>().setCursor(remotecursor);
      } else if (message == HardwareSimulator.CURSOR_INVISIBLE &&
          StreamingSettings.autoHideLocalCursor) {
        //print("cursor invisible");
        //lock cursor will start tracing mouse.
        if (isCursorLocked) {
          return;
        }
        isCursorLocked = true;

        HardwareSimulator.lockCursor();
        HardwareSimulator.addCursorMoved(cursorMovedCallback);
        if (AppPlatform.isWeb) {
          HardwareSimulator.addCursorPressed(cursorPressedCallback);
          HardwareSimulator.addCursorWheel(cursorWheelCallback);
        }
      } else if (message == HardwareSimulator.CURSOR_VISIBLE &&
          StreamingSettings.autoHideLocalCursor) {
        if (!isCursorLocked) {
          return;
        }
        isCursorLocked = false;
        // 如果已经有timer在运行，取消它
        blockCursorMove = true;
        ByteData byteData = ByteData.sublistView(buffer);
        HardwareSimulator.unlockCursor().then((value) {
          // buffer.length > 10 used to be compatible with old version.
          if (buffer.length > 10 && screenId == msgInfo) {
            double xPercent = byteData.getFloat32(9, Endian.little);
            double yPercent = byteData.getFloat32(13, Endian.little);
            if (AppPlatform.isDeskTop) {
              //TODO: implement cursor move for Linux.
              cursorPositionCallback?.call(xPercent, yPercent);
            }
          }
          Timer(const Duration(milliseconds: 200), () {
            blockCursorMove = false;
          });
          HardwareSimulator.removeCursorMoved(cursorMovedCallback);
          if (AppPlatform.isWeb) {
            HardwareSimulator.removeCursorPressed(cursorPressedCallback);
            HardwareSimulator.removeCursorWheel(cursorWheelCallback);
          }
        });
      } else if (message == HardwareSimulator.CURSOR_POSITION_CHANGED) {
          int msgscreenId = byteData.getInt32(5);
          double xPercent = byteData.getFloat32(9, Endian.little);
          double yPercent = byteData.getFloat32(13, Endian.little);
          if (screenId == msgscreenId) {
            if (AppPlatform.isDeskTop && (!isCursorLocked || isCursorLockedbySyncMouse) && DateTime.now().millisecondsSinceEpoch - lastAbslMoveTime > 1000) {
              //TODO: implement cursor move for Linux.
              //This will generate a mousemoveabsl event. so we block the next
              //由于精度问题 可能触发反复同步。block住这个同步。
              //即使这次没有真正触发鼠标移动 也仅仅会多消耗掉下一次用户鼠标移动事件。
              if (isCursorLocked) {
                //鼠标从别的屏幕移入
                HardwareSimulator.unlockCursor();
                HardwareSimulator.removeCursorMoved(cursorMovedCallback);
                isCursorLockedbySyncMouse = false;
                isCursorLocked = false;
              }
              blockNextAbsl++;
              cursorPositionCallback?.call(xPercent, yPercent);
            }
          } else {
            if (canControlOtherMonitors && AppPlatform.isDeskTop && !isCursorLocked && !isCursorLockedbySyncMouse) {
              //鼠标移动到别的屏幕(非边缘),锁住鼠标
              if ((xPercent < 0.98 && xPercent > 0.02) && (yPercent < 0.98 && yPercent > 0.02)) {
                blockNextAbsl++;
                cursorPositionCallback?.call(0.5, 0.5);
                HardwareSimulator.lockCursor();
                HardwareSimulator.addCursorMoved(cursorMovedCallback);
                isCursorLockedbySyncMouse = true;
                isCursorLocked = true;
              }
            }
          }
      }
    }
  }
}
