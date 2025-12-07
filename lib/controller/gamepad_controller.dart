// We can't implement this logic in the gampads package because when calling getStateString
// in the callback of gamepad event it is still not updated yet.
// ignore_for_file: always_put_control_body_on_new_line

import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:gamepads/gamepads.dart';

class CGamepadState {
  int word = 0;
  List<bool> buttonDown = List.filled(14, false);
  List<int> analogs = List.filled(6, 0);

  static const int XINPUT_GAMEPAD_DPAD_UP = 0;
  static const int XINPUT_GAMEPAD_DPAD_DOWN = 1;
  static const int XINPUT_GAMEPAD_DPAD_LEFT = 2;
  static const int XINPUT_GAMEPAD_DPAD_RIGHT = 3;
  static const int XINPUT_GAMEPAD_START = 4;
  static const int XINPUT_GAMEPAD_BACK = 5;
  static const int XINPUT_GAMEPAD_LEFT_THUMB = 6;
  static const int XINPUT_GAMEPAD_RIGHT_THUMB = 7;
  static const int XINPUT_GAMEPAD_LEFT_SHOULDER = 8;
  static const int XINPUT_GAMEPAD_RIGHT_SHOULDER = 9;
  static const int XINPUT_GAMEPAD_A = 10;
  static const int XINPUT_GAMEPAD_B = 11;
  static const int XINPUT_GAMEPAD_X = 12;
  static const int XINPUT_GAMEPAD_Y = 13;

  static const int bLeftTrigger = 0; //LT,0-255
  static const int bRightTrigger = 1;
  static const int sThumbLX = 2; //-32768 -32767
  static const int sThumbLY = 3;
  static const int sThumbRX = 4;
  static const int sThumbRY = 5;
  /*
  bool XINPUT_GAMEPAD_DPAD_UP = false;
  bool XINPUT_GAMEPAD_DPAD_DOWN = false;
  bool XINPUT_GAMEPAD_DPAD_LEFT = false;
  bool XINPUT_GAMEPAD_DPAD_RIGHT = false;
  bool XINPUT_GAMEPAD_START = false;
  bool XINPUT_GAMEPAD_BACK = false;
  bool XINPUT_GAMEPAD_LEFT_THUMB = false;
  bool XINPUT_GAMEPAD_RIGHT_THUMB = false;
  bool XINPUT_GAMEPAD_LEFT_SHOULDER = false;
  bool XINPUT_GAMEPAD_RIGHT_SHOULDER = false;
  bool XINPUT_GAMEPAD_A = false;
  bool XINPUT_GAMEPAD_B = false;
  bool XINPUT_GAMEPAD_X = false;
  bool XINPUT_GAMEPAD_Y = false;

  //int wButtons;

  if (XINPUT_GAMEPAD_DPAD_UP) word |= 0x0001;
  if (XINPUT_GAMEPAD_DPAD_DOWN) word |= 0x0002;
  if (XINPUT_GAMEPAD_DPAD_LEFT) word |= 0x0004;
  if (XINPUT_GAMEPAD_DPAD_RIGHT) word |= 0x0008;
  if (XINPUT_GAMEPAD_START) word |= 0x0010;
  if (XINPUT_GAMEPAD_BACK) word |= 0x0020;
  if (XINPUT_GAMEPAD_LEFT_THUMB) word |= 0x0040;
  if (XINPUT_GAMEPAD_RIGHT_THUMB) word |= 0x0080;
  if (XINPUT_GAMEPAD_LEFT_SHOULDER) word |= 0x0100;
  if (XINPUT_GAMEPAD_RIGHT_SHOULDER) word |= 0x0200;
  if (XINPUT_GAMEPAD_A) word |= 0x1000;
  if (XINPUT_GAMEPAD_B) word |= 0x2000;
  if (XINPUT_GAMEPAD_X) word |= 0x4000;
  if (XINPUT_GAMEPAD_Y) word |= 0x8000;

  int bLeftTrigger = 0; //LT,0-255
  int bRightTrigger = 0;
  int sThumbLX = 0; //-32768 -32767
  int sThumbLY = 0;
  int sThumbRX = 0;
  int sThumbRY = 0;
  */

