//这个文件负责管理所有由本app远程控制别的app的状态。
import '../base/logging.dart';
import '../entities/device.dart';
import '../entities/session.dart';
import 'app_info_service.dart';

class StreamingManager {
  static Map<String, StreamingSession> sessions = {};

  static void startStreaming(Device target) {
    if (sessions.containsKey(target.websocketSessionid)) {
      VLOG0("Initializing session which is already initialized: $target.websocketSessionid");
      return;
    }
    StreamingSession session = StreamingSession(ApplicationInfo.thisDevice, target);
    session.start();
    sessions[target.websocketSessionid] = session;
  }

  static void stopStreaming(Device target) {
    if (sessions.containsKey(target.websocketSessionid)) {
      StreamingSession? session = sessions[target.websocketSessionid];
      session?.stop();
      sessions.remove(target.websocketSessionid);
    } else {
      VLOG0("No session found with sessionId: $target.websocketSessionid");
    }
  }
}