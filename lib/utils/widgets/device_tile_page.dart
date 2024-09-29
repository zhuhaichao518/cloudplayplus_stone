import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/utils/widgets/global_remote_screen_renderer.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_keyboard.dart';
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
    _shareController = TextEditingController();
    //StreamingManager.updateRendererCallback(widget.device, updateVideoRenderer);
  }

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  bool inbuilding = true;
  bool needSetstate = false;
  int _selectedMonitorId = 1;
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    inbuilding = true;

    WebrtcService.updateCurrentRenderingDevice(
        widget.device.websocketSessionid, onRemoteScreenReceived);

    if (StreamingManager.getStreamingStateto(widget.device) ==
        StreamingSessionConnectionState.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScreenController.setshowDetailUseScrollView(false);
        ScreenController.setShowDetailTitle(false);
      });
      return Stack(
        children: [
          const GlobalRemoteScreenRenderer(),
          FloatingMenuPanel(
            onPressed: (index) async {
              if (index == 0) {
                await ScreenController.setIsFullScreen(
                    !ScreenController.isFullScreen);
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
                ScreenController.setOnlyShowRemoteScreen(false);
                StreamingManager.stopStreaming(widget.device);
              }
            },
            buttons: const [
              Icons.crop_free,
              Icons.open_in_full,
              Icons.keyboard,
              Icons.close,
            ],
          ),
        ],
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenController.setshowDetailUseScrollView(true);
      ScreenController.setShowDetailTitle(true);
      ScreenController.setOnlyShowRemoteScreen(false);
    });
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), // 增加内边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 使用更大的字体和粗体来突出设备类型
          Text(
            "设备名称:${widget.device.devicename}",
          ),
          SizedBox(height: 16), // 增加垂直间距
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
                      StreamingSettings.targetScreenId = value - 1;
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
  }

  void _connectDevice(BuildContext context) {
    // 连接设备的逻辑
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
