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
      } else if (event.eventType == ControlEventType.mouseButton) {
        eventText = '鼠标按键';
      } else if (event.eventType == ControlEventType.mouseMove) {
        final mouseMoveEvent = event.data as MouseMoveEvent;
        eventText = '鼠标移动到角落: ${mouseMoveEvent.deltaX} ${mouseMoveEvent.deltaY}';
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
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('配置管理'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('新建空配置'),
                    subtitle: const Text('清空当前所有控件，创建新的配置'),
                    onTap: () {
                      Navigator.pop(context);
                      _showNewConfigDialog();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.save),
                    title: const Text('保存当前配置'),
                    subtitle: const Text('将当前控件布局保存为配置'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSaveConfigDialog();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: const Text('加载配置'),
                    subtitle: const Text('从已保存的配置中选择加载'),
                    onTap: () {
                      Navigator.pop(context);
                      _showLoadConfigDialog();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('删除配置'),
                    subtitle: const Text('删除已保存的配置'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfigDialog();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('新建空配置'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // 清空当前控件
                  widget.controlManager.clearControls();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已清空所有控件，编辑完后请自行保存配置')),
                  );
                  setState(() {}); // 刷新界面
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('确定'),
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 24),
                            SizedBox(width: 8),
                            Text(
                              '警告',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '确定要清空当前所有控件吗？',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• 此操作将删除当前所有虚拟手柄控件'),
                        Text('• 如果当前配置未保存，将无法恢复'),
                        Text('• 清空后可以重新添加控件'),
                        Text('• 建议在清空前先保存当前配置'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '操作说明',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• 点击"确定"将清空所有控件'),
                        Text('• 清空后可以重新设计虚拟手柄布局'),
                        Text('• 完成后记得保存新配置'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveConfigDialog() {
    _configNameController.text = widget.controlManager.currentConfigName;
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('保存配置'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (_configNameController.text.isNotEmpty) {
                    await widget.controlManager.saveConfig(_configNameController.text);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('配置"${_configNameController.text}"已保存')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入配置名称')),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '配置名称',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _configNameController,
                  decoration: const InputDecoration(
                    labelText: '配置名称',
                    hintText: '请输入配置名称，如：默认配置、游戏配置等',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      await widget.controlManager.saveConfig(value);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('配置"$value"已保存')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '保存说明',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• 配置将保存当前所有控件的位置和设置'),
                        Text('• 如果配置名称已存在，将覆盖原有配置'),
                        Text('• 保存后可以随时加载此配置'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadConfigDialog() async {
    final configNames = await widget.controlManager.getConfigNames();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('加载配置'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
          body: configNames.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('没有可加载的配置'),
                      SizedBox(height: 8),
                      Text('请先保存一些配置'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: configNames.length,
                  itemBuilder: (context, index) {
                    final configName = configNames[index];
                    final isCurrentConfig = configName == widget.controlManager.currentConfigName;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isCurrentConfig ? Icons.check_circle : Icons.folder,
                          color: isCurrentConfig ? Colors.green : Colors.blue,
                        ),
                        title: Text(configName),
                        subtitle: isCurrentConfig 
                            ? const Text('当前配置')
                            : const Text('点击加载此配置'),
                        trailing: isCurrentConfig 
                            ? const Chip(
                                label: Text('当前'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                        onTap: isCurrentConfig ? null : () async {
                          final success = await widget.controlManager.loadConfig(configName);
                          if (mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('配置"$configName"已加载')),
                              );
                              setState(() {}); // 刷新界面
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('加载配置失败')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showDeleteConfigDialog() async {
    final configNames = await widget.controlManager.getConfigNames();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('删除配置'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
          body: configNames.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('没有可删除的配置'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: configNames.length,
                  itemBuilder: (context, index) {
                    final configName = configNames[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.orange),
                        title: Text(configName),
                        subtitle: const Text('点击删除此配置'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // 显示确认对话框
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('确认删除'),
                                content: Text('确定要删除配置"$configName"吗？此操作无法撤销。'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              final success = await widget.controlManager.deleteConfig(configName);
                              if (mounted) {
                                Navigator.pop(context);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('配置"$configName"已删除')),
                                  );
                                  setState(() {}); // 刷新界面
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('删除配置失败')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
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
            icon: const Icon(Icons.edit),
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
