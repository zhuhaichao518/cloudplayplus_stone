import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gamepads_web_platform_interface.dart';

/// An implementation of [GamepadsWebPlatform] that uses method channels.
class MethodChannelGamepadsWeb extends GamepadsWebPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gamepads_web');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
