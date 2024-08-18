class StreamingSettings{
  static int? framerate;
  static int? bitrate;
  //the remote peer will render the cursor.
  static bool? showRemoteCursor;

  static bool? streamAudio;
  
  static bool? useTurnServer;
  static String? turnServerAddress;
  static String? turnServerUsername;
  static String? turnServerPassword;

  void init(){

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'framerate': framerate,
      'bitrate': bitrate,
      'showRemoteCursor': showRemoteCursor,
      'streamAudio': streamAudio,
      'useTurnServer': useTurnServer,
      'turnServerAddress': turnServerAddress,
      'turnServerUsername': turnServerUsername,
      'turnServerPassword': turnServerPassword
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}