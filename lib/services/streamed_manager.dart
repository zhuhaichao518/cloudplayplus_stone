//这个文件负责管理所有别的app控制本电脑的状态。
import 'package:cloudplayplus/global_settings/streaming_settings.dart';

import '../base/logging.dart';
import '../entities/device.dart';
import '../entities/session.dart';
import 'app_info_service.dart';

class StreamedManager {
  static Map<String, StreamingSession> sessions = {};

  static void startStreaming(Device target, StreamedSettings settings) {
    if (sessions.containsKey(target.websocketSessionid)) {
      VLOG0(
          "Starting session which is already started: $target.websocketSessionid");
      return;
    }
    StreamingSession session =
        StreamingSession(target, ApplicationInfo.thisDevice);
    session.acceptRequest(settings);
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

  static void onAnswerReceived(
      String targetConnectionid, Map<String, dynamic> answer) {
    if (sessions.containsKey(targetConnectionid)) {
      StreamingSession? session = sessions[targetConnectionid];
      session?.onAnswerReceived(answer);
    } else {
      VLOG0("No session found with sessionId: $targetConnectionid");
    }
  }

  static void onCandidateReceived(
      String targetConnectionid, Map<String, dynamic> candidate) {
    if (sessions.containsKey(targetConnectionid)) {
      StreamingSession? session = sessions[targetConnectionid];
      session?.onCandidateReceived(candidate);
    } else {
      VLOG0("No session found with sessionId: $targetConnectionid");
    }
  }
}
