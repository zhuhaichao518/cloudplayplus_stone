part of virtual_keyboard;

/// The default keyboard height. Can we overriden by passing
///  `height` argument to `VirtualKeyboard` widget.
const double _virtualKeyboardDefaultHeight = 300;

const int _virtualKeyboardBackspaceEventPerioud = 250;

typedef KeyPressedCallback = void Function(int keyCode, bool isDown);

/// Virtual Keyboard widget.
class VirtualKeyboard extends StatefulWidget {
  /// Keyboard Type: Should be inited in creation time.
  final VirtualKeyboardType type;

  final KeyPressedCallback keyPressedCallback;

  /// Virtual keyboard height. Default is 300
  final double height;

  /// Color for key texts and icons.
  final Color textColor;

  /// Font size for keyboard keys.
  final double fontSize;

  /// The builder function will be called for each Key object.
  final Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;

  /// Set to true if you want only to show Caps letters.
  final bool alwaysCaps;

  final Color keyBackgroundColor;
  final Color keyHighlightColor;
  final BorderRadius keyBorderRadius;

  VirtualKeyboard({
    Key? key,
    required this.type,
    required this.keyPressedCallback,
    this.builder,
    this.height = _virtualKeyboardDefaultHeight,
    this.textColor = Colors.black,
    this.fontSize = 20,
    this.alwaysCaps = false,
    this.keyBackgroundColor = Colors.grey,
    this.keyHighlightColor = Colors.blue,
    this.keyBorderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VirtualKeyboardState();
  }
}

/// Holds the state for Virtual Keyboard class.
class _VirtualKeyboardState extends State<VirtualKeyboard> {
  late double keyHeight;
  late double keySpacing;
  late double maxRowWidth;

  VirtualKeyboardType? type;
  // The builder function will be called for each Key object.
  Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;
  late double height;
  late double width;
  TextSelection? cursorPosition;
  late KeyPressedCallback keyPressedCallback;
  late Color textColor;
  late double fontSize;
  late bool alwaysCaps;
  // Text Style for keys.
  late TextStyle textStyle;

  // True if shift is enabled.
  bool isShiftEnabled = false;
  bool isAltEnabled = false;
  bool isCtrlEnabled = false;
  bool isWinEnabled = false;

  @override
  void didUpdateWidget(VirtualKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      type = widget.type;
      height = widget.height;
      textColor = widget.textColor;
      fontSize = widget.fontSize;
      alwaysCaps = widget.alwaysCaps;

      // Init the Text Style for keys.
      textStyle = TextStyle(
        fontSize: fontSize,
        color: textColor,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    keyPressedCallback = widget.keyPressedCallback;
    type = widget.type;
    height = widget.height;
    textColor = widget.textColor;
    fontSize = widget.fontSize;
    alwaysCaps = widget.alwaysCaps;

    // Init the Text Style for keys.
    textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;

    switch (type) {
      case VirtualKeyboardType.Numeric:
        return _keyLayout(numericLayout);
      case VirtualKeyboardType.Alphanumeric:
        return _keyLayout(usLayout);
      case VirtualKeyboardType.Symbolic:
        return _keyLayout(symbolLayout);
      case VirtualKeyboardType.Hardware:
        return _keyLayout(hardwareLayout);
      case VirtualKeyboardType.HardwareExt:
        return _keyLayout(hardwareLayoutExt1);
      default:
        throw new Error();
    }
  }

  Widget _keyLayout(List<List<VirtualKeyboardKey>> layout) {
    // arbritrary
    keySpacing = 4.0;
    double totalSpacing = keySpacing * (layout.length + 1);
    keyHeight = (height - totalSpacing) / layout.length;

    if (type == VirtualKeyboardType.HardwareExt) {
      keyHeight = keyHeight * 0.8;
    }

    int maxLengthRow = 0;
    for (var layoutRow in layout) {
      if (layoutRow.length > maxLengthRow) {
        maxLengthRow = layoutRow.length;
      }
    }
    maxRowWidth =
        ((maxLengthRow - 1) * keySpacing) + (maxLengthRow * keyHeight);

    return Container(
      height: height,
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _rows(layout),
      ),
    );
  }

