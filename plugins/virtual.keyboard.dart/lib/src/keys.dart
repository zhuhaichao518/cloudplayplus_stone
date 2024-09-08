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