  //"xinput: $word $bLeftTrigger $bRightTrigger $sThumbLX $sThumbLY $sThumbRX $sThumbRY "
  String getStateString() {
    var word = 0;
    if (buttonDown[XINPUT_GAMEPAD_DPAD_UP]) word |= 0x0001;
    if (buttonDown[XINPUT_GAMEPAD_DPAD_DOWN]) word |= 0x0002;
    if (buttonDown[XINPUT_GAMEPAD_DPAD_LEFT]) word |= 0x0004;
    if (buttonDown[XINPUT_GAMEPAD_DPAD_RIGHT]) word |= 0x0008;
    if (buttonDown[XINPUT_GAMEPAD_START]) word |= 0x0010;
    if (buttonDown[XINPUT_GAMEPAD_BACK]) word |= 0x0020;
    if (buttonDown[XINPUT_GAMEPAD_LEFT_THUMB]) word |= 0x0040;
    if (buttonDown[XINPUT_GAMEPAD_RIGHT_THUMB]) word |= 0x0080;
    if (buttonDown[XINPUT_GAMEPAD_LEFT_SHOULDER]) word |= 0x0100;
    if (buttonDown[XINPUT_GAMEPAD_RIGHT_SHOULDER]) word |= 0x0200;
    if (buttonDown[XINPUT_GAMEPAD_A]) word |= 0x1000;
    if (buttonDown[XINPUT_GAMEPAD_B]) word |= 0x2000;
    if (buttonDown[XINPUT_GAMEPAD_X]) word |= 0x4000;
    if (buttonDown[XINPUT_GAMEPAD_Y]) word |= 0x8000;

    return '$word ${analogs[bLeftTrigger]} ${analogs[bRightTrigger]} ${analogs[sThumbLX]} ${analogs[sThumbLY]} ${analogs[sThumbRX]} ${analogs[sThumbRY]}';
  }

  final Map<String, int> buttonMapping = {
    //web
    'button 0': XINPUT_GAMEPAD_A,
    'button 1': XINPUT_GAMEPAD_B,
    'button 2': XINPUT_GAMEPAD_X,
    'button 3': XINPUT_GAMEPAD_Y,
    'button 4': XINPUT_GAMEPAD_LEFT_SHOULDER,
    'button 5': XINPUT_GAMEPAD_RIGHT_SHOULDER,
    'button 8': XINPUT_GAMEPAD_BACK,
    'button 9': XINPUT_GAMEPAD_START,
    'button 10': XINPUT_GAMEPAD_LEFT_THUMB,
    'button 11': XINPUT_GAMEPAD_RIGHT_THUMB,
    'button 12': XINPUT_GAMEPAD_DPAD_UP,
    'button 13': XINPUT_GAMEPAD_DPAD_DOWN,
    'button 14': XINPUT_GAMEPAD_DPAD_LEFT,
    'button 15': XINPUT_GAMEPAD_DPAD_RIGHT,

    //windows
    'a': XINPUT_GAMEPAD_A,
    'b': XINPUT_GAMEPAD_B,
    'x': XINPUT_GAMEPAD_X,
    'y': XINPUT_GAMEPAD_Y,
    'leftShoulder': XINPUT_GAMEPAD_LEFT_SHOULDER,
    'rightShoulder': XINPUT_GAMEPAD_RIGHT_SHOULDER,
    'view': XINPUT_GAMEPAD_BACK,
    'menu': XINPUT_GAMEPAD_START,
    'leftThumbstick': XINPUT_GAMEPAD_LEFT_THUMB,
    'rightThumbstick': XINPUT_GAMEPAD_RIGHT_THUMB,
    'dpadUp': XINPUT_GAMEPAD_DPAD_UP,
    'dpadDown': XINPUT_GAMEPAD_DPAD_DOWN,
    'dpadLeft': XINPUT_GAMEPAD_DPAD_LEFT,
    'dpadRight': XINPUT_GAMEPAD_DPAD_RIGHT,

    //macos
    'a.circle': XINPUT_GAMEPAD_A,
    'b.circle': XINPUT_GAMEPAD_B,
    'x.circle': XINPUT_GAMEPAD_X,
    'y.circle': XINPUT_GAMEPAD_Y,
    'xmark.circle': XINPUT_GAMEPAD_A,
    'circle.circle': XINPUT_GAMEPAD_B,
    'square.circle': XINPUT_GAMEPAD_X,
    'triangle.circle': XINPUT_GAMEPAD_Y,
    'plus.rectangle': XINPUT_GAMEPAD_BACK,
    'capsule.portrait': XINPUT_GAMEPAD_START,
    'lb.rectangle.roundedbottom': XINPUT_GAMEPAD_LEFT_SHOULDER,
    'rb.rectangle.roundedbottom': XINPUT_GAMEPAD_RIGHT_SHOULDER,
    'rectangle.fill.on.rectangle.fill.circle': XINPUT_GAMEPAD_BACK,
    'line.horizontal.3.circle': XINPUT_GAMEPAD_START,
    'l.joystick.down': XINPUT_GAMEPAD_LEFT_THUMB,
    'r.joystick.press.down': XINPUT_GAMEPAD_RIGHT_THUMB,
    'dpad - xAxis': XINPUT_GAMEPAD_DPAD_LEFT,
    'dpad - yAxis': XINPUT_GAMEPAD_DPAD_UP,
    //ipad
    'r.joystick.down': XINPUT_GAMEPAD_RIGHT_THUMB,

    //Gamesir-X2
    'l1.rectangle.roundedbottom': XINPUT_GAMEPAD_LEFT_SHOULDER,
    'r1.rectangle.roundedbottom': XINPUT_GAMEPAD_RIGHT_SHOULDER,

    //SN30 pro
    "ellipsis.circle": XINPUT_GAMEPAD_BACK,

    //Android
    'KEYCODE_BUTTON_A': XINPUT_GAMEPAD_A,
    'KEYCODE_BUTTON_B': XINPUT_GAMEPAD_B,
    'KEYCODE_BUTTON_X': XINPUT_GAMEPAD_X,
    'KEYCODE_BUTTON_Y': XINPUT_GAMEPAD_Y,
    'KEYCODE_BUTTON_SELECT': XINPUT_GAMEPAD_BACK,
    'KEYCODE_BUTTON_START': XINPUT_GAMEPAD_START,
    'KEYCODE_BUTTON_THUMBL': XINPUT_GAMEPAD_LEFT_THUMB,
    'KEYCODE_BUTTON_THUMBR': XINPUT_GAMEPAD_RIGHT_THUMB,
    'KEYCODE_BUTTON_L1': XINPUT_GAMEPAD_LEFT_SHOULDER,
    'KEYCODE_BUTTON_R1': XINPUT_GAMEPAD_RIGHT_SHOULDER,
    'AXIS_HAT_X': XINPUT_GAMEPAD_DPAD_LEFT,
    'AXIS_HAT_Y': XINPUT_GAMEPAD_DPAD_UP,
    //'KEYCODE_BUTTON_MODE': 西瓜键
  };

