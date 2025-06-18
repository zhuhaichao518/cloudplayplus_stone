enum ControlEventType {
  gamepad,
  keyboard,
  mouseMode,
  mouseButton,
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
  //final List<MouseMode> enabledModes;
  final MouseMode currentMode;
  bool isUnique;
  bool isDown;

  MouseModeEvent({
    //required this.enabledModes,
    required this.currentMode,
    required this.isUnique,
    required this.isDown
  });
}

enum MouseMode {
  leftClick,
  rightClick,
  move,
}

class MouseButtonEvent {
  final int buttonId; // 1=左键, 2=中键, 3=右键
  final bool isDown;

  MouseButtonEvent({
    required this.buttonId,
    required this.isDown,
  });
}
