//render the global remote screen in an infinite vertical scroll view.
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_keyboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../../controller/hardware_input_controller.dart';
import '../../controller/platform_key_map.dart';
import '../../controller/screen_controller.dart';

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

  late Size widgetSize;
  RenderBox? renderBox;
  bool isCursorLocked = false;

  void onLockedCursorMoved(double dx, double dy) {
    print("dx:{$dx}dy:{$dy}");
    //有没有必要await？如果不保序的概率极低 感觉可以不await
    InputController.requestMoveMouseRelative(
        WebrtcService.currentRenderingSession!.channel,
        dx,
        dy,
        WebrtcService.currentRenderingSession!.screenId);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: ScreenController.showDetailUseScrollView,
        builder: (context, usescrollview, child) {
          if (!usescrollview) {
            return Stack(
              children: [
                Listener(
                  onPointerDown: (PointerDownEvent event) {
                    focusNode.requestFocus();
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    //TODO(Haichao):有没有必要在这里再更新一次鼠标位置？有没有可能onPointerHover报的位置不够新？
                    
                    int buttonId = 1;
                    if (event.buttons & kPrimaryMouseButton != 0){
                      buttonId = 1;
                    }else if (event.buttons & kSecondaryMouseButton != 0){
                      buttonId = 3;
                    }
                    InputController.requestMouseClick(
                        WebrtcService.currentRenderingSession!.channel,
                        buttonId,
                        true);
                    //HardwareSimulator.lockCursor();
                    //HardwareSimulator.addCursorMoved(onLockedCursorMoved);
                  },
                  onPointerUp: (PointerUpEvent event) {
                    if (renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    int buttonId = 1;
                    if (event.buttons & kPrimaryMouseButton != 0){
                      buttonId = 1;
                    }else if (event.buttons & kSecondaryMouseButton != 0){
                      buttonId = 3;
                    }
                    InputController.requestMouseClick(
                        WebrtcService.currentRenderingSession!.channel,
                        buttonId,
                        false);
                    //HardwareSimulator.unlockCursor();
                  },
                  onPointerMove: (PointerMoveEvent event) {
                    if (isCursorLocked ||
                        renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    final Offset localPosition =
                        renderBox!.globalToLocal(event.position);
                    final double xPercent =
                        (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                    final double yPercent =
                        (localPosition.dy / widgetSize.height).clamp(0.0, 1.0);
                    print(event.delta.distance);
                    InputController.requestMoveMouseAbsl(
                        WebrtcService.currentRenderingSession!.channel,
                        xPercent,
                        yPercent,
                        WebrtcService.currentRenderingSession!.screenId);
                  },
                  onPointerHover: (PointerHoverEvent event) {
                    if (isCursorLocked ||
                        renderBox == null ||
                        WebrtcService.currentRenderingSession == null) return;
                    final Offset localPosition =
                        renderBox!.globalToLocal(event.position);
                    final double xPercent =
                        (localPosition.dx / widgetSize.width).clamp(0.0, 1.0);
                    final double yPercent =
                        (localPosition.dy / widgetSize.height).clamp(0.0, 1.0);
                    InputController.requestMoveMouseAbsl(
                        WebrtcService.currentRenderingSession!.channel,
                        xPercent,
                        yPercent,
                        WebrtcService.currentRenderingSession!.screenId);
                  },
                  child: RawKeyboardListener(
                    focusNode: focusNode,
                    onKey: (event) {
                      if (event is RawKeyDownEvent) {
                        if (AppPlatform.isWeb) {
                          RawKeyEventDataWeb data =
                              event.data as RawKeyEventDataWeb;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              data.keyCode,
                              true);
                        } else if (AppPlatform.isWindows) {
                          RawKeyEventDataWindows data =
                              event.data as RawKeyEventDataWindows;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              data.keyCode,
                              true);
                        } else if (AppPlatform.isMacos) {
                          RawKeyEventDataMacOs data =
                              event.data as RawKeyEventDataMacOs;
                          int keyCode = macToWindowsKeyMap[data.keyCode]!;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              keyCode,
                              true);
                        }
                      } else if (event is RawKeyUpEvent) {
                        if (AppPlatform.isWeb) {
                          RawKeyEventDataWeb data =
                              event.data as RawKeyEventDataWeb;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              data.keyCode,
                              false);
                        } else if (AppPlatform.isWindows) {
                          RawKeyEventDataWindows data =
                              event.data as RawKeyEventDataWindows;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              data.keyCode,
                              false);
                        } else if (AppPlatform.isMacos) {
                          RawKeyEventDataMacOs data =
                              event.data as RawKeyEventDataMacOs;
                          int keyCode = macToWindowsKeyMap[data.keyCode]!;
                          InputController.requestKeyEvent(
                              WebrtcService.currentRenderingSession!.channel,
                              keyCode,
                              false);
                        }
                      }
                    },
                    child: kIsWeb
                        ? ValueListenableBuilder<double>(
                            valueListenable: aspectRatioNotifier, // 监听宽高比的变化
                            builder: (context, aspectRatio, child) {
                              return LayoutBuilder(builder:
                                  (BuildContext context,
                                      BoxConstraints constraints) {
                                print("------max height: {$constraints.maxHeight} aspectratio: {$aspectRatioNotifier.value}");
                                double realHeight = constraints.maxHeight;
                                double realWidth = constraints.maxWidth;
                                if (constraints.maxHeight *
                                        aspectRatioNotifier.value > constraints.maxWidth){
                                  realHeight = realWidth / aspectRatioNotifier.value;
                                }else{
                                  realWidth = realHeight * aspectRatioNotifier.value;
                                }
                                return SizedBox(
                                    width: realWidth,
                                    height: realHeight,
                                    child: RTCVideoView(
                                        WebrtcService.globalVideoRenderer!,
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
                                    }, onRenderBoxUpdated: (newRenderBox) {
                                      renderBox = newRenderBox;
                                      widgetSize = newRenderBox.size;
                                    }));
                              });
                            })
                        : RTCVideoView(WebrtcService.globalVideoRenderer!,
                            /*setAspectRatio: (AspectRatio) {
                      if(kIsWeb){
                        if (renderBox!=null){
                          double newheight = renderBox!.size.height;
                          double newwidth = renderBox!.size.width;
                          if (renderBox!.size.height * AspectRatio > renderBox!.size.width){
                            newheight = renderBox!.size.width/AspectRatio;
                          }else{

                          }
                        }
                      }
                    },*/
                            onRenderBoxUpdated: (newRenderBox) {
                            renderBox = newRenderBox;
                            widgetSize = newRenderBox.size;
                          }),
                  ),
                ),
                const OnScreenVirtualKeyboard(), // 放置在Stack中，独立于Listener和RawKeyboardListener
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
    if (isCursorLocked) {
      HardwareSimulator.unlockCursor();
      HardwareSimulator.removeCursorMoved(onLockedCursorMoved);
    }
    super.dispose();
  }
}
