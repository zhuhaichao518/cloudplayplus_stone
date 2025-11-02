import 'package:flutter/material.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/virtual_gamepad_settings_screen.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/control_manager.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/control_event.dart';
import 'package:cloudplayplus/utils/widgets/virtual_gamepad/joystick_control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '虚拟按键 Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const VirtualGamepadDemoPage(),
    );
  }
}

class VirtualGamepadDemoPage extends StatefulWidget {
  const VirtualGamepadDemoPage({super.key});

  @override
  State<VirtualGamepadDemoPage> createState() => _VirtualGamepadDemoPageState();
}

class _VirtualGamepadDemoPageState extends State<VirtualGamepadDemoPage> {
  late final ControlManager _controlManager;
  final List<String> _eventLog = [];
  static const int _maxEventLogSize = 20;

  @override
  void initState() {
    super.initState();
    _controlManager = ControlManager();
    _loadControls();
    _controlManager.addEventListener(_handleControlEvent);
  }

  @override
  void dispose() {
    _controlManager.removeEventListener(_handleControlEvent);
    super.dispose();
  }

  Future<void> _loadControls() async {
    await _controlManager.loadControls();
    
    // 如果没有任何控件，创建一些默认的示例控件
    if (_controlManager.controls.isEmpty) {
      _createDefaultControls();
    }
    
    setState(() {});
  }

  void _createDefaultControls() {
    // 创建左侧摇杆
    _controlManager.createJoystick(
      joystickType: JoystickType.left,
      centerX: 0.15,
      centerY: 0.75,
      size: 0.12,
    );

    // 创建右侧摇杆
    _controlManager.createJoystick(
      joystickType: JoystickType.right,
      centerX: 0.85,
      centerY: 0.75,
      size: 0.12,
    );

    // 创建A按钮
    _controlManager.createButton(
      label: 'A',
      keyCode: 0x1000, // 手柄按钮A
      centerX: 0.85,
      centerY: 0.5,
      size: 0.08,
      color: Colors.green,
      isGamepadButton: true,
    );

    // 创建B按钮
    _controlManager.createButton(
      label: 'B',
      keyCode: 0x1001, // 手柄按钮B
      centerX: 0.93,
      centerY: 0.42,
      size: 0.08,
      color: Colors.red,
      isGamepadButton: true,
    );

    // 创建X按钮
    _controlManager.createButton(
      label: 'X',
      keyCode: 0x1002, // 手柄按钮X
      centerX: 0.77,
      centerY: 0.42,
      size: 0.08,
      color: Colors.blue,
      isGamepadButton: true,
    );

    // 创建Y按钮
    _controlManager.createButton(
      label: 'Y',
      keyCode: 0x1003, // 手柄按钮Y
      centerX: 0.85,
      centerY: 0.34,
      size: 0.08,
      color: Colors.yellow,
      isGamepadButton: true,
    );

    // 创建八方向摇杆（左上角）
    _controlManager.createEightDirectionJoystick(
      centerX: 0.15,
      centerY: 0.3,
      size: 0.1,
    );
  }

  void _handleControlEvent(ControlEvent event) {
    String eventDescription = '';

    switch (event.eventType) {
      case ControlEventType.keyboard:
        final keyEvent = event.data as KeyboardEvent;
        eventDescription = 
            '键盘: 0x${keyEvent.keyCode.toRadixString(16).toUpperCase()} ${keyEvent.isDown ? "按下 ⬇️" : "松开 ⬆️"}';
        break;

      case ControlEventType.gamepad:
        if (event.data is GamepadButtonEvent) {
          final buttonEvent = event.data as GamepadButtonEvent;
          eventDescription = 
              '手柄按钮: 0x${buttonEvent.keyCode.toRadixString(16).toUpperCase()} ${buttonEvent.isDown ? "按下 🎮" : "松开 🎮"}';
        } else if (event.data is GamepadAnalogEvent) {
          final analogEvent = event.data as GamepadAnalogEvent;
          eventDescription = 
              '摇杆: ${_getJoystickName(analogEvent.key)} = ${analogEvent.value.toStringAsFixed(2)} 🕹️';
        }
        break;

      case ControlEventType.mouseMode:
        eventDescription = '鼠标模式切换 🖱️';
        break;

      case ControlEventType.mouseButton:
        final mouseButtonEvent = event.data as MouseButtonEvent;
        final buttonName = mouseButtonEvent.buttonId == 1 ? '左键' : 
                          mouseButtonEvent.buttonId == 2 ? '中键' : '右键';
        eventDescription = 
            '鼠标按钮: $buttonName ${mouseButtonEvent.isDown ? "按下" : "松开"} 🖱️';
        break;

      case ControlEventType.mouseMove:
        final mouseMoveEvent = event.data as MouseMoveEvent;
        eventDescription = 
            '鼠标移动: (${mouseMoveEvent.deltaX.toStringAsFixed(1)}, ${mouseMoveEvent.deltaY.toStringAsFixed(1)}) 🖱️';
        break;
    }

    setState(() {
      _eventLog.insert(0, eventDescription);
      if (_eventLog.length > _maxEventLogSize) {
        _eventLog.removeLast();
      }
    });
  }

  String _getJoystickName(GamepadKey key) {
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

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualGamepadSettingsPage(
          controlManager: _controlManager,
        ),
      ),
    ).then((_) {
      // 返回后刷新界面
      setState(() {});
    });
  }

  void _clearEventLog() {
    setState(() {
      _eventLog.clear();
    });
  }

  void _resetToDefaultControls() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置为默认控件'),
        content: const Text('确定要清空当前所有控件并重置为默认配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _controlManager.clearControls();
              _createDefaultControls();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认控件配置')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('虚拟按键 Demo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置为默认控件',
            onPressed: _resetToDefaultControls,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '编辑虚拟按键',
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // 说明文字和事件日志
          Column(
            children: [
              // 顶部说明卡片
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 点击右上角设置按钮进入编辑模式\n'
                      '• 可以添加、移动、删除虚拟按键\n'
                      '• 支持摇杆、按钮等多种控件类型\n'
                      '• 控件配置会自动保存',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // 事件日志卡片
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '事件日志',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _eventLog.isEmpty ? null : _clearEventLog,
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('清空'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _eventLog.isEmpty
                            ? Center(
                                child: Text(
                                  '触摸虚拟按键查看事件',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _eventLog.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${_eventLog.length - index}.',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _eventLog[index],
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 虚拟控件覆盖层
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: _controlManager.buildAllControls(
                  context,
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

