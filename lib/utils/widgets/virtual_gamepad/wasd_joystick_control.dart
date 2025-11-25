import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'control_base.dart';
import 'control_event.dart';
import 'dart:math';

// ============================================================================
// 常量定义
// ============================================================================
class WASDJoystickConstants {
  static const double thumbRadiusRatio = 0.2;
  static const double longPullThresholdRatio = 1.5; // 超过摇杆半径的1.5倍视为长拉
  static const double directionThresholdAngle = 22.5; // 度数，用于判断方向
}

// ============================================================================
// WASD 摇杆控制器
// ============================================================================
class WASDJoystickController {
  final ValueNotifier<Offset> offsetNotifier = ValueNotifier(Offset.zero);
  final Map<String, int> keyMapping; // 方向到按键码的映射
  final bool enableLongPull; // 是否启用长拉模式
  final int? sneakKeyCode; // 静步键按键码
  final int? sprintKeyCode; // 奔跑键按键码
  final double sneakThreshold; // 静步阈值（相对于摇杆半径的比例）
  final double sprintThreshold; // 奔跑阈值（相对于摇杆半径的比例）
  final bool enableArcadeMode; // 是否启用街机模式（双击模式）
  final double arcadeThreshold; // 街机模式阈值（相对于摇杆半径的比例）
  final void Function(ControlEvent) onEvent;
  
  Set<String> _pressedDirections = {}; // 当前按下的方向
  bool _isLongPulled = false; // 是否处于长拉状态
  bool _isSneakPressed = false; // 静步键是否按下
  bool _isSprintPressed = false; // 奔跑键是否按下
  bool _arcadeTriggered = false; // 街机模式是否已触发（避免重复触发）
  
  WASDJoystickController({
    required this.keyMapping,
    required this.enableLongPull,
    this.sneakKeyCode,
    this.sprintKeyCode,
    this.sneakThreshold = 0.3,
    this.sprintThreshold = 0.8,
    this.enableArcadeMode = false,
    this.arcadeThreshold = 0.5,
    required this.onEvent,
  });
  
  void updatePosition(Offset offset, double radius, Offset touchPosition) {
    offsetNotifier.value = offset;
    
    // 计算触摸点到中心的距离
    final distance = touchPosition.distance;
    // 计算距离相对于摇杆半径的比例
    final distanceRatio = distance / radius;
    
    // 检查是否进入长拉模式
    if (enableLongPull && distance > radius * WASDJoystickConstants.longPullThresholdRatio) {
      _isLongPulled = true;
    }
    
    // 处理静步键和奔跑键
    _updateSneakSprintKeys(distanceRatio);
    
    // 根据偏移量确定当前应该按下的方向
    final newDirections = _getDirectionsFromOffset(offset, radius);
    
    // 处理街机模式（双击模式）
    if (enableArcadeMode && distanceRatio > arcadeThreshold) {
      _handleArcadeMode(newDirections);
    }
    
    // 处理按键变化
    _updatePressedKeys(newDirections);
  }
  
