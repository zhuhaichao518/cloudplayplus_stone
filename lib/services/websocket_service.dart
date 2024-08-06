import 'dart:convert';

import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:flutter/foundation.dart';

import '../dev_settings.dart/develop_settings.dart';
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
  
  static const JsonEncoder _encoder = const JsonEncoder();
  static const JsonDecoder _decoder = JsonDecoder();

  static WebSocketConnectionState connectionState = WebSocketConnectionState.none;
  static void init() async{
    if (DevelopSettings.useLocalServer) {
      _baseUrl = 'ws://127.0.0.1:8000/ws/';
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
      connectionState = WebSocketConnectionState.connected;
      send('newconnection', {
        'devicename': ApplicationInfo.deviceName,
        'devicetype': ApplicationInfo.deviceTypeName,
        /*'appid': ApplicationInfo.appId,*/
        'connective': ApplicationInfo.connectable
      });
    };
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

  void onDisConnected(){
    connectionState = WebSocketConnectionState.disconnected;
  }

  
}
