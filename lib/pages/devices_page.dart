import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter/material.dart';
import '../../../plugins/flutter_master_detail/flutter_master_detail.dart';
import '../utils/icon_builder.dart';
import 'master_detail/data/fantasy_list.dart';
import 'master_detail/types/fantasy.dart';

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
          return Text("initializing");
        }
        if (key == 27) {
          return Text("my own devices");
        }
        return Text("shared by");
      },
      masterItemBuilder: _buildListTile,
      detailsTitleBuilder: (context, data) => FlexibleSpaceBar(
        title: Text(data.devicetype),
        centerTitle: false,
      ),
      detailsItemBuilder: (context, data) => Center(
        child: Text(data.devicename),
      ),
      sortBy: (data) => data.devicename,
      title: const FlexibleSpaceBar(
        title: Text("Contacts"),
      ),
      masterViewFraction: 0.5,
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