  void _updateSneakSprintKeys(double distanceRatio) {
    // 处理静步键
    if (sneakKeyCode != null) {
      final shouldPressSneak = distanceRatio < sneakThreshold;
      if (shouldPressSneak != _isSneakPressed) {
        _isSneakPressed = shouldPressSneak;
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: sneakKeyCode!, isDown: _isSneakPressed),
        ));
      }
    }
    
    // 处理奔跑键
    if (sprintKeyCode != null) {
      final shouldPressSprint = distanceRatio > sprintThreshold;
      if (shouldPressSprint != _isSprintPressed) {
        _isSprintPressed = shouldPressSprint;
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: sprintKeyCode!, isDown: _isSprintPressed),
        ));
      }
    }
  }
  
  void _handleArcadeMode(Set<String> directions) {
    // 街机模式：当拖动超过阈值时，如果左或右方向键被按下，触发松开再按下一次
    final hasLeftOrRight = directions.contains('left') || directions.contains('right');
    
    if (hasLeftOrRight && !_arcadeTriggered) {
      _arcadeTriggered = true;
      
      // 找到左或右方向键
      final leftKeyCode = keyMapping['left'];
      final rightKeyCode = keyMapping['right'];
      
      // 如果左键被按下，触发松开再按下
      if (directions.contains('left') && leftKeyCode != null) {
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: leftKeyCode, isDown: false),
        ));
        // 短暂延迟后再次按下（使用Future.microtask模拟）
        Future.microtask(() {
          onEvent(ControlEvent(
            eventType: ControlEventType.keyboard,
            data: KeyboardEvent(keyCode: leftKeyCode, isDown: true),
          ));
        });
      }
      
      // 如果右键被按下，触发松开再按下
      if (directions.contains('right') && rightKeyCode != null) {
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: rightKeyCode, isDown: false),
        ));
        // 短暂延迟后再次按下
        Future.microtask(() {
          onEvent(ControlEvent(
            eventType: ControlEventType.keyboard,
            data: KeyboardEvent(keyCode: rightKeyCode, isDown: true),
          ));
        });
      }
    } else if (!hasLeftOrRight) {
      // 如果不再有左或右方向，重置触发标志
      _arcadeTriggered = false;
    }
  }
  
  void reset() {
    // 如果是长拉模式且已触发，不释放按键，也不重置摇杆位置
    if (_isLongPulled && enableLongPull) {
      // 保持按键按下状态和摇杆位置，不做任何操作
      return;
    }
    
    // 否则重置摇杆位置并释放所有按键
    offsetNotifier.value = Offset.zero;
    _releaseAllKeys();
    _releaseSneakSprintKeys();
    _arcadeTriggered = false;
  }
  
  void forceReset() {
    // 强制重置，释放所有按键并清除长拉状态
    offsetNotifier.value = Offset.zero;
    _isLongPulled = false;
    _releaseAllKeys();
    _releaseSneakSprintKeys();
    _arcadeTriggered = false;
  }
  
  void _releaseSneakSprintKeys() {
    // 释放静步键
    if (_isSneakPressed && sneakKeyCode != null) {
      _isSneakPressed = false;
      onEvent(ControlEvent(
        eventType: ControlEventType.keyboard,
        data: KeyboardEvent(keyCode: sneakKeyCode!, isDown: false),
      ));
    }
    
    // 释放奔跑键
    if (_isSprintPressed && sprintKeyCode != null) {
      _isSprintPressed = false;
      onEvent(ControlEvent(
        eventType: ControlEventType.keyboard,
        data: KeyboardEvent(keyCode: sprintKeyCode!, isDown: false),
      ));
    }
  }
  
  Set<String> _getDirectionsFromOffset(Offset offset, double radius) {
    final Set<String> directions = {};
    
    // 如果偏移量太小，认为在死区
    final threshold = radius * 0.3;
    if (offset.distance < threshold) {
      return directions;
    }
    
    // 计算角度 (0度是右，逆时针)
    final angle = (atan2(-offset.dy, offset.dx) * 180 / pi + 360) % 360;
    
    // 8方向判断
    // 右: 337.5 - 22.5
    if (angle >= 337.5 || angle < 22.5) {
      directions.add('right');
    }
    // 右上: 22.5 - 67.5
    else if (angle >= 22.5 && angle < 67.5) {
      directions.add('up');
      directions.add('right');
    }
    // 上: 67.5 - 112.5
    else if (angle >= 67.5 && angle < 112.5) {
      directions.add('up');
    }
    // 左上: 112.5 - 157.5
    else if (angle >= 112.5 && angle < 157.5) {
      directions.add('up');
      directions.add('left');
    }
    // 左: 157.5 - 202.5
    else if (angle >= 157.5 && angle < 202.5) {
      directions.add('left');
    }
    // 左下: 202.5 - 247.5
    else if (angle >= 202.5 && angle < 247.5) {
      directions.add('down');
      directions.add('left');
    }
    // 下: 247.5 - 292.5
    else if (angle >= 247.5 && angle < 292.5) {
      directions.add('down');
    }
    // 右下: 292.5 - 337.5
    else if (angle >= 292.5 && angle < 337.5) {
      directions.add('down');
      directions.add('right');
    }
    
    return directions;
  }
  
  void _updatePressedKeys(Set<String> newDirections) {
    // 找出需要释放的按键
    final toRelease = _pressedDirections.difference(newDirections);
    // 找出需要按下的按键
    final toPress = newDirections.difference(_pressedDirections);
    
    // 释放不再需要的按键
    for (final direction in toRelease) {
      final keyCode = keyMapping[direction];
      if (keyCode != null) {
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: keyCode, isDown: false),
        ));
      }
    }
    
    // 按下新的按键
    for (final direction in toPress) {
      final keyCode = keyMapping[direction];
      if (keyCode != null) {
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: keyCode, isDown: true),
        ));
      }
    }
    
    _pressedDirections = newDirections;
  }
  
  void _releaseAllKeys() {
    for (final direction in _pressedDirections) {
      final keyCode = keyMapping[direction];
      if (keyCode != null) {
        onEvent(ControlEvent(
          eventType: ControlEventType.keyboard,
          data: KeyboardEvent(keyCode: keyCode, isDown: false),
        ));
      }
    }
    _pressedDirections.clear();
  }
  
  void dispose() {
    _releaseAllKeys();
    _releaseSneakSprintKeys();
    offsetNotifier.dispose();
  }
}

