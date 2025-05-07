import 'dart:async';
import 'dart:convert';

import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/login_service.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/utils/hash_util.dart';
import 'package:cloudplayplus/utils/system_tray_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../base/logging.dart';
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
  static Timer? _reconnectTimer;  // 添加定时器变量

  static const JsonEncoder _encoder = JsonEncoder();
  static const JsonDecoder _decoder = JsonDecoder();

  static WebSocketConnectionState connectionState =
      WebSocketConnectionState.none;

  static Function(dynamic list)? onDeviceListchanged;

  static bool should_be_connected = false;

  static void init() async {
    should_be_connected = true;
    if (connectionState == WebSocketConnectionState.connecting) {
      return;
    }
    if (DevelopSettings.useLocalServer) {
      if (AppPlatform.isAndroid) {
        //_baseUrl = "ws://10.0.2.2:8000/ws/";
        _baseUrl = "ws://127.0.0.1:8000/ws/";
      } else {
        _baseUrl = "ws://127.0.0.1:8000/ws/";
      }
    }
    if (!kIsWeb && DevelopSettings.useUnsafeServer) {
      _baseUrl = 'ws://101.132.58.198:8001/ws/';
    }
    String? accessToken;
    String? refreshToken;
    // ignore: non_constant_identifier_names
    bool refreshToken_invalid_ = false;
    if (DevelopSettings.useSecureStorage) {
      accessToken = await SecureStorageManager.getString('access_token');
      refreshToken = await SecureStorageManager.getString('refresh_token');
    } else {
      accessToken = SharedPreferencesManager.getString('access_token');
      refreshToken = SharedPreferencesManager.getString('refresh_token');
    }
    if (accessToken == null || refreshToken == null) {
      //TODO(haichao): show error dialog.
      VLOG0("error: no access token");
      return;
    }

    if (!LoginService.isTokenValid(accessToken)) {
      final newAccessToken = await LoginService.doRefreshToken(refreshToken);
      if (newAccessToken != null && LoginService.isTokenValid(newAccessToken)) {
        if (DevelopSettings.useSecureStorage) {
          await SecureStorageManager.setString('access_token', newAccessToken);
        } else {
          await SharedPreferencesManager.setString(
              'access_token', newAccessToken);
        }
        refreshToken_invalid_ = false;
        accessToken = newAccessToken;
      } else if (newAccessToken == "invalid refresh token"){
        refreshToken_invalid_ = true;
        return;
      } else {
        return;
      }
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

    _socket?.onClose = (code, message) async {
      onDisConnected();
      if (should_be_connected) {
        // 确保旧的定时器被清理
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (Timer timer) async {
          // 检查是否已经连接成功，如果是，则取消定时器
          if (connectionState == WebSocketConnectionState.connected) {
            timer.cancel();
            _reconnectTimer = null;
            return;
          }
          if (refreshToken_invalid_) {
            timer.cancel();
            _reconnectTimer = null;
            return;
          }
          reconnect();
        });
      }
      VLOG0(code);
      VLOG0(message);
    };
    await _socket?.connect();
  }

  static Future<void> updateDeviceInfo() async {
    send('updateDeviceInfo', {
      'deviceName': ApplicationInfo.deviceName,
      'deviceType': ApplicationInfo.deviceTypeName,
      'connective': ApplicationInfo.connectable,
      'screenCount': ApplicationInfo.screenCount,
    });
  }

  static Future<void> reconnect() async {
    should_be_connected = true;
    _socket?.close();
    _socket = null;
    // 确保旧的定时器被清理
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    init();
  }

  static Future<void> disconnect() async {
    should_be_connected = false;
    _socket?.close();
    _socket = null;
    // 确保定时器被清理
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  static Future<void> onMessage(message) async {
    VLOG0("--got message from server------------------------");
    VLOG0(message);
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
          ApplicationInfo.screencount =
              await HardwareSimulator.getMonitorCount();
          send('updateDeviceInfo', {
            'deviceName': ApplicationInfo.deviceName,
            'deviceType': ApplicationInfo.deviceTypeName,
            'connective': ApplicationInfo.connectable,
            'screenCount': ApplicationInfo.screenCount,
          });
          ApplicationInfo.thisDevice = (Device(
              uid: ApplicationInfo.user.uid,
              nickname: ApplicationInfo.user.nickname,
              devicename: ApplicationInfo.deviceName,
              devicetype: ApplicationInfo.deviceTypeName,
              websocketSessionid: AppStateService.websocketSessionid!,
              connective: ApplicationInfo.connectable,
              screencount: ApplicationInfo.screenCount));
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
      case 'restartRequested':
        {
          if (StreamingSettings.connectPasswordHash ==
            HashUtil.hash(data['password']) && AppPlatform.isWindows && ApplicationInfo.isSystem) {
             SystemTrayManager().restart();
          }
        }
      case 'offer':
        {
          StreamingManager.onOfferReceived(
              data['source_connectionid'], data['description']);
        }
      case 'answer':
        {
          StreamedManager.onAnswerReceived(
              data['source_connectionid'], data['description']);
        }
      case 'candidate':
        {
          StreamingManager.onCandidateReceived(
              data['source_connectionid'], data['candidate']);
        }
      //sent from controller to controlled
      case 'candidate2':
        {
          StreamedManager.onCandidateReceived(
              data['source_connectionid'], data['candidate']);
        }
      default:
        {
          VLOG0("warning:get unknown message from server");
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
    VLOG0("sending----------");
    VLOG0(event);
    VLOG0(data);
    VLOG0("end of sending------");
    var request = {};
    request["type"] = event;
    request["data"] = data;
    _socket?.send(_encoder.convert(request));
  }

  static void onDisConnected() {
    connectionState = WebSocketConnectionState.disconnected;
  }
}
