import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_initializer.dart';

class WebRTCInitializerNative implements WebRTCInitializer {
  void _handleSystemUiChange() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  Future<void> initialize() async {
    if (WebRTC.initialized) {
      throw Exception(
          'Tried to initialize WebRTC but it was already initialized.');
    }

    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
        if (systemOverlaysAreVisible) {
          // 用户手动显示系统UI后，延迟1秒重新隐藏
          Future.delayed(const Duration(seconds: 1), _handleSystemUiChange);
        }
        return;
      });

      final androidConfig = AndroidAudioConfiguration(
        manageAudioFocus: true,
        androidAudioMode: AndroidAudioMode.normal,
        androidAudioFocusMode: AndroidAudioFocusMode.gain,
        androidAudioStreamType: AndroidAudioStreamType.music,
        androidAudioAttributesUsageType: AndroidAudioAttributesUsageType.media,
        androidAudioAttributesContentType:
            AndroidAudioAttributesContentType.speech,
      );

      WebRTC.initialize(
        options: {
          'androidAudioConfiguration': androidConfig.toMap(),
        },
      );
    } else if (Platform.isIOS) {
      final appleConfig = AppleAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playback,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.mixWithOthers,
        },
        appleAudioMode: AppleAudioMode.default_,
      );

      await Helper.setAppleAudioConfiguration(appleConfig);
    }

    // 设置扬声器
    if (Platform.isIOS || Platform.isAndroid) {
      await Helper.setSpeakerphoneOnButPreferBluetooth();
    }
  }
}