// ============================================================================
// WASD 摇杆控件
// ============================================================================
class WASDJoystickControl extends ControlBase {
  final Map<String, int> keyMapping; // 方向到按键码的映射
  final bool enableLongPull; // 是否启用长拉模式
  final int? sneakKeyCode; // 静步键按键码
  final int? sprintKeyCode; // 奔跑键按键码
  final double sneakThreshold; // 静步阈值（相对于摇杆半径的比例）
  final double sprintThreshold; // 奔跑阈值（相对于摇杆半径的比例）
  final bool enableArcadeMode; // 是否启用街机模式（双击模式）
  final double arcadeThreshold; // 街机模式阈值（相对于摇杆半径的比例）

  WASDJoystickControl({
    required String id,
    required double centerX,
    required double centerY,
    required double size,
    required this.keyMapping,
    this.enableLongPull = false,
    this.sneakKeyCode,
    this.sprintKeyCode,
    this.sneakThreshold = 0.3,
    this.sprintThreshold = 0.8,
    this.enableArcadeMode = false,
    this.arcadeThreshold = 0.5,
    Color color = Colors.green,
    double opacity = 0.3,
  }) : super(
          id: id,
          centerX: centerX,
          centerY: centerY,
          size: size,
          type: 'wasdJoystick',
          color: color,
          opacity: opacity,
        );

  factory WASDJoystickControl.fromMap(Map<String, dynamic> map) {
    // 解析按键映射
    final keyMappingData = map['keyMapping'] as Map<String, dynamic>? ?? {};
    final keyMapping = keyMappingData.map(
      (key, value) => MapEntry(key, value as int),
    );
    
    return WASDJoystickControl(
      id: map['id'],
      centerX: map['centerX'],
      centerY: map['centerY'],
      size: map['size'],
      keyMapping: keyMapping,
      enableLongPull: map['enableLongPull'] ?? false,
      sneakKeyCode: map['sneakKeyCode'] as int?,
      sprintKeyCode: map['sprintKeyCode'] as int?,
      sneakThreshold: (map['sneakThreshold'] as num?)?.toDouble() ?? 0.3,
      sprintThreshold: (map['sprintThreshold'] as num?)?.toDouble() ?? 0.8,
      enableArcadeMode: map['enableArcadeMode'] ?? false,
      arcadeThreshold: (map['arcadeThreshold'] as num?)?.toDouble() ?? 0.5,
      color: Color(map['color'] as int? ?? Colors.green.value),
      opacity: map['opacity'] as double? ?? 0.3,
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
      'keyMapping': keyMapping,
      'enableLongPull': enableLongPull,
      'sneakKeyCode': sneakKeyCode,
      'sprintKeyCode': sprintKeyCode,
      'sneakThreshold': sneakThreshold,
      'sprintThreshold': sprintThreshold,
      'enableArcadeMode': enableArcadeMode,
      'arcadeThreshold': arcadeThreshold,
      'color': color.value,
      'opacity': opacity,
    };
  }

