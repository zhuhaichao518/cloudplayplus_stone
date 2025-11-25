import 'package:flutter/material.dart';
import 'control_base.dart';
import 'control_event.dart';

enum ButtonShape {
  circle,
  square,
}

class ButtonControl extends ControlBase {
  final String label;
  final int keyCode; // 按键码
  final bool isGamepadButton; // 是否是手柄按钮
  final bool isMouseButton; // 是否是鼠标按钮
  final ButtonShape shape; // 按钮形状
  final bool isFpsFireButton; // 是否是FPS开火按键（按下后手指移动会触发鼠标移动事件）
  final bool isToggleMode; // 是否是切换模式（按下时按下，再按一次松开）

  ButtonControl({
    required super.id,
    required super.centerX,
    required super.centerY,
    required super.size,
    required this.label,
    required this.keyCode,
    super.color = Colors.blue,
    super.opacity = 0.4,
    this.isGamepadButton = false, // 默认为键盘按钮
    this.isMouseButton = false, // 默认为非鼠标按钮
    this.shape = ButtonShape.circle, // 默认为圆形
    this.isFpsFireButton = false, // 默认不是FPS开火按键
    this.isToggleMode = false, // 默认为按下松开模式
  }) : super(
          type: 'button',
        );

  factory ButtonControl.fromMap(Map<String, dynamic> map) {
    return ButtonControl(
      id: map['id'],
      centerX: map['centerX'],
      centerY: map['centerY'],
      size: map['size'],
      label: map['label'] ?? 'Button',
      keyCode: map['keyCode'] ?? 0,
      color: Color(map['color'] ?? Colors.blue.value),
      opacity: map['opacity'] as double? ?? 0.4,
      isGamepadButton: map['isGamepadButton'] ?? false,
      isMouseButton: map['isMouseButton'] ?? false,
      shape: map['shape'] == 'square' ? ButtonShape.square : ButtonShape.circle,
      isFpsFireButton: map['isFpsFireButton'] ?? false,
      isToggleMode: map['isToggleMode'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'centerX': centerX,
      'centerY': centerY,
      'size': size,
      'label': label,
      'keyCode': keyCode,
      'color': color.value,
      'opacity': opacity,
      'isGamepadButton': isGamepadButton,
      'isMouseButton': isMouseButton,
      'shape': shape == ButtonShape.square ? 'square' : 'circle',
      'isFpsFireButton': isFpsFireButton,
      'isToggleMode': isToggleMode,
    };
  }

  @override
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  }) {
    return _ButtonWidget(
      control: this,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      onEvent: onEvent,
      isGamepadButton: isGamepadButton,
      isMouseButton: isMouseButton,
      isFpsFireButton: isFpsFireButton,
      isToggleMode: isToggleMode,
    );
  }

  @override
  void handleEvent(ControlEvent event) {
    // 按钮事件处理
  }
}

class _ButtonWidget extends StatefulWidget {
  final ButtonControl control;
  final double screenWidth;
  final double screenHeight;
  final Function(ControlEvent) onEvent;
  final bool isGamepadButton;
  final bool isMouseButton;
  final bool isFpsFireButton;
  final bool isToggleMode;

  const _ButtonWidget({
    required this.control,
    required this.screenWidth,
    required this.screenHeight,
    required this.onEvent,
    required this.isGamepadButton,
    required this.isMouseButton,
    required this.isFpsFireButton,
    required this.isToggleMode,
  });

  @override
  State<_ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<_ButtonWidget> {
  bool _isPressed = false; // UI显示状态
  bool _isKeyDown = false; // 实际按键状态（用于切换模式）
  Offset? _lastPosition; // 记录上一次的位置，用于FPS开火按键的移动事件
  double _moveSensitivity = 1.0; // FPS开火按键的移动灵敏度

  void _handleDown(Offset position) {
    // 如果是切换模式
    if (widget.isToggleMode) {
      // 切换按键状态
      _isKeyDown = !_isKeyDown;
      setState(() => _isPressed = _isKeyDown);
      
      // 发送对应的按键事件
      _sendKeyEvent(_isKeyDown);
    } else {
      // 普通模式：按下时发送按下事件
      setState(() => _isPressed = true);
      _isKeyDown = true;
      _sendKeyEvent(true);
    }
    
    // 如果是FPS开火按键，记录初始位置
    if (widget.isFpsFireButton) {
      _lastPosition = position;
    }
  }

  void _sendKeyEvent(bool isDown) {
    if (widget.isMouseButton) {
      widget.onEvent(ControlEvent(
        eventType: ControlEventType.mouseButton,
        data: MouseButtonEvent(
          buttonId: widget.control.keyCode,
          isDown: isDown,
        ),
      ));
    } else if (widget.isGamepadButton) {
      widget.onEvent(ControlEvent(
        eventType: ControlEventType.gamepad,
        data: GamepadButtonEvent(
          keyCode: widget.control.keyCode,
          isDown: isDown,
        ),
      ));
    } else {
      widget.onEvent(ControlEvent(
        eventType: ControlEventType.keyboard,
        data: KeyboardEvent(
          keyCode: widget.control.keyCode,
          isDown: isDown,
        ),
      ));
    }
  }

  void _handleMove(Offset position) {
    // 只有当按键按下且是FPS开火按键时才处理移动
    if (!_isPressed || !widget.isFpsFireButton || _lastPosition == null) {
      return;
    }

    // 计算位移增量
    final deltaX = (position.dx - _lastPosition!.dx) * _moveSensitivity;
    final deltaY = (position.dy - _lastPosition!.dy) * _moveSensitivity;

    // 只有当移动距离足够大时才触发事件（避免过于灵敏）
    if (deltaX.abs() > 0.5 || deltaY.abs() > 0.5) {
      widget.onEvent(ControlEvent(
        eventType: ControlEventType.mouseMove,
        data: MouseMoveEvent(
          deltaX: deltaX,
          deltaY: deltaY,
          isAbsolute: false,
        ),
      ));

      // 更新最后位置
      _lastPosition = position;
    }
  }

  void _handleUp() {
    // 如果是切换模式，松开时只更新UI显示，不发送事件
    if (widget.isToggleMode) {
      // 切换模式下，松开时只更新UI显示（如果当前是按下状态，保持按下显示）
      setState(() => _isPressed = _isKeyDown);
    } else {
      // 普通模式：松开时发送松开事件
      setState(() {
        _isPressed = false;
        _isKeyDown = false;
      });
      _sendKeyEvent(false);
    }
    
    _lastPosition = null; // 清除位置记录
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.screenWidth * widget.control.size;

    return Positioned(
      left: widget.screenWidth * widget.control.centerX - diameter / 2,
      bottom: widget.screenHeight * (1 - widget.control.centerY) - diameter / 2,
      child: Listener(
        onPointerDown: (event) => _handleDown(event.localPosition),
        onPointerMove: (event) => _handleMove(event.localPosition),
        onPointerUp: (_) => _handleUp(),
        onPointerCancel: (_) => _handleUp(),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: widget.control.color.withOpacity(_isPressed ? widget.control.opacity * 1.75 : widget.control.opacity),
            borderRadius: widget.control.shape == ButtonShape.circle 
                ? BorderRadius.circular(diameter / 2)
                : BorderRadius.circular(diameter * 0.1), // 方形时使用较小的圆角
            border: widget.isToggleMode && _isKeyDown
                ? Border.all(color: Colors.white, width: 2)
                : null, // 切换模式下，如果按键处于按下状态，显示边框
          ),
          child: Center(
            child: Text(
              widget.control.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: diameter * 0.3,
                fontWeight: widget.isFpsFireButton ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
