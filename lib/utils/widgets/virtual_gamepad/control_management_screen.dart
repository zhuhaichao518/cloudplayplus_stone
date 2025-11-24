import 'package:flutter/material.dart';
import 'control_base.dart';
import 'button_control.dart';
import 'joystick_control.dart';
import 'wasd_joystick_control.dart';
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
  bool _isEditMode = true;
  String? _draggingControlId;
  Offset? _dragStartPosition;
  Offset? _dragStartControlPosition;
  Map<String, Offset> _dragPositions = {}; // 存储拖拽时的实时位置

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: _isEditMode 
          ? _buildEditModeView()
          : _buildNormalView(),
    );
  }
  
  // Deprecated. use new model.
  Widget _buildNormalView() {
    return widget.controlManager.controls.isEmpty
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
          );
  }

  Widget _buildEditModeView() {
    return Stack(
      children: [
        // 背景网格
        _buildGridBackground(),
        
        // 可拖动的控件
        ...widget.controlManager.controls.map((control) => 
          _buildDraggableControl(control)
        ),
        
        // 空状态提示（当没有控件时显示）
        if (widget.controlManager.controls.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '编辑模式',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('没有可编辑的控件'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _importDefaultControls,
                  child: const Text('导入默认手柄控件开始编辑'),
                ),
              ],
            ),
          ),
        
        // 编辑模式提示
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  '编辑模式 - 拖动控件调整位置',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showEditModeHelp,
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 控件信息面板
        if (_draggingControlId != null)
          Positioned(
            top: 16,
            right: 16,
            child: _buildControlInfoPanel(),
          ),
        // 控制面板
        Positioned(
          bottom: 32,
          left: 16,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }

  Widget _buildDraggableControl(ControlBase control) {
    final screenSize = MediaQuery.of(context).size;
    final controlSize = control.size * screenSize.width;
    
    // 使用拖拽时的实时位置，如果没有则使用控件原始位置
    final dragPosition = _dragPositions[control.id];
    final centerX = dragPosition?.dx ?? control.centerX;
    final centerY = dragPosition?.dy ?? control.centerY;
    
    final pixelCenterX = centerX * screenSize.width;
    final pixelCenterY = centerY * screenSize.height;
    final isDragging = _draggingControlId == control.id;
    
    return Positioned(
      left: pixelCenterX - controlSize / 2,
      top: pixelCenterY - controlSize / 2,
      child: GestureDetector(
        onPanStart: (details) {
          if (_isEditMode) {
            setState(() {
              _draggingControlId = control.id;
              _dragStartPosition = details.globalPosition;
              _dragStartControlPosition = Offset(control.centerX, control.centerY);
              // 初始化拖拽位置
              _dragPositions[control.id] = Offset(control.centerX, control.centerY);
            });
            // 添加触觉反馈
            HapticFeedback.lightImpact();
          }
        },
        onPanUpdate: (details) {
          if (_isEditMode && _draggingControlId == control.id && 
              _dragStartPosition != null && _dragStartControlPosition != null) {
            
            // 计算拖拽的总距离
            final dragDelta = details.globalPosition - _dragStartPosition!;
            
            // 转换为屏幕比例
            final deltaX = dragDelta.dx / screenSize.width;
            final deltaY = dragDelta.dy / screenSize.height;
            
            // 计算新位置
            final newCenterX = _dragStartControlPosition!.dx + deltaX;
            final newCenterY = _dragStartControlPosition!.dy + deltaY;
            
            // 限制在屏幕范围内
            final clampedX = newCenterX.clamp(control.size / 2, 1.0 - control.size / 2);
            final clampedY = newCenterY.clamp(control.size / 2, 1.0 - control.size / 2);
            
            // 更新拖拽时的实时位置
            setState(() {
              _dragPositions[control.id] = Offset(clampedX, clampedY);
            });
          }
        },
        onPanEnd: (details) {
          if (_isEditMode && _draggingControlId == control.id) {
            // 拖拽结束时，将最终位置保存到ControlManager
            final finalPosition = _dragPositions[control.id];
            if (finalPosition != null) {
              widget.controlManager.updateControl(
                control.id,
                centerX: finalPosition.dx,
                centerY: finalPosition.dy,
              );
              widget.onControlsUpdated();
            }
            
            setState(() {
              _draggingControlId = null;
              _dragStartPosition = null;
              _dragStartControlPosition = null;
              _dragPositions.remove(control.id);
            });
            // 添加触觉反馈
            HapticFeedback.selectionClick();
          }
        },
        onTap: () {
          if (_isEditMode) {
            setState(() {
              if (_draggingControlId == control.id) {
                _draggingControlId = null;
              } else {
                _draggingControlId = control.id;
              }
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: controlSize,
          height: controlSize,
          decoration: BoxDecoration(
            color: isDragging 
                ? Colors.blue.withOpacity(0.2)
                : (_draggingControlId == control.id 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.transparent),
            border: Border.all(
              color: isDragging 
                  ? Colors.blue 
                  : (_draggingControlId == control.id 
                      ? Colors.blue.withOpacity(0.7)
                      : Colors.grey.withOpacity(0.3)),
              width: isDragging ? 3 : (_draggingControlId == control.id ? 2 : 1),
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isDragging ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Stack(
            children: [
              // 控件预览
              _buildControlPreview(control),
              
              // 编辑模式指示器
              if (_isEditMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDragging ? Colors.blue : Colors.grey.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDragging ? Icons.drag_handle : Icons.drag_indicator,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

              // 选中指示器
              if (_draggingControlId == control.id && !isDragging)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPreview(ControlBase control) {
    final screenSize = MediaQuery.of(context).size;
    final controlSize = control.size * screenSize.width;
    
    // 根据控件类型显示不同的预览
    Widget preview;
    
    if (control is JoystickControl) {
      preview = Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.gamepad,
            color: Colors.white,
            size: controlSize * 0.4,
          ),
        ),
      );
    } else if (control is ButtonControl) {
      preview = Container(
        decoration: BoxDecoration(
          color: control.color.withOpacity(0.6),
          borderRadius: control.shape == ButtonShape.circle 
              ? BorderRadius.circular(controlSize / 2)
              : BorderRadius.circular(controlSize * 0.1),
        ),
        child: Center(
          child: Text(
            control.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: controlSize * 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (control.type == 'eightDirectionJoystick') {
      preview = Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.navigation,
            color: Colors.white,
            size: controlSize * 0.4,
          ),
        ),
      );
    } else if (control.type == 'wasdJoystick') {
      preview = Container(
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.keyboard,
            color: Colors.white,
            size: controlSize * 0.4,
          ),
        ),
      );
    } else if (control.type == 'mouseModeButton') {
      preview = Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.mouse,
            color: Colors.white,
            size: controlSize * 0.4,
          ),
        ),
      );
    } else {
      preview = Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.touch_app,
            color: Colors.white,
            size: controlSize * 0.4,
          ),
        ),
      );
    }
    
    return preview;
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
                    '${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'wasdJoystick' ? 'WASD摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (control is ButtonControl && control.isGamepadButton ? '手柄按钮' : (control is ButtonControl && control.isMouseButton ? '鼠标按钮' : '键盘按键')))))}已删除')),
          );
        },
        child: ListTile(
          leading: Icon(
              control.type == 'joystick' ? Icons.gamepad : (control.type == 'eightDirectionJoystick' ? Icons.navigation : (control.type == 'wasdJoystick' ? Icons.keyboard : (control.type == 'mouseModeButton' ? Icons.mouse : (control is ButtonControl && control.isMouseButton ? Icons.mouse : Icons.touch_app))))),
          title: Text(control.type == 'joystick'
              ? '${(control as JoystickControl).joystickType == JoystickType.left ? '左' : '右'}摇杆'
              : control.type == 'eightDirectionJoystick'
                  ? '角落跳转摇杆'
                  : control.type == 'wasdJoystick'
                      ? 'WASD摇杆'
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
              leading: const Icon(Icons.keyboard),
              title: const Text('WASD摇杆'),
              subtitle: const Text('支持自定义按键映射和长拉模式'),
              onTap: () {
                Navigator.pop(context);
                _addWASDJoystick();
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
    JoystickType selectedType = JoystickType.left;

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
                DropdownButtonFormField<JoystickType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '摇杆类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: JoystickType.left, child: Text('左摇杆')),
                    DropdownMenuItem(value: JoystickType.right, child: Text('右摇杆')),
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

  void _addWASDJoystick() {
    final centerXController = TextEditingController(text: '0.2');
    final centerYController = TextEditingController(text: '0.8');
    final sizeController = TextEditingController(text: '0.12');
    
    // 默认WASD按键映射
    Map<String, int> keyMapping = {
      'up': 0x11,     // W
      'down': 0x1F,   // S
      'left': 0x1E,   // A
      'right': 0x20,  // D
    };
    bool enableLongPull = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('添加WASD摇杆'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    widget.controlManager.createWASDJoystick(
                      keyMapping: keyMapping,
                      enableLongPull: enableLongPull,
                      centerX: double.tryParse(centerXController.text) ?? 0.2,
                      centerY: double.tryParse(centerYController.text) ?? 0.8,
                      size: double.tryParse(sizeController.text) ?? 0.12,
                    );
                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WASD摇杆已添加')),
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
                    'WASD摇杆说明:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 将摇杆方向映射到自定义按键\n'
                    '• 支持8方向（包括对角线）\n'
                    '• 长拉模式：拉得足够远后松手也不释放按键\n'
                    '• 双击摇杆可强制释放所有按键',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '按键映射配置:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildKeyMappingRow('上', 'up', keyMapping, setDialogState),
                  const SizedBox(height: 8),
                  _buildKeyMappingRow('下', 'down', keyMapping, setDialogState),
                  const SizedBox(height: 8),
                  _buildKeyMappingRow('左', 'left', keyMapping, setDialogState),
                  const SizedBox(height: 8),
                  _buildKeyMappingRow('右', 'right', keyMapping, setDialogState),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('启用长拉模式'),
                    subtitle: const Text('拉动距离超过阈值后，松手不释放按键'),
                    value: enableLongPull,
                    onChanged: (value) {
                      enableLongPull = value;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '虚拟键盘（点击选择按键）:',
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
                                // 显示对话框让用户选择映射到哪个方向
                                _showDirectionSelectionDialog(
                                  context,
                                  keyCode,
                                  keyMapping,
                                  setDialogState,
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
                  const SizedBox(height: 24),
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

  Widget _buildKeyMappingRow(
    String label,
    String direction,
    Map<String, int> keyMapping,
    StateSetter setState,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '0x${keyMapping[direction]!.toRadixString(16).toUpperCase().padLeft(2, '0')}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            // 重置为默认值
            final defaults = {
              'up': 0x11,
              'down': 0x1F,
              'left': 0x1E,
              'right': 0x20,
            };
            keyMapping[direction] = defaults[direction]!;
            setState(() {});
          },
          tooltip: '重置为默认',
        ),
      ],
    );
  }

  void _showDirectionSelectionDialog(
    BuildContext parentContext,
    int keyCode,
    Map<String, int> keyMapping,
    StateSetter parentSetState,
  ) {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('选择方向'),
        content: const Text('将此按键映射到哪个方向？'),
        actions: [
          TextButton(
            onPressed: () {
              keyMapping['up'] = keyCode;
              parentSetState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text('已将 0x${keyCode.toRadixString(16)} 映射到 上')),
              );
            },
            child: const Text('上 ↑'),
          ),
          TextButton(
            onPressed: () {
              keyMapping['down'] = keyCode;
              parentSetState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text('已将 0x${keyCode.toRadixString(16)} 映射到 下')),
              );
            },
            child: const Text('下 ↓'),
          ),
          TextButton(
            onPressed: () {
              keyMapping['left'] = keyCode;
              parentSetState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text('已将 0x${keyCode.toRadixString(16)} 映射到 左')),
              );
            },
            child: const Text('左 ←'),
          ),
          TextButton(
            onPressed: () {
              keyMapping['right'] = keyCode;
              parentSetState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text('已将 0x${keyCode.toRadixString(16)} 映射到 右')),
              );
            },
            child: const Text('右 →'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
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
                  '• 拖动摇杆超过圆圈阈值时，鼠标会瞬间跳转到对应角落\n'
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
    bool isFpsFireButton = false;
    bool hasSelectedKey = false;
    ButtonShape selectedShape = ButtonShape.circle;

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
                      shape: selectedShape,
                      isFpsFireButton: isFpsFireButton,
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
                  Row(
                    children: [
                      const Text('按钮形状:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 16),
                      DropdownButton<ButtonShape>(
                        value: selectedShape,
                        items: const [
                          DropdownMenuItem(value: ButtonShape.circle, child: Text('圆形')),
                          DropdownMenuItem(value: ButtonShape.square, child: Text('方形')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            selectedShape = value;
                            setDialogState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('FPS开火按键'),
                    subtitle: const Text('按下后，手指移动会触发鼠标移动事件（适用于FPS游戏）'),
                    value: isFpsFireButton,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isFpsFireButton = value;
                      });
                    },
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
    JoystickType selectedType =
        control is JoystickControl ? control.joystickType : JoystickType.left;
    bool isGamepadButton =
        control is ButtonControl ? control.isGamepadButton : false;
    bool isMouseButton =
        control is ButtonControl ? control.isMouseButton : false;
    bool isFpsFireButton =
        control is ButtonControl ? control.isFpsFireButton : false;
    bool hasSelectedKey = false;
    ButtonShape selectedShape = control is ButtonControl ? control.shape : ButtonShape.circle;
    
    // 为 MouseModeButtonControl 添加变量
    List<MouseMode> selectedModes = control.type == 'mouseModeButton' 
        ? (control as dynamic).enabledModes.cast<MouseMode>().toList()
        : [MouseMode.leftClick, MouseMode.rightClick, MouseMode.move];
    
    // 为 WASDJoystickControl 添加变量
    Map<String, int> keyMapping = control is WASDJoystickControl
        ? Map<String, int>.from(control.keyMapping)
        : {
            'up': 0x11,
            'down': 0x1F,
            'left': 0x1E,
            'right': 0x20,
          };
    bool enableLongPull = control is WASDJoystickControl ? control.enableLongPull : false;
    
    // 颜色和透明度变量
    Color selectedColor = control.color;
    double selectedOpacity = control.opacity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  '编辑${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'wasdJoystick' ? 'WASD摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (isGamepadButton ? '手柄按钮' : '键盘按键'))))}'),
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
                        shape: selectedShape,
                        color: selectedColor,
                        opacity: selectedOpacity,
                        isFpsFireButton: isFpsFireButton,
                      );
                    } else if (control is JoystickControl) {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        joystickType: selectedType,
                        color: selectedColor,
                        opacity: selectedOpacity,
                      );
                    } else if (control.type == 'eightDirectionJoystick') {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        color: selectedColor,
                        opacity: selectedOpacity,
                      );
                    } else if (control.type == 'mouseModeButton') {
                      // 对于鼠标模式按钮，使用 updateControl 方法
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        enabledModes: selectedModes,
                        color: selectedColor,
                        opacity: selectedOpacity,
                      );
                    } else if (control is WASDJoystickControl) {
                      widget.controlManager.updateControl(
                        control.id,
                        centerX: centerX,
                        centerY: centerY,
                        size: size,
                        keyMapping: keyMapping,
                        enableLongPull: enableLongPull,
                        color: selectedColor,
                        opacity: selectedOpacity,
                      );
                    }

                    widget.onControlsUpdated();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${control.type == 'joystick' ? '摇杆' : (control.type == 'eightDirectionJoystick' ? '角落跳转摇杆' : (control.type == 'wasdJoystick' ? 'WASD摇杆' : (control.type == 'mouseModeButton' ? '鼠标模式切换按钮' : (isGamepadButton ? '手柄按钮' : (isMouseButton ? '鼠标按钮' : '键盘按键')))))}已更新')),
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
                    Row(
                      children: [
                        const Text('按钮形状:', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        DropdownButton<ButtonShape>(
                          value: selectedShape,
                          items: const [
                            DropdownMenuItem(value: ButtonShape.circle, child: Text('圆形')),
                            DropdownMenuItem(value: ButtonShape.square, child: Text('方形')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              selectedShape = value;
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('FPS开火按键'),
                      subtitle: const Text('按下后，手指移动会触发鼠标移动事件（适用于FPS游戏）'),
                      value: isFpsFireButton,
                      onChanged: (bool value) {
                        setDialogState(() {
                          isFpsFireButton = value;
                        });
                      },
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
                    DropdownButtonFormField<JoystickType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: '摇杆类型',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: JoystickType.left, child: Text('左摇杆')),
                        DropdownMenuItem(value: JoystickType.right, child: Text('右摇杆')),
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
                      '• 拖动摇杆超过圆圈阈值时，鼠标会瞬间跳转到对应角落\n'
                      '• 松开摇杆后可以重新使用',
                      style: TextStyle(fontSize: 14),
                    ),
                  ] else if (control.type == 'wasdJoystick') ...[
                    const Text(
                      '按键映射配置:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildKeyMappingRow('上', 'up', keyMapping, setDialogState),
                    const SizedBox(height: 8),
                    _buildKeyMappingRow('下', 'down', keyMapping, setDialogState),
                    const SizedBox(height: 8),
                    _buildKeyMappingRow('左', 'left', keyMapping, setDialogState),
                    const SizedBox(height: 8),
                    _buildKeyMappingRow('右', 'right', keyMapping, setDialogState),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('启用长拉模式'),
                      subtitle: const Text('拉动距离超过阈值后，松手不释放按键'),
                      value: enableLongPull,
                      onChanged: (value) {
                        enableLongPull = value;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '虚拟键盘（点击选择按键）:',
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
                                  _showDirectionSelectionDialog(
                                    context,
                                    keyCode,
                                    keyMapping,
                                    setDialogState,
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
                    '外观设置:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('颜色:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(selectedOpacity),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // 显示颜色选择器
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('选择颜色'),
                                      content: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Colors.red,
                                            Colors.pink,
                                            Colors.purple,
                                            Colors.deepPurple,
                                            Colors.indigo,
                                            Colors.blue,
                                            Colors.lightBlue,
                                            Colors.cyan,
                                            Colors.teal,
                                            Colors.green,
                                            Colors.lightGreen,
                                            Colors.lime,
                                            Colors.yellow,
                                            Colors.amber,
                                            Colors.orange,
                                            Colors.deepOrange,
                                            Colors.brown,
                                            Colors.grey,
                                            Colors.blueGrey,
                                            Colors.black,
                                          ].map((color) {
                                            return GestureDetector(
                                              onTap: () {
                                                selectedColor = color;
                                                setDialogState(() {});
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  border: Border.all(
                                                    color: selectedColor == color
                                                        ? Colors.white
                                                        : Colors.transparent,
                                                    width: 3,
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Center(
                                child: Text(
                                  '点击选择颜色',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('透明度:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: selectedOpacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(selectedOpacity * 100).toInt()}%',
                          onChanged: (value) {
                            selectedOpacity = value;
                            setDialogState(() {});
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(selectedOpacity * 100).toInt()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildControlPanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddControlDialog,
            tooltip: '添加控件',
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _showImportExportDialog,
            tooltip: '同步按钮配置',
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: '返回',
          ),
        ],
      ),
    );
  }

  Widget _buildControlInfoPanel() {
    final control = widget.controlManager.controls.firstWhere(
      (c) => c.id == _draggingControlId,
      orElse: () => throw Exception('Control not found'),
    );
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getControlIcon(control),
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                _getControlTypeName(control),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('位置: (${control.centerX.toStringAsFixed(3)}, ${control.centerY.toStringAsFixed(3)})'),
          Text('大小: ${control.size.toStringAsFixed(3)}'),
          if (control is ButtonControl) ...[
            Text('标签: ${control.label}'),
            Text('类型: ${control.isGamepadButton ? "手柄" : (control.isMouseButton ? "鼠标" : "键盘")}'),
            Text('形状: ${control.shape == ButtonShape.circle ? "圆形" : "方形"}'),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _showEditDialog(control),
                tooltip: '编辑',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: () {
                  widget.controlManager.removeControl(control.id);
                  widget.onControlsUpdated();
                  setState(() {
                    _draggingControlId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_getControlTypeName(control)}已删除')),
                  );
                },
                tooltip: '删除',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getControlIcon(ControlBase control) {
    if (control is JoystickControl) {
      return Icons.gamepad;
    } else if (control is ButtonControl) {
      return control.isMouseButton ? Icons.mouse : Icons.touch_app;
    } else if (control.type == 'eightDirectionJoystick') {
      return Icons.navigation;
    } else if (control.type == 'wasdJoystick') {
      return Icons.keyboard;
    } else if (control.type == 'mouseModeButton') {
      return Icons.mouse;
    }
    return Icons.touch_app;
  }

  String _getControlTypeName(ControlBase control) {
    if (control is JoystickControl) {
      return '${control.joystickType == JoystickType.left ? '左' : '右'}摇杆';
    } else if (control is ButtonControl) {
      if (control.isGamepadButton) {
        return '手柄按钮';
      } else if (control.isMouseButton) {
        return '鼠标按钮';
      } else {
        return '键盘按键';
      }
    } else if (control.type == 'eightDirectionJoystick') {
      return '角落跳转摇杆';
    } else if (control.type == 'wasdJoystick') {
      return 'WASD摇杆';
    } else if (control.type == 'mouseModeButton') {
      return '鼠标模式切换按钮';
    }
    return '控件';
  }

  void _showEditModeHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('编辑模式使用说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '编辑模式功能说明：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 拖动控件：长按并拖拽控件到新位置'),
              Text('• 选中控件：点击控件查看详细信息'),
              Text('• 编辑控件：在信息面板中点击编辑按钮'),
              Text('• 删除控件：在信息面板中点击删除按钮'),
              Text('• 添加控件：使用右下角的添加按钮'),
              SizedBox(height: 8),
              Text(
                '操作提示：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 控件会自动限制在屏幕范围内'),
              Text('• 位置以屏幕比例保存 (0.0-1.0)'),
              Text('• 拖拽时会有触觉反馈'),
              Text('• 蓝色网格帮助您精确定位'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

// 背景网格绘制器
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // 绘制垂直线
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制水平线
    for (int i = 0; i <= 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制中心十字线
    final centerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), centerPaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