  @override
  Widget buildWidget(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required Function(ControlEvent) onEvent,
  }) {
    return _WASDJoystickWidget(
      control: this,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      onEvent: onEvent,
    );
  }

  @override
  void handleEvent(ControlEvent event) {
    // WASD摇杆事件处理
  }
}

// ============================================================================
// WASD 摇杆 Widget
// ============================================================================
class _WASDJoystickWidget extends StatefulWidget {
  final WASDJoystickControl control;
  final double screenWidth;
  final double screenHeight;
  final Function(ControlEvent) onEvent;

  const _WASDJoystickWidget({
    required this.control,
    required this.screenWidth,
    required this.screenHeight,
    required this.onEvent,
  });

  @override
  State<_WASDJoystickWidget> createState() => _WASDJoystickWidgetState();
}

class _WASDJoystickWidgetState extends State<_WASDJoystickWidget> {
  late WASDJoystickController _controller;
  late double _joystickRadius;
  late double _thumbRadius;
  late Offset _localCenter;
  Offset? _startGlobalPosition; // 记录开始拖动时的全局位置

  @override
  void initState() {
    super.initState();
    _controller = WASDJoystickController(
      keyMapping: widget.control.keyMapping,
      enableLongPull: widget.control.enableLongPull,
      sneakKeyCode: widget.control.sneakKeyCode,
      sprintKeyCode: widget.control.sprintKeyCode,
      sneakThreshold: widget.control.sneakThreshold,
      sprintThreshold: widget.control.sprintThreshold,
      enableArcadeMode: widget.control.enableArcadeMode,
      arcadeThreshold: widget.control.arcadeThreshold,
      onEvent: widget.onEvent,
    );
    _updateSizes();
  }

