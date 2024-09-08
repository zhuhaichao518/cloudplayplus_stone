part of virtual_keyboard;

/// Type for virtual keyboard key.
///
/// `Action` - Can be action key - Return, Backspace, etc.
///
/// `String` - Keys that have text value - `Letters`, `Numbers`, `@` `.`
enum VirtualKeyboardKeyType { Action, String }

/// Virtual Keyboard key
class VirtualKeyboardKey {
  /// Will the key expand in it's place
  bool willExpand = false;
  String? text;
  String? capsText;
  final VirtualKeyboardKeyType keyType;
  final VirtualKeyboardKeyAction? action;

  VirtualKeyboardKey(
      {this.text, this.capsText, required this.keyType, this.action});
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
