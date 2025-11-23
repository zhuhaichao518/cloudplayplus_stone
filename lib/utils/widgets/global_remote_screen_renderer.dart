//render the global remote screen in an infinite vertical scroll view.
import 'package:cloudplayplus/base/logging.dart';
import 'package:cloudplayplus/controller/gamepad_controller.dart';
import 'package:cloudplayplus/controller/smooth_scroll_controller.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_gamepad.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_keyboard.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_mouse.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/control_manager.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/gamepad_keys.dart';
import 'package:cloudplayplus/widgets/video_info_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../controller/hardware_input_controller.dart';
import '../../controller/platform_key_map.dart';
import '../../controller/screen_controller.dart';
import 'cursor_change_widget.dart';
import 'on_screen_remote_mouse.dart';
import 'virtual_gamepad/control_event.dart';

enum TwoFingerGestureType { undecided, zoom, scroll }

class GlobalRemoteScreenRenderer extends StatefulWidget {
  const GlobalRemoteScreenRenderer({super.key});

  @override
  State<GlobalRemoteScreenRenderer> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<GlobalRemoteScreenRenderer> {
  // 使用 ValueNotifier 来动态存储宽高比
  ValueNotifier<double> aspectRatioNotifier =
      ValueNotifier<double>(1.6); // 初始宽高比为 16:10

  final FocusNode focusNode = FocusNode();
  final _fsnode = FocusScopeNode();

  final SmoothScrollController _scrollController = SmoothScrollController();

  late Size widgetSize;
  RenderBox? renderBox;
  RenderBox? parentBox;
  MouseMode _mouseTouchMode = MouseMode.leftClick;
  MouseMode _lastTouchMode = MouseMode.leftClick;
  bool _leftButtonDown = false;
  bool _rightButtonDown = false;
  bool _middleButtonDown = false;
  bool _backButtonDown = false;
  bool _forwardButtonDown = false;
  double _lastxPercent = 0;
  double _lastyPercent = 0;

  bool _penDown = false;
  double _lastPenOrientation = 0.0;
  double _lastPenTilt = 0.0;

  final Offset _virtualMousePosition = const Offset(100, 100);
  
  Offset? _lastTouchpadPosition;
  Map<int, Offset> _touchpadPointers = {};
  double? _lastPinchDistance;
  double? _initialPinchDistance;
  Offset? _initialTwoFingerCenter;
  bool _isTwoFingerScrolling = false;
  
  double _videoScale = 1.0;
  Offset _videoOffset = Offset.zero;
  Offset? _pinchFocalPoint;
  TwoFingerGestureType _twoFingerGestureType = TwoFingerGestureType.undecided;

  /*bool _hasAudio = false;

  void onAudioRenderStateChanged(bool has_audio) {
    if (_hasAudio != has_audio) {
      setState(() {
        _hasAudio = has_audio;
      });
    }
  }*/

  void onLockedCursorMoved(double dx, double dy) {
    //print("dx:{$dx}dy:{$dy}");
    //有没有必要await？如果不保序的概率极低 感觉可以不await
    WebrtcService.currentRenderingSession?.inputController
        ?.requestMoveMouseRelative(
            dx, dy, WebrtcService.currentRenderingSession!.screenId);
  }

  ({double xPercent, double yPercent})? _calculatePositionPercent(Offset globalPosition) {
    if (renderBox == null) return null;
    Offset localPosition = renderBox!.globalToLocal(globalPosition);
    
    if (_videoScale != 1.0 || _videoOffset != Offset.zero) {
      Offset viewCenter = Offset(widgetSize.width / 2, widgetSize.height / 2);
      localPosition = viewCenter + (localPosition - viewCenter - _videoOffset) / _videoScale;
    }
    
    final double xPercent = (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
    final double yPercent = (localPosition.dy / widgetSize.height).clamp(0.0, 1.0);
    return (xPercent: xPercent, yPercent: yPercent);
  }

  TouchInputMode get _currentTouchInputMode {
    if (WebrtcService.currentRenderingSession?.controlled.devicetype != 'Windows') {
      return TouchInputMode.mouse;
    }
    return TouchInputMode.values[StreamingSettings.touchInputMode];
  }

  bool get _isUsingTouchMode => _currentTouchInputMode == TouchInputMode.touch;
  bool get _isUsingTouchpadMode => _currentTouchInputMode == TouchInputMode.touchpad;

  void _handleTouchDown(PointerDownEvent event) {
    final pos = _calculatePositionPercent(event.position);
    if (pos == null) return;

    if (_isUsingTouchMode) {
      _handleTouchModeDown(pos.xPercent, pos.yPercent, event.pointer % 9 + 1);
    } else if (_isUsingTouchpadMode) {
      _handleTouchpadDown(event);
    } else {
      _handleMouseModeDown(pos.xPercent, pos.yPercent);
    }
  }

  void _handleTouchUp(PointerUpEvent event) {
    if (_isUsingTouchMode) {
      _handleTouchModeUp(event.pointer % 9 + 1);
    } else if (_isUsingTouchpadMode) {
      _handleTouchpadUp(event);
    } else {
      _handleMouseModeUp();
    }
  }

  void _handleTouchMove(PointerMoveEvent event) {
    final pos = _calculatePositionPercent(event.position);
    if (pos == null) return;

    if (_isUsingTouchMode) {
      _handleTouchModeMove(pos.xPercent, pos.yPercent, event.pointer % 9 + 1);
    } else if (_isUsingTouchpadMode) {
      _handleTouchpadMove(event);
    } else {
      _handleMousePositionUpdate(event.position);
    }
  }

  void _handleTouchModeDown(double xPercent, double yPercent, int pointerId) {
    _leftButtonDown = true;
    _lastxPercent = xPercent;
    _lastyPercent = yPercent;
    WebrtcService.currentRenderingSession?.inputController
        ?.requestTouchButton(xPercent, yPercent, pointerId, true);
  }

  void _handleTouchModeUp(int pointerId) {
    _leftButtonDown = false;
    WebrtcService.currentRenderingSession?.inputController
        ?.requestTouchButton(_lastxPercent, _lastyPercent, pointerId, false);
  }

  void _handleTouchModeMove(double xPercent, double yPercent, int pointerId) {
    _lastxPercent = xPercent;
    _lastyPercent = yPercent;
    WebrtcService.currentRenderingSession?.inputController
        ?.requestTouchMove(xPercent, yPercent, pointerId);
  }

  void _handleMouseModeDown(double xPercent, double yPercent) {
    WebrtcService.currentRenderingSession?.inputController
        ?.requestMoveMouseAbsl(xPercent, yPercent,
            WebrtcService.currentRenderingSession!.screenId);
    
    if (_mouseTouchMode == MouseMode.leftClick) {
      _leftButtonDown = true;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(1, _leftButtonDown);
    } else if (_mouseTouchMode == MouseMode.rightClick) {
      _rightButtonDown = true;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(3, _rightButtonDown);
    }
  }

  void _handleTouchpadDown(PointerDownEvent event) {
    _touchpadPointers[event.pointer] = event.position;
    
    if (_touchpadPointers.length == 1) {
      _lastTouchpadPosition = event.position;
    } else if (_touchpadPointers.length == 2) {
      _lastTouchpadPosition = null;
      _lastPinchDistance = _calculatePinchDistance();
      
      List<Offset> positions = _touchpadPointers.values.toList();
      Offset center = Offset(
        (positions[0].dx + positions[1].dx) / 2,
        (positions[0].dy + positions[1].dy) / 2,
      );
      
      _initialTwoFingerCenter = center;
      _initialPinchDistance = _calculatePinchDistance();
      _lastPinchDistance = _initialPinchDistance;
      _lastTouchpadPosition = center;
      _pinchFocalPoint = center;
      _twoFingerGestureType = TwoFingerGestureType.undecided;
      
      _scrollController.startScroll();
      _isTwoFingerScrolling = true;
    }
  }

  void _handleTouchpadMove(PointerMoveEvent event) {
    _touchpadPointers[event.pointer] = event.position;
    
    if (_touchpadPointers.length == 1) {
      _handleSingleFingerMove(event);
    } else if (_touchpadPointers.length == 2) {
      _handleTwoFingerGesture(event);
    }
  }

  void _handleTouchpadUp(PointerEvent event) {
    _touchpadPointers.remove(event.pointer);
    
    if (_isTwoFingerScrolling && _touchpadPointers.length < 2) {
      _scrollController.startFling();
      _isTwoFingerScrolling = false;
    }
    
    if (_touchpadPointers.isEmpty) {
      _lastTouchpadPosition = null;
      _lastPinchDistance = null;
      _initialPinchDistance = null;
      _initialTwoFingerCenter = null;
      _pinchFocalPoint = null;
      _twoFingerGestureType = TwoFingerGestureType.undecided;
    } else if (_touchpadPointers.length == 1) {
      _lastTouchpadPosition = _touchpadPointers.values.first;
      _lastPinchDistance = null;
      _initialPinchDistance = null;
      _initialTwoFingerCenter = null;
      _pinchFocalPoint = null;
      _twoFingerGestureType = TwoFingerGestureType.undecided;
    }
  }

  void _handleSingleFingerMove(PointerMoveEvent event) {
    if (_lastTouchpadPosition == null) {
      _lastTouchpadPosition = event.position;
      return;
    }
    
    double deltaX = (event.position.dx - _lastTouchpadPosition!.dx) * StreamingSettings.touchpadSensitivity;
    double deltaY = (event.position.dy - _lastTouchpadPosition!.dy) * StreamingSettings.touchpadSensitivity;
    _lastTouchpadPosition = event.position;
    
    if (InputController.isCursorLocked) {
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMoveMouseRelative(deltaX * 10, deltaY * 10, 0);
    } else {
      InputController.mouseController.moveDelta(deltaX, deltaY);
    }
  }

  void _handleTwoFingerGesture(PointerMoveEvent event) {
    if (_touchpadPointers.length != 2) return;
    
    List<Offset> positions = _touchpadPointers.values.toList();
    Offset center = Offset(
      (positions[0].dx + positions[1].dx) / 2,
      (positions[0].dy + positions[1].dy) / 2,
    );
    _pinchFocalPoint = center;
    
    double currentDistance = _calculatePinchDistance();
    
    if (_lastTouchpadPosition != null && _lastPinchDistance != null && 
        _initialPinchDistance != null && _initialTwoFingerCenter != null) {
      
      if (_twoFingerGestureType == TwoFingerGestureType.undecided) {
        double cumulativeDistanceChangeRatio = 
          (currentDistance - _initialPinchDistance!).abs() / _initialPinchDistance!;
        double cumulativeCenterMovement = (center - _initialTwoFingerCenter!).distance;
        
        if (cumulativeDistanceChangeRatio > 1.3 || cumulativeDistanceChangeRatio < 0.7) {
          _twoFingerGestureType = TwoFingerGestureType.zoom;
        } else if (cumulativeCenterMovement > 15) {
          _twoFingerGestureType = TwoFingerGestureType.scroll;
        }
      }
      
      if (_twoFingerGestureType == TwoFingerGestureType.zoom) {
        _handlePinchZoom(currentDistance - _lastPinchDistance!);
      } else if (_twoFingerGestureType == TwoFingerGestureType.scroll) {
        double scrollDeltaX = center.dx - _lastTouchpadPosition!.dx;
        double scrollDeltaY = center.dy - _lastTouchpadPosition!.dy;
        _handleTwoFingerScroll(scrollDeltaX, scrollDeltaY);
      }
    }
    
    _lastTouchpadPosition = center;
    _lastPinchDistance = currentDistance;
  }

  double _calculatePinchDistance() {
    if (_touchpadPointers.length != 2) return 0.0;
    List<Offset> positions = _touchpadPointers.values.toList();
    return (positions[0] - positions[1]).distance;
  }

  void _handleTwoFingerScroll(double deltaX, double deltaY) {
    if (!StreamingSettings.touchpadTwoFingerScroll) return;
    _scrollController.doScroll(-deltaX, deltaY);
  }

  void _handlePinchZoom(double distanceDelta) {
    if (!StreamingSettings.touchpadTwoFingerZoom) return;
    if (_lastPinchDistance == null || _lastPinchDistance == 0) return;
    
    double currentDistance = _calculatePinchDistance();
    double scaleChange = currentDistance / _lastPinchDistance!;
    
    setState(() {
      double newScale = (_videoScale * scaleChange).clamp(1.0, 5.0);
      
      if (newScale == 1.0) {
        _videoScale = 1.0;
        _videoOffset = Offset.zero;
      } else if (_pinchFocalPoint != null && renderBox != null) {
        Offset localFocal = renderBox!.globalToLocal(_pinchFocalPoint!);
        Offset viewCenter = Offset(renderBox!.size.width / 2, renderBox!.size.height / 2);
        
        Offset videoPoint = viewCenter + (localFocal - viewCenter - _videoOffset) / _videoScale;
        _videoOffset = localFocal - viewCenter - (videoPoint - viewCenter) * newScale;
        _videoScale = newScale;
      } else {
        _videoScale = newScale;
      }
    });
  }

  void _handleMouseModeUp() {
    if (_mouseTouchMode == MouseMode.leftClick) {
      _leftButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(1, _leftButtonDown);
    } else if (_mouseTouchMode == MouseMode.rightClick) {
      _rightButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(3, _rightButtonDown);
    }
  }

  void _handleMousePositionUpdate(Offset globalPosition) {
    final pos = _calculatePositionPercent(globalPosition);
    if (pos == null) return;

    WebrtcService.currentRenderingSession?.inputController
        ?.requestMoveMouseAbsl(pos.xPercent, pos.yPercent,
            WebrtcService.currentRenderingSession!.screenId);
  }

  void _handleStylusDown(PointerDownEvent event) {
    final pos = _calculatePositionPercent(event.position);
    if (pos == null) return;

    _penDown = true;
    _lastPenOrientation = event.orientation;
    _lastPenTilt = event.tilt;

    bool hasButton = (event.buttons & kSecondaryMouseButton) != 0;

    WebrtcService.currentRenderingSession?.inputController?.requestPenEvent(
      pos.xPercent,
      pos.yPercent,
      true, // isDown
      hasButton,
      event.pressure,
      event.orientation * 180.0 / 3.14159,
      event.tilt * 180.0 / 3.14159,
    );
  }

  void _handleStylusUp(PointerUpEvent event) {
    final pos = _calculatePositionPercent(event.position);
    if (pos == null) return;

    _penDown = false;
    
    bool hasButton = (event.buttons & kSecondaryMouseButton) != 0;

    WebrtcService.currentRenderingSession?.inputController?.requestPenEvent(
      pos.xPercent,
      pos.yPercent,
      false, // isDown
      hasButton,
      0.0, // 抬起时压力为0
      _lastPenOrientation * 180.0 / 3.14159,
      _lastPenTilt * 180.0 / 3.14159,
    );
  }

  void _handleStylusMove(PointerMoveEvent event) {
    final pos = _calculatePositionPercent(event.position);
    if (pos == null) return;

    _lastPenOrientation = event.orientation;
    _lastPenTilt = event.tilt;

    bool hasButton = (event.buttons & kSecondaryMouseButton) != 0;

    if (_penDown) {
      WebrtcService.currentRenderingSession?.inputController?.requestPenMove(
        pos.xPercent,
        pos.yPercent,
        hasButton,
        event.pressure,
        event.orientation * 180.0 / 3.14159,
        event.tilt * 180.0 / 3.14159,
      );
    }
  }

  //Special case for ios mouse cursor.
  //IOS only specify the button id without other button infos.
  void _syncMouseButtonStateUP(PointerEvent event) {
    if (event.buttons & kPrimaryMouseButton != 0) {
      _leftButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(1, _leftButtonDown);
    }
    if (event.buttons & kSecondaryMouseButton != 0) {
      _rightButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(3, _rightButtonDown);
    }
    if (event.buttons == 0) {
      _middleButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(2, _middleButtonDown);
    }
    if (event.buttons & kMiddleMouseButton != 0) {
      _middleButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(2, _middleButtonDown);
    }
    if (event.buttons & kBackMouseButton != 0) {
      _backButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(4, _backButtonDown);
    }
    if (event.buttons & kForwardMouseButton != 0) {
      _forwardButtonDown = false;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(5, _forwardButtonDown);
    }
  }

  void _syncMouseButtonState(PointerEvent event) {
    if ((event.buttons & kPrimaryMouseButton != 0) != _leftButtonDown) {
      _leftButtonDown = !_leftButtonDown;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(1, _leftButtonDown);
    }
    if ((event.buttons & kSecondaryMouseButton != 0) != _rightButtonDown) {
      _rightButtonDown = !_rightButtonDown;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(3, _rightButtonDown);
    }
    //special case for ios
    if (AppPlatform.isIOS) {
      if ((event.buttons == 0) != _middleButtonDown) {
        _middleButtonDown = !_middleButtonDown;
        WebrtcService.currentRenderingSession?.inputController
            ?.requestMouseClick(2, _middleButtonDown);
      }
    }

    if ((event.buttons & kMiddleMouseButton != 0) != _middleButtonDown) {
      _middleButtonDown = !_middleButtonDown;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(2, _middleButtonDown);
    }
    if ((event.buttons & kBackMouseButton != 0) != _backButtonDown) {
      _backButtonDown = !_backButtonDown;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(4, _backButtonDown);
    }
    if ((event.buttons & kForwardMouseButton != 0) != _forwardButtonDown) {
      _forwardButtonDown = !_forwardButtonDown;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestMouseClick(5, _forwardButtonDown);
    }
  }

  CGamepadState gamepadState = CGamepadState();

  /*
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
  }*/

  static Map<int, int> gampadToCGamepad = {
    // 方向键
    GamepadKeys.DPAD_UP: CGamepadState.XINPUT_GAMEPAD_DPAD_UP,
    GamepadKeys.DPAD_DOWN: CGamepadState.XINPUT_GAMEPAD_DPAD_DOWN,
    GamepadKeys.DPAD_LEFT: CGamepadState.XINPUT_GAMEPAD_DPAD_LEFT,
    GamepadKeys.DPAD_RIGHT: CGamepadState.XINPUT_GAMEPAD_DPAD_RIGHT,

    // 开始和返回键
    GamepadKeys.START: CGamepadState.XINPUT_GAMEPAD_START,
    GamepadKeys.BACK: CGamepadState.XINPUT_GAMEPAD_BACK,

    // 摇杆按钮
    GamepadKeys.LEFT_STICK_BUTTON: CGamepadState.XINPUT_GAMEPAD_LEFT_THUMB,
    GamepadKeys.RIGHT_STICK_BUTTON: CGamepadState.XINPUT_GAMEPAD_RIGHT_THUMB,

    // 肩键
    GamepadKeys.LEFT_SHOULDER: CGamepadState.XINPUT_GAMEPAD_LEFT_SHOULDER,
    GamepadKeys.RIGHT_SHOULDER: CGamepadState.XINPUT_GAMEPAD_RIGHT_SHOULDER,

    // 功能键
    GamepadKeys.A: CGamepadState.XINPUT_GAMEPAD_A,
    GamepadKeys.B: CGamepadState.XINPUT_GAMEPAD_B,
    GamepadKeys.X: CGamepadState.XINPUT_GAMEPAD_X,
    GamepadKeys.Y: CGamepadState.XINPUT_GAMEPAD_Y,
  };

  void _handleControlEvent(ControlEvent event) {
    if (event.eventType == ControlEventType.keyboard) {
      final keyboardEvent = event.data as KeyboardEvent;
      WebrtcService.currentRenderingSession?.inputController
          ?.requestKeyEvent(keyboardEvent.keyCode, keyboardEvent.isDown);
    } else if (event.eventType == ControlEventType.gamepad) {
      if (event.data is GamepadAnalogEvent) {
        final analogEvent = event.data as GamepadAnalogEvent;
        if (analogEvent.key == GamepadKey.leftStickX) {
          gamepadState.analogs[CGamepadState.sThumbLX] =
              (analogEvent.value * 32767).toInt();
        } else if (analogEvent.key == GamepadKey.leftStickY) {
          gamepadState.analogs[CGamepadState.sThumbLY] =
              (analogEvent.value * 32767).toInt();
          WebrtcService.currentRenderingSession?.inputController
              ?.requestGamePadEvent("0", gamepadState.getStateString());
        } else if (analogEvent.key == GamepadKey.rightStickX) {
          gamepadState.analogs[CGamepadState.sThumbRX] =
              (analogEvent.value * 32767).toInt();
        } else if (analogEvent.key == GamepadKey.rightStickY) {
          gamepadState.analogs[CGamepadState.sThumbRY] =
              (analogEvent.value * 32767).toInt();
          WebrtcService.currentRenderingSession?.inputController
              ?.requestGamePadEvent("0", gamepadState.getStateString());
        }
      } else if (event.data is GamepadButtonEvent) {
        final buttonEvent = event.data as GamepadButtonEvent;
        if (buttonEvent.keyCode == GamepadKeys.LEFT_TRIGGER) {
          gamepadState.analogs[CGamepadState.bLeftTrigger] =
              buttonEvent.isDown ? 255 : 0;
        } else if (buttonEvent.keyCode == GamepadKeys.RIGHT_TRIGGER) {
          gamepadState.analogs[CGamepadState.bRightTrigger] =
              buttonEvent.isDown ? 255 : 0;
        } else {
          gamepadState.buttonDown[gampadToCGamepad[buttonEvent.keyCode]!] =
              buttonEvent.isDown;
        }
        WebrtcService.currentRenderingSession?.inputController
            ?.requestGamePadEvent("0", gamepadState.getStateString());
      }
    } else if (event.eventType == ControlEventType.mouseMode) {
      if (event.data is MouseModeEvent) {
        final mouseModeEvent = event.data as MouseModeEvent;
        if (mouseModeEvent.isUnique) {
          if (mouseModeEvent.isDown) {
            _lastTouchMode = _mouseTouchMode;
            _mouseTouchMode = mouseModeEvent.currentMode;
          } else {
            _mouseTouchMode = _lastTouchMode;
          }
        } else {
          if (mouseModeEvent.isDown) {
            _mouseTouchMode = mouseModeEvent.currentMode;
          }
        }
      }
    } else if (event.eventType == ControlEventType.mouseButton) {
      if (event.data is MouseButtonEvent) {
        final mouseButtonEvent = event.data as MouseButtonEvent;
        WebrtcService.currentRenderingSession?.inputController
            ?.requestMouseClick(mouseButtonEvent.buttonId, mouseButtonEvent.isDown);
      }
    } else if (event.eventType == ControlEventType.mouseMove) {
      if (event.data is MouseMoveEvent) {
        final mouseMoveEvent = event.data as MouseMoveEvent;
        if (mouseMoveEvent.isAbsolute) {
          // 绝对位置跳转
          WebrtcService.currentRenderingSession?.inputController
              ?.requestMoveMouseAbsl(mouseMoveEvent.deltaX, mouseMoveEvent.deltaY, WebrtcService.currentRenderingSession!.screenId);
        } else {
          // 相对移动
          double sensitivity = StreamingSettings.touchpadSensitivity * 10;
          WebrtcService.currentRenderingSession?.inputController
              ?.requestMoveMouseRelative(mouseMoveEvent.deltaX * sensitivity, mouseMoveEvent.deltaY * sensitivity, WebrtcService.currentRenderingSession!.screenId);
        }
      }
    }
  }

  static int initcount = 0;

  void _handleKeyBlocked(int keyCode, bool isDown) {
    WebrtcService.currentRenderingSession?.inputController
        ?.requestKeyEvent(keyCode, isDown);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.onScroll = (dx, dy) {
      if (dx.abs() > 0 || dy.abs() > 0) {
        WebrtcService.currentRenderingSession?.inputController
            ?.requestMouseScroll(dx * 10, dy * 10);
      }
    };
    ControlManager().addEventListener(_handleControlEvent);
    if (AppPlatform.isMobile) {
       HardwareSimulator.lockCursor();
    }
    WakelockPlus.enable();
    if (AppPlatform.isWindows) {
      HardwareSimulator.addKeyBlocked(_handleKeyBlocked);
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          HardwareSimulator.putImmersiveModeEnabled(true);
        } else {
          HardwareSimulator.putImmersiveModeEnabled(false);
        }
      });
    }
    initcount++;
  }

  void onHardwareCursorPositionUpdateRequested(double x, double y) {
    if (renderBox == null || parentBox == null) return;
    //print("onHardwareCursorPositionUpdateRequested: renderBox(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})");
    try {
      final screenSize = MediaQuery.of(context).size;

      final Offset globalPosition = renderBox!.localToGlobal(Offset(renderBox!.size.width * x, renderBox!.size.height * y));
      final double targetXInWindow = (globalPosition.dx / screenSize.width).clamp(0.0, 1.0);
      final double targetYInWindow = (globalPosition.dy / screenSize.height).clamp(0.0, 1.0);

      HardwareSimulator.mouse.performMouseMoveToWindowPosition(targetXInWindow, targetYInWindow);
      
      VLOG0("Hardware cursor position updated: renderBox(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}) -> window(${targetXInWindow.toStringAsFixed(3)}, ${targetYInWindow.toStringAsFixed(3)})");
    } catch (e) {
      VLOG0("Error updating hardware cursor position: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // set the default focus to remote desktop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppPlatform.isDeskTop) {
        InputController.cursorPositionCallback = onHardwareCursorPositionUpdateRequested;
      }
      focusNode.requestFocus();
    });
    /*WebrtcService.audioStateChanged = onAudioRenderStateChanged;*/
    return ValueListenableBuilder<bool>(
        valueListenable: ScreenController.showDetailUseScrollView,
        builder: (context, usescrollview, child) {
          if (!usescrollview) {
            return Stack(
              children: [
                Listener(
                  onPointerSignal: (PointerSignalEvent event) {
                    if (AppPlatform.isMobile) return;
                    if (event is PointerScrollEvent) {
                      //this does not work on macos for touch bar, works for web.
                      if (event.scrollDelta.dx.abs() > 0 ||
                          event.scrollDelta.dy.abs() > 0) {
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseScroll(
                                event.scrollDelta.dx, event.scrollDelta.dy);
                      }
                    }
                  },
                  onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
                    if (AppPlatform.isDeskTop) {
                      _scrollController.startScroll();
                    }
                  },
                  onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
                    if (AppPlatform.isDeskTop) {
                      _scrollController.doScroll(
                          event.panDelta.dx, event.panDelta.dy);
                    }
                  },
                  onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
                    if (AppPlatform.isDeskTop) {
                      _scrollController.startFling();
                    }
                  },
                  onPointerDown: (PointerDownEvent event) {
                    focusNode.requestFocus();
                    if (WebrtcService.currentRenderingSession == null) return;
                    
                    if (event.kind == PointerDeviceKind.touch) {
                      _handleTouchDown(event);
                    } else if (event.kind == PointerDeviceKind.stylus) {
                      _handleStylusDown(event);
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      // For IOS we use on_screen_remote_mouse_cursor.
                      if (AppPlatform.isMobile) return;
                      _syncMouseButtonState(event);
                    }
                  },
                  onPointerUp: (PointerUpEvent event) {
                    if (WebrtcService.currentRenderingSession == null) return;
                    
                    if (event.kind == PointerDeviceKind.touch) {
                      _handleTouchUp(event);
                    } else if (event.kind == PointerDeviceKind.stylus) {
                      _handleStylusUp(event);
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      if (AppPlatform.isMobile) {
                        //legacy impl for mouse on IOS. Used when user does not want on screen cursor.
                        _syncMouseButtonStateUP(event);
                      } else {
                        _syncMouseButtonState(event);
                      }
                    }
                  },
                  onPointerCancel: (PointerCancelEvent event) {
                    if (WebrtcService.currentRenderingSession == null) return;
                    
                    // 根据不同的输入设备类型，调用相应的 up 处理
                    if (event.kind == PointerDeviceKind.touch) {
                      if (_isUsingTouchMode) {
                        _handleTouchModeUp(event.pointer % 9 + 1);
                      } else if (_isUsingTouchpadMode) {
                        _handleTouchpadUp(event);
                      } else {
                        _handleMouseModeUp();
                      }
                    } else if (event.kind == PointerDeviceKind.stylus) {
                      // 手写笔取消时，发送笔抬起事件
                      final pos = _calculatePositionPercent(event.position);
                      if (pos != null) {
                        _penDown = false;
                        WebrtcService.currentRenderingSession?.inputController?.requestPenEvent(
                          pos.xPercent,
                          pos.yPercent,
                          false, // isDown
                          false, // hasButton
                          0.0, // 压力为0
                          _lastPenOrientation * 180.0 / 3.14159,
                          _lastPenTilt * 180.0 / 3.14159,
                        );
                      }
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      // 鼠标取消时，释放所有按钮
                      if (_leftButtonDown) {
                        _leftButtonDown = false;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, false);
                      }
                      if (_rightButtonDown) {
                        _rightButtonDown = false;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(3, false);
                      }
                      if (_middleButtonDown) {
                        _middleButtonDown = false;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(2, false);
                      }
                      if (_backButtonDown) {
                        _backButtonDown = false;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(4, false);
                      }
                      if (_forwardButtonDown) {
                        _forwardButtonDown = false;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(5, false);
                      }
                    }
                    
                    // 清理触控板状态
                    if (_isUsingTouchpadMode) {
                      _lastTouchpadPosition = null;
                    }
                  },
                  onPointerMove: (PointerMoveEvent event) {
                    if (WebrtcService.currentRenderingSession == null) return;
                    
                    if (_mouseTouchMode == MouseMode.leftClick && event.kind == PointerDeviceKind.mouse) {
                      _syncMouseButtonState(event);
                    }
                    
                    // When cursor is locked, we don't need to handle mouse move events here.
                    if (InputController.isCursorLocked && event.kind == PointerDeviceKind.mouse) return;

                    if (event.kind == PointerDeviceKind.touch) {
                      _handleTouchMove(event);
                    } else if (event.kind == PointerDeviceKind.stylus) {
                      _handleStylusMove(event);
                    } else {
                      if (AppPlatform.isMobile) return;
                      _handleMousePositionUpdate(event.position);
                    }
                  },
                  onPointerHover: (PointerHoverEvent event) {
                    if (AppPlatform.isMobile) return;
                    if (InputController.isCursorLocked || 
                        WebrtcService.currentRenderingSession == null) return;
                    
                    _handleMousePositionUpdate(event.position);
                  },
                  child: FocusScope(
                    node: _fsnode,
                    onKey: (data, event) {
                      return KeyEventResult.handled;
                    },
                    child: KeyboardListener(
                      focusNode: focusNode,
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent || event is KeyUpEvent) {
                          // For web, there is a bug where an unexpected keyup is
                          // triggered. https://github.com/flutter/engine/pull/17742/files
                          /*_pressedKey = event.logicalKey.keyLabel.isEmpty
                              ? event.logicalKey.debugName ?? 'Unknown'
                              : event.logicalKey.keyLabel;
                          if (event is KeyDownEvent) {
                            _pressedKey = _pressedKey + " Down";
                          } else if (event is KeyUpEvent) {
                            _pressedKey = _pressedKey + " Up";
                          }
                          print("${_pressedKey} at ${DateTime.now()}");*/
                          PhysicalKeyboardKey keyToSend = event.physicalKey;
                          if (StreamingSettings.switchCmdCtrl) {
                            if (event.physicalKey ==
                                PhysicalKeyboardKey.metaLeft) {
                              keyToSend = PhysicalKeyboardKey.controlLeft;
                            } else if (event.physicalKey ==
                                PhysicalKeyboardKey.controlLeft) {
                              keyToSend = PhysicalKeyboardKey.metaLeft;
                            }
                          }
                          WebrtcService.currentRenderingSession?.inputController
                              ?.requestKeyEvent(
                                  physicalToWindowsKeyMap[keyToSend],
                                  event is KeyDownEvent);
                        }
                      },
                      child: kIsWeb
                          ? ValueListenableBuilder<double>(
                              valueListenable: aspectRatioNotifier, // 监听宽高比的变化
                              builder: (context, aspectRatio, child) {
                                return LayoutBuilder(builder:
                                    (BuildContext context,
                                        BoxConstraints constraints) {
                                  VLOG0(
                                      "------max height: {$constraints.maxHeight} aspectratio: {$aspectRatioNotifier.value}");
                                  double realHeight = constraints.maxHeight;
                                  double realWidth = constraints.maxWidth;
                                  if (constraints.maxHeight *
                                          aspectRatioNotifier.value >
                                      constraints.maxWidth) {
                                    realHeight =
                                        realWidth / aspectRatioNotifier.value;
                                  } else {
                                    realWidth =
                                        realHeight * aspectRatioNotifier.value;
                                  }
                                  return Center(
                                      child: SizedBox(
                                          width: realWidth,
                                          height: realHeight,
                                          child: RTCVideoView(
                                              WebrtcService
                                                  .globalVideoRenderer!,
                                              setAspectRatio: (newAspectRatio) {
                                            // 延迟更新 aspectRatio，避免在构建过程中触发 setState
                                            if (newAspectRatio.isNaN) return;
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (aspectRatioNotifier.value ==
                                                  newAspectRatio) {
                                                return;
                                              }
                                              aspectRatioNotifier.value =
                                                  newAspectRatio;
                                            });
                                          }, onRenderBoxUpdated:
                                                  (newRenderBox) {
                                            parentBox =
                                                context.findRenderObject()
                                                    as RenderBox;
                                            renderBox = newRenderBox;
                                            widgetSize = newRenderBox.size;
                                          })));
                                });
                              })
                          : RTCVideoView(WebrtcService.globalVideoRenderer!,
                              scale: _videoScale,
                              offset: _videoOffset,
                              onRenderBoxUpdated: (newRenderBox) {
                              parentBox =
                                  context.findRenderObject() as RenderBox;
                              renderBox = newRenderBox;
                              widgetSize = newRenderBox.size;
                            },
                            setAspectRatio: (newAspectRatio) {
                              if (AppPlatform.isMobile) {
                                InputController.mouseController.setAspectRatio(newAspectRatio);
                              }
                            },
                            ),
                    ),
                  ),
                ),
                /*Text(
                  'You pressed: $_pressedKey',
                  style: TextStyle(fontSize: 24, color: Colors.red),
                ),*/
                if ((AppPlatform.isAndroidTV) || (AppPlatform.isMobile /*&& AppStateService.isMouseConnected*/))
                  OnScreenRemoteMouse(
                  controller: InputController.mouseController,
                  onPositionChanged: (percentage) {
                    double xPercent = percentage.dx;
                    double yPercent = percentage.dy;
                    
                    if (_videoScale != 1.0 || _videoOffset != Offset.zero) {
                      Offset screenPosition = Offset(
                        percentage.dx * widgetSize.width,
                        percentage.dy * widgetSize.height,
                      );
                      
                      Offset viewCenter = Offset(widgetSize.width / 2, widgetSize.height / 2);
                      Offset videoPosition = viewCenter + (screenPosition - viewCenter - _videoOffset) / _videoScale;
                      
                      xPercent = (videoPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                      yPercent = (videoPosition.dy / widgetSize.height).clamp(0.0, 1.0);
                    }
                    
                    WebrtcService.currentRenderingSession?.inputController
                      ?.requestMoveMouseAbsl(
                          xPercent,
                          yPercent,
                          WebrtcService
                              .currentRenderingSession!.screenId);
                  },
                ),
                BlocProvider(
                  create: (context) => MouseStyleBloc(),
                  child: const MouseStyleRegion(),
                ),
                /*_hasAudio
                    ? RTCVideoView(WebrtcService.globalAudioRenderer!)
                    : Container(),*/
                const OnScreenVirtualGamepad(),
                const OnScreenVirtualKeyboard(), // 放置在Stack中，独立于Listener和RawKeyboardListener,
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Center(
                      child: VideoInfoWidget(),
                    ),
                  ),
                ),
                OnScreenVirtualMouse(
                    initialPosition: _virtualMousePosition,
                    onPositionChanged: (pos) {
                      if (renderBox == null || parentBox == null) return;
                      /*final Offset globalPosition =
                        parentBox.localToGlobal(Offset.zero);*/
                      final Offset globalPosition =
                          parentBox!.localToGlobal(pos);
                      final Offset localPosition =
                          renderBox!.globalToLocal(globalPosition);
                      final double xPercent =
                          (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                      final double yPercent =
                          (localPosition.dy / widgetSize.height)
                              .clamp(0.0, 1.0);
                      VLOG0("dx:{$xPercent},dy{$yPercent},");
                      WebrtcService.currentRenderingSession!.inputController
                          ?.requestMoveMouseAbsl(xPercent, yPercent,
                              WebrtcService.currentRenderingSession!.screenId);
                    },
                    onLeftPressed: () {
                      if (_leftButtonDown == false) {
                        _leftButtonDown = !_leftButtonDown;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, _leftButtonDown);
                      }
                    },
                    onLeftReleased: () {
                      if (_leftButtonDown == true) {
                        _leftButtonDown = !_leftButtonDown;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, _leftButtonDown);
                      }
                    },
                    onRightPressed: () {
                      if (_rightButtonDown == false) {
                        _rightButtonDown = !_rightButtonDown;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(3, _rightButtonDown);
                      }
                    },
                    onRightReleased: () {
                      if (_rightButtonDown == true) {
                        _rightButtonDown = !_rightButtonDown;
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(3, _rightButtonDown);
                      }
                    }),
              ],
            );
          }
          return const SizedBox.shrink();
          // We need to calculate and define the size if we want to show the remote screen in a scroll view.
          // Keep this code just to make user able to scroll the content in the future.
          return ValueListenableBuilder<double>(
            valueListenable: aspectRatioNotifier, // 监听宽高比的变化
            builder: (context, aspectRatio, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double videoWidth = constraints.maxWidth;
                  double videoHeight = 0;
                  if (ScreenController.videoRendererExpandToWidth) {
                    videoHeight = videoWidth / aspectRatio;
                  } else {
                    videoHeight = MediaQuery.of(context).size.height;
                    if (ScreenController.showBottomNav.value) {
                      //I don't know why it is 2 from default height.
                      videoHeight -= ScreenController.bottomNavHeight + 2;
                    }
                  }
                  return SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: Stack(children: [
                      RTCVideoView(WebrtcService.globalVideoRenderer!,
                          setAspectRatio: (newAspectRatio) {
                        // 延迟更新 aspectRatio，避免在构建过程中触发 setState
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (aspectRatioNotifier.value == newAspectRatio ||
                              !ScreenController.videoRendererExpandToWidth) {
                            return;
                          }
                          aspectRatioNotifier.value = newAspectRatio;
                        });
                      }),
                      // We put keyboard here to aviod calculate the videoHeight again.
                      const OnScreenVirtualKeyboard(),
                    ]),
                  );
                },
              );
            },
          );
        });
  }

  @override
  void dispose() {
    focusNode.dispose();
    if (AppPlatform.isWindows) {
      HardwareSimulator.putImmersiveModeEnabled(false);
      HardwareSimulator.removeKeyBlocked(_handleKeyBlocked);
      InputController.cursorPositionCallback = null;
    }
    _scrollController.dispose(); // 清理滚动控制器资源
    aspectRatioNotifier.dispose(); // 销毁时清理 ValueNotifier
    ControlManager().removeEventListener(_handleControlEvent);

    initcount --;
    //The globalRemoteScreenRenderer is inited twice in a session and the dispose
    //of the first one is after the init of second one.
    //So for singleton scenarios only do it when initcount == 0.
    if (initcount == 0) {
      WakelockPlus.disable();
      if (AppPlatform.isMobile) {
        HardwareSimulator.unlockCursor();
      }
    }
    super.dispose();
  }
}
