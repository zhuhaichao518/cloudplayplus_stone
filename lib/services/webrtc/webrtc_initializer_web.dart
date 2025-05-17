import 'webrtc_initializer.dart';

class WebRTCInitializerPlatForm implements WebRTCInitializer {
  @override
  Future<void> initialize() async {
    // Web 平台不需要特殊初始化
    return;
  }
}
