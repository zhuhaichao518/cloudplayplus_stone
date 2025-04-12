import 'package:flutter/material.dart';
import 'control_management_screen.dart';
import 'control_manager.dart';
import 'control_event.dart';
import 'gamepad_keys.dart';

class VirtualGamepadSettingsPage extends StatefulWidget {
  final ControlManager controlManager;

  const VirtualGamepadSettingsPage({super.key, required this.controlManager});

  @override
  State<VirtualGamepadSettingsPage> createState() => _VirtualGamepadSettingsPageState();
}

class _VirtualGamepadSettingsPageState extends State<VirtualGamepadSettingsPage> {
  final List<String> _eventLog = [];
  static const int _maxEvents = 5;

  @override
  void initState() {
    super.initState();
    widget.controlManager.addEventListener(_handleControlEvent);
  }

  @override
  void dispose() {
    widget.controlManager.removeEventListener(_handleControlEvent);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('虚拟手柄设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToManagementScreen(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(color: Colors.grey[100]),

              // Event Log
              Positioned(
                left: constraints.maxWidth * 0.1,
                right: constraints.maxWidth * 0.1,
                top: constraints.maxHeight * 0.1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最近事件:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._eventLog.map((event) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              event,
                              style: const TextStyle(
                                color: Colors.white,
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
