import 'webrtc_initializer.dart';
import 'webrtc_initializer_web.dart'
    if (dart.library.io) 'webrtc_initializer_native.dart';

WebRTCInitializer createWebRTCInitializer() {
  return WebRTCInitializerWeb();
}
