import 'package:flutter/material.dart';

import '../../entities/device.dart';
import '../../services/app_info_service.dart';

class DeviceDetailPage extends StatefulWidget {
  final Device device;

  DeviceDetailPage({required this.device});

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final TextEditingController _userIdController = TextEditingController();
  List<String> sharedUsers = []; // 存储设备被分享给的用户ID

  @override
  Widget build(BuildContext context) {
    return
   Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            //Icon(Icons.device_unknown, size: 100), // 示例图标，根据需要调整
            Text(widget.device.devicename),
            Text(widget.device.devicetype),
            Text("应用ID: ${widget.device.websocketSessionid}"),
            ElevatedButton(
              onPressed: () {
                /*if (widget.device.appid != ApplicationInfoServiceImpl().appid) {
                  WebSocketServiceImpl().requestRemoteScreen(widget.device);
                }*/
              },
              child: Text('连接设备'),
            ),
            if (widget.device.uid == ApplicationInfo.user.uid)TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: '你想分享给的用户ID'),
            ),
            if (widget.device.uid == ApplicationInfo.user.uid)ElevatedButton(
              onPressed: _shareDevice,
              child: Text('共享'),
            ),
            ...sharedUsers.map((userId) => Text('分享给(关闭app后会停止共享): $userId')).toList(),
          ],
        ),
      );
  }


  void _shareDevice() async{
    // 假设有一个服务方法来处理设备分享逻辑
    // 这里的代码应该调用那个服务，以下是示意性逻辑
    /*String nickname = await ApiServiceImpl().requestNickName(_userIdController.text);
    if (nickname == "未找到用户。您输入的UID不正确。"){
      setState(() {
        sharedUsers.add(nickname);
      });
      _userIdController.clear();
      return;
    }
    
    WebSocketServiceImpl().sharedDevice(_userIdController.text);
    setState(() {
      sharedUsers.add(nickname);
    });
    _userIdController.clear();*/
    // 实际的共享逻辑应该在这里实现，比如调用后端API
  }


  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}
