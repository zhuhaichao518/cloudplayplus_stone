import 'package:flutter/services.dart';

Map<PhysicalKeyboardKey, int> physicalToWindowsKeyMap = {
  // Alphabet keys
  PhysicalKeyboardKey.keyA: 0x41,
  PhysicalKeyboardKey.keyB: 0x42,
  PhysicalKeyboardKey.keyC: 0x43,
  PhysicalKeyboardKey.keyD: 0x44,
  PhysicalKeyboardKey.keyE: 0x45,
  PhysicalKeyboardKey.keyF: 0x46,
  PhysicalKeyboardKey.keyG: 0x47,
  PhysicalKeyboardKey.keyH: 0x48,
  PhysicalKeyboardKey.keyI: 0x49,
  PhysicalKeyboardKey.keyJ: 0x4A,
  PhysicalKeyboardKey.keyK: 0x4B,
  PhysicalKeyboardKey.keyL: 0x4C,
  PhysicalKeyboardKey.keyM: 0x4D,
  PhysicalKeyboardKey.keyN: 0x4E,
  PhysicalKeyboardKey.keyO: 0x4F,
  PhysicalKeyboardKey.keyP: 0x50,
  PhysicalKeyboardKey.keyQ: 0x51,
  PhysicalKeyboardKey.keyR: 0x52,
  PhysicalKeyboardKey.keyS: 0x53,
  PhysicalKeyboardKey.keyT: 0x54,
  PhysicalKeyboardKey.keyU: 0x55,
  PhysicalKeyboardKey.keyV: 0x56,
  PhysicalKeyboardKey.keyW: 0x57,
  PhysicalKeyboardKey.keyX: 0x58,
  PhysicalKeyboardKey.keyY: 0x59,
  PhysicalKeyboardKey.keyZ: 0x5A,

  // Number keys
  PhysicalKeyboardKey.digit0: 0x30,
  PhysicalKeyboardKey.digit1: 0x31,
  PhysicalKeyboardKey.digit2: 0x32,
  PhysicalKeyboardKey.digit3: 0x33,
  PhysicalKeyboardKey.digit4: 0x34,
  PhysicalKeyboardKey.digit5: 0x35,
  PhysicalKeyboardKey.digit6: 0x36,
  PhysicalKeyboardKey.digit7: 0x37,
  PhysicalKeyboardKey.digit8: 0x38,
  PhysicalKeyboardKey.digit9: 0x39,

  // Function keys
  PhysicalKeyboardKey.f1: 0x70,
  PhysicalKeyboardKey.f2: 0x71,
  PhysicalKeyboardKey.f3: 0x72,
  PhysicalKeyboardKey.f4: 0x73,
  PhysicalKeyboardKey.f5: 0x74,
  PhysicalKeyboardKey.f6: 0x75,
  PhysicalKeyboardKey.f7: 0x76,
  PhysicalKeyboardKey.f8: 0x77,
  PhysicalKeyboardKey.f9: 0x78,
  PhysicalKeyboardKey.f10: 0x79,
  PhysicalKeyboardKey.f11: 0x7A,
  PhysicalKeyboardKey.f12: 0x7B,

  // Control keys
  PhysicalKeyboardKey.escape: 0x1B, // ESC key
  PhysicalKeyboardKey.enter: 0x0D, // ENTER key
  PhysicalKeyboardKey.backspace: 0x08, // BACKSPACE key
  PhysicalKeyboardKey.tab: 0x09, // TAB key
  PhysicalKeyboardKey.space: 0x20, // SPACEBAR
  PhysicalKeyboardKey.capsLock: 0x14, // CAPS LOCK key
  PhysicalKeyboardKey.shiftLeft: 0xA0, // Left SHIFT key
  PhysicalKeyboardKey.shiftRight: 0xA1, // Right SHIFT key
  PhysicalKeyboardKey.controlLeft: 0xA2, // Left CONTROL key
  PhysicalKeyboardKey.controlRight: 0xA3, // Right CONTROL key
  PhysicalKeyboardKey.altLeft: 0xA4, // Left ALT key
  PhysicalKeyboardKey.altRight: 0xA5, // Right ALT key

  // Arrow keys
  PhysicalKeyboardKey.arrowUp: 0x26, // UP ARROW key
  PhysicalKeyboardKey.arrowDown: 0x28, // DOWN ARROW key
  PhysicalKeyboardKey.arrowLeft: 0x25, // LEFT ARROW key
  PhysicalKeyboardKey.arrowRight: 0x27, // RIGHT ARROW key

  // Navigation keys
  PhysicalKeyboardKey.pageUp: 0x21, // PAGE UP key
  PhysicalKeyboardKey.pageDown: 0x22, // PAGE DOWN key
  PhysicalKeyboardKey.home: 0x24, // HOME key
  PhysicalKeyboardKey.end: 0x23, // END key
  PhysicalKeyboardKey.insert: 0x2D, // INSERT key
  PhysicalKeyboardKey.delete: 0x2E, // DELETE key

  // Lock keys
  PhysicalKeyboardKey.numLock: 0x90, // NUM LOCK key
  PhysicalKeyboardKey.scrollLock: 0x91, // SCROLL LOCK key

  // Numpad keys
  PhysicalKeyboardKey.numpad0: 0x60, // Numeric keypad 0 key
  PhysicalKeyboardKey.numpad1: 0x61, // Numeric keypad 1 key
  PhysicalKeyboardKey.numpad2: 0x62, // Numeric keypad 2 key
  PhysicalKeyboardKey.numpad3: 0x63, // Numeric keypad 3 key
  PhysicalKeyboardKey.numpad4: 0x64, // Numeric keypad 4 key
  PhysicalKeyboardKey.numpad5: 0x65, // Numeric keypad 5 key
  PhysicalKeyboardKey.numpad6: 0x66, // Numeric keypad 6 key
  PhysicalKeyboardKey.numpad7: 0x67, // Numeric keypad 7 key
  PhysicalKeyboardKey.numpad8: 0x68, // Numeric keypad 8 key
  PhysicalKeyboardKey.numpad9: 0x69, // Numeric keypad 9 key
  PhysicalKeyboardKey.numpadAdd: 0x6B, // Add key
  PhysicalKeyboardKey.numpadSubtract: 0x6D, // Subtract key
  PhysicalKeyboardKey.numpadMultiply: 0x6A, // Multiply key
  PhysicalKeyboardKey.numpadDivide: 0x6F, // Divide key
  PhysicalKeyboardKey.numpadEnter: 0x0D, // Numpad ENTER key
  PhysicalKeyboardKey.numpadDecimal: 0x6E, // Decimal key

  // Punctuation and symbols
  PhysicalKeyboardKey.minus: 0xBD, // - key
  PhysicalKeyboardKey.equal: 0xBB, // = key
  PhysicalKeyboardKey.bracketLeft: 0xDB, // [ key
  PhysicalKeyboardKey.bracketRight: 0xDD, // ] key
  PhysicalKeyboardKey.backslash: 0xDC, // \ key
  PhysicalKeyboardKey.semicolon: 0xBA, // ; key
  PhysicalKeyboardKey.quote: 0xDE, // ' key
  PhysicalKeyboardKey.comma: 0xBC, // , key
  PhysicalKeyboardKey.period: 0xBE, // . key
  PhysicalKeyboardKey.slash: 0xBF, // / key
  PhysicalKeyboardKey.backquote: 0xC0, // ` key

  // Special keys
  PhysicalKeyboardKey.printScreen: 0x2C, // PRINT SCREEN key
  PhysicalKeyboardKey.pause: 0x13, // PAUSE key
  PhysicalKeyboardKey.help: 0x2F, // HELP key

  // Windows keys
  PhysicalKeyboardKey.metaLeft: 0x5B, // Left Windows key
  PhysicalKeyboardKey.metaRight: 0x5C, // Right Windows key
  PhysicalKeyboardKey.contextMenu: 0x5D, // Applications key

  // Media keys
  //PhysicalKeyboardKey.volumeMute: 0xAD, // Volume Mute key
  //PhysicalKeyboardKey.volumeDown: 0xAE, // Volume Down key
  //PhysicalKeyboardKey.volumeUp: 0xAF, // Volume Up key
  PhysicalKeyboardKey.mediaPlayPause: 0xB3, // Play/Pause Media key
  PhysicalKeyboardKey.mediaStop: 0xB2, // Stop Media key
  //PhysicalKeyboardKey.mediaNextTrack: 0xB0, // Next Track key
  //PhysicalKeyboardKey.mediaPrevTrack: 0xB1, // Previous Track key
  PhysicalKeyboardKey.launchMail: 0xB4, // Start Mail key
  PhysicalKeyboardKey.launchApp1: 0xB6, // Start Application 1 key
  PhysicalKeyboardKey.launchApp2: 0xB7, // Start Application 2 key

  // Browser keys
  PhysicalKeyboardKey.browserBack: 0xA6, // Browser Back key
  PhysicalKeyboardKey.browserForward: 0xA7, // Browser Forward key
  PhysicalKeyboardKey.browserRefresh: 0xA8, // Browser Refresh key
  PhysicalKeyboardKey.browserStop: 0xA9, // Browser Stop key
  PhysicalKeyboardKey.browserSearch: 0xAA, // Browser Search key
  PhysicalKeyboardKey.browserFavorites: 0xAB, // Browser Favorites key
  PhysicalKeyboardKey.browserHome: 0xAC, // Browser Home key

  // OEM keys (miscellaneous characters, often keyboard-specific)
  /*PhysicalKeyboardKey.oem1: 0xBA, // For US standard keyboards, the ;: key
  PhysicalKeyboardKey.oemPlus: 0xBB, // For any country/region, the + key
  PhysicalKeyboardKey.oemComma: 0xBC, // For any country/region, the , key
  PhysicalKeyboardKey.oemMinus: 0xBD, // For any country/region, the - key
  PhysicalKeyboardKey.oemPeriod: 0xBE, // For any country/region, the . key
  PhysicalKeyboardKey.oem2: 0xBF, // For US standard keyboards, the /? key
  PhysicalKeyboardKey.oem3: 0xC0, // For US standard keyboards, the `~ key
  PhysicalKeyboardKey.oem4: 0xDB, // For US standard keyboards, the [{ key
  PhysicalKeyboardKey.oem5: 0xDC, // For US standard keyboards, the \| key
  PhysicalKeyboardKey.oem6: 0xDD, // For US standard keyboards, the ]} key
  PhysicalKeyboardKey.oem7: 0xDE, // For US standard keyboards, the '" key
*/

  // Additional function keys (F13-F24)
  PhysicalKeyboardKey.f13: 0x7C, // F13 key
  PhysicalKeyboardKey.f14: 0x7D, // F14 key
  PhysicalKeyboardKey.f15: 0x7E, // F15 key
  PhysicalKeyboardKey.f16: 0x7F, // F16 key
  PhysicalKeyboardKey.f17: 0x80, // F17 key
  PhysicalKeyboardKey.f18: 0x81, // F18 key
  PhysicalKeyboardKey.f19: 0x82, // F19 key
  PhysicalKeyboardKey.f20: 0x83, // F20 key
  PhysicalKeyboardKey.f21: 0x84, // F21 key
  PhysicalKeyboardKey.f22: 0x85, // F22 key
  PhysicalKeyboardKey.f23: 0x86, // F23 key
  PhysicalKeyboardKey.f24: 0x87, // F24 key

  // Additional special keys
  PhysicalKeyboardKey.zoomIn: 0x22D, // Zoom In key
  PhysicalKeyboardKey.zoomOut: 0x22E, // Zoom Out key
  PhysicalKeyboardKey.zoomToggle: 0x232, // Zoom Toggle key
  PhysicalKeyboardKey.redo: 0x0279, // Redo key
  PhysicalKeyboardKey.mailReply: 0x0289, // Mail Reply key
  PhysicalKeyboardKey.mailForward: 0x028B, // Mail Forward key
  PhysicalKeyboardKey.mailSend: 0x028C, // Mail Send key

  // System keys
  /* acutally logic keys
  PhysicalKeyboardKey.attn: 0xF6, // Attn key
  PhysicalKeyboardKey.crSel: 0xF7, // CrSel key
  PhysicalKeyboardKey.exSel: 0xF8, // ExSel key
  PhysicalKeyboardKey.eraseEOF: 0xF9, // Erase EOF key
  PhysicalKeyboardKey.play: 0xFA, // Play key
  PhysicalKeyboardKey.zoom: 0xFB, // Zoom key
  PhysicalKeyboardKey.noName: 0xFC, // Reserved
  PhysicalKeyboardKey.pa1: 0xFD, // PA1 key
  PhysicalKeyboardKey.oemClear: 0xFE, // Clear key
  */
};

