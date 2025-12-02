//掉线连接管理.md
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../entities/device.dart';
import '../entities/user.dart';

class ApplicationInfo {
  static late Device thisDevice;
  static late User user;
  //count of connected monitors.
  static int? screencount;
  static bool connectable = false;
  static String? deviceNameOverride;

  //For windows, it is needed to be run as system to capture UAC window.
  static bool isSystem = true;
  
  // 全局的显示器数量变化Completer，供StreamedManager使用
  static Completer<void>? displayCountChangedCompleter;

  static int get screenCount {
    if (screencount != null) {
      return screencount!;
    }
    return 1;
  }

  static String get deviceName {
    if (deviceNameOverride != null && deviceNameOverride != "") {
      return deviceNameOverride!;
    }
    if (AppPlatform.isWeb) {
      // \u4E91\u73A9\u52A0\u7F51\u9875\u7AEF
      return '云玩加网页端';
    }
    if (AppPlatform.isIOS) {
      return 'IOS设备';
    }
    if (AppPlatform.isMacos) {
      return 'MacOS设备';
    }
    if (AppPlatform.isAndroid) {
      return '安卓设备';
    }
    return Platform.localHostname;
  }

  static String get deviceTypeName {
    if (AppPlatform.isWeb) {
      return 'Web';
    }
    if (Platform.isWindows) {
      return 'Windows';
    }
    if (Platform.isMacOS) {
      return 'MacOS';
    }
    if (Platform.isAndroid) {
      return 'Android';
    }
    if (Platform.isIOS) {
      return 'IOS';
    }
    if (Platform.isLinux) {
      return 'Linux';
    }
    return 'Unknown';
  }

  static Map toJson() {
    return {};
  }
}

enum ControlState { normal, controlRequested, answerSent, conneted }

enum HostState { normal, offerSent, answerReceived, conneted }

//这个类负责管理当前运行的app的状态 见 如何管理用户登录状态.md
class AppStateService {
  static late Future<int> appInitState;
  // When conneted to ws server, get the ws session id.
  // This is the connection_id on the server
  static String? websocketSessionid;
  // Used during reconnection.
  static String? lastwebsocketSessionid;
  static ControlState controlState = ControlState.normal;
  static HostState hostState = HostState.normal;
  // Only used for mobile to render native cursor.
  static bool isMouseConnected = false;
  //static bool visible = true;
}

//TODO: find the platform when isWeb.
class AppPlatform {
  static const bool isWeb = kIsWeb;
  static final bool isAndroid = !kIsWeb && Platform.isAndroid;
  static bool isAndroidTV = false;
  static final bool isIOS = !kIsWeb && Platform.isIOS;
  static final bool isWindows = !kIsWeb && Platform.isWindows;
  static final bool isMacos = !kIsWeb && Platform.isMacOS;
  static final bool isLinux = !kIsWeb && Platform.isLinux;
  static final bool isDeskTop =
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  static final bool isMobile =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
      if (isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        isAndroidTV = androidInfo.systemFeatures.contains('android.software.leanback');
      }
  }
}
