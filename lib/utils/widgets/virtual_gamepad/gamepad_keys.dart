class GamepadKeys {
  // 摇杆按键
  static const int LEFT_STICK = 0x1000;
  static const int RIGHT_STICK = 0x2000;

  // 摇杆按钮
  static const int LEFT_STICK_BUTTON = 0x1003;
  static const int RIGHT_STICK_BUTTON = 0x2003;

  // 摇杆移动
  static const int LEFT_STICK_X = 0x1001;
  static const int LEFT_STICK_Y = 0x1002;
  static const int RIGHT_STICK_X = 0x2001;
  static const int RIGHT_STICK_Y = 0x2002;

  // 功能键
  static const int A = 0x1004;
  static const int B = 0x1005;
  static const int X = 0x1006;
  static const int Y = 0x1007;

  // 肩键
  static const int LEFT_SHOULDER = 0x0100;
  static const int RIGHT_SHOULDER = 0x0200;
  static const int LEFT_TRIGGER = 0x0101;
  static const int RIGHT_TRIGGER = 0x0201;

  // 开始和返回键
  static const int START = 0x0010;
  static const int BACK = 0x0020;

  // 方向键
  static const int DPAD_UP = 0x0001;
  static const int DPAD_DOWN = 0x0002;
  static const int DPAD_LEFT = 0x0004;
  static const int DPAD_RIGHT = 0x0008;

  // 判断是否是摇杆按键
  static bool isStickKey(int keyCode) {
    return keyCode == LEFT_STICK || keyCode == RIGHT_STICK;
  }

  // 判断是否是按钮按键
  static bool isButton(int keyCode) {
    return keyCode == A ||
        keyCode == B ||
        keyCode == X ||
        keyCode == Y ||
        keyCode == LEFT_SHOULDER ||
        keyCode == RIGHT_SHOULDER ||
        keyCode == LEFT_TRIGGER ||
        keyCode == RIGHT_TRIGGER ||
        keyCode == START ||
        keyCode == BACK ||
        keyCode == DPAD_UP ||
        keyCode == DPAD_DOWN ||
        keyCode == DPAD_LEFT ||
        keyCode == DPAD_RIGHT ||
        keyCode == LEFT_STICK_BUTTON ||
        keyCode == RIGHT_STICK_BUTTON;
  }

  // 判断是否是摇杆移动
  static bool isStickMovement(int keyCode) {
    return keyCode == LEFT_STICK_X ||
        keyCode == LEFT_STICK_Y ||
        keyCode == RIGHT_STICK_X ||
        keyCode == RIGHT_STICK_Y;
  }

  // 获取按键名称
  static String getKeyName(int keyCode) {
    switch (keyCode) {
      case LEFT_STICK:
        return '左摇杆';
      case RIGHT_STICK:
        return '右摇杆';
      case LEFT_STICK_BUTTON:
        return '左摇杆按钮';
      case RIGHT_STICK_BUTTON:
        return '右摇杆按钮';
      case LEFT_STICK_X:
        return '左摇杆X轴';
      case LEFT_STICK_Y:
        return '左摇杆Y轴';
      case RIGHT_STICK_X:
        return '右摇杆X轴';
      case RIGHT_STICK_Y:
        return '右摇杆Y轴';
      case A:
        return 'A键';
      case B:
        return 'B键';
      case X:
        return 'X键';
      case Y:
        return 'Y键';
      case LEFT_SHOULDER:
        return '左肩键';
      case RIGHT_SHOULDER:
        return '右肩键';
      case LEFT_TRIGGER:
        return '左扳机键';
      case RIGHT_TRIGGER:
        return '右扳机键';
      case START:
        return '开始键';
      case BACK:
        return '返回键';
      case DPAD_UP:
        return '方向上键';
      case DPAD_DOWN:
        return '方向下键';
      case DPAD_LEFT:
        return '方向左键';
      case DPAD_RIGHT:
        return '方向右键';
      default:
        return '未选择';
    }
  }
}
