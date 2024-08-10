class Device {
  //都用基本类型 传输简便
  final int uid;
  final String nickname;
  final String devicename;
  final String devicetype;
  final String websocketSessionid;
  //allow this device to be connected
  final bool connective;

  Device(
      {required this.uid,
      required this.nickname,
      required this.devicename,
      required this.devicetype,
      required this.websocketSessionid,
      required this.connective});
}

final defaultDeviceList = [
  Device(
    uid: 0, nickname: 'initializing...', devicename: 'initializing...', devicetype: 'initializing...', websocketSessionid: '', connective: false,
  )
];