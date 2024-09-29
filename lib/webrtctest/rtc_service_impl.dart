import 'package:cloudplayplus/base/logging.dart';

import 'turn.dart' if (dart.library.js) 'turn_web.dart';

class RTCServiceImpl {
  RTCServiceImpl._internal();

  static final RTCServiceImpl _instance = RTCServiceImpl._internal();

  factory RTCServiceImpl() {
    return _instance;
  }

  // ignore: prefer_typing_uninitialized_variables
  var _turnCredential;

  Future<Map<String, dynamic>> get iceservers async {
    _turnCredential ??= await getTurnCredential('20.2.208.38', 8086);
    Map<String, dynamic> iceServers = {
      'iceServers': [
        {
          'urls': _turnCredential['uris'][0],
          'username': _turnCredential['username'],
          'credential': _turnCredential['password']
        },
      ]
    };
    VLOG0("got iceservers:$iceServers");
    return iceServers;
  }
}
