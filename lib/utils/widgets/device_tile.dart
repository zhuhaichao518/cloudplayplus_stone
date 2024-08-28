import 'package:flutter/material.dart';
import '../../entities/device.dart';
import '../../services/app_info_service.dart';
import 'device_tile_page.dart';

class DeviceTile extends StatelessWidget {
  final Device device;

  DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0, // 卡片阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // 圆角
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeviceDetailPage(device: device),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(getIconData(device.devicetype), size: 60),
            SizedBox(height: 8), // 间距
            Text(
              "sb",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4), // 间距
            Text(
              device.uid == ApplicationInfo.user.uid
                  ? "(Yourself)"
                  : device.uid == ApplicationInfo.user.uid
                      ? ""
                      : "(Shared by ${device.nickname})",
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              "App ID: ${device.websocketSessionid}",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  IconData getIconData(String deviceType) {
    switch (deviceType) {
      case 'Windows':
        return Icons.computer;
      case 'Android':
        return Icons.phone_android;
      case 'MacOS':
        return Icons.laptop_mac;
      case 'IOS':
        return Icons.phone_iphone;
      case 'Web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }
}
