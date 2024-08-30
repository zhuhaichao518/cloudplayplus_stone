import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../base/logging.dart';

class WebrtcService {
  static RTCVideoRenderer? globalVideoRenderer;
  static Map<String, MediaStream> streams = {};
  static String currentDeviceId = "";

  static Function()? userViewCallback;
  /*static void updateUserViewCallback(Function() callback) {
    userViewCallback = callback;
  }*/

  static void runUserViewCallback() {
    if (userViewCallback != null) {
      userViewCallback!();
    }
  }

  static void addStream(String deviceId, RTCTrackEvent event) {
    streams[deviceId] = event.streams[0];
    if (globalVideoRenderer == null) {
      globalVideoRenderer = RTCVideoRenderer();
      globalVideoRenderer?.initialize().then((data) {
        if(currentDeviceId == deviceId){
          globalVideoRenderer!.srcObject = event.streams[0];
          runUserViewCallback();
        }
      }).catchError((error) {
        VLOG0('Error: failed to create RTCVideoRenderer');
      });
    } else {
      if(currentDeviceId == deviceId){
        globalVideoRenderer!.srcObject = event.streams[0];
        runUserViewCallback();
      }
    }
  }
  
  static void updateRenderer(String deviceId,Function() callback){
    currentDeviceId = deviceId;
    userViewCallback = callback;
    if (streams.containsKey(deviceId)){
        globalVideoRenderer?.srcObject = streams[deviceId];
        runUserViewCallback();
    }
  }
}
