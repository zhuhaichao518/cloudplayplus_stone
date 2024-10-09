/// Represents a single, currently connected joystick controller (or gamepad).
class GamepadController {
  /// A unique identifier for the gamepad controller.
  ///
  /// On Linux, it maps to the file descriptor path.
  /// On macOs and Windows, it's just the index of the connected controller.
  final String id;

  /// A user-facing, platform-dependant name for the gamepad controller.
  final String name;

  GamepadController({
    required this.id,
    required this.name,
  });

  factory GamepadController.parse(Map<dynamic, dynamic> map) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    return GamepadController(id: id, name: name);
  }
}
