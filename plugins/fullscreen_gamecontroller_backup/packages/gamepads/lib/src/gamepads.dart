library gamepads;

import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';

class Gamepads {
  Gamepads._();

  static final _platform = GamepadsPlatformInterface.instance;

  static Future<List<GamepadController>> list() => _platform.listGamepads();

  static Stream<GamepadEvent> get events => _platform.gamepadEventsStream;

  // ignore: lines_longer_than_80_chars
  static List<String> get gamepadstates =>
      _platform.getGamepadStatesListString();

  static Stream<GamepadEvent> eventsByGamepad(String gamepadId) {
    return events.where((event) => event.gamepadId == gamepadId);
  }
}
