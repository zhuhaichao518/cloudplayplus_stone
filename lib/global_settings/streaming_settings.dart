import 'package:cloudplayplus/controller/hardware_input_controller.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';

var officialStun1 = {
  'urls': "stun:stun.l.google.com:19302",
};

/*
var cloudPlayPlusStun = {
  'urls': "turn:101.132.58.198:3478",
  'username': "sunshine",
  'credential': "pangdahai"
};*/

var cloudPlayPlusStun = {
  'urls': "stun:101.132.58.198:3478",
};

class StreamingSettings {
  static int? framerate;
  static int? bitrate;
  //the remote peer will render the cursor.
  static bool? showRemoteCursor;

  static bool? streamAudio;

  static String? codec;
  static bool? hookCursorImage;

  static bool useTurnServer = false;
  static String? customTurnServerAddress;
  static String? customTurnServerUsername;
  static String? customTurnServerPassword;

  static String connectPasswordHash = "";
  //这两项会在连接的瞬间更新
  static int? targetScreenId;
  static String? connectPassword;

  static bool autoHideLocalCursor = true;
  static bool switchCmdCtrl = false;

  static bool useClipBoard = true;
  
  //if input is touch, then simulate touch on target device.
  static bool useTouchForTouch = true;

  static void init() {
    InputController.resendCount =
        SharedPreferencesManager.getInt('ControlMsgResendCount') ?? 3;

    framerate =
        SharedPreferencesManager.getInt('framerate') ?? 60; // Default to 60
    bitrate =
        SharedPreferencesManager.getInt('bitrate') ?? 80000; // Default to 80000
    showRemoteCursor = SharedPreferencesManager.getBool('renderRemoteCursor') ??
        false; // Default to false
    streamAudio = SharedPreferencesManager.getBool('haveAudio') ??
        true; // Default to true
    // This will be updated when user clicks connect button.
    targetScreenId = 0;
    /*turnServerSettings =
        SharedPreferencesManager.getInt('turnServerSettings') ??
            0; // Default to false
    useCustomTurnServer =
        SharedPreferencesManager.getBool('useCustomTurnServer') ??
            false; // Default to false
    turnServerAddress =
        SharedPreferencesManager.getString('customTurnServerAddress') ??
            ''; // Default to empty string
    turnServerUsername =
        SharedPreferencesManager.getString('turnServerUsername') ??
            ''; // Default to empty string
    turnServerPassword =
        SharedPreferencesManager.getString('turnServerPassword') ??
            ''; // Default to empty string*/
    customTurnServerAddress =
        SharedPreferencesManager.getString('customTurnServerAddress') ??
            'turn:106.14.91.137:3478';
    customTurnServerUsername =
        SharedPreferencesManager.getString('customTurnServerUsername') ??
            'haichaozhu';
    customTurnServerPassword =
        SharedPreferencesManager.getString('customTurnServerPassword') ??
            'pdhcppturn123';

    codec = SharedPreferencesManager.getString('codec') ?? 'default';

    hookCursorImage ??= (AppPlatform.isWeb || AppPlatform.isDeskTop);

    connectPasswordHash =
        SharedPreferencesManager.getString('connectPasswordHash') ?? "";

    autoHideLocalCursor = SharedPreferencesManager.getBool('autoHideCursor') ??
        (AppPlatform.isDeskTop || AppPlatform.isWeb);

    switchCmdCtrl = SharedPreferencesManager.getBool('switchCmdCtrl') ?? AppPlatform.isMacos;

    useTouchForTouch = SharedPreferencesManager.getBool('useTouchForTouch') ?? true;

    if (AppPlatform.isDeskTop) {
      useClipBoard = SharedPreferencesManager.getBool('useClipBoard') ?? true;
    } else {
      useClipBoard = SharedPreferencesManager.getBool('useClipBoard') ?? false;
    }
  }

  //Screen id setting is not global, so we need to call before start streaming.
  static void updateScreenId(int newScreenId) {
    targetScreenId = newScreenId;
  }

  static Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'framerate': framerate,
      'bitrate': bitrate,
      'showRemoteCursor': showRemoteCursor,
      'streamAudio': streamAudio,
      /*'turnServerSettings': turnServerSettings,
      'useCustomTurnServer': useCustomTurnServer,
      'customTurnServerAddress': turnServerAddress,
      'turnServerUsername': turnServerUsername,
      'turnServerPassword': turnServerPassword,*/
      'targetScreenId': targetScreenId,
      'codec': codec,
      'hookCursorImage': hookCursorImage,
      'connectPassword': connectPassword,
      'useClipBoard': useClipBoard,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class StreamedSettings {
  int? framerate;
  int? bitrate;
  //the remote peer will render the cursor.
  bool? showRemoteCursor;

  bool? streamAudio;
  int? screenId;

  //0: Use both.
  //1: Only use Peer to Peer
  //2: Only use Turn.
  /*int? turnServerSettings;
  bool? useCustomTurnServer;
  String? turnServerAddress;
  String? turnServerUsername;
  String? turnServerPassword;*/
  String? codec;
  bool? hookCursorImage;
  //设备的连接密码
  String? connectPassword = "";
  bool? useClipBoard;
  static StreamedSettings fromJson(Map<String, dynamic> settings) {
    return StreamedSettings()
      ..framerate = settings['framerate'] as int?
      ..bitrate = settings['bitrate'] as int?
      ..showRemoteCursor = settings['showRemoteCursor'] as bool?
      ..streamAudio = settings['streamAudio'] as bool?
      /*..turnServerSettings = settings['turnServerSettings'] as int?
      ..useCustomTurnServer = settings['useCustomTurnServer'] as bool?
      ..turnServerAddress = settings['customTurnServerAddress'] as String?
      ..turnServerUsername = settings['turnServerUsername'] as String?
      ..turnServerPassword = settings['turnServerPassword'] as String?*/
      ..screenId = settings['targetScreenId'] as int?
      ..codec = settings['codec'] as String?
      ..hookCursorImage = settings['hookCursorImage'] as bool?
      ..connectPassword = settings['connectPassword'] as String?
      ..useClipBoard = settings['useClipBoard'] as bool?;
  }
}
