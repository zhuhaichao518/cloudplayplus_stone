import 'package:flutter/material.dart';
import 'control_management_screen.dart';
import 'control_manager.dart';
import 'control_event.dart';
import 'gamepad_keys.dart';

class VirtualGamepadSettingsPage extends StatefulWidget {
  final ControlManager controlManager;

  const VirtualGamepadSettingsPage({super.key, required this.controlManager});

  @override
  State<VirtualGamepadSettingsPage> createState() =>
      _VirtualGamepadSettingsPageState();
}

class _VirtualGamepadSettingsPageState
    extends State<VirtualGamepadSettingsPage> {
  final List<String> _eventLog = [];
  static const int _maxEvents = 5;
  final TextEditingController _configNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controlManager.addEventListener(_handleControlEvent);
  }

  @override
  void dispose() {
    widget.controlManager.removeEventListener(_handleControlEvent);
    _configNameController.dispose();
    super.dispose();
  }

  void _handleControlEvent(ControlEvent event) {
    setState(() {
      String eventText = '';

      if (event.eventType == ControlEventType.keyboard) {
        final keyboardEvent = event.data as KeyboardEvent;
        eventText =
            '键盘按键: 0x${keyboardEvent.keyCode.toRadixString(16)} ${keyboardEvent.isDown ? "按下" : "松开"}';
      } else if (event.eventType == ControlEventType.gamepad) {
        if (event.data is GamepadAnalogEvent) {
          final analogEvent = event.data as GamepadAnalogEvent;
          final stickName = _getStickName(analogEvent.key);
          eventText = '摇杆: $stickName ${analogEvent.value.toStringAsFixed(2)}';
        } else if (event.data is GamepadButtonEvent) {
          final buttonEvent = event.data as GamepadButtonEvent;
          eventText =
              '手柄按钮: ${GamepadKeys.getKeyName(buttonEvent.keyCode)} ${buttonEvent.isDown ? "按下" : "松开"}';
        }
      } else if (event.eventType == ControlEventType.mouseMode) {
        eventText = '按键模式切换';
      }

      _eventLog.insert(0, eventText);
      if (_eventLog.length > _maxEvents) {
        _eventLog.removeLast();
      }
    });
  }

  String _getStickName(GamepadKey key) {
    switch (key) {
      case GamepadKey.leftStickX:
        return '左摇杆X';
      case GamepadKey.leftStickY:
        return '左摇杆Y';
      case GamepadKey.rightStickX:
        return '右摇杆X';
      case GamepadKey.rightStickY:
        return '右摇杆Y';
    }
  }

  void _showConfigManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('保存当前配置'),
              onTap: () => _showSaveConfigDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('加载配置'),
              onTap: () => _showLoadConfigDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除配置'),
              onTap: () => _showDeleteConfigDialog(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSaveConfigDialog() {
    _configNameController.text = widget.controlManager.currentConfigName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存配置'),
        content: TextField(
          controller: _configNameController,
          decoration: const InputDecoration(
            labelText: '配置名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (_configNameController.text.isNotEmpty) {
                await widget.controlManager
                    .saveConfig(_configNameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('配置已保存')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLoadConfigDialog() async {
    final configNames = await widget.controlManager.getConfigNames();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加载配置'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: configNames.length,
            itemBuilder: (context, index) {
              final configName = configNames[index];
              return ListTile(
                title: Text(configName),
                onTap: () async {
                  final success =
                      await widget.controlManager.loadConfig(configName);
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('配置已加载')),
                      );
                      setState(() {}); // 刷新界面
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('加载配置失败')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfigDialog() async {
    final configNames = await widget.controlManager.getConfigNames();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: configNames.length,
            itemBuilder: (context, index) {
              final configName = configNames[index];
              return ListTile(
                title: Text(configName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final success =
                        await widget.controlManager.deleteConfig(configName);
                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('配置已删除')),
                        );
                        setState(() {}); // 刷新界面
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('删除配置失败')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('虚拟手柄设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToManagementScreen(),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _showConfigManagementDialog(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),

              // Event Log
              Positioned(
                left: constraints.maxWidth * 0.1,
                right: constraints.maxWidth * 0.1,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最近事件:',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._eventLog.map((event) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              event,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 14,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Controls
              ...widget.controlManager.buildAllControls(
                context,
                screenWidth: constraints.maxWidth,
                screenHeight: constraints.maxHeight,
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToManagementScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlManagementScreen(
          controlManager: widget.controlManager,
          onControlsUpdated: () => setState(() {}),
        ),
      ),
    );
    setState(() {}); // 确保返回时刷新界面
  }
}
