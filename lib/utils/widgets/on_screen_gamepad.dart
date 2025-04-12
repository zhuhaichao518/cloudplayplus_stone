//render the global remote screen in an infinite vertical scroll view.
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:flutter/material.dart';
import 'package:vk/vk.dart';

import '../../controller/screen_controller.dart';
import 'virtual_gamepad/control_manager.dart';

class OnScreenVirtualGamepad extends StatefulWidget {
  const OnScreenVirtualGamepad({super.key});

  @override
  State<OnScreenVirtualGamepad> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<OnScreenVirtualGamepad> {
  final controlManager = ControlManager();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVirtualGamePad, // 监听键盘显示状态
      builder: (context, showVirtualGamePad, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (!showVirtualGamePad) return const SizedBox(); // 如果不显示键盘，返回空控件
              return Stack(
                children: controlManager.buildAllControls(
                context,
                screenWidth: constraints.maxWidth,
                screenHeight: constraints.maxHeight,
              )
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
