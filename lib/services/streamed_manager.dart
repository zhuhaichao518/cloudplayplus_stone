//这个文件负责管理所有别的app控制本电脑的状态。
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

import '../base/logging.dart';
import '../entities/device.dart';
import '../entities/session.dart';
import 'app_info_service.dart';

class StreamedManager {
  static Map<String, StreamingSession> sessions = {};

  //We put localstream here because we want sessions share a local stream.
  //Screenid to MediaStream
  static Map<int, MediaStream> localVideoStreams = {};
  static Map<int, int> localVideoStreamsCount = {};
  
  //auto increment. used for cursor hooks.
  static int cursorImageHookID = 0;

  static void startStreaming(Device target, StreamedSettings settings) async {
    acquireLock();
    if (sessions.containsKey(target.websocketSessionid)) {
      VLOG0(
          "Starting session which is already started: $target.websocketSessionid");
      releaseLock();
      return;
    }
    if (!localVideoStreams.containsKey(settings.screenId)) {
      final Map<String, dynamic> mediaConstraints;
      if (AppPlatform.isWeb) {
        mediaConstraints = {
          'audio': false,
          'video': {
            'frameRate': {
              'ideal': settings.framerate,
              'max': settings.framerate
            }
          }
        };
      } else {
        var sources =
            await desktopCapturer.getSources(types: [SourceType.Screen]);
        //Todo(haichao): currently this should have no effect. we should change it to be right.
        final source = sources[settings.screenId!];
        mediaConstraints = <String, dynamic>{
          'video': {
            'deviceId': {'exact': source.id},
            'mandatory': {
              'frameRate': settings.framerate,
              'hideCursor': (settings.showRemoteCursor == false)
            }
          },
          'audio': false
        };
      }
      localVideoStreams[settings.screenId!] =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      localVideoStreamsCount[settings.screenId!] = 1;
    } else {
      localVideoStreamsCount[settings.screenId!] =
          localVideoStreamsCount[settings.screenId!]! + 1;
    }
    StreamingSession session =
        StreamingSession(target, ApplicationInfo.thisDevice);
    cursorImageHookID++;
    session.cursorImageHookID = cursorImageHookID;
    session.acceptRequest(settings);
    sessions[target.websocketSessionid] = session;
    releaseLock();
  }

  static final locker = Mutex();

  static void acquireLock() {
    locker.acquire();
  }

  static void releaseLock() {
    locker.release();
  }

  static void stopStreaming(Device target) {
    acquireLock();
    if (sessions.containsKey(target.websocketSessionid)) {
      StreamingSession? session = sessions[target.websocketSessionid];
      session?.stop();
      int screenId = session!.streamSettings!.screenId!;
      sessions.remove(target.websocketSessionid);
      localVideoStreamsCount[screenId] = localVideoStreamsCount[screenId]! - 1;
      if (localVideoStreamsCount[screenId] == 0) {
        if (localVideoStreams[screenId] != null) {
          localVideoStreams[screenId]?.getTracks().forEach((track) {
            track.stop();
          });
          localVideoStreams.remove(screenId);
        }
      }
      if (sessions.isEmpty) {
        //TODO(Haichao): maybe restart app to save memory? 给用户一个按钮来重启app.
      }
    } else {
      VLOG0("No session found with sessionId: $target.websocketSessionid");
    }
    releaseLock();
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