  /// Returns the rows for keyboard.
  List<Widget> _rows(List<List<VirtualKeyboardKey>> layout) {
    // Generate keyboard row.
    List<Widget> rows = [];
    for (var rowEntry in layout.asMap().entries) {
      int rowNum = rowEntry.key;
      List<VirtualKeyboardKey> rowKeys = rowEntry.value;

      List<Widget> cols = [];
      for (var colEntry in rowKeys.asMap().entries) {
        int colNum = colEntry.key;
        VirtualKeyboardKey virtualKeyboardKey = colEntry.value;
        Widget keyWidget;

        if (builder == null) {
          // Check the key type.
          switch (virtualKeyboardKey.keyType) {
            case VirtualKeyboardKeyType.String:
              // Draw String key.
              keyWidget = _keyboardDefaultKey(virtualKeyboardKey);
              break;
            case VirtualKeyboardKeyType.Action:
              // Draw action key.
              keyWidget = _keyboardDefaultActionKey(virtualKeyboardKey);
              break;
            case VirtualKeyboardKeyType.Hardware:
              keyWidget = _keyboardDefaultHardwareKey(virtualKeyboardKey);
              break;
            case VirtualKeyboardKeyType.HardwareAction:
              keyWidget = _keyboardHardwareActionKey(virtualKeyboardKey);
              break;
          }
        } else {
          // Call the builder function, so the user can specify custom UI for keys.
          keyWidget = builder!(context, virtualKeyboardKey);

          throw 'builder function must return Widget';
        }
        cols.add(keyWidget);

        // space between keys
        if (colNum != rowKeys.length - 1) {
          cols.add(SizedBox(
            width: keySpacing,
          ));
        }
      }
      rows.add(Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxRowWidth),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                // Generate keboard keys
                children: cols),
          )));
      // space between rows
      if (rowNum != layout.length - 1) {
        rows.add(SizedBox(
          height: keySpacing,
        ));
      }
    }
    return rows;
  }

  // True if long press is enabled.
  late bool longPress;

  /// Creates default UI element for keyboard Key.
  Widget _keyboardDefaultKey(VirtualKeyboardKey key) {
    return Material(
        color: widget.keyBackgroundColor,
        clipBehavior: Clip.hardEdge,
        borderRadius: widget.keyBorderRadius,
        child: InkWell(
          highlightColor: widget.keyHighlightColor,
          borderRadius: widget.keyBorderRadius,
          onTap: () {
            _onKeyPress(key);
          },
          child: Container(
            width: keyHeight,
            height: keyHeight,
            child: Center(
                child: Text(
              alwaysCaps
                  ? key.capsText!
                  : (isShiftEnabled ? key.capsText! : key.text!),
              style: textStyle,
            )),
          ),
        ));
  }

  void _onKeyPress(VirtualKeyboardKey key) {
    if (key.keyType == VirtualKeyboardKeyType.String) {
      /*String text = textController.text;
      if (cursorPosition == null) textControllerEvent();
      textController.text = cursorPosition!.textBefore(text) +
          (isShiftEnabled ? key.capsText! : key.text!) +
          cursorPosition!.textAfter(text);

      cursorPosition = TextSelection(
          baseOffset: cursorPosition!.baseOffset + 1,
          extentOffset: cursorPosition!.extentOffset + 1);*/
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          /*if (textController.text.length == 0) return;
          if (cursorPosition!.start == 0) return;
          String text = textController.text;
          if (cursorPosition == null) textControllerEvent();
          textController.text = cursorPosition!.start == text.length
              ? text.substring(0, text.length - 1)
              : text.substring(0, cursorPosition!.start - 1) +
                  text.substring(cursorPosition!.start);
          cursorPosition = TextSelection(
              baseOffset: cursorPosition!.baseOffset - 1,
              extentOffset: cursorPosition!.extentOffset - 1);*/
          break;
        case VirtualKeyboardKeyAction.Return:
          //textController.text += '\n';
          break;
        case VirtualKeyboardKeyAction.Space:
          //textController.text += key.text!;
          break;
        case VirtualKeyboardKeyAction.Shift:
          break;
        case VirtualKeyboardKeyAction.Alpha:
          setState(() {
            type = VirtualKeyboardType.Hardware;
          });
          break;
        case VirtualKeyboardKeyAction.Symbols:
          setState(() {
            type = VirtualKeyboardType.HardwareExt;
          });
          break;
        default:
      }
    }
  }

  /// Creates default UI element for keyboard Action Key.
  Widget _keyboardDefaultActionKey(VirtualKeyboardKey key) {
    // Holds the action key widget.
    Widget actionKey;

    // Switch the action type to build action Key widget.
    switch (key.action!) {
      case VirtualKeyboardKeyAction.Backspace:
        actionKey = GestureDetector(
            onLongPress: () {
              longPress = true;
              // Start sending backspace key events while longPress is true
              Timer.periodic(
                  Duration(milliseconds: _virtualKeyboardBackspaceEventPerioud),
                  (timer) {
                if (longPress) {
                  _onKeyPress(key);
                } else {
                  // Cancel timer.
                  timer.cancel();
                }
              });
            },
            onLongPressUp: () {
              // Cancel event loop
              longPress = false;
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.backspace,
                color: textColor,
              ),
            ));
        break;
      case VirtualKeyboardKeyAction.Shift:
        actionKey = Icon(Icons.arrow_upward,
            color: isShiftEnabled ? Colors.lime : textColor);
        break;
      case VirtualKeyboardKeyAction.Space:
        actionKey = Icon(Icons.space_bar, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Return:
        actionKey = Icon(
          Icons.keyboard_return,
          color: textColor,
        );
        break;
      case VirtualKeyboardKeyAction.Symbols:
        actionKey = Icon(Icons.emoji_symbols, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Alpha:
        actionKey = Icon(Icons.sort_by_alpha, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Ctrl:
        actionKey = Icon(FontAwesomeIcons.arrowUp,
            color: isCtrlEnabled ? Colors.lime : textColor);
        break;
      default:
        actionKey = Container();
    }
    var finalKey = Material(
      color: widget.keyBackgroundColor,
      clipBehavior: Clip.hardEdge,
      borderRadius: widget.keyBorderRadius,
      child: InkWell(
        borderRadius: widget.keyBorderRadius,
        highlightColor: widget.keyHighlightColor,
        onTap: () {
          if (key.action == VirtualKeyboardKeyAction.Shift) {
            if (!alwaysCaps) {
              if (isShiftEnabled) {
                //vk_shift
                keyPressedCallback(160, false);
              } else {
                keyPressedCallback(160, true);
              }
              setState(() {
                isShiftEnabled = !isShiftEnabled;
              });
            }
          }

          _onKeyPress(key);
        },
        child: Container(
          width: keyHeight,
          height: keyHeight,
          child: actionKey,
        ),
      ),
    );

    if (key.willExpand) {
      return Expanded(child: finalKey);
    } else {
      return finalKey;
    }
  }

  /// Creates default UI element for keyboard Hardware Key.
  Widget _keyboardDefaultHardwareKey(VirtualKeyboardKey key) {
    return Material(
        color: widget.keyBackgroundColor,
        clipBehavior: Clip.hardEdge,
        borderRadius: widget.keyBorderRadius,
        child: InkWell(
          highlightColor: widget.keyHighlightColor,
          borderRadius: widget.keyBorderRadius,
          onTapDown: (details) {
            keyPressedCallback(key.keyCode!, true);

            if (isCtrlEnabled ||
                isShiftEnabled ||
                isWinEnabled ||
                isAltEnabled) {
              if (isCtrlEnabled) {
                isCtrlEnabled = !isCtrlEnabled;
                keyPressedCallback(162, false);
              }
              /*if (isShiftEnabled){
                isShiftEnabled = !isShiftEnabled;
                keyPressedCallback(160, false);
              }*/
              if (isWinEnabled) {
                isWinEnabled = !isWinEnabled;
                keyPressedCallback(91, false);
              }
              if (isAltEnabled) {
                isAltEnabled = !isAltEnabled;
                keyPressedCallback(164, false);
              }
              setState(() {});
            }
          },
          onTapUp: (details) {
            keyPressedCallback(key.keyCode!, false);
          },
          child: Container(
            width: keyHeight,
            height: keyHeight,
            child: Center(
                child: Text(
              alwaysCaps
                  ? key.capsText!
                  : (isShiftEnabled ? key.capsText! : key.text!),
              style: textStyle,
            )),
          ),
        ));
  }

  /// Creates default UI element for keyboard Hardware Key.
  Widget _keyboardHardwareActionKey(VirtualKeyboardKey key) {
    Widget actionKey;
    switch (key.keyCode!) {
      case 8:
        /*actionKey = GestureDetector(
            onLongPress: () {
              longPress = true;
              // Start sending backspace key events while longPress is true
              Timer.periodic(
                  Duration(milliseconds: _virtualKeyboardBackspaceEventPerioud),
                  (timer) {
                if (longPress) {
                  keyPressedCallback(key.keyCode!, true);
                } else {
                  // Cancel timer.
                  timer.cancel();
                }
              });
            },
            onLongPressUp: () {
              // Cancel event loop
              longPress = false;
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.backspace,
                color: textColor,
              ),
            ));*/
        actionKey = Icon(Icons.backspace, color: textColor);
        break;
      case 13: //return
        actionKey = Icon(
          Icons.keyboard_return,
          color: textColor,
        );
        break;
      case 91: //left win
      case 92: //right win
        actionKey = Icon(FontAwesomeIcons.windows,
            color: isWinEnabled ? Colors.lime : textColor);
        break;
      case 160: //left shift
      case 161: //right shift
        actionKey = Icon(Icons.arrow_upward,
            color: isShiftEnabled ? Colors.lime : textColor);
        break;
      case 164: // left alt
      case 165: // right alt
        actionKey = Center(
            child: Text(
          "⎇",
          style: TextStyle(
            fontSize: fontSize,
            color: isAltEnabled ? Colors.lime : textColor,
          ),
        ));
        break;
      case 162: // left ctrl
      case 163: // right ctrl
        actionKey = Center(
            child: Text(
          "⌃",
          style: TextStyle(
            fontSize: fontSize,
            color: isCtrlEnabled ? Colors.lime : textColor,
          ),
        ));
        break;
      case 32:
        actionKey = Icon(Icons.space_bar, color: textColor);
        break;
      default:
        actionKey = Container();
        break;
    }

    var finalKey = Material(
      color: widget.keyBackgroundColor,
      clipBehavior: Clip.hardEdge,
      borderRadius: widget.keyBorderRadius,
      child: InkWell(
        borderRadius: widget.keyBorderRadius,
        highlightColor: widget.keyHighlightColor,
        onTap: () {
          if (key.action == VirtualKeyboardKeyAction.Shift) {
            keyPressedCallback(key.keyCode!, !isShiftEnabled);
            setState(() {
              isShiftEnabled = !isShiftEnabled;
            });
          } else if (key.action == VirtualKeyboardKeyAction.Alt) {
            keyPressedCallback(key.keyCode!, !isAltEnabled);
            setState(() {
              isAltEnabled = !isAltEnabled;
            });
          } else if (key.action == VirtualKeyboardKeyAction.Ctrl) {
            keyPressedCallback(key.keyCode!, !isCtrlEnabled);
            setState(() {
              isCtrlEnabled = !isCtrlEnabled;
            });
          } else if (key.action == VirtualKeyboardKeyAction.Win) {
            keyPressedCallback(key.keyCode!, !isWinEnabled);
            setState(() {
              isWinEnabled = !isWinEnabled;
            });
          }
        },
        onTapDown: (details) {
          if (key.action == VirtualKeyboardKeyAction.Space ||
              key.action == VirtualKeyboardKeyAction.Return ||
              key.action == VirtualKeyboardKeyAction.Backspace) {
            keyPressedCallback(key.keyCode!, true);
          }
        },
        onTapUp: (details) {
          if (key.action == VirtualKeyboardKeyAction.Space ||
              key.action == VirtualKeyboardKeyAction.Return ||
              key.action == VirtualKeyboardKeyAction.Backspace) {
            keyPressedCallback(key.keyCode!, false);
          }
        },
        child: Container(
          width: keyHeight,
          height: keyHeight,
          child: actionKey,
        ),
      ),
    );

    if (key.willExpand) {
      return Expanded(child: finalKey);
    } else {
      return finalKey;
    }
  }
}