  final Map<String, int> analogMapping = {
    //this is button for web (special case), but analog for desktop.
    //because it is conflict with XINPUT_GAMEPAD_DPAD_UP, we use the raw 'button 6|7'.
    'button 6': bLeftTrigger,
    'button 7': bRightTrigger,
    //web
    'analog 0': sThumbLX,
    'analog 1': sThumbLY,
    'analog 2': sThumbRX,
    'analog 3': sThumbRY,

    //windows
    'leftTrigger': bLeftTrigger,
    'rightTrigger': bRightTrigger,
    'leftThumbstickX': sThumbLX,
    'leftThumbstickY': sThumbLY,
    'rightThumbstickX': sThumbRX,
    'rightThumbstickY': sThumbRY,

    //macos
    'lt.rectangle.roundedtop': bLeftTrigger,
    'rt.rectangle.roundedtop': bRightTrigger,
    'l.joystick - xAxis': sThumbLX,
    'l.joystick - yAxis': sThumbLY,
    'r.joystick - xAxis': sThumbRX,
    'r.joystick - yAxis': sThumbRY,

    //Gamesir-X2
    'l2.rectangle.roundedtop': bLeftTrigger,
    'r2.rectangle.roundedtop': bRightTrigger,

    //Android
    'AXIS_Y': sThumbLY,
    'AXIS_X': sThumbLX,
    'AXIS_Z': sThumbRX,
    'AXIS_RZ': sThumbRY,
    'AXIS_BRAKE': bLeftTrigger,
    'AXIS_LTRIGGER': bLeftTrigger,
    'AXIS_GAS': bRightTrigger,
    'AXIS_RTRIGGER': bRightTrigger,
  };

