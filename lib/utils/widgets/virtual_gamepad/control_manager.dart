import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'button_control.dart';
import 'control_base.dart';
import 'joystick_control.dart';
import 'control_event.dart';
import 'dart:convert';

typedef ControlEventListener = void Function(ControlEvent event);

class ControlManager {
  static const String _storageKey = 'controls';
  static const String _nextIdKey = 'next_control_id';
  static const String _configsKey = 'control_configs';

  static ControlManager? _instance;

  final List<ControlBase> _controls = [];
  final List<ControlEventListener> _eventListeners = [];
  int _nextId = 1;
  String _currentConfigName = '默认配置';

  // 私有构造函数
  ControlManager._();

  // 工厂构造函数，返回单例实例
  factory ControlManager() {
    _instance ??= ControlManager._();
    return _instance!;
  }

  List<ControlBase> get controls => List.unmodifiable(_controls);
  String get currentConfigName => _currentConfigName;

  // 获取所有配置名称
  Future<List<String>> getConfigNames() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);
    if (configsJson != null) {
      try {
        final Map<String, dynamic> configs = jsonDecode(configsJson);
        return configs.keys.toList();
      } catch (e) {
        print('Error loading config names: $e');
      }
    }
    return ['默认配置'];
  }

  // 保存当前配置
  Future<void> saveConfig(String configName) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);
    Map<String, dynamic> configs = {};

    if (configsJson != null) {
      try {
        configs = jsonDecode(configsJson);
      } catch (e) {
        print('Error loading existing configs: $e');
      }
    }

    // 保存当前配置
    configs[configName] = {
      'controls': _controls.map((c) => c.toMap()).toList(),
      'nextId': _nextId,
    };

    await prefs.setString(_configsKey, jsonEncode(configs));
    _currentConfigName = configName;
  }

  // 加载配置
  Future<bool> loadConfig(String configName) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);
    if (configsJson != null) {
      try {
        final Map<String, dynamic> configs = jsonDecode(configsJson);
        if (configs.containsKey(configName)) {
          final config = configs[configName];
          _controls.clear();
          _controls.addAll((config['controls'] as List)
              .map((map) => ControlBase.fromMap(map)));
          _nextId = config['nextId'] ?? 1;
          _currentConfigName = configName;
          return true;
        }
      } catch (e) {
        print('Error loading config: $e');
      }
    }
    return false;
  }

  // 删除配置
  Future<bool> deleteConfig(String configName) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);
    if (configsJson != null) {
      try {
        final Map<String, dynamic> configs = jsonDecode(configsJson);
        if (configs.containsKey(configName)) {
          configs.remove(configName);
          await prefs.setString(_configsKey, jsonEncode(configs));
          if (_currentConfigName == configName) {
            // 如果删除的是当前配置，加载默认配置
            await loadConfig('默认配置');
          }
          return true;
        }
      } catch (e) {
        print('Error deleting config: $e');
      }
    }
    return false;
  }

  // 创建并添加摇杆
  void createJoystick({
    required String joystickType,
    double centerX = 0.2,
    double centerY = 0.8,
    double size = 0.1,
  }) {
    addControl(
      JoystickControl(
        id: _getNextId().toString(),
        centerX: centerX,
        centerY: centerY,
        size: size,
        joystickType: joystickType,
      ),
    );
  }

  // 创建并添加按钮
  void createButton({
    required String label,
    required int keyCode,
    double? centerX,
    double? centerY,
    double? size,
    Color color = Colors.blue,
    bool isGamepadButton = false,
  }) {
    addControl(
      ButtonControl(
        id: _getNextId().toString(),
        centerX: centerX ?? 0.8,
        centerY: centerY ?? 0.8,
        size: size ?? 0.1,
        label: label,
        keyCode: keyCode,
        color: color,
        isGamepadButton: isGamepadButton,
      ),
    );
  }

  // 创建并添加鼠标模式切换按钮
  void createMouseModeButton({
    required List<MouseMode> enabledModes,
    double centerX = 0.8,
    double centerY = 0.8,
    double size = 0.1,
    Color color = Colors.blue,
  }) {
    addControl(
      MouseModeButtonControl(
        id: _getNextId().toString(),
        centerX: centerX,
        centerY: centerY,
        size: size,
        enabledModes: enabledModes,
        color: color,
      ),
    );
  }

  int _getNextId() {
    final id = _nextId;
    _nextId++;
    _saveNextId();
    return id;
  }

  void addControl(ControlBase control) {
    _controls.add(control);
    _saveControls();
  }

  void removeControl(String id) {
    _controls.removeWhere((c) => c.id == id);
    _saveControls();
  }

  void updateControl(
    String id, {
    double? centerX,
    double? centerY,
    double? size,
    String? label,
    int? keyCode,
    String? joystickType,
    bool? isGamepadButton,
  }) {
    final index = _controls.indexWhere((c) => c.id == id);
    if (index != -1) {
      final control = _controls[index];
      if (control is JoystickControl) {
        _controls[index] = JoystickControl(
          id: control.id,
          centerX: centerX ?? control.centerX,
          centerY: centerY ?? control.centerY,
          size: size ?? control.size,
          joystickType: joystickType ?? control.joystickType,
        );
      } else if (control is ButtonControl) {
        _controls[index] = ButtonControl(
          id: control.id,
          centerX: centerX ?? control.centerX,
          centerY: centerY ?? control.centerY,
          size: size ?? control.size,
          label: label ?? control.label,
          keyCode: keyCode ?? control.keyCode,
          color: control.color,
          isGamepadButton: isGamepadButton ?? control.isGamepadButton,
        );
      }
      _saveControls();
    }
  }

  void addEventListener(ControlEventListener listener) {
    _eventListeners.add(listener);
  }

  void removeEventListener(ControlEventListener listener) {
    _eventListeners.remove(listener);
  }

  void _notifyEvent(ControlEvent event) {
    for (final listener in _eventListeners) {
      listener(event);
    }
  }

  Future<void> _saveControls() async {
    final prefs = await SharedPreferences.getInstance();
    final controlsJson = jsonEncode(_controls.map((c) => c.toMap()).toList());
    await prefs.setString(_storageKey, controlsJson);
  }

  Future<void> _saveNextId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_nextIdKey, _nextId);
  }

  Future<void> loadControls() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载下一个ID
    _nextId = prefs.getInt(_nextIdKey) ?? 1;

    // 加载控件
    final controlsJson = prefs.getString(_storageKey);
    if (controlsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(controlsJson) as List<dynamic>;
        _controls.clear();
        _controls.addAll(decoded.map((map) => ControlBase.fromMap(map)));

        // 确保nextId大于所有现有控件的ID
        for (final control in _controls) {
          final id = int.tryParse(control.id);
          if (id != null && id >= _nextId) {
            _nextId = id + 1;
          }
        }
        _saveNextId();
      } catch (e) {
        print('Error loading controls: $e');
      }
    }
  }

  List<Widget> buildAllControls(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
  }) {
    return _controls
        .map((control) => control.buildWidget(
              context,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              onEvent: _notifyEvent,
            ))
        .toList();
  }

  // 导出所有控件为JSON字符串
  String exportControls() {
    final controlsList = _controls.map((c) => c.toMap()).toList();
    return jsonEncode(controlsList);
  }

  // 从JSON字符串导入控件
  Future<bool> importControls(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final List<ControlBase> newControls =
          decoded.map((map) => ControlBase.fromMap(map)).toList();

      // 清除现有控件
      _controls.clear();

      // 添加新控件
      for (final control in newControls) {
        // 重新分配ID
        if (control is JoystickControl) {
          _controls.add(JoystickControl(
            id: _getNextId().toString(),
            centerX: control.centerX,
            centerY: control.centerY,
            size: control.size,
            joystickType: control.joystickType,
          ));
        } else if (control is ButtonControl) {
          _controls.add(ButtonControl(
            id: _getNextId().toString(),
            centerX: control.centerX,
            centerY: control.centerY,
            size: control.size,
            label: control.label,
            keyCode: control.keyCode,
            color: control.color,
            isGamepadButton: control.isGamepadButton,
          ));
        }
      }

      await _saveControls();
      return true;
    } catch (e) {
      print('Error importing controls: $e');
      return false;
    }
  }
}
