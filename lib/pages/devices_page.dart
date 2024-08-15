import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter/material.dart';
import '../../../plugins/flutter_master_detail/flutter_master_detail.dart';
import '../services/app_info_service.dart';
import '../utils/icon_builder.dart';
import '../utils/widgets/device_tile_page.dart';

class DevicesPage extends StatefulWidget {
  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<Device> _deviceList = defaultDeviceList;

  // 更新列表的方法
  void _updateList(devicelist) {
    setState(() {
      // 假设我们添加了一个新的Fantasy对象到列表
      _deviceList.clear();
      for (Map device in devicelist){
        if (device['owner_id'] == ApplicationInfo.user.uid){
          //We set owner id to -1 to identify it is the device of ourself.
          device['owner_id'] = -1;
        }
        _deviceList.add(Device(uid: device['owner_id'], nickname: device['owner_nickname'], devicename: device['device_name'], devicetype: device['device_type'], websocketSessionid: device['connection_id'], connective: device['connective']));
      }
    });
  }
  
  _registerCallbacks(){
    // It is nearly impossible WS receive response before we register here. So fell free. 
    WebSocketService.onDeviceListchanged = _updateList;
  }

  _unregisterCallbacks(){
    WebSocketService.onDeviceListchanged = null;
  }

  @override
  void initState() {
    super.initState();
    _registerCallbacks();
  }

  @override
  void dispose() {
    _unregisterCallbacks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterDetailsList<Device>(
      items: _deviceList, // 使用_fantasyList作为数据源
      groupedBy: (data) => data.uid,
      groupHeaderBuilder:(context, key, itemsCount) {
        if (key == 0) {
          return Theme(
            // 使用当前主题
            data: Theme.of(context),
            child: ListTile(
              title: Text(
                "初始化...",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyText1?.color, // 使用主题中定义的文本颜色
                  fontSize: 18, // 根据需要设置字体大小
                  fontWeight: FontWeight.bold, // 加粗文本
                ),
              ),
              tileColor: Theme.of(context).primaryColor, // 使用主题中定义的主要颜色作为背景
            ),
          );
        }
        if (key.value[0].uid == -1) {
          return Theme(
            // 使用当前主题
            data: Theme.of(context),
            child: ListTile(
              title: Text(
                "我的设备",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color, // 使用主题中定义的文本颜色
                  fontSize: 18, // 根据需要设置字体大小
                  fontWeight: FontWeight.bold, // 加粗文本
                ),
              ),
              tileColor: Theme.of(context).primaryColor, // 使用主题中定义的主要颜色作为背景
            ),
          );
        }
        return Theme(
            // 使用当前主题
            data: Theme.of(context),
            child: ListTile(
              title: Text(
                key.value[0].nickname,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color, // 使用主题中定义的文本颜色
                  fontSize: 18, // 根据需要设置字体大小
                  fontWeight: FontWeight.bold, // 加粗文本
                ),
              ),
              tileColor: Theme.of(context).primaryColor, // 使用主题中定义的主要颜色作为背景
            ),
          );
      },
      masterItemBuilder: _buildListTile,
      detailsTitleBuilder: (context, data) => FlexibleSpaceBar(
        title: Text(data.devicename,style: const TextStyle(color: Colors.black),),
        centerTitle: false,
      ),
      detailsItemBuilder: (context, data) => DeviceDetailPage(device:data),
      sortBy: (data) => data.uid,
      //TODO(haichao): how it is used?
      /*title: const FlexibleSpaceBar(
        title: Text("Cloud Play Plus"),
      ),*/
      masterViewFraction: 0.8,
    );
  }


  Widget _buildListTile(
    BuildContext context,
    Device data,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(data.devicename),
      //subtitle: Text(data.devicetype),
      trailing: IconBuilder.findIconByName(data.devicetype),
      selected: isSelected,
    );
  }
}