  /// Updates the state based on the given event.
  bool update(GamepadEvent event) {
    switch (event.type) {
      case KeyType.analog:
        final mapped = analogMapping[event.key];
        if (mapped != null) {
          if (mapped == bLeftTrigger || mapped == bRightTrigger) {
            /*if (event.value < 0.05 && analogs[mapped] != 0) {
              analogs[mapped] = 0;
              return true;
            }*/
            int oldValue = analogs[mapped];
            // 防止触发太频繁，设置3% gap
            int newValue = (event.value * 255).toInt();
            if ((newValue - oldValue).abs() < 8) return false;
            analogs[mapped] = newValue;
          } else {
            //5% deadzone.
            /*if (event.value < 0.05 && analogs[mapped] != 0) {
              analogs[mapped] = 0;
              return true;
            }*/
            int oldValue = analogs[mapped];
            // 防止触发太频繁，设置3% gap
            int newValue = (event.value * 32767).toInt();
            if ((newValue - oldValue).abs() < 100) return false;
            analogs[mapped] = newValue;
            if (AppPlatform.isWeb &&
                (mapped == sThumbLY || mapped == sThumbRY)) {
              analogs[mapped] = -analogs[mapped];
            }
          }
        } else {
          // For Gamesir-X2 controller, buttons are reported as analogs.
          final mapped = buttonMapping[event.key];
          if (mapped != null) {
            if (AppPlatform.isMacos ||
                AppPlatform.isIOS ||
                AppPlatform.isAndroid) {
              if (mapped == XINPUT_GAMEPAD_DPAD_LEFT) {
                if (event.value == -1) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_LEFT] = true;
                } else if (event.value == 0) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_LEFT] = false;
                  buttonDown[XINPUT_GAMEPAD_DPAD_RIGHT] = false;
                } else if (event.value == 1) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_RIGHT] = true;
                }
              } else if (mapped == XINPUT_GAMEPAD_DPAD_UP) {
                if (event.value == 1) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_UP] = true;
                } else if (event.value == 0) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_UP] = false;
                  buttonDown[XINPUT_GAMEPAD_DPAD_DOWN] = false;
                } else if (event.value == -1) {
                  buttonDown[XINPUT_GAMEPAD_DPAD_DOWN] = true;
                }
              } else {
                buttonDown[mapped] = event.value != 0;
              }
            } else {
              buttonDown[mapped] = event.value != 0;
            }
          }
        }
        break;
      case KeyType.button:
        //special case for web.
        if (AppPlatform.isWeb &&
            (event.key == 'button 6' || event.key == 'button 7')) {
          final mapped = analogMapping[event.key];
          int newValue = (event.value * 255).toInt();
          int oldValue = analogs[mapped!];
          // 防止触发太频繁，设置3% gap
          if ((newValue - oldValue).abs() < 8) return false;
          analogs[mapped] = newValue;
          return true;
        }
        final mapped = buttonMapping[event.key];
        if (mapped != null) {
          if (AppPlatform.isMacos ||
              AppPlatform.isIOS ||
              AppPlatform.isAndroid) {
            if (mapped == XINPUT_GAMEPAD_DPAD_LEFT) {
              if (event.value == -1) {
                buttonDown[XINPUT_GAMEPAD_DPAD_LEFT] = true;
              } else if (event.value == 0) {
                buttonDown[XINPUT_GAMEPAD_DPAD_LEFT] = false;
                buttonDown[XINPUT_GAMEPAD_DPAD_RIGHT] = false;
              } else if (event.value == 1) {
                buttonDown[XINPUT_GAMEPAD_DPAD_RIGHT] = true;
              }
            } else if (mapped == XINPUT_GAMEPAD_DPAD_UP) {
              if (event.value == 1) {
                buttonDown[XINPUT_GAMEPAD_DPAD_UP] = true;
              } else if (event.value == 0) {
                buttonDown[XINPUT_GAMEPAD_DPAD_UP] = false;
                buttonDown[XINPUT_GAMEPAD_DPAD_DOWN] = false;
              } else if (event.value == -1) {
                buttonDown[XINPUT_GAMEPAD_DPAD_DOWN] = true;
              }
            } else {
              if (AppPlatform.isAndroid) {
                if (buttonDown[mapped] == (event.value == 0)) {
                  // no update. but android keeps triggering event.
                  return false;
                }
                buttonDown[mapped] = event.value == 0;
              } else {
                buttonDown[mapped] = event.value != 0;
              }
            }
          } else {
            buttonDown[mapped] = event.value != 0;
          }
        } else {
          // 8BitDo SN30 Pro
          final mapped = analogMapping[event.key];
          if (mapped != null) {
            if (mapped == bLeftTrigger || mapped == bRightTrigger) {
              int oldValue = analogs[mapped];
              // 防止触发太频繁，设置3% gap
              int newValue = (event.value * 255).toInt();
              if ((newValue - oldValue).abs() < 8) return false;
              analogs[mapped] = newValue;
            }
          }
        }
        break;
    }
    //TODO: 应该return false, 前面有update的分支return true，需要详细测试
    return true;
  }
}

class CGamepadController {
  static Map<String, CGamepadState> gamepadstates = {};
  static bool ignore_first = false;
  static List<GamepadController> gamepads = [];
  static void onEvent(GamepadEvent event) {
    CGamepadState state;
    if (!gamepadstates.containsKey(event.gamepadId)) {
      gamepadstates[event.gamepadId] = CGamepadState();
    }
    state = gamepadstates[event.gamepadId]!;
    if (state.update(event)) {
      if (AppPlatform.isAndroid || AppPlatform.isWindows) {
        int realId = 0;
        for (int i = 0; i < gamepads.length; i++) {
          if (gamepads[i].id == event.gamepadId) {
            realId = i;
            if (ignore_first && i > 0) {
              realId--;
            }
          }
        }
        WebrtcService.currentRenderingSession?.inputController
            ?.requestGamePadEvent(realId.toString(), state.getStateString());
      } else {
        WebrtcService.currentRenderingSession?.inputController
            ?.requestGamePadEvent(event.gamepadId, state.getStateString());
      }
    }
    //VLOG0(state.getStateString());
  }
}
