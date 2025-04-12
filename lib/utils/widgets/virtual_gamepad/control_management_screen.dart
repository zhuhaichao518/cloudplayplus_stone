import 'package:flutter/material.dart';
import 'control_base.dart';
import 'button_control.dart';
import 'joystick_control.dart';
import 'control_manager.dart';
import 'package:vk/vk.dart';
import 'package:flutter/services.dart';
import 'virtual_gamepad.dart';
import 'gamepad_keys.dart';

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
            icon: const Icon(Icons.import_export),
            onPressed: _showImportExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddControlDialog,
          ),
        ],
      ),
      body: widget.controlManager.controls.isEmpty
          ? const Center(
              child: Text('单击右上角+添加按键或者导入虚拟按键列表'),
            )
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
                    '${control.type == 'joystick' ? '摇杆' : (control is ButtonControl && GamepadKeys.isButton(control.keyCode) ? '手柄按钮' : '键盘按键')}已删除')),
          );
        },
        child: ListTile(
          leading: Icon(
              control.type == 'joystick' ? Icons.gamepad : Icons.touch_app),
          title: Text(control.type == 'joystick'
              ? '${(control as JoystickControl).joystickType == 'left' ? '左' : '右'}摇杆'
              : (control is ButtonControl && control.isGamepadButton
                  ? '手柄按钮：${GamepadKeys.getKeyName(control.keyCode)}'
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
              leading: const Icon(Icons.touch_app),
              title: const Text('键盘/手柄按钮'),
              onTap: () {
                Navigator.pop(context);
                _addButton();
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

  void _addButton() {
    final labelController = TextEditingController();
    final centerXController = TextEditingController(text: '0.8');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.1');
    int? selectedKeyCode;
    bool isGamepadButton = false;
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
                              : '按钮')
                          : labelController.text,
                      keyCode: selectedKeyCode!,
                      centerX: double.tryParse(centerXController.text) ?? 0.8,
                      centerY: double.tryParse(centerYController.text) ?? 0.8,
                      size: double.tryParse(sizeController.text) ?? 0.1,
                      isGamepadButton: isGamepadButton,
                    );
                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${isGamepadButton ? "手柄按钮" : "键盘按键"}已添加')),
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
                      DropdownButton<bool>(
                        value: isGamepadButton,
                        items: const [
                          DropdownMenuItem(value: false, child: Text('键盘按键')),
                          DropdownMenuItem(value: true, child: Text('手柄按钮')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            isGamepadButton = value;
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
                      hintText: isGamepadButton ? 'A, B, X, Y, etc.' : '按钮名称',
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
                  ] else ...[
                    const Text(
                      '在虚拟键盘上按下一个键:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 计算键盘高度，使其宽度不超过屏幕宽度的90%
                          final maxWidth = constraints.maxWidth;
                          final height = maxWidth / 2.6;
                          return Container(
                            width: maxWidth,
                            child: VirtualKeyboard(
                              keyBackgroundColor: Colors.grey.withOpacity(0.5),
                              height: height,
                              type: VirtualKeyboardType.Hardware,
                              keyPressedCallback: (keyCode, isDown) {
                                if (isDown) {
                                  selectedKeyCode = keyCode;
                                  hasSelectedKey = true;
                                  setDialogState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '已选择按键: 0x${keyCode.toRadixString(16)}'),
                                    ),
                                  );
                                }
                              },
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
                                  : '0x${selectedKeyCode!.toRadixString(16)}',
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
    bool isButtonSelected = control is ButtonControl && control.isGamepadButton;
    bool hasSelectedKey = false;
    bool isGamepadButton =
        control is ButtonControl ? control.isGamepadButton : false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  '编辑${control.type == 'joystick' ? '摇杆' : (isGamepadButton ? '手柄按钮' : '键盘按键')}'),
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
                      );
                    } else if (control is JoystickControl) {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        joystickType: selectedType,
                      );
                    }

                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${control.type == 'joystick' ? '摇杆' : (isGamepadButton ? '手柄按钮' : '键盘按键')}已更新')),
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
                        DropdownButton<bool>(
                          value: isGamepadButton,
                          items: const [
                            DropdownMenuItem(value: false, child: Text('键盘按键')),
                            DropdownMenuItem(value: true, child: Text('手柄按钮')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              isGamepadButton = value;
                              selectedKeyCode = null;
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
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
                    ] else ...[
                      const Text(
                        '在虚拟键盘上按下一个键:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 计算键盘高度，使其宽度不超过屏幕宽度的90%
                            final maxWidth = constraints.maxWidth;
                            final height = maxWidth / 2.6;
                            return Container(
                              width: maxWidth,
                              child: VirtualKeyboard(
                                keyBackgroundColor:
                                    Colors.grey.withOpacity(0.5),
                                height: height,
                                type: VirtualKeyboardType.Hardware,
                                keyPressedCallback: (keyCode, isDown) {
                                  if (isDown) {
                                    selectedKeyCode = keyCode;
                                    hasSelectedKey = true;
                                    setDialogState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '已选择按键: 0x${keyCode.toRadixString(16)}'),
                                      ),
                                    );
                                  }
                                },
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
                                    : '0x${selectedKeyCode!.toRadixString(16)}',
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

  void _showImportExportDialog() {
    final exportController = TextEditingController(
      text: widget.controlManager.exportControls(),
    );
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('导入/导出虚拟屏幕控件'),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制导出内容到剪贴板')),
                );
              },
              child: const Text('复制配置'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
}