  @override
  void didUpdateWidget(_WASDJoystickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenWidth != widget.screenWidth ||
        oldWidget.screenHeight != widget.screenHeight ||
        oldWidget.control.size != widget.control.size) {
      _updateSizes();
    }
    // 如果配置发生变化，需要重新创建控制器
    if (oldWidget.control.keyMapping != widget.control.keyMapping ||
        oldWidget.control.enableLongPull != widget.control.enableLongPull ||
        oldWidget.control.sneakKeyCode != widget.control.sneakKeyCode ||
        oldWidget.control.sprintKeyCode != widget.control.sprintKeyCode ||
        oldWidget.control.sneakThreshold != widget.control.sneakThreshold ||
        oldWidget.control.sprintThreshold != widget.control.sprintThreshold ||
        oldWidget.control.enableArcadeMode != widget.control.enableArcadeMode ||
        oldWidget.control.arcadeThreshold != widget.control.arcadeThreshold) {
      _controller.dispose();
      _controller = WASDJoystickController(
        keyMapping: widget.control.keyMapping,
        enableLongPull: widget.control.enableLongPull,
        sneakKeyCode: widget.control.sneakKeyCode,
        sprintKeyCode: widget.control.sprintKeyCode,
        sneakThreshold: widget.control.sneakThreshold,
        sprintThreshold: widget.control.sprintThreshold,
        enableArcadeMode: widget.control.enableArcadeMode,
        arcadeThreshold: widget.control.arcadeThreshold,
        onEvent: widget.onEvent,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSizes() {
    _joystickRadius = widget.screenWidth * widget.control.size / 2;
    _thumbRadius = _joystickRadius * WASDJoystickConstants.thumbRadiusRatio;
    _localCenter = Offset(_joystickRadius, _joystickRadius);
  }

  Offset _constrainOffset(Offset offset) {
    final distance = offset.distance;
    if (distance > _joystickRadius) {
      return Offset(
        offset.dx * _joystickRadius / distance,
        offset.dy * _joystickRadius / distance,
      );
    }
    return offset;
  }

  void _handlePanStart(DragStartDetails details) {
    // 强制重置（释放长拉状态）
    _controller.forceReset();
    _startGlobalPosition = details.globalPosition;
    final offset = _constrainOffset(details.localPosition - _localCenter);
    _controller.updatePosition(
      offset,
      _joystickRadius,
      details.localPosition - _localCenter,
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final offset = _constrainOffset(details.localPosition - _localCenter);
    
    // 计算从初始位置到当前位置的实际距离
    final actualOffset = details.globalPosition - (_startGlobalPosition ?? details.globalPosition);
    
    _controller.updatePosition(
      offset,
      _joystickRadius,
      actualOffset,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    _startGlobalPosition = null;
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.screenWidth * widget.control.centerX - _joystickRadius,
      bottom: widget.screenHeight * (1 - widget.control.centerY) - _joystickRadius,
      child: RepaintBoundary(
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          /*onTapDown: (TapDownDetails details) {
            // 强制重置（释放长拉状态）
            _controller.forceReset();
          },*/
          child: Container(
            width: _joystickRadius * 2,
            height: _joystickRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.control.color.withOpacity(widget.control.opacity),
              border: Border.all(
                color: widget.control.color.withOpacity(widget.control.opacity * 2),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // 长拉阈值圆圈（如果启用了长拉模式）
                if (widget.control.enableLongPull)
                  Center(
                    child: Container(
                      width: _joystickRadius * 2 * WASDJoystickConstants.longPullThresholdRatio,
                      height: _joystickRadius * 2 * WASDJoystickConstants.longPullThresholdRatio,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.control.color.withOpacity(widget.control.opacity * 1.33),
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                    ),
                  ),
                // TODO: 方向指示器显示文字
                //_buildDirectionIndicators(),
                // 摇杆
                ValueListenableBuilder<Offset>(
                  valueListenable: _controller.offsetNotifier,
                  builder: (context, offset, child) {
                    return Center(
                      child: Transform.translate(
                        offset: offset,
                        child: Container(
                          width: _thumbRadius * 2,
                          height: _thumbRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.control.color.withOpacity(widget.control.opacity * 2.33),
                            border: Border.all(
                              color: Colors.white.withOpacity(widget.control.opacity * 2.67),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionIndicators() {
    // 计算标签的大小（基于摇杆半径）
    final labelSize = _joystickRadius * 0.35;
    final halfLabelSize = labelSize / 2;
    
    return Stack(
      children: [
        // 上
        Positioned(
          top: _joystickRadius * 0.15,
          left: _joystickRadius - halfLabelSize,
          child: _buildDirectionLabel('↑', labelSize),
        ),
        // 下
        Positioned(
          bottom: _joystickRadius * 0.15,
          left: _joystickRadius - halfLabelSize,
          child: _buildDirectionLabel('↓', labelSize),
        ),
        // 左
        Positioned(
          left: _joystickRadius * 0.15,
          top: _joystickRadius - halfLabelSize,
          child: _buildDirectionLabel('←', labelSize),
        ),
        // 右
        Positioned(
          right: _joystickRadius * 0.15,
          top: _joystickRadius - halfLabelSize,
          child: _buildDirectionLabel('→', labelSize),
        ),
      ],
    );
  }

  Widget _buildDirectionLabel(String label, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: widget.control.color.withOpacity(widget.control.opacity * 2.5),
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



