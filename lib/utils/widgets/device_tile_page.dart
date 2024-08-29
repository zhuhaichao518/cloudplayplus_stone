import 'package:cloudplayplus/services/app_init_service.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../base/logging.dart';
import '../../entities/device.dart';
import '../../services/app_info_service.dart'; // 假设你的Device实体在这里定义
import 'package:qr_flutter/qr_flutter.dart';

class DeviceDetailPage extends StatefulWidget {
  final Device device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late TextEditingController _shareController;
  bool _showVideo = false;
  RTCVideoRenderer? _videoRenderer;

  void updateVideoRenderer(String mediatype, MediaStream stream) {
    setState(() {
      _videoRenderer = RTCVideoRenderer();
      _videoRenderer?.initialize().then((data) {
        _videoRenderer!.srcObject = stream;
        _showVideo = true;
      }).catchError((error) {
        VLOG0('Error: failed to create RTCVideoRenderer');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _shareController = TextEditingController();
    StreamingManager.updateRendererCallback(widget.device, updateVideoRenderer);
  }

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  double aspectRatio = 1920 / 1080;
  void setAspectRatio(double ratio) {
    aspectRatio = ratio;
  }

  @override
  Widget build(BuildContext context) {
    StreamingManager.updateRendererCallback(widget.device, updateVideoRenderer);
    if (_showVideo) {
      return SizedBox(
        height: MediaQuery.of(context).size.height, // 给 Column 明确的高度
        child: Column(
          children: [
            Expanded(
              child: RTCVideoView(_videoRenderer!, setAspectRatio: setAspectRatio),
            ),
          ],
        ),
      );
    }
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
          // 使用装饰文本来展示应用ID
          Text(
            "会话ID: ${widget.device.websocketSessionid.toString().substring(widget.device.websocketSessionid.toString().length - 6)}",
          ),
          SizedBox(height: 48), // 增加垂直间距
          // 使用按钮来提供连接设备的交互
          widget.device.websocketSessionid ==
                  ApplicationInfo.thisDevice.websocketSessionid
              ? ElevatedButton(
                  onPressed: () => _connectDevice(context),
                  child: const Text('连接设备', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : Container(),
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
