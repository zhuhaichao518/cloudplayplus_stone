import 'package:flutter/material.dart';
import 'gamepad_keys.dart';

class VirtualGamepad extends StatelessWidget {
  final Function(int keyCode, bool isDown) onKeyPressed;
  final double size;

  const VirtualGamepad({
    super.key,
    required this.onKeyPressed,
    this.size = 450,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size * 0.12;
    final spacing = size * 0.02;

    return SizedBox(
      width: size,
      height: size * 0.4,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: [
          // 方向键
          _buildButton('↑', GamepadKeys.DPAD_UP, buttonSize),
          _buildButton('↓', GamepadKeys.DPAD_DOWN, buttonSize),
          _buildButton('←', GamepadKeys.DPAD_LEFT, buttonSize),
          _buildButton('→', GamepadKeys.DPAD_RIGHT, buttonSize),

          // 功能键
          _buildButton('A', GamepadKeys.A, buttonSize),
          _buildButton('B', GamepadKeys.B, buttonSize),
          _buildButton('X', GamepadKeys.X, buttonSize),
          _buildButton('Y', GamepadKeys.Y, buttonSize),

          // 肩键和扳机键
          _buildButton('LB', GamepadKeys.LEFT_SHOULDER, buttonSize),
          _buildButton('RB', GamepadKeys.RIGHT_SHOULDER, buttonSize),
          _buildButton('LT', GamepadKeys.LEFT_TRIGGER, buttonSize),
          _buildButton('RT', GamepadKeys.RIGHT_TRIGGER, buttonSize),

          // 摇杆按钮
          _buildButton('LS', GamepadKeys.LEFT_STICK_BUTTON, buttonSize),
          _buildButton('RS', GamepadKeys.RIGHT_STICK_BUTTON, buttonSize),

          // 功能键
          _buildButton('ST', GamepadKeys.START, buttonSize),
          _buildButton('BK', GamepadKeys.BACK, buttonSize),
        ],
      ),
    );
  }

  Widget _buildButton(String label, int keyCode, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 2),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        onPressed: () {
          onKeyPressed(keyCode, true);
          Future.delayed(const Duration(milliseconds: 100), () {
            onKeyPressed(keyCode, false);
          });
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
