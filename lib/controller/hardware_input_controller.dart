import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../entities/messages.dart';

class InputController {
  static RTCDataChannel? target_channel;

  /*static void requestMoveMouseAbsl(Float percentx, Float percenty, int screenId) async {
    // 创建一个 Uint8List，足够存储 LP_MOUSE, dx 高位, dx 低位, dy 高位, dy 低位
    Uint8List buffer = Uint8List(10);
    buffer[0] = LP_MOUSE_RELATIVE;


    target_channel?.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  static void handleMoveMouseAbsl(RTCDataChannelMessage message){
    Uint8List buffer = message.binary;
    HardwareSimulator.mouse.performMouseMoveAbsl(percentx, percenty, screenId)
  }*/

  static void requestMoveMouseRelative(
      double dx, double dy, int screenId) async {
    // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
    ByteData byteData = ByteData(10);
    byteData.setUint8(0, LP_MOUSE_ABSL);
    byteData.setUint8(1, screenId);

    // 将dx, dy转换为浮点数并存储
    byteData.setFloat32(2, dx, Endian.little);
    byteData.setFloat32(6, dy, Endian.little);

    // 转换ByteData为Uint8List
    Uint8List buffer = byteData.buffer.asUint8List();

    // 发送消息
    target_channel?.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  static void handleMoveMouseRelative(RTCDataChannelMessage message) {
    Uint8List buffer = message.binary;
    ByteData byteData = buffer.buffer.asByteData();

    int screenId = byteData.getUint8(1);
    double dx = byteData.getFloat32(2, Endian.little);
    double dy = byteData.getFloat32(6, Endian.little);

    // 调用模拟器或实际硬件接口执行操作
    HardwareSimulator.mouse.performMouseMoveRelative(dx, dy, screenId);
  }
}
