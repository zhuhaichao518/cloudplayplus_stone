//render the global remote screen in an infinite vertical scroll view.
import 'package:flutter/material.dart';
import 'package:vk/vk.dart';

import '../../controller/screen_controller.dart';

class OnScreenVirtualKeyboard extends StatefulWidget {
  const OnScreenVirtualKeyboard({super.key});

  @override
  State<OnScreenVirtualKeyboard> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<OnScreenVirtualKeyboard> {
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVirtualKeyboard, // 监听键盘显示状态
      builder: (context, showKeyboard, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (!showKeyboard) return const SizedBox();
            bool isNumericMode = false;
            return Align(
              alignment: Alignment.bottomCenter, // 键盘始终居中下方
              child: Container(
                color: Colors.transparent,
                child: VirtualKeyboard(
                  keyBackgroundColor: Colors.grey,
                  height: 400,
                  type: isNumericMode
                      ? VirtualKeyboardType.Numeric
                      : VirtualKeyboardType.Alphanumeric,
                  textController: textController,
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
