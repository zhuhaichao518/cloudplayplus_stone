import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String keyUp = 'Arrow Up';
const String keyDown = 'Arrow Down';
const String keyLeft = 'Arrow Left';
const String keyRight = 'Arrow Right';
const String keyCenter = 'Select';
const String goBack = 'Go Back';

class DpadTextField extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const DpadTextField({
    super.key,
    required this.focusNode,
    required this.child,
  });

  @override
  State<DpadTextField> createState() => _DpadTextFieldState();
}

class _DpadTextFieldState extends State<DpadTextField> {
  // DpadTextField or textField has focus
  // TODO :use widget.focusNode.hasPrimaryFocus
  bool _wapperhasFocus = false;
  bool blockNextFocusChange = false;
  bool _textFieldhasFocus = false;

  @override
  void initState() {
    super.initState();
    _wapperhasFocus = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        if (widget.focusNode.hasFocus) {
          _wapperhasFocus = widget.focusNode.hasFocus;
        } else {
          _wapperhasFocus = widget.focusNode.hasFocus;
        }
        if (!_textFieldhasFocus && widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: widget.focusNode,
      onKeyEvent: (event) {
        if (event is KeyUpEvent) {
          if (event.logicalKey.keyLabel == keyCenter && !_textFieldhasFocus) {
            _textFieldhasFocus = true;
            FocusScope.of(context).nextFocus();
          } else if (event.logicalKey.keyLabel == keyDown && !_textFieldhasFocus) {
            _textFieldhasFocus = false;
          } else if (event.logicalKey.keyLabel == keyUp && !_textFieldhasFocus) {
            _textFieldhasFocus = false;
          } else if (event.logicalKey.keyLabel == keyCenter && _textFieldhasFocus){
            SystemChannels.textInput.invokeMethod('TextInput.show');
          } else if (event.logicalKey.keyLabel == keyUp && _textFieldhasFocus){
            _textFieldhasFocus = false;
            widget.focusNode.requestFocus();
          } else if (event.logicalKey.keyLabel == keyDown && _textFieldhasFocus){
            _textFieldhasFocus = false;
            widget.focusNode.requestFocus();
          }
        }
      },
      child: Container(
        decoration: _wapperhasFocus
            ? BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}