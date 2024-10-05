import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../entities/messages.dart';

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
}
