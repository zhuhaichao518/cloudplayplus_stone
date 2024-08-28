import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

class StreamingSession {
  StreamingSessionConnectionState connectionState =
      StreamingSessionConnectionState.free;
  Device controller, controlled;
  late RTCPeerConnection video;
  late RTCPeerConnection audio;

  MediaStream? _localVideoStream;
  MediaStream? _localAudioStream;

  RTCRtpSender? videoSender;
  RTCRtpSender? audioSender;
  late RTCDataChannel channel;

  StreamingSession(this.controller, this.controlled) {
    connectionState = StreamingSessionConnectionState.free;
  }

  void startRequest() {
    assert(connectionState == StreamingSessionConnectionState.free);
    if (controller.websocketSessionid != AppStateService.websocketSessionid) {
      VLOG0("requiring connection on wrong device. Please debug.");
      return;
    }
    WebSocketService.send('requestRemoteControl', {
      'target_uid':
          controlled.uid == -1 ? ApplicationInfo.user.uid : controlled.uid,
      'target_connectionid': controlled.websocketSessionid,
      'settings': StreamingSettings.toJson(),
    });
    connectionState = StreamingSessionConnectionState.requestSent;
  }

  //accept request and send offer to the peer. you should verify this is authorized before calling this funciton.
  void acceptRequest(StreamedSettings settings) async {
    assert(connectionState == StreamingSessionConnectionState.free);
    if (controlled.websocketSessionid != AppStateService.websocketSessionid) {
      VLOG0("requiring connection on wrong device. Please debug.");
      return;
    }

    final Map<String, dynamic> mediaConstraints;
    if (AppPlatform.isWeb) {
      mediaConstraints = {
        'audio': false,
        'video': {
          'frameRate': {'ideal': settings.framerate, 'max': settings.framerate}
        }
      };
    } else {
      var sources =
          await desktopCapturer.getSources(types: [SourceType.Screen]);
      //Todo(haichao): currently this should have no effect. we should change it to be right.
      final source = sources[0];
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

    _localVideoStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

    Map<String, dynamic> iceServers;
    if (settings.turnServerSettings == 0) {
      iceServers = {
        'iceServers': [
          {
            'urls': settings.turnServerAddress,
            'username': settings.turnServerUsername,
            'credential': settings.turnServerPassword
          },
        ]
      };
    } else {
      iceServers = {
        'iceServers': [
          {
            'urls': settings.turnServerAddress,
            'username': settings.turnServerUsername,
            'credential': settings.turnServerPassword
          },
        ]
      };
    }

    final Map<String, dynamic> config = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ]
    };

    video = await createPeerConnection({
      ...iceServers,
      ...{'sdpSemantics': 'unified-plan'}
    }, config);

    if (_localVideoStream != null) {
      // one track expected.
      _localVideoStream!.getTracks().forEach((track) async {
        videoSender = (await video.addTrack(track, _localVideoStream!));
      });
    }

    var transceivers = await video.getTransceivers();
    var vcaps = await getRtpSenderCapabilities('video');
    for (var transceiver in transceivers) {
      var codecs = vcaps.codecs
              ?.where(
                  (element) => element.mimeType.toLowerCase().contains('h264'))
              .toList() ??
          [];
      transceiver.setCodecPreferences(codecs);
    }

    video.onIceCandidate = (candidate) async {
      if (settings.turnServerSettings == 2) {
        if (!candidate.candidate!.contains("srflx")) {
          return;
        }
      }
      if (settings.turnServerSettings == 1) {
        if (candidate.candidate!.contains("srflx")) {
          return;
        }
      }
      await Future.delayed(
          const Duration(seconds: 1),
          () => WebSocketService.send('candidate', {
                'to': controller.websocketSessionid,
                'from': controlled.websocketSessionid,
                'candidate': {
                  'sdpMLineIndex': candidate.sdpMLineIndex,
                  'sdpMid': candidate.sdpMid,
                  'candidate': candidate.candidate,
                },
              }));
    };

    //TODO:Create offer

    connectionState = StreamingSessionConnectionState.offerSent;
  }

  void onOfferReceived(Map description) {}

  void onCandidateReceived() {}

  void stop() async {}
}
