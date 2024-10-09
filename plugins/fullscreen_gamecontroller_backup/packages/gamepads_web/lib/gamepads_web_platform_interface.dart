import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gamepads_web_method_channel.dart';

abstract class GamepadsWebPlatform extends PlatformInterface {
  /// Constructs a GamepadsWebPlatform.
  GamepadsWebPlatform() : super(token: _token);

  static final Object _token = Object();

  static GamepadsWebPlatform _instance = MethodChannelGamepadsWeb();

  /// The default instance of [GamepadsWebPlatform] to use.
  ///
  /// Defaults to [MethodChannelGamepadsWeb].
  static GamepadsWebPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GamepadsWebPlatform] when
  /// they register themselves.
  static set instance(GamepadsWebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
