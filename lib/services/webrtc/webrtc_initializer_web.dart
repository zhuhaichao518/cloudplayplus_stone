import 'webrtc_initializer.dart';

class WebRTCInitializerWeb implements WebRTCInitializer {
  @override
  Future<void> initialize() async {
    // Web 平台不需要特殊初始化
    return;
  }
}
