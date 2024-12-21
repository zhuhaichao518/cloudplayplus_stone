part of virtual_keyboard;

/// US keyboard layout
List<List<VirtualKeyboardKey>> usLayout = [
  // Row 1
  [
    TextKey(
      "q",
    ),
    TextKey(
      "w",
    ),
    TextKey(
      "e",
    ),
    TextKey(
      "r",
    ),
    TextKey(
      "t",
    ),
    TextKey(
      "y",
    ),
    TextKey(
      "u",
    ),
    TextKey(
      "i",
    ),
    TextKey(
      "o",
    ),
    TextKey(
      "p",
    ),
  ],
  // Row 2
  [
    TextKey(
      "a",
    ),
    TextKey(
      "s",
    ),
    TextKey(
      "d",
    ),
    TextKey(
      "f",
    ),
    TextKey(
      "g",
    ),
    TextKey(
      "h",
    ),
    TextKey(
      "j",
    ),
    TextKey(
      "k",
    ),
    TextKey(
      "l",
    ),
  ],
  // Row 3
  [
    ActionKey(VirtualKeyboardKeyAction.Shift),
    TextKey(
      "z",
    ),
    TextKey(
      "x",
    ),
    TextKey(
      "c",
    ),
    TextKey(
      "v",
    ),
    TextKey(
      "b",
    ),
    TextKey(
      "n",
    ),
    TextKey(
      "m",
    ),
    ActionKey(VirtualKeyboardKeyAction.Backspace),
  ],
  // Row 4
  [
    ActionKey(VirtualKeyboardKeyAction.Symbols),
    TextKey(','),
    ActionKey(VirtualKeyboardKeyAction.Space),
    TextKey('.'),
    ActionKey(VirtualKeyboardKeyAction.Return),
  ]
];

/// Symbol layout
List<List<VirtualKeyboardKey>> symbolLayout = [
  // Row 1
  [
    TextKey(
      "1",
    ),
    TextKey(
      "2",
    ),
    TextKey(
      "3",
    ),
    TextKey(
      "4",
    ),
    TextKey(
      "5",
    ),
    TextKey(
      "6",
    ),
    TextKey(
      "7",
    ),
    TextKey(
      "8",
    ),
    TextKey(
      "9",
    ),
    TextKey(
      "0",
    ),
  ],
  // Row 2
  [
    TextKey('@'),
    TextKey('#'),
    TextKey('\$'),
    TextKey('_'),
    TextKey('-'),
    TextKey('+'),
    TextKey('('),
    TextKey(')'),
    TextKey('/'),
  ],
  // Row 3
  [
    TextKey('|'),
    TextKey('*'),
    TextKey('"'),
    TextKey('\''),
    TextKey(':'),
    TextKey(';'),
    TextKey('!'),
    TextKey('?'),
    ActionKey(VirtualKeyboardKeyAction.Backspace),
  ],
  // Row 5
  [
    ActionKey(VirtualKeyboardKeyAction.Alpha),
    TextKey(','),
    ActionKey(VirtualKeyboardKeyAction.Space),
    TextKey('.'),
    ActionKey(VirtualKeyboardKeyAction.Return),
  ]
];

/// numeric keyboard layout
List<List<VirtualKeyboardKey>> numericLayout = [
  // Row 1
  [
    TextKey('1'),
    TextKey('2'),
    TextKey('3'),
  ],
  // Row 1
  [
    TextKey('4'),
    TextKey('5'),
    TextKey('6'),
  ],
  // Row 1
  [
    TextKey('7'),
    TextKey('8'),
    TextKey('9'),
  ],
  // Row 1
  [TextKey('.'), TextKey('0'), ActionKey(VirtualKeyboardKeyAction.Backspace)],
];

