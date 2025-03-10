//render the global remote screen in an infinite vertical scroll view.
import 'package:cloudplayplus/base/logging.dart';
import 'package:cloudplayplus/controller/smooth_scroll_controller.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_keyboard.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_mouse.dart';
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
                      WebrtcService.currentRenderingSession?.inputController
                          ?.requestMoveMouseAbsl(xPercent, yPercent,
                              WebrtcService.currentRenderingSession!.screenId);
                      WebrtcService.currentRenderingSession?.inputController
                          ?.requestMouseClick(1, _leftButtonDown);
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      _syncMouseButtonState(event);
                    }
                  },
                  onPointerUp: (PointerUpEvent event) {
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    if (event.kind == PointerDeviceKind.touch) {
                      _leftButtonDown = false;
                      WebrtcService.currentRenderingSession?.inputController
                          ?.requestMouseClick(1, _leftButtonDown);
                    } else if (event.kind == PointerDeviceKind.mouse) {
                      _syncMouseButtonState(event);
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
                    WebrtcService.currentRenderingSession?.inputController
                        ?.requestMoveMouseAbsl(xPercent, yPercent,
                            WebrtcService.currentRenderingSession!.screenId);
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
                          WebrtcService.currentRenderingSession?.inputController
                              ?.requestKeyEvent(
                                  physicalToWindowsKeyMap[event.physicalKey],
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
    super.dispose();
  }
}
