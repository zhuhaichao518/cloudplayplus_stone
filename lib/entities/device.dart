import 'package:cloudplayplus/entities/session.dart';
import 'package:flutter/foundation.dart';

class Device {
  //都用基本类型 传输简便
  final int uid;
  final String nickname;
  String devicename;
  //TODO: use an enum value instead of string.
  final String devicetype;
  final String websocketSessionid;
  //allow this device to be connected
  bool connective;
  int screencount;

  ValueNotifier<StreamingSessionConnectionState> connectionState =
      ValueNotifier(StreamingSessionConnectionState.free);

  Device(
      {required this.uid,
      required this.nickname,
      required this.devicename,
      required this.devicetype,
      required this.websocketSessionid,
      required this.connective,
      required this.screencount});

  static Device fromJson(Map<String, dynamic> deviceinfo) {
    return Device(
      uid: deviceinfo['owner_id'] as int,
      nickname: deviceinfo['owner_nickname'] as String,
      devicename: deviceinfo['device_name'] as String,
      devicetype: deviceinfo['device_type'] as String,
      websocketSessionid: deviceinfo['connection_id'] as String,
      connective: deviceinfo['connective'] as bool,
      screencount: deviceinfo['screen_count'] as int,
    );
  }
}

final defaultDeviceList = [
  Device(
    uid: 0,
    nickname: '获取中...',
    devicename: '初始化...',
    devicetype: '初始化...',
    websocketSessionid: '',
    connective: false,
    screencount: 0,
  )
];