/// Hardware keyboard layout
List<List<VirtualKeyboardKey>> hardwareLayout = [
  // Row 1
  [
    HardwareKey("q", 81),
    HardwareKey("w", 87),
    HardwareKey("e", 69),
    HardwareKey("r", 82),
    HardwareKey("t", 84),
    HardwareKey("y", 89),
    HardwareKey("u", 85),
    HardwareKey("i", 73),
    HardwareKey("o", 79),
    HardwareKey("p", 80),
  ],
  // Row 2
  [
    HardwareKey("a", 65),
    HardwareKey("s", 83),
    HardwareKey("d", 68),
    HardwareKey("f", 70),
    HardwareKey("g", 71),
    HardwareKey("h", 72),
    HardwareKey("j", 74),
    HardwareKey("k", 75),
    HardwareKey("l", 76),
  ],
  // Row 3
  [
    ActionKey(VirtualKeyboardKeyAction.Shift),
    HardwareKey("z", 90),
    HardwareKey("x", 88),
    HardwareKey("c", 67),
    HardwareKey("v", 86),
    HardwareKey("b", 66),
    HardwareKey("n", 78),
    HardwareKey("m", 77),
    HardwareActionKey(VirtualKeyboardKeyAction.Backspace, keyCode: 8),
  ],
  // Row 4
  [
    ActionKey(VirtualKeyboardKeyAction.Symbols),
    HardwareActionKey(VirtualKeyboardKeyAction.Ctrl,keyCode: 162),
    HardwareKey(",", 188, capsText: "<"),
    HardwareActionKey(VirtualKeyboardKeyAction.Space, keyCode: 32),
    HardwareKey(".", 190, capsText: ">"),
    HardwareActionKey(VirtualKeyboardKeyAction.Return, keyCode: 13),
  ]
];

/// esc ~ f12, 1 ~ 0, ctrl, etc, no charactors
List<List<VirtualKeyboardKey>> hardwareLayoutExt1 = [
  // Row 1
  [
    HardwareKey("⎋", 27),
    HardwareKey("F1", 112),
    HardwareKey("F2", 113),
    HardwareKey("F3", 114),
    HardwareKey("F4", 115),
    HardwareKey("F5", 116),
    HardwareKey("F6", 117),
    HardwareKey("F7", 118),
    HardwareKey("F8", 119),
    HardwareKey("F9", 120),
    HardwareKey("F10", 121),
    HardwareKey("F11", 122),
    HardwareKey("F12", 123),
  ],
  // Row 2
  [
    HardwareKey("↹", 9, willExpand: true),
    HardwareKey("`", 192, capsText: "~"),
    HardwareKey("-", 189, capsText: "_"),
    HardwareKey("=", 187, capsText: "+"),
    HardwareKey("[", 219, capsText: "{"),
    HardwareKey("]", 221, capsText: "}"),
    HardwareKey("\\", 220, capsText: "|"),
    HardwareKey(";", 186, capsText: ":"),
    HardwareKey("'", 222, capsText: "\""),
    HardwareKey(",", 188, capsText: "<"),
    HardwareKey(".", 190, capsText: ">"),
    HardwareKey("/", 191, capsText: "?"),
  ],
  // Row 3
  [
    //ActionKey(VirtualKeyboardKeyAction.Shift),
    //HardWareActionKey(),
    HardwareActionKey(VirtualKeyboardKeyAction.Shift, keyCode: 160),
    HardwareKey("⇪", 20),
    HardwareKey("1", 49, capsText: "!"),
    HardwareKey("2", 50, capsText: "@"),
    HardwareKey("3", 51, capsText: "#"),
    HardwareKey("4", 52, capsText: "\$"),
    HardwareKey("5", 53, capsText: "%"),
    HardwareKey("6", 54, capsText: "^"),
    HardwareKey("7", 55, capsText: "&"),
    HardwareKey("8", 56, capsText: "*"),
    HardwareKey("9", 57, capsText: "("),
    HardwareKey("↑", 38, capsText: "↑"),
    HardwareKey("0", 48, capsText: ")"),
  ],
  // Row 4
  [
    ActionKey(VirtualKeyboardKeyAction.Alpha),
    //HardwareKey("⌃", 162),
    //HardwareKey("⊞", 91),
    //HardwareKey("⎇", 164),
    HardwareActionKey(VirtualKeyboardKeyAction.Ctrl,keyCode: 162),
    HardwareActionKey(VirtualKeyboardKeyAction.Win,keyCode: 91),
    HardwareActionKey(VirtualKeyboardKeyAction.Alt,keyCode: 164),
    HardwareActionKey(VirtualKeyboardKeyAction.Space, keyCode: 32),
    HardwareKey("⎇", 165),
    HardwareKey("⊞", 92),
    HardwareKey("⌃", 163), 
    HardwareKey("←", 37),
    HardwareKey("↓", 40),
    HardwareKey("→", 39),
  ]
];
