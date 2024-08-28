import 'package:cloudplayplus/services/app_init_service.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:flutter/material.dart';
import '../../base/logging.dart';
import '../../entities/device.dart';
import '../../services/app_info_service.dart'; // 假设你的Device实体在这里定义
import 'package:qr_flutter/qr_flutter.dart';

class DeviceDetailPage extends StatelessWidget {
  final Device device;

  DeviceDetailPage({required this.device});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), // 增加内边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 使用更大的字体和粗体来突出设备类型
          Text(
            "设备名称:${device.devicename}",
          ),
          SizedBox(height: 16), // 增加垂直间距
          // 使用更大的字体和粗体来突出设备类型
          Text(
            "设备平台:${device.devicetype}",
          ),
          SizedBox(height: 16), // 增加垂直间距
          // 使用装饰文本来展示应用ID
          Text(
            "会话ID: ${device.websocketSessionid.toString().substring(device.websocketSessionid.toString().length - 6)}",
          ),
          SizedBox(height: 48), // 增加垂直间距
          // 使用按钮来提供连接设备的交互
          device.websocketSessionid !=
                  ApplicationInfo.thisDevice.websocketSessionid
              ? ElevatedButton(
                  onPressed: () => _connectDevice(context),
                  child: const Text('连接设备', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    //primary: Theme.of(context).colorScheme.secondary, // 使用主题的次要颜色
                    //onPrimary: Theme.of(context).colorScheme.onSecondary, // 文字颜色
                  ),
                )
              : Container(),
          SizedBox(height: 24), // 增加垂直间距
          // 如果设备是用户的，显示分享组件
          if (device.uid == ApplicationInfo.user.uid) ...[
            TextField(
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
          // 显示已共享的用户列表
          /*if (device.sharedUsers.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('已共享给:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 8), // 增加垂直间距
              for (final userId in device.sharedUsers)
                ListTile(
                  title: Text(userId),
                  trailing: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => _removeSharedUser(userId),
                  ),
                ),
              SizedBox(height: 24), // 增加垂直间距
            ],*/
        ],
      ),
    );
  }

  void _connectDevice(BuildContext context) {
    // 连接设备的逻辑
    StreamingManager.startStreaming(device);
    VLOG0('连接设备: ${device.devicename}');
  }

  void _shareDevice(BuildContext context) {
    // 共享设备的逻辑
    final controller = TextEditingController(); // 假设这是获取到的输入
    print('共享设备给用户: ${controller.text}');
  }

  void _removeSharedUser(String userId) {
    // 移除共享用户的逻辑
    print('移除共享用户: $userId');
  }
}
