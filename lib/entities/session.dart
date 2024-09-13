import 'dart:async';
import 'dart:typed_data';

import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../base/logging.dart';
import '../global_settings/streaming_settings.dart';
import '../services/app_info_service.dart';
import '../services/webrtc_service.dart';
import '../webrtctest/rtc_service_impl.dart';
import 'messages.dart';

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
  connected,
  disconnecting,
  disconnected,
}

enum SelfSessionType {
  none,
  controller,
  controlled,
}

class StreamingSession {
  StreamingSessionConnectionState connectionState =
      StreamingSessionConnectionState.free;
  SelfSessionType selfSessionType = SelfSessionType.none;
  Device controller, controlled;
  RTCPeerConnection? pc;
  //late RTCPeerConnection audio;

  MediaStream? _localVideoStream;
  //MediaStream? _localAudioStream;

  RTCRtpSender? videoSender;
  //RTCRtpSender? audioSender;
  RTCDataChannel? channel;

  //This is the common settings on both.
  StreamedSettings? streamSettings;

  List<RTCIceCandidate> candidates = [];

  StreamingSession(this.controller, this.controlled) {
    connectionState = StreamingSessionConnectionState.free;
  }

  Function(String mediatype, MediaStream stream)? onAddRemoteStream;

  //We are the controller
  void startRequest() async {
    if (connectionState != StreamingSessionConnectionState.free &&
        connectionState != StreamingSessionConnectionState.disconnected) {
      VLOG0("starting connection on which is already started. Please debug.");
      return;
    }

    if (controller.websocketSessionid != AppStateService.websocketSessionid) {
      VLOG0("requiring connection on wrong device. Please debug.");
      return;
    }
    selfSessionType = SelfSessionType.controller;

    await acquireLock();
    streamSettings = StreamedSettings.fromJson(StreamingSettings.toJson());
    connectionState = StreamingSessionConnectionState.requestSent;
    pc = await createRTCPeerConnection();

    pc!.onIceCandidate = (candidate) async {
      if (streamSettings!.turnServerSettings == 2) {
        if (!candidate.candidate!.contains("srflx")) {
          return;
        }
      }
      if (streamSettings!.turnServerSettings == 1) {
        if (candidate.candidate!.contains("srflx")) {
          return;
        }
      }

      /*if (candidate.candidate!.contains("srflx")) {
          return;
        }
      if (!candidate.candidate!.contains("192.168")) {
        return;
      }*/
      // We are controller so source is ourself
      await Future.delayed(
          const Duration(seconds: 1),
          //controller's candidate
          () => WebSocketService.send('candidate2', {
                'source_connectionid': controller.websocketSessionid,
                'target_uid': controlled.uid,
                'target_connectionid': controlled.websocketSessionid,
                'candidate': {
                  'sdpMLineIndex': candidate.sdpMLineIndex,
                  'sdpMid': candidate.sdpMid,
                  'candidate': candidate.candidate,
                },
              }));
    };

    pc!.onTrack = (event) {
      connectionState = StreamingSessionConnectionState.connected;
      //tell the device tile page to render the rtc video.
      //StreamingManager.runUserViewCallback();
      WebrtcService.addStream(controlled.websocketSessionid, event);
      //rtcvideoKey.currentState?.updateVideoRenderer(event.track.kind!, event.streams[0]);
      //We used to this function to render the control. Currently we use overlay for convenience.
      //onAddRemoteStream?.call(event.track.kind!, event.streams[0]);
    };
    pc!.onDataChannel = (newchannel) {
      channel = newchannel;
      channel?.onMessage = (msg) {
        processDataChannelMessageFromHost(msg);
      };
      channel?.send(RTCDataChannelMessage.fromBinary(
          Uint8List.fromList([LP_PING, RP_PING])));
    };
    // read the latest settings from user settings.
    WebSocketService.send('requestRemoteControl', {
      'target_uid': ApplicationInfo.user.uid,
      'target_connectionid': controlled.websocketSessionid,
      'settings': StreamingSettings.toJson(),
    });
    releaseLock();
  }

