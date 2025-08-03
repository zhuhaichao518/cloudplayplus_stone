import 'dart:async';
import 'dart:math';
import 'package:cloudplayplus/utils/widgets/on_screen_remote_mouse.dart';

class SmoothMouseController {
  static const double _maxSpeed = 10.0; // 最大速度
  static const double _acceleration = 0.5; // 加速度
  static const Duration _updateInterval = Duration(milliseconds: 16); // 约60fps

  final OnScreenRemoteMouseController _mouseController;
  Timer? _updateTimer;
  
  // 当前速度
  double _currentSpeedX = 0.0;
  double _currentSpeedY = 0.0;
  
  // 按键状态
  bool _isUpPressed = false;
  bool _isDownPressed = false;
  bool _isLeftPressed = false;
  bool _isRightPressed = false;

  SmoothMouseController(this._mouseController);

  void dispose() {
    _updateTimer?.cancel();
  }

  // 处理方向键按下
  void onDirectionKeyDown(int keycode) {
    switch (keycode) {
      case 1019: // Up
        _isUpPressed = true;
        break;
      case 1020: // Down
        _isDownPressed = true;
        break;
      case 1021: // Left
        _isLeftPressed = true;
        break;
      case 1022: // Right
        _isRightPressed = true;
        break;
    }
    _startUpdateTimer();
  }

  // 处理方向键释放
  void onDirectionKeyUp(int keycode) {
    switch (keycode) {
      case 1019: // Up
        _isUpPressed = false;
        _currentSpeedY = 0.0; // 立即重置Y轴速度
        break;
      case 1020: // Down
        _isDownPressed = false;
        _currentSpeedY = 0.0; // 立即重置Y轴速度
        break;
      case 1021: // Left
        _isLeftPressed = false;
        _currentSpeedX = 0.0; // 立即重置X轴速度
        break;
      case 1022: // Right
        _isRightPressed = false;
        _currentSpeedX = 0.0; // 立即重置X轴速度
        break;
    }
    
    // 如果没有按键被按下，停止定时器
    if (!_isUpPressed && !_isDownPressed && !_isLeftPressed && !_isRightPressed) {
      _stopUpdateTimer();
    }
  }

  void _startUpdateTimer() {
    if (_updateTimer?.isActive == true) return;
    
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      _updateMouseMovement();
    });
  }

  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void _updateMouseMovement() {
    // 计算目标速度
    double targetSpeedX = 0.0;
    double targetSpeedY = 0.0;

    if (_isRightPressed) targetSpeedX += _maxSpeed;
    if (_isLeftPressed) targetSpeedX -= _maxSpeed;
    if (_isDownPressed) targetSpeedY += _maxSpeed;
    if (_isUpPressed) targetSpeedY -= _maxSpeed;

    // 平滑加速到目标速度
    if (targetSpeedX > _currentSpeedX) {
      _currentSpeedX = min(_currentSpeedX + _acceleration, targetSpeedX);
    } else if (targetSpeedX < _currentSpeedX) {
      _currentSpeedX = max(_currentSpeedX - _acceleration, targetSpeedX);
    }

    if (targetSpeedY > _currentSpeedY) {
      _currentSpeedY = min(_currentSpeedY + _acceleration, targetSpeedY);
    } else if (targetSpeedY < _currentSpeedY) {
      _currentSpeedY = max(_currentSpeedY - _acceleration, targetSpeedY);
    }

    // 应用移动
    if (_currentSpeedX.abs() > 0.1 || _currentSpeedY.abs() > 0.1) {
      _mouseController.moveDelta(_currentSpeedX, _currentSpeedY);
    }
  }

  // 重置所有状态
  void reset() {
    _isUpPressed = false;
    _isDownPressed = false;
    _isLeftPressed = false;
    _isRightPressed = false;
    _currentSpeedX = 0.0;
    _currentSpeedY = 0.0;
    _stopUpdateTimer();
  }
} 