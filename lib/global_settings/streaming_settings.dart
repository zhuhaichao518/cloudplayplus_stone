import 'package:cloudplayplus/services/shared_preferences_manager.dart';

var officialStun1 = {
  'urls': "stun:stun.l.google.com:19302",
};

var cloudPlayPlusStun = {
  'urls': "turn:101.132.58.198:3478",
  'username': "sunshine",
  'credential': "pangdahai"
};

class StreamingSettings {
  static int? framerate;
  static int? bitrate;
  static int? targetScreenId;
  //the remote peer will render the cursor.
  static bool? showRemoteCursor;

  static bool? streamAudio;

  //0: Use both.
  //1: Only use Stun
  //2: Only use Turn.
  static int? turnServerSettings;
  static bool? useCustomTurnServer;
  static String? turnServerAddress;
  static String? turnServerUsername;
  static String? turnServerPassword;
  static String? codec;

  static void init() {
    framerate =
        SharedPreferencesManager.getInt('framerate') ?? 60; // Default to 60
    bitrate =
        SharedPreferencesManager.getInt('bitrate') ?? 80000; // Default to 80000
    showRemoteCursor = SharedPreferencesManager.getBool('showRemoteCursor') ??
        false; // Default to false
    streamAudio = SharedPreferencesManager.getBool('streamAudio') ??
        true; // Default to true
    turnServerSettings =
        SharedPreferencesManager.getInt('turnServerSettings') ??
            0; // Default to false
    useCustomTurnServer =
        SharedPreferencesManager.getBool('useCustomTurnServer') ??
            false; // Default to false
    turnServerAddress =
        SharedPreferencesManager.getString('turnServerAddress') ??
            ''; // Default to empty string
    turnServerUsername =
        SharedPreferencesManager.getString('turnServerUsername') ??
            ''; // Default to empty string
    turnServerPassword =
        SharedPreferencesManager.getString('turnServerPassword') ??
            ''; // Default to empty string
    targetScreenId = 0;
    codec = SharedPreferencesManager.getString('codec') ?? 'default';
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
      'turnServerSettings': turnServerSettings,
      'useCustomTurnServer': useCustomTurnServer,
      'turnServerAddress': turnServerAddress,
      'turnServerUsername': turnServerUsername,
      'turnServerPassword': turnServerPassword,
      'targetScreenId': targetScreenId,
      'codec': codec,
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
  int? turnServerSettings;
  bool? useCustomTurnServer;
  String? turnServerAddress;
  String? turnServerUsername;
  String? turnServerPassword;
  String? codec;
  static StreamedSettings fromJson(Map<String, dynamic> settings) {
    return StreamedSettings()
      ..framerate = settings['framerate'] as int?
      ..bitrate = settings['bitrate'] as int?
      ..showRemoteCursor = settings['showRemoteCursor'] as bool?
      ..streamAudio = settings['streamAudio'] as bool?
      ..turnServerSettings = settings['turnServerSettings'] as int?
      ..useCustomTurnServer = settings['useCustomTurnServer'] as bool?
      ..turnServerAddress = settings['turnServerAddress'] as String?
      ..turnServerUsername = settings['turnServerUsername'] as String?
      ..turnServerPassword = settings['turnServerPassword'] as String?
      ..screenId = settings['targetScreenId'] as int?
      ..codec = settings['codec'] as String?;
  }
}
