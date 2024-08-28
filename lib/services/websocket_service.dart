import 'dart:convert';

import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:flutter/foundation.dart';

import '../dev_settings.dart/develop_settings.dart';
import '../entities/device.dart';
import '../entities/user.dart';
import '../utils/websocket.dart'
    if (dart.library.js) '../utils/websocket_web.dart';
import 'app_info_service.dart';
import 'secure_storage_manager.dart';

enum WebSocketConnectionState {
  none,
  connecting, // 请求连接中
  connected, // 已连接
  disconnected, // 断开
}

// This class manages the connection state of the client to the CloudPlayPlus server.
class WebSocketService {
  static SimpleWebSocket? _socket;
  static String _baseUrl = 'wss://www.cloudplayplus.com/ws/';

  static const JsonEncoder _encoder = JsonEncoder();
  static const JsonDecoder _decoder = JsonDecoder();

  static WebSocketConnectionState connectionState =
      WebSocketConnectionState.none;

  static Function(dynamic list)? onDeviceListchanged;

  static void init() async {
    if (DevelopSettings.useLocalServer) {
      if (AppPlatform.isAndroid) {
        //_baseUrl = "ws://10.0.2.2:8000/ws/";
        _baseUrl = "ws://127.0.0.1:8000/ws/";
      } else {
        _baseUrl = "ws://127.0.0.1:8000/ws/";
      }
    }
    String? accessToken;
    if (DevelopSettings.useSecureStorage) {
      accessToken = await SecureStorageManager.getString("access_token");
    } else {
      accessToken = SharedPreferencesManager.getString("access_token");
    }
    if (accessToken == null) {
      //TODO(haichao): show error dialog.
    }
    var url = '$_baseUrl?token=$accessToken';
    _socket = SimpleWebSocket(url);
    connectionState = WebSocketConnectionState.connecting;
    _socket?.onOpen = () {
      onConnected();
    };

    _socket?.onMessage = (message) async {
      await onMessage(_decoder.convert(message));
    };
    await _socket?.connect();
  }

  static Future<void> onMessage(message) async {
    if (kDebugMode) {
      print("--got message from server------------------------");
      print(message);
    }
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];
    switch (mapData['type']) {
      //当ws连上时 服务器会发给你你的id 并要求你更新信息。你也可以主动更新信息
      case 'connection_info':
        {
          //This is first response from server. update device info.
          AppStateService.websocketSessionid = data['connection_id'];
          ApplicationInfo.user =
              User(uid: data['uid'], nickname: data['nickname']);
          send('updateDeviceInfo', {
            'deviceName': ApplicationInfo.deviceName,
            'deviceType': ApplicationInfo.deviceTypeName,
            'connective': ApplicationInfo.connectable
          });
          ApplicationInfo.thisDevice = (Device(
              uid: ApplicationInfo.user.uid,
              nickname: ApplicationInfo.user.nickname,
              devicename: ApplicationInfo.deviceName,
              devicetype: ApplicationInfo.deviceTypeName,
              websocketSessionid: AppStateService.websocketSessionid!,
              connective: ApplicationInfo.connectable));
        }
      case 'connected_devices':
        {
          onDeviceListchanged?.call(data);
        }
      case 'remoteSessionRequested':
        {
          StreamedManager.startStreaming(
              Device.fromJson(data['requester_info']),
              StreamedSettings.fromJson(data['settings']));
        }
      default:
        {
          if (kDebugMode) {
            print("warning:get unknown message from server");
          }
          break;
        }
    }
  }

  static void onConnected() {
    connectionState = WebSocketConnectionState.connected;
    //connected and waiting for our connection uuid.
    /*send('newconnection', {
      'devicename': ApplicationInfo.deviceName,
      'devicetype': ApplicationInfo.deviceTypeName,
      /*'appid': ApplicationInfo.appId,*/
      'connective': ApplicationInfo.connectable
    });*/
  }

  static void send(event, data) {
    if (kDebugMode) {
      print("sending----------");
      print(data);
    }
    var request = {};
    request["type"] = event;
    request["data"] = data;
    _socket?.send(_encoder.convert(request));
  }

  void onDisConnected() {
    connectionState = WebSocketConnectionState.disconnected;
  }
}
