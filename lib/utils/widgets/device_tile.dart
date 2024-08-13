import 'dart:math';

import 'package:flutter/material.dart';

import '../../entities/device.dart';
import 'device_tile_page.dart';

class DeviceTile extends StatelessWidget {
  final Device device;

  DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (device.devicetype) {
      case 'Windows':
        iconData = Icons.computer; // 示例，你可能需要自定义图标
        break;
      case 'Android':
        iconData = Icons.phone_android;
      case 'MacOS':
        iconData = Icons.laptop_mac;
      case 'IOS':
        iconData = Icons.phone_iphone;
      case "Web":
        iconData = Icons.web;
      default:
        iconData = Icons.device_unknown;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  // 设定一个合适的高度和宽度
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: DeviceDetailPage(device: device),
                ),
              );
            },
          );
        },
          child: Icon(iconData, size: 150),
        ),
        /*Text(device.devicename +
            (
              (device.appid == ApplicationInfoServiceImpl().appid)
                ? "(yourself)"
                : "")
                +  
                ((device.uid == ApplicationInfoServiceImpl().user.uid)? "":"(来自 ${device.nickname} 的分享)")
                ),
        Text("应用id:${device.appid.substring(min(30, device.appid.length))}"),*/
      ],
    );
  }
}