  Future<RTCPeerConnection> createRTCPeerConnection() async {
    Map<String, dynamic> iceServers;

    if (streamSettings!.turnServerSettings == 2) {
      iceServers = {
        'iceServers': [
          {
            'urls': streamSettings!.turnServerAddress,
            'username': streamSettings!.turnServerUsername,
            'credential': streamSettings!.turnServerPassword
          },
        ]
      };
    } else {
      iceServers = {
        'iceServers': [
          {
            'urls': streamSettings!.turnServerAddress,
            'username': streamSettings!.turnServerUsername,
            'credential': streamSettings!.turnServerPassword
          },
          officialStun1,
        ]
      };
    }

    final Map<String, dynamic> config = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ]
    };

    if (DevelopSettings.useRTCTestServer) {
      iceServers = await RTCServiceImpl().iceservers;
    }

    return createPeerConnection({
      ...iceServers,
      ...{'sdpSemantics': 'unified-plan'}
    }, config);
  }

  //accept request and send offer to the peer. you should verify this is authorized before calling this funciton.
  //We are the 'controlled'.
  void acceptRequest(StreamedSettings settings) async {
    if (connectionState != StreamingSessionConnectionState.free &&
        connectionState != StreamingSessionConnectionState.disconnected) {
      VLOG0("starting connection on which is already started. Please debug.");
      return;
    }
    if (controlled.websocketSessionid != AppStateService.websocketSessionid) {
      VLOG0("requiring connection on wrong device. Please debug.");
      return;
    }
    selfSessionType = SelfSessionType.controlled;
    await acquireLock();
    streamSettings = settings;
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

    _localVideoStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

    pc = await createRTCPeerConnection();

    if (_localVideoStream != null) {
      // one track expected.
      _localVideoStream!.getTracks().forEach((track) async {
        videoSender = (await pc!.addTrack(track, _localVideoStream!));
      });
    }

    var transceivers = await pc!.getTransceivers();
    var vcaps = await getRtpSenderCapabilities('video');
    for (var transceiver in transceivers) {
      var codecs = vcaps.codecs
              ?.where(
                  (element) => element.mimeType.toLowerCase().contains('h264'))
              .toList() ??
          [];
      transceiver.setCodecPreferences(codecs);
    }

    pc!.onIceCandidate = (candidate) async {
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

      /*if (candidate.candidate!.contains("srflx")) {
          return;
        }
      if (!candidate.candidate!.contains("192.168")) {
        return;
      }*/
      // We are controlled so source is ourself
      await Future.delayed(
          const Duration(seconds: 1),
          () => WebSocketService.send('candidate', {
                'source_connectionid': controlled.websocketSessionid,
                'target_uid': controller.uid,
                'target_connectionid': controller.websocketSessionid,
                'candidate': {
                  'sdpMLineIndex': candidate.sdpMLineIndex,
                  'sdpMid': candidate.sdpMid,
                  'candidate': candidate.candidate,
                },
              }));
    };

    //create data channel
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
      ..maxRetransmits = 30
      ..ordered = true;
    channel = await pc!.createDataChannel('userInput', dataChannelDict);

    channel?.onMessage = (RTCDataChannelMessage msg) {
      processDataChannelMessageFromClient(msg);
    };

    //For web, RTCDataChannel.readyState is not 'open', and this should only for windows
    /*if (!kIsWeb && Platform.isWindows){
      channel.send(RTCDataChannelMessage("csrhook"));
      channel.send(RTCDataChannelMessage("xboxinit"));
    }*/

    RTCSessionDescription sdp = await pc!.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    });

    await pc!.setLocalDescription(_fixSdp(sdp, settings.bitrate!));

    while (candidates.isNotEmpty) {
      await pc!.addCandidate(candidates[0]);
      candidates.removeAt(0);
    }

    WebSocketService.send('offer', {
      'source_connectionid': controlled.websocketSessionid,
      'target_uid': controller.uid,
      'target_connectionid': controller.websocketSessionid,
      'description': {'sdp': sdp.sdp, 'type': sdp.type},
      'bitrate': settings.bitrate,
    });

    connectionState = StreamingSessionConnectionState.offerSent;
    releaseLock();
  }

  RTCSessionDescription _fixSdp(RTCSessionDescription s, int bitrate) {
    var sdp = s.sdp;
    sdp = sdp!.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032');

    RegExp exp = RegExp(r"^a=fmtp.*$", multiLine: true);
    String appendStr =
        ";x-google-max-bitrate=$bitrate;x-google-min-bitrate=$bitrate;x-google-start-bitrate=$bitrate)";

    sdp = sdp.replaceAllMapped(exp, (match) {
      return match.group(0)! + appendStr;
    });

    RegExp exp2 = RegExp(r"^c=IN.*$", multiLine: true);
    String appendStr2 = "\r\nb=AS:$bitrate";
    sdp = sdp.replaceAllMapped(exp2, (match) {
      return match.group(0)! + appendStr2;
    });

    s.sdp = sdp;
    return s;
  }

  //controller
  void onOfferReceived(Map offer) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received offer on disconnection. Dropping");
      return;
    }
    await acquireLock();
    await pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']));

    RTCSessionDescription sdp = await pc!.createAnswer({
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    });
    await pc!.setLocalDescription(_fixSdp(sdp, streamSettings!.bitrate!));
    while (candidates.isNotEmpty) {
      await pc!.addCandidate(candidates[0]);
      candidates.removeAt(0);
    }
    WebSocketService.send('answer', {
      'source_connectionid': controller.websocketSessionid,
      'target_uid': controlled.uid,
      'target_connectionid': controlled.websocketSessionid,
      'description': {'sdp': sdp.sdp, 'type': sdp.type},
    });
    releaseLock();
  }

  void onAnswerReceived(Map<String, dynamic> anwser) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received answer on disconnection. Dropping");
      return;
    }
    await acquireLock();
    await pc!.setRemoteDescription(
        RTCSessionDescription(anwser['sdp'], anwser['type']));
    releaseLock();
  }

  void onCandidateReceived(Map<String, dynamic> candidateMap) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received candidate on disconnection. Dropping");
      return;
    }
    await acquireLock();
    // It is possible that the peerconnection has not been inited. add to list and add later for this case.
    RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
        candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
    if (pc == null) {
      // This can not be triggered after adding lock. Keep this and We may resue this list in the future.
      candidates.add(candidate);
    } else {
      await pc!.addCandidate(candidate);
    }
    releaseLock();
  }

  void updateRendererCallback(
      Function(String mediatype, MediaStream stream)? callback) {
    onAddRemoteStream = callback;
  }

  void close() {
    if (selfSessionType == SelfSessionType.controller) {
      StreamingManager.stopStreaming(controlled);
    }
    if (selfSessionType == SelfSessionType.controlled) {
      StreamedManager.stopStreaming(controller);
    }
  }

  void stop() async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      //Another stop request was triggered. return.
      return;
    }
    _pingTimeoutTimer?.cancel(); // 取消之前的Timer
    connectionState = StreamingSessionConnectionState.disconnecting;
    // We don't want to see more new connections when it is stopped. So we may want to use a lock.
    await acquireLock();
    candidates.clear();

    if (channel != null) {
      await channel?.send(RTCDataChannelMessage.fromBinary(
          Uint8List.fromList([LP_DISCONNECT, RP_PING])));

      await channel?.close();
      channel = null;
    }

    if (_localVideoStream != null) {
      _localVideoStream?.getTracks().forEach((track) {
        track.stop();
      });
      await pc?.removeTrack(videoSender!);
      _localVideoStream = null;
    }

    pc?.close();
    pc = null;
    connectionState = StreamingSessionConnectionState.disconnected;

    releaseLock();
  }

  Timer? _pingTimeoutTimer;

  // We take 15s as timeout from remote peer.
  void restartPingTimeoutTimer() {
    _pingTimeoutTimer?.cancel(); // 取消之前的Timer
    _pingTimeoutTimer = Timer(const Duration(seconds: 15), () {
      // 超过15秒没收到pingpong，断开连接
      VLOG0("No ping message received within 15 seconds, disconnecting...");
      close();
    });
  }

  Completer<void>? _lock;

  Future<void> acquireLock() async {
    // 如果当前没有锁，创建一个新的锁
    if (_lock == null) {
      _lock = Completer<void>();
      return; // 第一次调用，不阻塞，直接返回
    }

    // 如果已有锁，等待锁被释放
    await _lock!.future;
  }

  void releaseLock() {
    // 如果锁存在并且未完成，释放锁
    if (_lock != null && !_lock!.isCompleted) {
      _lock!.complete();
      _lock = null; // 释放锁后清空
    }
  }

  void processDataChannelMessageFromClient(RTCDataChannelMessage message) {
    VLOG0("message from Client:${message.binary[0]}");
    if (message.isBinary) {
      switch (message.binary[0]) {
        case LP_PING:
          if (message.binary.length == 2 && message.binary[1] == RP_PING) {
            VLOG0("ping received from client");
            restartPingTimeoutTimer();
            Timer(const Duration(seconds: 1), () {
              if (connectionState ==
                  StreamingSessionConnectionState.disconnecting) return;
              channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PONG])));
            });
          }
          break;
        case LP_MOUSE:
          break;
        case LP_DISCONNECT:
          close();
          break;
        default:
          VLOG0("unhandled message.please debug");
      }
    } else {
      VLOG0("Channel message: ${message.text}");
    }
  }

  void processDataChannelMessageFromHost(RTCDataChannelMessage message) async {
    if (message.isBinary) {
      switch (message.binary[0]) {
        case LP_PING:
          if (message.binary.length == 2 && message.binary[1] == RP_PONG) {
            VLOG0("pong received from host");
            restartPingTimeoutTimer();
            Timer(const Duration(seconds: 1), () {
              if (connectionState ==
                  StreamingSessionConnectionState.disconnecting) return;
              channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PING])));
            });
          }
          break;
        case LP_DISCONNECT:
          close();
          break;
        default:
          VLOG0("unhandled message from host.please debug");
      }
    } else {}
  }
}
