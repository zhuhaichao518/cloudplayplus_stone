import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/websocket_service.dart';

import '../base/logging.dart';
import '../global_settings/streaming_settings.dart';
import '../services/app_info_service.dart';

/*
每个启动的app均有两个state controlstate是作为控制端的state hoststate是作为被控端的state
整个连接建立过程：
                            A controlstate = free     B hoststate = free
A向B发起控制请求             A controlstate = control request sent 
B收到request后向A发起offer   B hoststate = offer sent
A收到offer后向B发起answer    A controlstate = answer sent
B收到answer后                B hoststate = answerreceived
中间可能有一些candidate消息 。。。
直到data channel中收到对方的ping A controlstate = connected  B hoststate = connected
*/
enum StreamingSessionConnectionState {
  free,
  requestSent,
  offerSent, 
  answerSent, 
  answerReceived,
  disconnected,
}
class StreamingSession{
  StreamingSessionConnectionState connectionState = StreamingSessionConnectionState.free;
  Device controller, controlled;

  StreamingSession(this.controller, this.controlled){
    connectionState = StreamingSessionConnectionState.free;
  }

  void start(){
    if (controller.websocketSessionid!=AppStateService.websocketSessionid){
      VLOG0("requiring connection on wrong device. Please debug.");
      return;
    }
    WebSocketService.send('requestRemoteControl',
    {
      'target_uid': controlled.uid == -1? ApplicationInfo.user.uid:controlled.uid,
      'target_connectionid': controlled.websocketSessionid,
      'settings': StreamingSettings.toJson(),
    });
  }

  void stop() async{

  }
}