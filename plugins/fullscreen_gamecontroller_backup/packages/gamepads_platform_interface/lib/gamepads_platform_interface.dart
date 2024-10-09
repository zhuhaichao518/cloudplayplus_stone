import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GamepadsPlatformInterface extends PlatformInterface {
  static final Object _token = Object();

  GamepadsPlatformInterface() : super(token: _token);

  /// The default instance of [GamepadsPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelGamepadsPlatformInterface].
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [GamepadsPlatformInterface] when they register
  /// themselves.
  static GamepadsPlatformInterface instance =
      MethodChannelGamepadsPlatformInterface();

  List<String> getGamepadStatesListString() {
    return [];
  }

  Future<List<GamepadController>> listGamepads();

  Stream<GamepadEvent> get gamepadEventsStream;
}
