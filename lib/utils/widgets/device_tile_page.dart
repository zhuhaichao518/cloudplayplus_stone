import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:cloudplayplus/utils/system_tray_manager.dart';
import 'package:cloudplayplus/utils/widgets/global_remote_screen_renderer.dart';
import 'package:cloudplayplus/utils/widgets/message_box.dart';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import '../../base/logging.dart';
import '../../entities/device.dart';
import '../../entities/session.dart';
import '../../services/app_info_service.dart';
import '../../services/webrtc_service.dart';
import '../hash_util.dart';

class DeviceDetailPage extends StatefulWidget {
  final Device device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late TextEditingController _shareController;
  late TextEditingController _deviceNameController;

  /*void updateVideoRenderer(String mediatype, MediaStream stream) {
    setState(() {
      _videoRenderer = RTCVideoRenderer();
      _videoRenderer?.initialize().then((data) {
        _videoRenderer!.srcObject = stream;
        _showVideo = true;
      }).catchError((error) {
        VLOG0('Error: failed to create RTCVideoRenderer');
      });
    });
  }*/

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController();
    _shareController = TextEditingController();
    //StreamingManager.updateRendererCallback(widget.device, updateVideoRenderer);
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _shareController.dispose();
    super.dispose();
  }

  bool inbuilding = true;
  bool needSetstate = false;
  int _selectedMonitorId = 1;
  bool _editingDeviceName = false;
  /*void setAspectRatio(double ratio) {
    if (aspectRatio == ratio) return;
    aspectRatio = ratio;
    if (inbuilding) {
      needSetstate = true;
    }else{
      setState(() {
      });
    }
  }*/

  // callback and trigger rebuild when StreamingSessionConnectionState is updated.
  void onRemoteScreenReceived() {
    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    inbuilding = true;

    MessageBoxManager().init(context);
    WebrtcService.updateCurrentRenderingDevice(
        widget.device.websocketSessionid, onRemoteScreenReceived);

    return ValueListenableBuilder<StreamingSessionConnectionState>(
        valueListenable: widget.device.connectionState,
        builder: (context, value, child) {
          if (value == StreamingSessionConnectionState.connceting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),
                  CircularProgressIndicator(), // 显示加载动画
                  SizedBox(height: 16), // 添加加载动画和文字之间的间距
                  Text(
                    '正在连接远程桌面...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          if (value == StreamingSessionConnectionState.connected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScreenController.showDetailUseScrollView.value = false;
            });
            return Stack(
              children: [
                const GlobalRemoteScreenRenderer(),
                FloatingMenuPanel(
                  onPressed: (index) async {
                    if (index == 0) {
                      await ScreenController.setIsFullScreen(
                          !ScreenController.isFullScreen);
                      ScreenController.setOnlyShowRemoteScreen(true);
                    }
                    if (index == 1) {
                      /*ScreenController.setShowNavBar(
                          !ScreenController.showBottomNav.value);
                      ScreenController.setShowMasterList(!ScreenController.showMasterList.value);*/
                      ScreenController.setOnlyShowRemoteScreen(
                          !ScreenController.onlyShowRemoteScreen);
                    }
                    if (index == 2) {
                      ScreenController.setShowVirtualKeyboard(
                          !ScreenController.showVirtualKeyboard.value);
                    }
                    if (index == 3) {
                      ScreenController.setShowVirtualMouse(
                          !ScreenController.showVirtualMouse.value);
                    }
                    if (index == 4) {
                      ScreenController.setshowDetailUseScrollView(true);
                      ScreenController.setOnlyShowRemoteScreen(false);
                      StreamingManager.stopStreaming(widget.device);
                    }
                  },
                  buttons: const [
                    Icons.crop_free,
                    Icons.open_in_full,
                    Icons.keyboard,
                    Icons.mouse,
                    Icons.close,
                  ],
                ),
              ],
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScreenController.showDetailUseScrollView.value = true;
            ScreenController.setOnlyShowRemoteScreen(false);
          });
          return SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), // 增加内边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // 使用更大的字体和粗体来突出设备类型
                const Text(
                  "设备名称:",
                  style: TextStyle(fontWeight: FontWeight.bold), // 突出显示标签
                ),
                const SizedBox(width: 16), // 增加一些水平间距
                // 用 Container 设置宽度，避免使用 Expanded
                _editingDeviceName
                    ? Container(
                        width: 300, // 可以根据需要调整宽度
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: InputDecoration(
                            hintText: widget.device.devicename, // 提示文本
                          ),
                          onChanged: (newName) {
                            // 将新名称存储在一个临时变量中
                            setState(() {
                              //_newDeviceName = newName;
                            });
                          },
                        ),
                      )
                    : Text(
                        widget.device.devicename,
                      ),
                SizedBox(height: 8),
                if (widget.device.websocketSessionid ==
                    ApplicationInfo.thisDevice.websocketSessionid)
                  ElevatedButton(
                    onPressed: () {
                      if (!_editingDeviceName) {
                        setState(() {
                          _editingDeviceName = true;
                        });
                      } else {
                        setState(() {
                          _editingDeviceName = false;
                          widget.device.devicename = _deviceNameController.text;
                          ApplicationInfo.deviceNameOverride =
                              _deviceNameController.text;
                          SharedPreferencesManager.setString(
                              "deviceNameOverride", _deviceNameController.text);
                          WebSocketService.updateDeviceInfo();
                        });
                      }
                    },
                    child: const Text("编辑设备名"),
                  ),
                const SizedBox(height: 16), // 增加垂直间距
                // 使用更大的字体和粗体来突出设备类型
                Text(
                  "设备平台:${widget.device.devicetype}",
                ),
                SizedBox(height: 16), // 增加垂直间距
                if (widget.device.screencount > 1)
                  for (int i = 1; i <= widget.device.screencount; i++)
                    ListTile(
                      title: Text('显示器 $i'),
                      leading: Radio(
                        value: i,
                        groupValue: _selectedMonitorId,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedMonitorId = value!;
                          });
                        },
                      ),
                    ),
                SizedBox(height: 16), // 增加垂直间距
                // 使用装饰文本来展示应用ID
                Text(
                  "会话ID: ${widget.device.websocketSessionid.toString().substring(widget.device.websocketSessionid.toString().length - 6)}",
                ),
                SizedBox(height: 16), // 增加垂直间距
                (widget.device.websocketSessionid !=
                            ApplicationInfo.thisDevice.websocketSessionid &&
                        widget.device.connective)
                    ? TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '连接密码',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Container(),
                SizedBox(height: 16),
                // 使用按钮来提供连接设备的交互
                (widget.device.websocketSessionid !=
                            ApplicationInfo.thisDevice.websocketSessionid &&
                        widget.device.connective)
                    ? ElevatedButton(
                        onPressed: () => _connectDevice(context),
                        child:
                            const Text('连接设备', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : (widget.device.websocketSessionid !=
                            ApplicationInfo.thisDevice.websocketSessionid || AppPlatform.isMobile)
                        ? const SizedBox()
                        : ApplicationInfo
                                .connectable /* || (AppPlatform.isWindows && (ApplicationInfo.isSystem || SharedPreferencesManager.getBool('allowConnect')==true))*/
                            ? ElevatedButton(
                                onPressed: () => _unhostDevice(context),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('不允许本设备被连接',
                                    style: TextStyle(fontSize: 18)),
                              )
                            : ElevatedButton(
                                onPressed: () => _hostDevice(context),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('允许本设备被连接',
                                    style: TextStyle(fontSize: 18)),
                              ),
                const SizedBox(height: 24), // 增加垂直间距
                // 如果设备是用户的，显示分享组件
/*                if (widget.device.uid == ApplicationInfo.user.uid) ...[
                  TextField(
                    controller: _shareController,
                    decoration: InputDecoration(
                      labelText: '分享给...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24), // 增加垂直间距
                  QrImageView(
                    data: 'https://www.cloudplayplus.com',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  ElevatedButton(
                    onPressed: () => _shareDevice(context),
                    child: Text('共享设备', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                        // 按钮样式
                        ),
                  ),
                ],*/
              ],
            ),
          );
        });
  }

  /*
  Future<String?> _showPasswordDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("二级密码（无密码不填）"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "请输入密码",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("确定"),
            ),
          ],
        );
      },
    );
  }
  */
  final TextEditingController _passwordController = TextEditingController();

  void _connectDevice(BuildContext context) async {
    // 连接设备的逻辑
    // String? password = await _showPasswordDialog(context);
    // if (password == null) return;
    StreamingSettings.updateScreenId(_selectedMonitorId - 1);
    StreamingSettings.connectPassword = _passwordController.text;
    StreamingManager.startStreaming(widget.device);
    VLOG0('连接设备: ${widget.device.devicename}');
  }

  TextEditingController passwordController = TextEditingController();

  void _unhostDevice(BuildContext context) {
    ApplicationInfo.connectable = false;
    SharedPreferencesManager.setBool('allowConnect', false);
    setState(() {});
    WebSocketService.updateDeviceInfo();
    if (AppPlatform.isWindows) {
      //这样写会有个问题就是用户打开系统权限的app取消注册会退出app 暂时先这样吧
      //HardwareSimulator.unregisterService();
    }
  }

  void _hostDevice(BuildContext context) async {
    if (AppPlatform.isWindows && ApplicationInfo.isSystem == false) {
      String? result1 = await showDialog<String>(
        context: context,
        barrierDismissible: false, // 不允许点击外部关闭
        builder: (context) {
          return AlertDialog(
            title: const Text("以系统权限运行"),
            content: const Text(
                "抓取UAC窗口需要系统权限。点击确定以系统权限重新启动APP(可在系统托盘退出)。取消则以当前权限抓取,可能导致无法抓取或者操作部分内容。"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null), // 取消返回 null
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, "OK"), // 返回密码
                child: const Text('确认'),
              ),
            ],
          );
        },
      );
      if (result1 != null) {
        await HardwareSimulator.registerService();
        Future.delayed(const Duration(seconds: 2), () {
          SystemTrayManager().exitApp();
        });
      }
    }

    //主持设备
    var txt = '请设置密码，不填则无密码';
    String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) {
        return AlertDialog(
          title: Text(txt),
          content: TextField(
            controller: passwordController,
            obscureText: true, // 隐藏输入
            decoration: InputDecoration(
              labelText: '二级密码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // 取消返回 null
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, passwordController.text), // 返回密码
              child: Text('确认'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      SharedPreferencesManager.setBool('allowConnect', true);
      String hash = HashUtil.hash(result);
      SharedPreferencesManager.setString("connectPasswordHash", hash);
      ApplicationInfo.connectable = true;
      StreamingSettings.connectPasswordHash = hash;
    }
    setState(() {});
    WebSocketService.updateDeviceInfo();
  }

  void _shareDevice(BuildContext context) {
    // 共享设备的逻辑
    print('共享设备给用户: ${_shareController.text}');
  }

  void _removeSharedUser(String userId) {
    // 移除共享用户的逻辑
    print('移除共享用户: $userId');
  }
}
