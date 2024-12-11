part of virtual_keyboard;

/// Type for virtual keyboard key.
///
/// `Action` - Can be action key - Return, Backspace, etc.
///
/// `String` - Keys that have text value - `Letters`, `Numbers`, `@` `.`
enum VirtualKeyboardKeyType { Action, String , Hardware}

/// Virtual Keyboard key
class VirtualKeyboardKey {
  /// Will the key expand in it's place
  bool willExpand = false;
  String? text;
  String? capsText;
  int? keyCode;
  final VirtualKeyboardKeyType keyType;
  final VirtualKeyboardKeyAction? action;

  VirtualKeyboardKey(
      {this.text, this.capsText, this.keyCode, required this.keyType, this.action});
}

/// Shorthand for creating a simple text key
class TextKey extends VirtualKeyboardKey {
  TextKey(String text, {String? capsText})
      : super(
            text: text,
            capsText: capsText == null ? text.toUpperCase() : capsText,
            keyType: VirtualKeyboardKeyType.String);
}

/// Shorthand for creating action keys
class ActionKey extends VirtualKeyboardKey {
  ActionKey(VirtualKeyboardKeyAction action)
      : super(keyType: VirtualKeyboardKeyType.Action, action: action) {
    switch (action) {
      case VirtualKeyboardKeyAction.Space:
        super.text = ' ';
        super.capsText = ' ';
        super.willExpand = true;
        break;
      case VirtualKeyboardKeyAction.Return:
        super.text = '\n';
        super.capsText = '\n';
        break;
      case VirtualKeyboardKeyAction.Backspace:
        super.willExpand = true;
        break;
      default:
        break;
    }
  }
}

/// Shorthand for creating hardware keys
class HardwareKey extends VirtualKeyboardKey {
  HardwareKey(String text, int keyCode, {String? capsText})
      : super(text: text,
            keyCode:keyCode,
            capsText: capsText == null ? text.toUpperCase() : capsText,
            keyType: VirtualKeyboardKeyType.Hardware) {
    switch (action) {
      case VirtualKeyboardKeyAction.Space:
        super.text = ' ';
        super.capsText = ' ';
        super.willExpand = true;
        break;
      case VirtualKeyboardKeyAction.Return:
        super.text = '\n';
        super.capsText = '\n';
        break;
      case VirtualKeyboardKeyAction.Backspace:
        super.willExpand = true;
        break;
      default:
        break;
    }
  }
}