Map<int, int> macToWindowsKeyMap = {
  0x00: 0x41, // A
  0x01: 0x53, // S
  0x02: 0x44, // D
  0x03: 0x46, // F
  0x04: 0x48, // H
  0x05: 0x47, // G
  0x06: 0x5A, // Z
  0x07: 0x58, // X
  0x08: 0x43, // C
  0x09: 0x56, // V
  0x0B: 0x42, // B
  0x0C: 0x51, // Q
  0x0D: 0x57, // W
  0x0E: 0x45, // E
  0x0F: 0x52, // R
  0x10: 0x59, // Y
  0x11: 0x54, // T
  0x12: 0x31, // 1
  0x13: 0x32, // 2
  0x14: 0x33, // 3
  0x15: 0x34, // 4
  0x16: 0x36, // 6
  0x17: 0x35, // 5
  0x18: 0xBB, // Equals
  0x19: 0x39, // 9
  0x1A: 0x37, // 7
  0x1B: 0xBD, // Minus
  0x1C: 0x38, // 8
  0x1D: 0x30, // 0
  0x1E: 0xDD, // Right Bracket
  0x1F: 0x4F, // O
  0x20: 0x55, // U
  0x21: 0xDB, // Left Bracket
  0x22: 0x49, // I
  0x23: 0x50, // P
  0x24: 0x0D, // Return
  0x25: 0x4C, // L
  0x26: 0x4A, // J
  0x27: 0xDE, // Quote
  0x28: 0x4B, // K
  0x29: 0xBA, // Semicolon
  0x2A: 0xDC, // Backslash
  0x2B: 0xBC, // Comma
  0x2C: 0xBF, // Slash
  0x2D: 0x4E, // N
  0x2E: 0x4D, // M
  0x2F: 0xBE, // Period
  0x30: 0x09, // Tab
  0x31: 0x20, // Space
  0x32: 0xC0, // Back Quote
  0x33: 0x08, // Delete
  0x34: 0x0D, // Enter
  0x35: 0x1B, // Escape
  0x36: 0x5B, // Right Windows
  0x37: 0x5B, // Left Windows
  0x38: 0x10, // Shift
  0x39: 0x14, // Caps Lock
  0x3A: 0x12, // Menu
  0x3B: 0x11, // Control
  0x3C: 0xA1, // Right Shift
  0x3D: 0xA5, // Right Menu
  0x3E: 0xA3, // Right Control
  0x3F: 0x18, // Final
  0x40: 0x84, // F17
  0x41: 0x6C, // Separator
  0x43: 0x6A, // Multiply
  0x45: 0x6B, // Add
  0x47: 0x90, // Num Lock
  0x48: 0xAF, // Volume Up
  0x49: 0xAE, // Volume Down
  0x4A: 0xAD, // Volume Mute
  0x4B: 0x6F, // Divide
  0x4C: 0x0D, // Numpad Enter
  0x4E: 0x6D, // Subtract
  0x4F: 0x85, // F18
  0x50: 0x86, // F19
  0x52: 0x60, // Numpad 0
  0x53: 0x61, // Numpad 1
  0x54: 0x62, // Numpad 2
  0x55: 0x63, // Numpad 3
  0x56: 0x64, // Numpad 4
  0x57: 0x65, // Numpad 5
  0x58: 0x66, // Numpad 6
  0x59: 0x67, // Numpad 7
  0x5A: 0x87, // F20
  0x5B: 0x68, // Numpad 8
  0x5C: 0x69, // Numpad 9
  0x5D: 0xFFE5, // Yen (JIS layout)
  0x5E: 0xBF, // Underscore (JIS layout)
  0x5F: 0xBC, // Keypad Comma/Separator (JIS layout)
  0x66: 0xE5, // Eisu (JIS layout)
  0x68: 0x15, // Kana (JIS layout)
  0x6A: 0x87, // F16
  0x6E: 0x5D, // Apps
  0x7F: 0x5F, // Sleep
};
