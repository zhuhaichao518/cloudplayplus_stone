import 'dart:async';
import 'dart:typed_data';

import 'package:cloudplayplus/utils/widgets/cursor_change_widget.dart';
import 'package:custom_mouse_cursor/custom_mouse_cursor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'dart:ui' as ui show Image,
        decodeImageFromPixels,
        PixelFormat;
import '../entities/messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef CursorUpdatedCallback = void Function(MouseCursor newcursor);

class InputController {
  static void requestMoveMouseAbsl(
      RTCDataChannel? channel, double x, double y, int screenId) async {
    if (channel == null) return;
    // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
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
  }

  static void handleMoveMouseAbsl(RTCDataChannelMessage message) {
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    int screenId = byteData.getUint8(1);
    double x = byteData.getFloat32(2, Endian.little);
    double y = byteData.getFloat32(6, Endian.little);

    HardwareSimulator.mouse.performMouseMoveAbsl(x, y, screenId);
  }

  static void requestMoveMouseRelative(
      RTCDataChannel? channel, double x, double y, int screenId) async {
    if (channel == null) return;
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
  }

  static void handleMoveMouseRelative(RTCDataChannelMessage message) {
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);
    int screenId = byteData.getUint8(1);
    double dx = byteData.getFloat32(2, Endian.little);
    double dy = byteData.getFloat32(6, Endian.little);

    HardwareSimulator.mouse.performMouseMoveRelative(dx, dy, screenId);
  }

  static void requestMouseClick(
      RTCDataChannel? channel, int buttonId, bool isDown) async {
    if (channel == null) return;

    // 创建一个 ByteData 足够存储 LP_MOUSEBUTTON, buttonId, isDown
    ByteData byteData = ByteData(3);
    byteData.setUint8(0, LP_MOUSEBUTTON); // 操作符，用于指示鼠标按键操作
    byteData.setUint8(1, buttonId); // 鼠标按键 ID，例如 0 表示左键，1 表示右键
    byteData.setUint8(2, isDown ? 1 : 0); // isDown，1 表示按下，0 表示松开

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  static void handleMouseClick(RTCDataChannelMessage message) {
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);

    // 获取 buttonId 和 isDown 信息
    int buttonId = byteData.getUint8(1); // 第2个字节存储了 buttonId
    bool isDown = byteData.getUint8(2) == 1; // 第3个字节存储了 isDown (1 表示按下, 0 表示松开)
    
    print("--handle mouse click:{$buttonId} {$isDown}");
    // 调用模拟点击的方法
    HardwareSimulator.mouse.performMouseClick(buttonId, isDown);
  }

  static void requestKeyEvent(
      RTCDataChannel? channel, int keyCode, bool isDown) async {
    if (channel == null) return;

    // 创建一个 ByteData 足够存储 LP_MOUSEBUTTON, buttonId, isDown
    ByteData byteData = ByteData(3);
    byteData.setUint8(0, LP_KEYPRESSED); // 操作符，用于指示鼠标按键操作
    byteData.setUint8(1, keyCode); // 鼠标按键 ID，例如 0 表示左键，1 表示右键
    byteData.setUint8(2, isDown ? 1 : 0); // isDown，1 表示按下，0 表示松开

    // 转换 ByteData 为 Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  static void handleKeyEvent(RTCDataChannelMessage message) {
    Uint8List buffer = message.binary;
    ByteData byteData = ByteData.sublistView(buffer);

    // 获取 buttonId 和 isDown 信息
    int keyCode = byteData.getUint8(1); // 第2个字节存储了 buttonId
    bool isDown = byteData.getUint8(2) == 1; // 第3个字节存储了 isDown (1 表示按下, 0 表示松开)

    // 调用模拟点击的方法
    HardwareSimulator.keyboard.performKeyEvent(keyCode, isDown);
  }

  static Map<int,MouseCursor> cachedCursors = {};
  
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
  static void setCursorContext(BuildContext context){
    _cursorContext = context;
  }

  static void removeCursorContext(BuildContext context){
    //check if the cursorcontext to remove is the current active one.
    if (_cursorContext == context){
      _cursorContext = null;
    }
  }

  static void handleCursorUpdate(RTCDataChannelMessage msg) async {
    Uint8List buffer = msg.binary;
    if (buffer[0] == LP_MOUSECURSOR_CHANGED_WITHBUFFER){
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
        MouseCursor newcursor = await registerIncomingCursor(width, height, buffer.sublist(21), hotx, hoty, hash);
        cachedCursors[hash] = newcursor;
        _cursorContext?.read<MouseStyleBloc>().setCursor(newcursor);
      }
    } else {
      ByteData byteData = ByteData.sublistView(buffer);
      int message = byteData.getInt32(1);
      int msgInfo = byteData.getInt32(5);
      if (message == HardwareSimulator.CURSOR_UPDATED_CACHED){
        if (cachedCursors.containsKey(msgInfo)) {
          _cursorContext?.read<MouseStyleBloc>().setCursor(cachedCursors[msgInfo]!);
        }
      } else if (message == HardwareSimulator.CURSOR_UPDATED_DEFAULT){
          MouseCursor remotecursor;
          switch (msgInfo) {
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
              remotecursor = SystemMouseCursors.resizeUpLeftDownRight;
              break;
            case 32643: // IDC_SIZENESW
              remotecursor = SystemMouseCursors.resizeUpRightDownLeft;
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
      }
    }
  }
}
