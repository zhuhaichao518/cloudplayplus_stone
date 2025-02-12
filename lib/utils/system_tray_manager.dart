// system_tray_manager.dart
import 'dart:io';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:system_tray/system_tray.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_window_close/flutter_window_close.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();

  bool _isInitialized = false;

  factory SystemTrayManager() => _instance;

  SystemTrayManager._internal();

  Future<void> initialize({
    String iconPath = 'assets/images/cpp_logo',
    //String tooltip = '',
    bool hideDockIconOnStart = false,
  }) async {
    if (_isInitialized) return;

    // TODO:不明bug导致hide的时候闪退。
    if (Platform.isMacOS) return;
    // 处理 macOS Dock 图标
    if ((Platform.isMacOS && hideDockIconOnStart)) {
      appWindow.hide();
    }

    // 初始化系统托盘
    final trayIconPath = _getPlatformIconPath(iconPath);
    await _systemTray.initSystemTray(iconPath: trayIconPath);
    //_systemTray.setToolTip(tooltip);

    // 构建菜单
    await _buildContextMenu();

    // 注册托盘事件
    _systemTray.registerSystemTrayEventHandler(_handleTrayEvent);

    if (AppPlatform.isDeskTop && ApplicationInfo.isSystem) {
      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        appWindow.hide();
        return false; // 阻止默认关闭行为
      });
    }

    _isInitialized = true;
  }

  Future<void> _buildContextMenu() async {
    await _menu.buildFrom([
      MenuItemLabel(
        label: '显示窗口',
        onClicked: (_) => showWindow(),
      ),
      MenuItemLabel(
        label: '隐藏窗口',
        onClicked: (_) => hideWindow(),
      ),
      MenuSeparator(),
      if (AppPlatform.isWindows && ApplicationInfo.isSystem)
        MenuItemLabel(
          label: '重启服务',
          onClicked: (_) => restart(),
        ),
      MenuItemLabel(
        label: '退出云玩加',
        onClicked: (_) => exitApp(),
      ),
    ]);
    await _systemTray.setContextMenu(_menu);
  }

  void _handleTrayEvent(String eventName) {
    switch (eventName) {
      case kSystemTrayEventClick:
        Platform.isWindows ? showWindow() : _systemTray.popUpContextMenu();
        break;
      case kSystemTrayEventRightClick:
        Platform.isWindows ? _systemTray.popUpContextMenu() : showWindow();
        break;
    }
  }

  String _getPlatformIconPath(String basePath) {
    return Platform.isWindows ? '$basePath.ico' : '$basePath.png';
  }

  void showWindow() {
    appWindow.show();
  }

  void hideWindow() => appWindow.hide();

  void restart() {
    appWindow.close();
    exit(0);
  }

  void exitApp() {
    if (AppPlatform.isWindows && ApplicationInfo.isSystem) {
      HardwareSimulator.unregisterService();
    } else {
      appWindow.close();
      exit(0);
    }
  }

  // 高级配置方法
  Future<void> updateTooltip(String newTooltip) async {
    await _systemTray.setToolTip(newTooltip);
  }

  Future<void> updateIcon(String newIconPath) async {
    await _systemTray.setImage(_getPlatformIconPath(newIconPath));
  }
}
