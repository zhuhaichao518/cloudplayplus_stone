//It is not a controller but it is named a 'controller', so I put it here. :)
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

class SmoothScrollController {
  void Function(double dx, double dy)? onScroll;
  Ticker? _ticker;
  FrictionSimulation? _simulationX;
  FrictionSimulation? _simulationY;
  double _lastTime = 0;

  late DateTime _scrollStartTime;
  int accumulatedx = 0;
  int accumulatedy = 0;

  void startScroll() {
    _stopFling(); // 停止惯性滚动
    accumulatedx = 0;
    accumulatedy = 0;
    _scrollStartTime = DateTime.now();
  }

  void doScroll(double dx, double dy) {
    if (dx.abs() < 2) dx = 0;
    if (dy.abs() < 1) dy = 0;
    if (dy.abs() < 2) dy = dy / 2;
    accumulatedx += dx.toInt();
    accumulatedy += dy.toInt();
    onScroll?.call(dx / 2, dy);
  }

  void startFling() {
    Duration difference = DateTime.now().difference(_scrollStartTime);
    double elapsedSeconds = difference.inMilliseconds / 1000.0;

    if (elapsedSeconds == 0) return;

    double velocityX = accumulatedx / elapsedSeconds;
    double velocityY = accumulatedy / elapsedSeconds;

    if (velocityX.abs() < 50 && velocityY.abs() < 50) return;

    _simulationX = FrictionSimulation(0.0005, 0, velocityX);
    _simulationY = FrictionSimulation(0.0005, 0, velocityY);

    _lastTime = 0;
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    final double t = elapsed.inMilliseconds / 1000.0;

    if (_lastTime == 0) {
      _lastTime = t;
      return;
    }

    if (_simulationX == null || _simulationY == null) return;

    final double deltaX = _simulationX!.x(t) - _simulationX!.x(_lastTime);
    final double deltaY = _simulationY!.x(t) - _simulationY!.x(_lastTime);

    _lastTime = t;

    if (_simulationX!.isDone(t) && _simulationY!.isDone(t)) {
      _stopFling();
      return;
    }
    if (deltaX.abs() > 1 || deltaY.abs() > 1) {
      if (deltaX.abs() > deltaY.abs()) {
        onScroll?.call(deltaX, 0);
      } else {
        onScroll?.call(0, deltaY);
      }
    }
  }

  void _stopFling() {
    _ticker?.dispose();
    _ticker = null;
  }

  /// 清理资源，防止内存泄漏
  void dispose() {
    _stopFling(); // 停止并清理 Ticker
    onScroll = null; // 清理回调引用
    _simulationX = null; // 清理模拟对象
    _simulationY = null;
  }
}
