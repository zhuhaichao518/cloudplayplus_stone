import 'package:flutter/material.dart';
import 'control_base.dart';
import 'button_control.dart';
import 'joystick_control.dart';
import 'control_manager.dart';
import 'package:vk/vk.dart';
import 'package:flutter/services.dart';
import 'virtual_gamepad.dart';
import 'gamepad_keys.dart';
import 'control_event.dart';

//import 'plugins/virtual.keyboard.dart/lib/vk.dart';

class ControlManagementScreen extends StatefulWidget {
  final ControlManager controlManager;
  final VoidCallback onControlsUpdated;

  const ControlManagementScreen({
    super.key,
    required this.controlManager,
    required this.onControlsUpdated,
  });

  @override
  State<ControlManagementScreen> createState() =>
      _ControlManagementScreenState();
}

class _ControlManagementScreenState extends State<ControlManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理屏幕按键'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _showImportExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddControlDialog,
          ),
        ],
      ),
      body: widget.controlManager.controls.isEmpty
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('单击右上角+添加按键或者点击同步按键导入/导出虚拟按键列表'),
                const SizedBox(height: 20), // 添加间距
                ElevatedButton(
                  onPressed: _importDefaultControls,
                  child: const Text('导入手机默认虚拟手柄'),
                ),
              ],
            ))
          : ListView.builder(
              itemCount: widget.controlManager.controls.length,
              itemBuilder: (context, index) {
                final control = widget.controlManager.controls[index];
                return _buildControlItem(control);
              },
            ),
    );
  }

  Widget _buildControlItem(ControlBase control) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Dismissible(
        key: Key(control.id),
        background: Container(color: Colors.red),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这个控件吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          widget.controlManager.removeControl(control.id);
          widget.onControlsUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (control is ButtonControl && control.isGamepadButton ? '手柄按钮' : (control is ButtonControl && control.isMouseButton ? '鼠标按钮' : '键盘按键'))))}已删除')),
          );
        },
        child: ListTile(
          leading: Icon(
              control.type == 'joystick' ? Icons.gamepad : (control.type == 'eightDirectionJoystick' ? Icons.navigation : (control.type == 'mouseModeButton' ? Icons.mouse : (control is ButtonControl && control.isMouseButton ? Icons.mouse : Icons.touch_app)))),
          title: Text(control.type == 'joystick'
              ? '${(control as JoystickControl).joystickType == 'left' ? '左' : '右'}摇杆'
              : control.type == 'eightDirectionJoystick'
                  ? '角落跳转摇杆'
                  : control.type == 'mouseModeButton'
                      ? '鼠标模式切换按钮'
                      : (control is ButtonControl && control.isGamepadButton
                          ? '手柄按钮：${GamepadKeys.getKeyName(control.keyCode)}'
                          : control is ButtonControl && control.isMouseButton
                              ? '鼠标按钮：${_getMouseButtonName(control.keyCode)}'
                              : '键盘按键：${control is ButtonControl ? control.label : ''}')),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '位置: (${control.centerX.toStringAsFixed(2)}, ${control.centerY.toStringAsFixed(2)})'),
              Text('大小: ${control.size.toStringAsFixed(2)}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    widget.controlManager.removeControl(control.id);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(control),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddControlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新控件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.gamepad),
              title: const Text('手柄摇杆'),
              onTap: () {
                Navigator.pop(context);
                _addJoystick();
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('角落跳转摇杆'),
              onTap: () {
                Navigator.pop(context);
                _addEightDirectionJoystick();
              },
            ),
            ListTile(
              leading: const Icon(Icons.touch_app),
              title: const Text('键盘/手柄/鼠标按钮'),
              onTap: () {
                Navigator.pop(context);
                _addButton();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mouse),
              title: const Text('鼠标模式切换按钮'),
              onTap: () {
                Navigator.pop(context);
                _addMouseModeButton();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addJoystick() {
    final centerXController = TextEditingController(text: '0.2');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.1');
    String selectedType = 'left';

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('添加摇杆'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  widget.controlManager.createJoystick(
                    joystickType: selectedType,
                    centerX: double.tryParse(centerXController.text) ?? 0.2,
                    centerY: double.tryParse(centerYController.text) ?? 0.8,
                    size: double.tryParse(sizeController.text) ?? 0.1,
                  );
                  widget.onControlsUpdated();
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('摇杆已添加')),
                  );
                },
                child: const Text('添加'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '摇杆类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'left', child: Text('左摇杆')),
                    DropdownMenuItem(value: 'right', child: Text('右摇杆')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedType = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: centerXController,
                  decoration: const InputDecoration(
                    labelText: '中心X (0.0-1.0)',
                    hintText: '0.0是左边，1.0是右边',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: centerYController,
                  decoration: const InputDecoration(
                    labelText: '中心Y (0.0-1.0)',
                    hintText: '0.0是底部，1.0是顶部',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    labelText: '大小 (0.0-1.0)',
                    hintText: '相对于屏幕宽度',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addEightDirectionJoystick() {
    final centerXController = TextEditingController(text: '0.2');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.1');

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('添加角落跳转摇杆'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  widget.controlManager.createEightDirectionJoystick(
                    centerX: double.tryParse(centerXController.text) ?? 0.2,
                    centerY: double.tryParse(centerYController.text) ?? 0.8,
                    size: double.tryParse(sizeController.text) ?? 0.1,
                  );
                  widget.onControlsUpdated();
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('角落跳转摇杆已添加')),
                  );
                },
                child: const Text('添加'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '角落跳转摇杆说明:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• 用于MOBA游戏小地图拖动\n'
                  '• 拖动摇杆超过红色圆圈阈值时，鼠标会瞬间跳转到对应角落\n'
                  '• 松开摇杆后可以重新使用',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: centerXController,
                  decoration: const InputDecoration(
                    labelText: '中心X (0.0-1.0)',
                    hintText: '0.0是左边，1.0是右边',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: centerYController,
                  decoration: const InputDecoration(
                    labelText: '中心Y (0.0-1.0)',
                    hintText: '0.0是底部，1.0是顶部',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    labelText: '大小 (0.0-1.0)',
                    hintText: '相对于屏幕宽度',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addButton() {
    final labelController = TextEditingController();
    final centerXController = TextEditingController(text: '0.8');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.1');
    int? selectedKeyCode;
    bool isGamepadButton = false;
    bool isMouseButton = false;
    bool hasSelectedKey = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('添加按钮'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedKeyCode == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请先选择一个按键')),
                      );
                      return;
                    }

                    widget.controlManager.createButton(
                      label: labelController.text.isEmpty
                          ? (isGamepadButton
                              ? _getDefaultGamepadButtonLabel(selectedKeyCode!)
                              : isMouseButton
                                  ? _getMouseButtonName(selectedKeyCode!)
                                  : '按钮')
                          : labelController.text,
                      keyCode: selectedKeyCode!,
                      centerX: double.tryParse(centerXController.text) ?? 0.8,
                      centerY: double.tryParse(centerYController.text) ?? 0.8,
                      size: double.tryParse(sizeController.text) ?? 0.1,
                      isGamepadButton: isGamepadButton,
                      isMouseButton: isMouseButton,
                    );
                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${isGamepadButton ? "手柄按钮" : (isMouseButton ? "鼠标按钮" : "键盘按键")}已添加')),
                    );
                  },
                  child: const Text('添加'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('按钮类型:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: isMouseButton ? 'mouse' : (isGamepadButton ? 'gamepad' : 'keyboard'),
                        items: const [
                          DropdownMenuItem(value: 'keyboard', child: Text('键盘按键')),
                          DropdownMenuItem(value: 'gamepad', child: Text('手柄按钮')),
                          DropdownMenuItem(value: 'mouse', child: Text('鼠标按钮')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            isGamepadButton = value == 'gamepad';
                            isMouseButton = value == 'mouse';
                            selectedKeyCode = null;
                            hasSelectedKey = false;
                            setDialogState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: '按钮标签',
                      hintText: isGamepadButton ? 'A, B, X, Y, etc.' : (isMouseButton ? 'Left Click, Right Click, Move' : '按钮名称'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isGamepadButton) ...[
                    const Text(
                      '请选择手柄按钮:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: VirtualGamepad(
                        size: MediaQuery.of(context).size.width * 0.95,
                        onKeyPressed: (keyCode, isDown) {
                          if (isDown && GamepadKeys.isButton(keyCode)) {
                            selectedKeyCode = keyCode;
                            labelController.text =
                                _getDefaultGamepadButtonLabel(keyCode);
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '已选择手柄按钮: ${GamepadKeys.getKeyName(keyCode)}'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 64),
                  ] else if (isMouseButton) ...[
                    const Text(
                      '请选择鼠标按钮:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMouseButtonOption(1, '左键', selectedKeyCode == 1, (keyCode) {
                          selectedKeyCode = keyCode;
                          labelController.text = '左键';
                          hasSelectedKey = true;
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已选择鼠标左键')),
                          );
                        }),
                        _buildMouseButtonOption(2, '中键', selectedKeyCode == 2, (keyCode) {
                          selectedKeyCode = keyCode;
                          labelController.text = '中键';
                          hasSelectedKey = true;
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已选择鼠标中键')),
                          );
                        }),
                        _buildMouseButtonOption(3, '右键', selectedKeyCode == 3, (keyCode) {
                          selectedKeyCode = keyCode;
                          labelController.text = '右键';
                          hasSelectedKey = true;
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已选择鼠标右键')),
                          );
                        }),
                        _buildMouseButtonOption(4, '侧键1', selectedKeyCode == 4, (keyCode) {
                          selectedKeyCode = keyCode;
                          labelController.text = '侧键1';
                          hasSelectedKey = true;
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已选择鼠标侧键1')),
                          );
                        }),
                        _buildMouseButtonOption(5, '侧键2', selectedKeyCode == 5, (keyCode) {
                          selectedKeyCode = keyCode;
                          labelController.text = '侧键2';
                          hasSelectedKey = true;
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已选择鼠标侧键2')),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 64),
                  ] else ...[
                    const Text(
                      '在虚拟键盘上按下一个键:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final height = maxWidth / 2.6;
                          return Container(
                            width: maxWidth,
                            child: VirtualKeyboard(
                              type: VirtualKeyboardType.Hardware,
                              keyPressedCallback: (keyCode, isDown) {
                                if (isDown) {
                                  selectedKeyCode = keyCode;
                                  hasSelectedKey = true;
                                  setDialogState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已选择按键: 0x${keyCode.toRadixString(16)}'),
                                    ),
                                  );
                                }
                              },
                              height: height,
                              keyBackgroundColor: Colors.grey.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                  if (hasSelectedKey && selectedKeyCode != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text(
                              '已选择: ',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isGamepadButton
                                  ? GamepadKeys.getKeyName(selectedKeyCode!)
                                  : (isMouseButton ? _getMouseButtonName(selectedKeyCode!) : '0x${selectedKeyCode!.toRadixString(16)}'),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                selectedKeyCode = null;
                                hasSelectedKey = false;
                                if (isGamepadButton) {
                                  labelController.text = '';
                                }
                                setDialogState(() {});
                              },
                              child: const Text('清除'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '按钮位置和大小:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: centerXController,
                    decoration: const InputDecoration(
                      labelText: '中心X (0.0-1.0)',
                      hintText: '0.0是左边，1.0是右边',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: centerYController,
                    decoration: const InputDecoration(
                      labelText: '中心Y (0.0-1.0)',
                      hintText: '0.0是底部，1.0是顶部',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: '大小 (0.0-1.0)',
                      hintText: '相对于屏幕宽度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addMouseModeButton() {
    final centerXController = TextEditingController(text: '0.8');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.1');
    List<MouseMode> selectedModes = [MouseMode.leftClick, MouseMode.rightClick, MouseMode.move];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('添加鼠标模式切换按钮(使用触摸模式时无效)'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedModes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请至少选择一个模式')),
                      );
                      return;
                    }

                    widget.controlManager.createMouseModeButton(
                      enabledModes: selectedModes,
                      centerX: double.tryParse(centerXController.text) ?? 0.8,
                      centerY: double.tryParse(centerYController.text) ?? 0.8,
                      size: double.tryParse(sizeController.text) ?? 0.1,
                    );
                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('鼠标模式切换按钮已添加')),
                    );
                  },
                  child: const Text('添加'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择可用模式(如果仅选择一项，则在按下时临时切换):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('左键点击'),
                    value: selectedModes.contains(MouseMode.leftClick),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedModes.add(MouseMode.leftClick);
                        } else {
                          selectedModes.remove(MouseMode.leftClick);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('右键点击'),
                    value: selectedModes.contains(MouseMode.rightClick),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedModes.add(MouseMode.rightClick);
                        } else {
                          selectedModes.remove(MouseMode.rightClick);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('移动模式'),
                    value: selectedModes.contains(MouseMode.move),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedModes.add(MouseMode.move);
                        } else {
                          selectedModes.remove(MouseMode.move);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '按钮位置和大小:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: centerXController,
                    decoration: const InputDecoration(
                      labelText: '中心X (0.0-1.0)',
                      hintText: '0.0是左边，1.0是右边',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: centerYController,
                    decoration: const InputDecoration(
                      labelText: '中心Y (0.0-1.0)',
                      hintText: '0.0是底部，1.0是顶部',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: '大小 (0.0-1.0)',
                      hintText: '相对于屏幕宽度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDefaultGamepadButtonLabel(int keyCode) {
    switch (keyCode) {
      case GamepadKeys.A:
        return 'A';
      case GamepadKeys.B:
        return 'B';
      case GamepadKeys.X:
        return 'X';
      case GamepadKeys.Y:
        return 'Y';
      case GamepadKeys.LEFT_SHOULDER:
        return 'LB';
      case GamepadKeys.RIGHT_SHOULDER:
        return 'RB';
      case GamepadKeys.LEFT_TRIGGER:
        return 'LT';
      case GamepadKeys.RIGHT_TRIGGER:
        return 'RT';
      case GamepadKeys.START:
        return 'ST';
      case GamepadKeys.BACK:
        return 'BK';
      case GamepadKeys.DPAD_UP:
        return '↑';
      case GamepadKeys.DPAD_DOWN:
        return '↓';
      case GamepadKeys.DPAD_LEFT:
        return '←';
      case GamepadKeys.DPAD_RIGHT:
        return '→';
      case GamepadKeys.LEFT_STICK_BUTTON:
        return 'LS';
      case GamepadKeys.RIGHT_STICK_BUTTON:
        return 'RS';
      default:
        return 'Button';
    }
  }

  void _showEditDialog(ControlBase control) {
    final centerXController =
        TextEditingController(text: control.centerX.toStringAsFixed(2));
    final centerYController =
        TextEditingController(text: control.centerY.toStringAsFixed(2));
    final sizeController =
        TextEditingController(text: control.size.toStringAsFixed(2));
    final labelController = TextEditingController(
        text: control is ButtonControl ? control.label : '');
    int? selectedKeyCode = control is ButtonControl ? control.keyCode : null;
    bool showKeyboard = false;
    String selectedType =
        control is JoystickControl ? control.joystickType : 'left';
    bool isGamepadButton =
        control is ButtonControl ? control.isGamepadButton : false;
    bool isMouseButton =
        control is ButtonControl ? control.isMouseButton : false;
    bool hasSelectedKey = false;
    
    // 为 MouseModeButtonControl 添加变量
    List<MouseMode> selectedModes = control.type == 'mouseModeButton' 
        ? (control as dynamic).enabledModes.cast<MouseMode>().toList()
        : [MouseMode.leftClick, MouseMode.rightClick, MouseMode.move];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  '编辑${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (isGamepadButton ? '手柄按钮' : '键盘按键')))}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final centerX = double.tryParse(centerXController.text) ??
                        control.centerX;
                    final centerY = double.tryParse(centerYController.text) ??
                        control.centerY;
                    final size =
                        double.tryParse(sizeController.text) ?? control.size;

                    if (control is ButtonControl) {
                      if (selectedKeyCode == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先选择一个按键')),
                        );
                        return;
                      }
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        label: labelController.text,
                        keyCode: selectedKeyCode,
                        isGamepadButton: isGamepadButton,
                        isMouseButton: isMouseButton,
                      );
                    } else if (control is JoystickControl) {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        joystickType: selectedType,
                      );
                    } else if (control.type == 'eightDirectionJoystick') {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                      );
                    } else if (control.type == 'mouseModeButton') {
                      // 对于鼠标模式按钮，使用 updateControl 方法
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        enabledModes: selectedModes,
                      );
                    }

                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (isGamepadButton ? '手柄按钮' : (isMouseButton ? '鼠标按钮' : '键盘按键'))))}已更新')),
                    );
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
                  if (control is ButtonControl) ...[
                    Row(
                      children: [
                        const Text('按钮类型:', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: isMouseButton ? 'mouse' : (isGamepadButton ? 'gamepad' : 'keyboard'),
                          items: const [
                            DropdownMenuItem(value: 'keyboard', child: Text('键盘按键')),
                            DropdownMenuItem(value: 'gamepad', child: Text('手柄按钮')),
                            DropdownMenuItem(value: 'mouse', child: Text('鼠标按钮')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              isGamepadButton = value == 'gamepad';
                              isMouseButton = value == 'mouse';
                              selectedKeyCode = null;
                              hasSelectedKey = false;
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: '按钮标签',
                        hintText: isGamepadButton ? 'A, B, X, Y, etc.' : (isMouseButton ? 'Left Click, Right Click, Move' : '按钮名称'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isGamepadButton) ...[
                      const Text(
                        '请选择手柄按钮:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: VirtualGamepad(
                          size: MediaQuery.of(context).size.width * 0.95,
                          onKeyPressed: (keyCode, isDown) {
                            if (isDown && GamepadKeys.isButton(keyCode)) {
                              selectedKeyCode = keyCode;
                              hasSelectedKey = true;
                              setDialogState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '已选择手柄按钮: ${GamepadKeys.getKeyName(keyCode)}')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 64),
                    ] else if (isMouseButton) ...[
                      const Text(
                        '请选择鼠标按钮:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMouseButtonOption(1, '左键', selectedKeyCode == 1, (keyCode) {
                            selectedKeyCode = keyCode;
                            labelController.text = '左键';
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已选择鼠标左键')),
                            );
                          }),
                          _buildMouseButtonOption(2, '中键', selectedKeyCode == 2, (keyCode) {
                            selectedKeyCode = keyCode;
                            labelController.text = '中键';
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已选择鼠标中键')),
                            );
                          }),
                          _buildMouseButtonOption(3, '右键', selectedKeyCode == 3, (keyCode) {
                            selectedKeyCode = keyCode;
                            labelController.text = '右键';
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已选择鼠标右键')),
                            );
                          }),
                          _buildMouseButtonOption(4, '侧键1', selectedKeyCode == 4, (keyCode) {
                            selectedKeyCode = keyCode;
                            labelController.text = '侧键1';
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已选择鼠标侧键1')),
                            );
                          }),
                          _buildMouseButtonOption(5, '侧键2', selectedKeyCode == 5, (keyCode) {
                            selectedKeyCode = keyCode;
                            labelController.text = '侧键2';
                            hasSelectedKey = true;
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已选择鼠标侧键2')),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 64),
                    ] else ...[
                      const Text(
                        '在虚拟键盘上按下一个键:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final height = maxWidth / 2.6;
                            return Container(
                              width: maxWidth,
                              child: VirtualKeyboard(
                                type: VirtualKeyboardType.Hardware,
                                keyPressedCallback: (keyCode, isDown) {
                                  if (isDown) {
                                    selectedKeyCode = keyCode;
                                    hasSelectedKey = true;
                                    setDialogState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('已选择按键: 0x'+keyCode.toRadixString(16)),
                                      ),
                                    );
                                  }
                                },
                                height: height,
                                keyBackgroundColor: Colors.grey.withOpacity(0.5),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 64),
                    ],
                    if (hasSelectedKey && selectedKeyCode != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text(
                                '已选择: ',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isGamepadButton
                                    ? GamepadKeys.getKeyName(selectedKeyCode!)
                                    : (isMouseButton ? _getMouseButtonName(selectedKeyCode!) : '0x${selectedKeyCode!.toRadixString(16)}'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  selectedKeyCode = null;
                                  hasSelectedKey = false;
                                  setDialogState(() {});
                                },
                                child: const Text('清除'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else if (control is JoystickControl) ...[
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: '摇杆类型',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'left', child: Text('左摇杆')),
                        DropdownMenuItem(value: 'right', child: Text('右摇杆')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          selectedType = value;
                          setDialogState(() {});
                        }
                      },
                    ),
                  ] else if (control.type == 'eightDirectionJoystick') ...[
                    const Text(
                      '角落跳转摇杆说明:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 用于MOBA游戏小地图拖动\n'
                      '• 拖动摇杆超过红色圆圈阈值时，鼠标会瞬间跳转到对应角落\n'
                      '• 松开摇杆后可以重新使用',
                      style: TextStyle(fontSize: 14),
                    ),
                  ] else if (control.type == 'mouseModeButton') ...[
                    const Text(
                      '选择可用模式(如果仅选择一项，则在按下时临时切换):',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('左键点击'),
                      value: selectedModes.contains(MouseMode.leftClick),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedModes.add(MouseMode.leftClick);
                          } else {
                            selectedModes.remove(MouseMode.leftClick);
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('右键点击'),
                      value: selectedModes.contains(MouseMode.rightClick),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedModes.add(MouseMode.rightClick);
                          } else {
                            selectedModes.remove(MouseMode.rightClick);
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('仅移动'),
                      value: selectedModes.contains(MouseMode.move),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedModes.add(MouseMode.move);
                          } else {
                            selectedModes.remove(MouseMode.move);
                          }
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '位置和大小:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: centerXController,
                    decoration: const InputDecoration(
                      labelText: '中心X (0.0-1.0)',
                      hintText: '0.0是左边，1.0是右边',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: centerYController,
                    decoration: const InputDecoration(
                      labelText: '中心Y (0.0-1.0)',
                      hintText: '0.0是底部，1.0是顶部',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: '大小 (0.0-1.0)',
                      hintText: '相对于屏幕宽度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _importDefaultControls() async {
    String defaultController =
        '[{"id":"1","type":"joystick","centerX":0.22,"centerY":0.7,"size":0.12,"joystickType":"left"},{"id":"2","type":"joystick","centerX":0.7,"centerY":0.2,"size":0.1,"joystickType":"right"},{"id":"3","type":"button","centerX":0.1,"centerY":0.1,"size":0.07,"label":"↑","keyCode":1,"color":4280391411,"isGamepadButton":true},{"id":"4","type":"button","centerX":0.1,"centerY":0.3,"size":0.07,"label":"↓","keyCode":2,"color":4280391411,"isGamepadButton":true},{"id":"5","type":"button","centerX":0.15,"centerY":0.2,"size":0.07,"label":"→","keyCode":8,"color":4280391411,"isGamepadButton":true},{"id":"6","type":"button","centerX":0.05,"centerY":0.2,"size":0.07,"label":"←","keyCode":4,"color":4280391411,"isGamepadButton":true},{"id":"7","type":"button","centerX":0.08,"centerY":0.55,"size":0.07,"label":"BK","keyCode":32,"color":4280391411,"isGamepadButton":true},{"id":"8","type":"button","centerX":0.08,"centerY":0.75,"size":0.07,"label":"ST","keyCode":16,"color":4280391411,"isGamepadButton":true},{"id":"9","type":"button","centerX":0.8,"centerY":0.85,"size":0.1,"label":"A","keyCode":4100,"color":4280391411,"isGamepadButton":true},{"id":"10","type":"button","centerX":0.8,"centerY":0.5,"size":0.1,"label":"Y","keyCode":4103,"color":4280391411,"isGamepadButton":true},{"id":"11","type":"button","centerX":0.88,"centerY":0.68,"size":0.1,"label":"B","keyCode":4101,"color":4280391411,"isGamepadButton":true},{"id":"12","type":"button","centerX":0.72,"centerY":0.68,"size":0.1,"label":"X","keyCode":4102,"color":4280391411,"isGamepadButton":true},{"id":"13","type":"button","centerX":0.66,"centerY":0.5,"size":0.1,"label":"LT","keyCode":257,"color":4280391411,"isGamepadButton":true},{"id":"14","type":"button","centerX":0.6,"centerY":0.68,"size":0.1,"label":"LB","keyCode":256,"color":4280391411,"isGamepadButton":true},{"id":"15","type":"button","centerX":0.8,"centerY":0.25,"size":0.1,"label":"RB","keyCode":512,"color":4280391411,"isGamepadButton":true},{"id":"16","type":"button","centerX":0.9,"centerY":0.25,"size":0.1,"label":"RT","keyCode":513,"color":4280391411,"isGamepadButton":true}]';
    final success =
        await widget.controlManager.importControls(defaultController);
    if (success) {
      widget.onControlsUpdated();
      setState(() {}); // 确保界面更新
    }
  }

  void _showImportExportDialog() {
    final exportController = TextEditingController(
      text: widget.controlManager.exportControls(),
    );
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入/导出虚拟屏幕控件'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: exportController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制导出内容到剪贴板')),
                      );
                    },
                    child: const Text('复制配置'),
                  ),
                ],
              ),
              const Text('导出JSON:'),
              TextField(
                controller: exportController,
                readOnly: true,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('导入JSON:'),
              TextField(
                controller: importController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '粘贴JSON字符串',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (importController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入要导入的JSON')),
                );
                return;
              }

              final success = await widget.controlManager
                  .importControls(importController.text);
              if (success) {
                widget.onControlsUpdated();
                setState(() {}); // 确保界面更新
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('控件导入成功')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('控件导入失败，请检查JSON格式')),
                );
              }
            },
            child: const Text('导入'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getButtonName(int keyCode) {
    return GamepadKeys.getKeyName(keyCode);
  }

  String _getMouseButtonName(int keyCode) {
    switch (keyCode) {
      case 1:
        return '左键';
      case 2:
        return '中键';
      case 3:
        return '右键';
      case 4:
        return '侧键1';
      case 5:
        return '侧键2';
      default:
        return '按钮$keyCode';
    }
  }

  Widget _buildMouseButtonOption(int keyCode, String label, bool isSelected, Function(int) onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(keyCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
