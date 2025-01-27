import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:cloudplayplus/utils/widgets/global_remote_screen_renderer.dart';
import 'package:cloudplayplus/utils/widgets/message_box.dart';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';
import '../../base/logging.dart';
import '../../entities/device.dart';
import '../../entities/session.dart';
import '../../services/app_info_service.dart'; // 假设你的Device实体在这里定义
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/webrtc_service.dart';

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
                      ScreenController.setOnlyShowRemoteScreen(
                          true);
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
                      ScreenController.setShowVirtualMouse(!ScreenController.showVirtualMouse.value);
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
                SizedBox(height: 48), // 增加垂直间距
                // 使用按钮来提供连接设备的交互
                //widget.device.websocketSessionid ==
                //        ApplicationInfo.thisDevice.websocketSessionid?
                ElevatedButton(
                  onPressed: () => _connectDevice(context),
                  child: const Text('连接设备', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // : Container(),
                SizedBox(height: 24), // 增加垂直间距
                // 如果设备是用户的，显示分享组件
                if (widget.device.uid == ApplicationInfo.user.uid) ...[
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
                ],
              ],
            ),
          );
        });
  }

  void _connectDevice(BuildContext context) {
    // 连接设备的逻辑
    StreamingSettings.updateScreenId(_selectedMonitorId - 1);
    StreamingManager.startStreaming(widget.device);
    VLOG0('连接设备: ${widget.device.devicename}');
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
