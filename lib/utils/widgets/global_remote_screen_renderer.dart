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
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/virtual_gamepad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../controller/hardware_input_controller.dart';
import '../../controller/platform_key_map.dart';
import '../../controller/screen_controller.dart';
import 'cursor_change_widget.dart';
import 'virtual_gamepad/control_event.dart';

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
  bool _leftButtonDown = false;
  bool _rightButtonDown = false;
  bool _middleButtonDown = false;
  bool _backButtonDown = false;
  bool _forwardButtonDown = false;
  double _lastxPercent = 0;
  double _lastyPercent = 0;

  final Offset _virtualMousePosition = const Offset(100, 100);

  /*bool _hasAudio = false;

  void onAudioRenderStateChanged(bool has_audio) {
    if (_hasAudio != has_audio) {
      setState(() {
        _hasAudio = has_audio;
      });
    }
  }*/

  void onLockedCursorMoved(double dx, double dy) {
    print("dx:{$dx}dy:{$dy}");
    //有没有必要await？如果不保序的概率极低 感觉可以不await
    WebrtcService.currentRenderingSession?.inputController
        ?.requestMoveMouseRelative(
            dx, dy, WebrtcService.currentRenderingSession!.screenId);
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
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.onScroll = (dx, dy) {
      // 发送事件到远程桌面
      if (dx.abs() > 0 || dy.abs() > 0) {
        WebrtcService.currentRenderingSession?.inputController
            ?.requestMouseScroll(dx * 10, dy * 10);
      }
    };
    ControlManager().addEventListener(_handleControlEvent);
  }

  @override
  Widget build(BuildContext context) {
    // set the default focus to remote desktop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    if (event.kind == PointerDeviceKind.touch) {
                      _leftButtonDown = true;
                      final Offset localPosition =
                          renderBox!.globalToLocal(event.position);
                      final double xPercent =
                          (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                      final double yPercent =
                          (localPosition.dy / widgetSize.height)
                              .clamp(0.0, 1.0);
                      if (StreamingSettings.useTouchForTouch && WebrtcService.currentRenderingSession?.controlled.devicetype == 'Windows') {
                        _lastxPercent = xPercent;
                        _lastyPercent = yPercent;
                        WebrtcService.currentRenderingSession?.inputController?.requestTouchButton(
                          xPercent, yPercent, event.pointer % 9 + 1, true);
                      } else {
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMoveMouseAbsl(xPercent, yPercent,
                                WebrtcService.currentRenderingSession!.screenId);
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, _leftButtonDown);
                      }
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      _syncMouseButtonState(event);
                    }
                  },
                  onPointerUp: (PointerUpEvent event) {
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    if (event.kind == PointerDeviceKind.touch) {
                      _leftButtonDown = false;
                      if (StreamingSettings.useTouchForTouch && WebrtcService.currentRenderingSession?.controlled.devicetype == 'Windows') {
                        WebrtcService.currentRenderingSession?.inputController?.requestTouchButton(
                          _lastxPercent, _lastyPercent, event.pointer % 9 + 1, false);
                      } else {
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, _leftButtonDown);
                      }
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      if (AppPlatform.isIOS) {
                        _syncMouseButtonStateUP(event);
                      } else {
                        _syncMouseButtonState(event);
                      }
                    }
                  },
                  onPointerMove: (PointerMoveEvent event) {
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    _syncMouseButtonState(event);
                    if (InputController.isCursorLocked) return;
                    final Offset localPosition =
                        renderBox!.globalToLocal(event.position);
                    final double xPercent =
                        (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                    final double yPercent =
                        (localPosition.dy / widgetSize.height).clamp(0.0, 1.0);
                    
                    if (event.kind == PointerDeviceKind.touch) {
                      if (StreamingSettings.useTouchForTouch && WebrtcService.currentRenderingSession?.controlled.devicetype == 'Windows') {
                        _lastxPercent = xPercent;
                        _lastyPercent = yPercent;
                        WebrtcService.currentRenderingSession?.inputController?.requestTouchMove(
                          xPercent, yPercent, event.pointer % 9 + 1);
                      } else {
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMoveMouseAbsl(xPercent, yPercent,
                                WebrtcService.currentRenderingSession!.screenId);
                        WebrtcService.currentRenderingSession?.inputController
                            ?.requestMouseClick(1, _leftButtonDown);
                      }
                    }
                    else {
                      WebrtcService.currentRenderingSession?.inputController
                          ?.requestMoveMouseAbsl(xPercent, yPercent,
                              WebrtcService.currentRenderingSession!.screenId);
                    }
                  },
                  onPointerHover: (PointerHoverEvent event) {
                    if (InputController.isCursorLocked ||
                        renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    final Offset localPosition =
                        renderBox!.globalToLocal(event.position);
                    final double xPercent =
                        (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                    final double yPercent =
                        (localPosition.dy / widgetSize.height).clamp(0.0, 1.0);
                    WebrtcService.currentRenderingSession!.inputController
                        ?.requestMoveMouseAbsl(xPercent, yPercent,
                            WebrtcService.currentRenderingSession!.screenId);
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
                            if (event.physicalKey == PhysicalKeyboardKey.metaLeft) {
                              keyToSend = PhysicalKeyboardKey.controlLeft;
                            } else if (event.physicalKey == PhysicalKeyboardKey.controlLeft) {
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
                              onRenderBoxUpdated: (newRenderBox) {
                              parentBox =
                                  context.findRenderObject() as RenderBox;
                              renderBox = newRenderBox;
                              widgetSize = newRenderBox.size;
                            }),
                    ),
                  ),
                ),
                /*Text(
                  'You pressed: $_pressedKey',
                  style: TextStyle(fontSize: 24, color: Colors.red),
                ),*/
                BlocProvider(
                  create: (context) => MouseStyleBloc(),
                  child: const MouseStyleRegion(),
                ),
                /*_hasAudio
                    ? RTCVideoView(WebrtcService.globalAudioRenderer!)
                    : Container(),*/
                const OnScreenVirtualGamepad(),
                const OnScreenVirtualKeyboard(), // 放置在Stack中，独立于Listener和RawKeyboardListener,
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
    aspectRatioNotifier.dispose(); // 销毁时清理 ValueNotifier
    ControlManager().removeEventListener(_handleControlEvent);
    super.dispose();
  }
}
