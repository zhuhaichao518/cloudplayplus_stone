# 平滑鼠标控制器使用说明

## 概述

`SmoothMouseController` 是一个用于实现平滑鼠标移动的控制器，特别适用于Android TV遥控器的方向键控制。

## 功能特性

- **平滑加速**: 按下方向键时，鼠标会平滑加速到最大速度
- **立即停止**: 释放方向键时，鼠标会立即停止移动
- **多方向支持**: 支持上下左右四个方向的独立控制
- **组合移动**: 支持同时按下多个方向键实现斜向移动
- **高性能**: 使用60fps的更新频率，确保流畅的移动体验

## 使用方法

### 1. 初始化

```dart
// 在应用初始化时创建
OnScreenRemoteMouseController mouseController = OnScreenRemoteMouseController();
SmoothMouseController smoothController = SmoothMouseController(mouseController);
```

### 2. 处理按键事件

```dart
// 处理方向键按下
void onKeyDown(int keycode) {
  switch (keycode) {
    case 1019: // Up
    case 1020: // Down
    case 1021: // Left
    case 1022: // Right
      smoothController.onDirectionKeyDown(keycode);
      break;
  }
}

// 处理方向键释放
void onKeyUp(int keycode) {
  switch (keycode) {
    case 1019: // Up
    case 1020: // Down
    case 1021: // Left
    case 1022: // Right
      smoothController.onDirectionKeyUp(keycode);
      break;
  }
}
```

### 3. 清理资源

```dart
// 在应用退出时清理
smoothController.dispose();
```

## 配置参数

可以通过修改 `SmoothMouseController` 中的常量来调整行为：

- `_maxSpeed`: 最大移动速度 (默认: 20.0)
- `_acceleration`: 加速度 (默认: 2.0)
- `_updateInterval`: 更新频率 (默认: 16ms, 约60fps)

> **注意**: 释放按键时会立即停止移动，不使用减速过程

## 集成到现有代码

在 `hardware_input_controller.dart` 中已经集成了平滑鼠标控制器：

1. 在 `init()` 方法中创建控制器
2. 在按键处理回调中使用控制器
3. 在 `dispose()` 方法中清理资源

## 测试

运行测试来验证功能：

```bash
flutter test test/smooth_mouse_controller_test.dart
```

## 注意事项

1. 确保在TVControllerMode.mouse模式下才启用平滑移动
2. 控制器会自动管理定时器，无需手动启动/停止
3. 支持同时按下多个方向键，实现斜向移动
4. 释放按键时会立即停止该方向的移动，提供更精确的控制 