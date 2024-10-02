import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../base/logging.dart';
import '../entities/session.dart';
import 'streaming_manager.dart';

class WebrtcService {
  static RTCVideoRenderer? globalVideoRenderer;
  static StreamingSession? currentRenderingSession;
  static Map<String, MediaStream> streams = {};
  static String currentDeviceId = "";

  static Function()? userViewCallback;

  static void addStream(String deviceId, RTCTrackEvent event) {
    streams[deviceId] = event.streams[0];
    if (globalVideoRenderer == null) {
      globalVideoRenderer = RTCVideoRenderer();
      globalVideoRenderer?.initialize().then((data) {
        if (currentDeviceId == deviceId) {
          globalVideoRenderer!.srcObject = event.streams[0];
          if (StreamingManager.sessions.containsKey(currentDeviceId)){
            currentRenderingSession = StreamingManager.sessions[currentDeviceId];
          }
        }
      }).catchError((error) {
        VLOG0('Error: failed to create RTCVideoRenderer');
      });
    } else {
      if (currentDeviceId == deviceId) {
        globalVideoRenderer!.srcObject = event.streams[0];
        if (StreamingManager.sessions.containsKey(currentDeviceId)){
          currentRenderingSession = StreamingManager.sessions[currentDeviceId];
        }
      }
    }
  }

  static void removeStream(String deviceId) {
    streams.remove(deviceId);
    if (currentDeviceId == deviceId) {
      globalVideoRenderer!.srcObject = null;
      currentRenderingSession = null;
    }
  }

  //当用户切换设备页面时 告诉我们现在应该渲染那个设备（如果那个设备也在stream）
  static void updateCurrentRenderingDevice(
      String deviceId, Function() callback) {
    if (currentDeviceId == deviceId) return;
    currentDeviceId = deviceId;
    if (streams.containsKey(deviceId)) {
      globalVideoRenderer?.srcObject = streams[deviceId];
      if (StreamingManager.sessions.containsKey(currentDeviceId)){
        currentRenderingSession = StreamingManager.sessions[currentDeviceId];
      }else{
        currentRenderingSession = null;
      }
    }
  }
}
