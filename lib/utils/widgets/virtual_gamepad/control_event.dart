enum ControlEventType {
  gamepad,
  keyboard,
  mouse,
}

enum GamepadEventType {
  analog,
  button,
}

enum GamepadKey {
  leftStickX,
  leftStickY,
  rightStickX,
  rightStickY,
}

class ControlEvent {
  final ControlEventType eventType;
  final dynamic data;

  ControlEvent({
    required this.eventType,
    required this.data,
  });
}

class GamepadAnalogEvent {
  final GamepadKey key;
  final double value; // -1.0 to 1.0

  GamepadAnalogEvent({
    required this.key,
    required this.value,
  });
}

class GamepadButtonEvent {
  final int keyCode;
  final bool isDown;

  GamepadButtonEvent({
    required this.keyCode,
    required this.isDown,
  });
}

class KeyboardEvent {
  final int keyCode;
  final bool isDown;

  KeyboardEvent({
    required this.keyCode,
    required this.isDown,
  });
}

class MouseModeEvent {
  final List<MouseMode> enabledModes;
  final MouseMode currentMode;

  MouseModeEvent({
    required this.enabledModes,
    required this.currentMode,
  });
}

enum MouseMode {
  leftClick,
  rightClick,
  move,
}
