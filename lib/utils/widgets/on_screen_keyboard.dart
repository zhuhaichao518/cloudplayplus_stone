//render the global remote screen in an infinite vertical scroll view.
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:flutter/material.dart';
import 'package:vk/vk.dart';

import '../../controller/screen_controller.dart';

class OnScreenVirtualKeyboard extends StatefulWidget {
  const OnScreenVirtualKeyboard({super.key});

  @override
  State<OnScreenVirtualKeyboard> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<OnScreenVirtualKeyboard> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVirtualKeyboard, // 监听键盘显示状态
      builder: (context, showKeyboard, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (!showKeyboard) return const SizedBox(); // 如果不显示键盘，返回空控件

            //目前设定的键盘长宽，待更新
            double originalWidth = 1000; // 键盘的原始宽度
            double originalHeight = 350; // 键盘的原始高度

            // 容器的最大宽度和高度
            double maxWidth = constraints.maxWidth;
            double maxHeight = constraints.maxHeight;

            // 计算适合的缩放比例
            double widthScale = maxWidth / originalWidth;
            double heightScale = maxHeight / originalHeight;

            // 选择最小的缩放比例，确保宽高都能适应容器
            double scale = widthScale < heightScale ? widthScale : heightScale;

            // 计算缩放后的宽度和高度
            double scaledWidth = originalWidth * scale;
            double scaledHeight = originalHeight * scale;

            return Align(
              alignment: Alignment.bottomCenter, // 键盘始终居中下方
              child: Container(
                width: scaledWidth,
                height: scaledHeight,
                color: Colors.transparent,
                child: VirtualKeyboard(
                  keyBackgroundColor: Colors.grey.withOpacity(0.5),
                  height: scaledHeight, // 将缩放后的高度传递给键盘
                  type: VirtualKeyboardType.Hardware, // 设置键盘类型
                  keyPressedCallback: (keyCode, isDown) {
                    WebrtcService.currentRenderingSession?.inputController
                        ?.requestKeyEvent(keyCode, isDown);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
