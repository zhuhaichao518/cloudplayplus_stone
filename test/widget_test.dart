// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:typed_data';

import 'package:cloudplayplus/entities/messages.dart';

void requestMoveMouseRelative(double dx, double dy, int screenId) async {
  // 创建一个ByteData足够存储 LP_MOUSE, screenId, dx, dy
  ByteData byteData = ByteData(10);
  byteData.setUint8(0, LP_MOUSE_ABSL);
  byteData.setUint8(1, screenId);

  // 将dx, dy转换为浮点数并存储
  byteData.setFloat32(2, dx, Endian.little);
  byteData.setFloat32(6, dy, Endian.little);

  // 转换ByteData为Uint8List
  Uint8List buffer = byteData.buffer.asUint8List();
  handleMoveMouseRelative(buffer);
}

void handleMoveMouseRelative(Uint8List buffer) {
  ByteData byteData = buffer.buffer.asByteData();

  int screenId = byteData.getUint8(1);
  double dx = byteData.getFloat32(2, Endian.little);
  double dy = byteData.getFloat32(6, Endian.little);

  // 调用模拟器或实际硬件接口执行操作
  print(dx);
  print(dy);
}

void main() {
  requestMoveMouseRelative(-123.33, 44.33, 1);
}
