import 'package:flutter/material.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:hardware_simulator/display_data.dart';

class DisplayManagerPage extends StatefulWidget {
  @override
  _DisplayManagerPageState createState() => _DisplayManagerPageState();
}

class _DisplayManagerPageState extends State<DisplayManagerPage> {
  List<DisplayData> displays = [];
  bool isLoading = false;
  List<Map<String, dynamic>> customConfigs = [];
  MultiDisplayMode currentMultiDisplayMode = MultiDisplayMode.unknown;

  @override
  void initState() {
    super.initState();
    _loadDisplays();
    _loadCustomConfigs();
    _loadCurrentMultiDisplayMode();
  }

  Future<void> _loadDisplays() async {
    setState(() {
      isLoading = true;
    });

    try {

        List<DisplayData> displayList = await HardwareSimulator.getDisplayList();
        displays = displayList;
        //log the loaded displays
        print('Loaded displays: ${displays.length}');
        for (var display in displays) {
          //print display all details
          print('Display ID: ${display.index}, Resolution: ${display.width}x${display.height}, Refresh Rate: ${display.refreshRate}Hz'
          ', Virtual: ${display.isVirtual}, Name: ${display.displayName}, Device: ${display.deviceName}, Active: ${display.active}, UID: ${display.displayUid}'
          ', Coordinates: (${display.left}, ${display.top}) - (${display.right}, ${display.bottom}), Primary: ${display.isPrimary}');
        }

    } catch (e) {
      print('Error loading displays: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载显示器列表失败: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadCustomConfigs() async {
    try {
      final configs = await HardwareSimulator.getCustomDisplayConfigs();
      setState(() {
        customConfigs = configs;
      });
    } catch (e) {
      print('Failed to load custom configs: $e');
    }
  }

  Future<void> _loadCurrentMultiDisplayMode() async {
    try {
      MultiDisplayMode mode = await HardwareSimulator.getCurrentMultiDisplayMode();
      setState(() {
        currentMultiDisplayMode = mode;
      });
      print('Current multi-display mode: $mode');
    } catch (e) {
      print('Failed to load current multi-display mode: $e');
    }
  }

  Future<void> _setMultiDisplayMode(MultiDisplayMode mode) async {
    try {
      bool success = await HardwareSimulator.setMultiDisplayMode(mode);
      if (success) {
        await _loadCurrentMultiDisplayMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('多显示器模式已更改为 ${_getMultiDisplayModeName(mode)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更改多显示器模式失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更改多显示器模式失败: $e')),
      );
    }
  }

  String _getMultiDisplayModeName(MultiDisplayMode mode) {
    switch (mode) {
      case MultiDisplayMode.extend:
        return '扩展这些显示器';
      case MultiDisplayMode.primaryOnly:
        return '仅在主显示器上显示';
      case MultiDisplayMode.secondaryOnly:
        return '仅在副显示器上显示';
      case MultiDisplayMode.duplicate:
        return '复制这些显示器';
      case MultiDisplayMode.unknown:
        return '未知模式';
    }
  }

  Future<void> _addCustomConfig() async {
    String? width;
    String? height;
    String? refreshRate;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Custom Display Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Width'),
                keyboardType: TextInputType.number,
                onChanged: (value) => width = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Height'),
                keyboardType: TextInputType.number,
                onChanged: (value) => height = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Refresh Rate'),
                keyboardType: TextInputType.number,
                onChanged: (value) => refreshRate = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (width != null && height != null && refreshRate != null) {
                  try {
                    int widthInt = int.parse(width!);
                    int heightInt = int.parse(height!);
                    int refreshRateInt = int.parse(refreshRate!);
                    
                    List<Map<String, dynamic>> newConfigs = List.from(customConfigs);
                    newConfigs.add({
                      'width': widthInt,
                      'height': heightInt,
                      'refreshRate': refreshRateInt,
                    });
                    
                    bool success = await HardwareSimulator.setCustomDisplayConfigs(newConfigs);
                    if (success) {
                      await _loadCustomConfigs();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Custom configuration added successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save configuration. Please run as administrator to modify registry.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add configuration: $e'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeCustomConfig(int index) async {
    try {
      List<Map<String, dynamic>> newConfigs = List.from(customConfigs);
      newConfigs.removeAt(index);
      
      bool success = await HardwareSimulator.setCustomDisplayConfigs(newConfigs);
      if (success) {
        await _loadCustomConfigs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom configuration removed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove configuration. Please run as administrator to modify registry.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove configuration: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _createDefaultDisplay() async {
    try {
      bool initialized = await HardwareSimulator.initParsecVdd();
      if (!initialized) {
        throw Exception('初始化parsec-vdd失败');
      }

      int displayId = await HardwareSimulator.createDisplay();
      print('创建默认显示器成功，ID: $displayId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建默认显示器成功，ID: $displayId')),
      );
      
      // 重新加载显示器列表
      await _loadDisplays();
    } catch (e) {
      print('Error creating default display: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建默认显示器失败: $e')),
      );
    }
  }

  Future<void> _removeDisplay(int displayId) async {
    try {
      bool removed = await HardwareSimulator.removeDisplay(displayId);
      if (removed) {
        print('删除显示器成功，ID: $displayId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除显示器成功，ID: $displayId')),
        );
        
        // 重新加载显示器列表
        await _loadDisplays();
      } else {
        throw Exception('删除失败');
      }
    } catch (e) {
      print('Error removing display: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除显示器失败: $e')),
      );
    }
  }

  void _showChangeDisplayDialog(DisplayData display) async {
    List<Map<String, dynamic>> availableConfigs = [];
    
    try {
      availableConfigs = await HardwareSimulator.getDisplayConfigs(display.displayUid);
      print('Available configs for display ${display.displayUid}: ${availableConfigs.length}');
    } catch (e) {
      print('Error getting display configs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取显示器配置失败: $e')),
      );
      return;
    }

    if (availableConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该显示器没有可用的配置选项')),
      );
      return;
    }

    String newResolution = '${display.width}x${display.height}';
    int newRefreshRate = display.refreshRate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 从可用配置中创建唯一的分辨率列表
          Set<String> uniqueResolutions = availableConfigs
              .map((config) => '${config['width']}x${config['height']}')
              .toSet();
          List<String> resolutionList = uniqueResolutions.toList()..sort();
          
          // 为当前选择的分辨率获取可用的刷新率
          List<int> availableRefreshRates = availableConfigs
              .where((config) => '${config['width']}x${config['height']}' == newResolution)
              .map<int>((config) => config['refreshRate'] as int)
              .toList()
              ..sort();
          
          // 如果当前刷新率不在可用列表中，选择第一个可用的
          if (availableRefreshRates.isNotEmpty && !availableRefreshRates.contains(newRefreshRate)) {
            newRefreshRate = availableRefreshRates.first;
          }
          
          return AlertDialog(
            title: Text('修改显示器 ${display.index}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前配置: ${display.width}x${display.height}@${display.refreshRate}Hz'),
                Text('坐标位置: (${display.left}, ${display.top}) - (${display.right}, ${display.bottom})'),
                if (display.isPrimary) Text('主显示器', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('可用配置数量: ${availableConfigs.length}'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('分辨率: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: resolutionList.contains(newResolution) ? newResolution : resolutionList.first,
                        isExpanded: true,
                        onChanged: (String? value) {
                          setDialogState(() {
                            newResolution = value!;
                            // 更新可用刷新率
                            List<int> newRefreshRates = availableConfigs
                                .where((config) => '${config['width']}x${config['height']}' == newResolution)
                                .map<int>((config) => config['refreshRate'] as int)
                                .toList()
                                ..sort();
                            if (newRefreshRates.isNotEmpty) {
                              newRefreshRate = newRefreshRates.first;
                            }
                          });
                        },
                        items: resolutionList.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('刷新率: '),
                    Expanded(
                      child: DropdownButton<int>(
                        value: availableRefreshRates.contains(newRefreshRate) ? newRefreshRate : (availableRefreshRates.isNotEmpty ? availableRefreshRates.first : 60),
                        isExpanded: true,
                        onChanged: (int? value) {
                          setDialogState(() {
                            newRefreshRate = value!;
                          });
                        },
                        items: availableRefreshRates.map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('${value}Hz'),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _changeDisplay(display, newResolution, newRefreshRate);
                },
                child: Text('确认修改'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changeDisplay(DisplayData display, String resolution, int refreshRate) async {
    try {
      List<String> resolutionParts = resolution.split('x');
      int width = int.parse(resolutionParts[0]);
      int height = int.parse(resolutionParts[1]);
      
      bool success = await HardwareSimulator.changeDisplaySettings(
        display.displayUid,
        width,
        height,
        refreshRate,
      );
      
      if (success) {
        print('显示器设置修改成功: ${display.displayUid} -> ${width}x${height}@${refreshRate}Hz');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('显示器设置修改成功')),
        );
        
        // 重新加载显示器列表
        await _loadDisplays();
      } else {
        throw Exception('修改失败');
      }
    } catch (e) {
      print('Error changing display: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('修改显示器失败: $e')),
      );
    }
  }

  String _getOrientationName(int orientation) {
    switch (orientation) {
      case 0:
        return '横向 (0°)';
      case 1:
        return '竖向 (90°)';
      case 2:
        return '横向翻转 (180°)';
      case 3:
        return '竖向翻转 (270°)';
      default:
        return '未知';
    }
  }

  Future<void> _setDisplayOrientation(int displayUid, DisplayOrientation orientation) async {
    try {
      bool success = await HardwareSimulator.setDisplayOrientation(displayUid, orientation);
      if (success) {
        await _loadDisplays();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('显示器方向已更改')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更改显示器方向失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更改显示器方向失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('显示器管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDisplays,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 多显示器模式控制面板 (当显示器数量>1时显示)
            if (displays.length > 1) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '多显示器模式设置',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('当前模式: ${_getMultiDisplayModeName(currentMultiDisplayMode)}'),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _loadCurrentMultiDisplayMode,
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('刷新模式'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _setMultiDisplayMode(MultiDisplayMode.extend),
                            icon: Icon(Icons.open_in_full),
                            label: Text('扩展这些显示器'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentMultiDisplayMode == MultiDisplayMode.extend ? Colors.blue : null,
                            ),
                          ),
                          // 当显示器数量>=3时，只允许扩展模式
                          if (displays.length < 3) ...[
                            ElevatedButton.icon(
                              onPressed: () => _setMultiDisplayMode(MultiDisplayMode.duplicate),
                              icon: Icon(Icons.content_copy),
                              label: Text('复制这些显示器'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentMultiDisplayMode == MultiDisplayMode.duplicate ? Colors.blue : null,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _setMultiDisplayMode(MultiDisplayMode.primaryOnly),
                              icon: Icon(Icons.looks_one),
                              label: Text('仅在显示器1上显示'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentMultiDisplayMode == MultiDisplayMode.primaryOnly ? Colors.blue : null,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _setMultiDisplayMode(MultiDisplayMode.secondaryOnly),
                              icon: Icon(Icons.looks_two),
                              label: Text('仅在显示器2上显示'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentMultiDisplayMode == MultiDisplayMode.secondaryOnly ? Colors.blue : null,
                              ),
                            ),
                          ] else ...[
                            // 当显示器>=3时，显示提示信息
                            Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info, color: Colors.orange, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '当连接3个或更多显示器时，只能使用扩展模式',
                                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // 创建显示器的控制区域
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '创建新显示器',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _createDefaultDisplay,
                          child: Text('创建默认显示器'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _loadDisplays,
                          child: Text('获取显示器列表'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Custom Display Configurations section
            if (customConfigs.isNotEmpty) ...[
              Text(
                '自定义可配置显示器分辨率',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: customConfigs.length,
                  itemBuilder: (context, index) {
                    final config = customConfigs[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 4.0),
                      child: ListTile(
                        title: Text('${config['width']}x${config['height']} @ ${config['refreshRate']}Hz'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeCustomConfig(index),
                          tooltip: 'Remove',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addCustomConfig,
                  child: Text('添加自定义分辨率（Admin）'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadCustomConfigs,
                  child: Text('加载已添加分辨率'),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // 显示器列表
            Text(
              '显示器列表 (${displays.length}个)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (displays.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.display_settings, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无显示器', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('点击上方按钮创建或获取显示器', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: displays.map((display) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: display.isPrimary 
                              ? Colors.orange 
                              : (display.isVirtual ? Colors.blue : Colors.green),
                          child: Text('${display.index}'),
                        ),
                        title: Text(display.displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('分辨率: ${display.width}x${display.height}'),
                            Text('刷新率: ${display.refreshRate}Hz'),
                            Text('类型: ${display.isVirtual ? "虚拟显示器" : "物理显示器"}${display.isPrimary ? " (主显示器)" : ""}'),
                            Text('方向: ${_getOrientationName(display.orientation)}'),
                            Text('坐标: (${display.left}, ${display.top}) - (${display.right}, ${display.bottom})'),
                            Text('设备: ${display.deviceName}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<DisplayOrientation>(
                              icon: Icon(Icons.screen_rotation, color: Colors.orange),
                              tooltip: '旋转屏幕',
                              onSelected: (orientation) => _setDisplayOrientation(display.displayUid, orientation),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: DisplayOrientation.landscape,
                                  child: Text('横向 (0°)'),
                                ),
                                PopupMenuItem(
                                  value: DisplayOrientation.portrait,
                                  child: Text('竖向 (90°)'),
                                ),
                                PopupMenuItem(
                                  value: DisplayOrientation.landscapeFlipped,
                                  child: Text('横向翻转 (180°)'),
                                ),
                                PopupMenuItem(
                                  value: DisplayOrientation.portraitFlipped,
                                  child: Text('竖向翻转 (270°)'),
                                ),
                              ],
                            ),
                            if (display.isVirtual) ...[
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showChangeDisplayDialog(display),
                                tooltip: '修改',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeDisplay(display.displayUid),
                                tooltip: '删除',
                              ),
                            ] else
                              Icon(Icons.lock, color: Colors.grey, size: 20),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
