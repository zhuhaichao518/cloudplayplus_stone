import 'dart:convert';

import 'package:cloudplayplus/base/logging.dart';
import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/entities/messages.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:cloudplayplus/webrtctest/rtc_service_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mutex/mutex.dart';

class AudioSession {
  RTCDataChannel channel;
  RTCPeerConnection? pc;
  RTCRtpSender? audioSender;
  //store candidates which came too early.
  List<RTCIceCandidate> candidates = [];

  Device controller, controlled;

  Future<RTCPeerConnection> createRTCPeerConnection() async {
    Map<String, dynamic> iceServers;

    if (StreamingSettings.useTurnServer) {
      iceServers = {
        'iceServers': [
          {
            'urls': StreamingSettings.customTurnServerAddress,
            'username': StreamingSettings.customTurnServerUsername,
            'credential': StreamingSettings.customTurnServerPassword
          }
        ]
      };
    } else {
      iceServers = {
        'iceServers': [cloudPlayPlusStun]
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

  AudioSession(this.channel, this.controller, this.controlled);

  //client
  Future<void> requestAudio() async {
    await channel.send(RTCDataChannelMessage.fromBinary(
        Uint8List.fromList([LP_AUDIO_CONNECT])));
    pc = await createRTCPeerConnection();

    pc!.onIceCandidate = (candidate) async {
      Map<String, dynamic> mapData = {
        'candidate': {
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        },
      };
      RTCDataChannelMessage msg = RTCDataChannelMessage(jsonEncode(mapData));
      await Future.delayed(
          const Duration(seconds: 1),
          //controller's candidate
          () => channel.send(msg));
    };

    pc!.onTrack = (event) {
      WebrtcService.addAudioStream(controlled.websocketSessionid, event);
    };
  }

  final locker = Mutex();

  void acquireLock() {
    locker.acquire();
  }

  void releaseLock() {
    locker.release();
  }

  Map<String, dynamic> _getMediaConstraints({audio = true, video = true}) {
    return {
      'audio': audio ? true : false,
      'video': video
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };
  }

  //host
  //调用这里时进行lock 防止candidate先到
  Future<void> audioRequested() async {
    acquireLock();
    // currently only support windows.
    //if (!AppPlatform.isWindows) return;
    if (!StreamedManager.localAudioStreams.containsKey(AUDIO_SYSTEM)) {
      if (AppPlatform.isWindows) {
        Helper.selectAudioInput("system");
      }

      //StreamedManager.localAudioStreams[AUDIO_SYSTEM] = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      StreamedManager.localAudioStreams[AUDIO_SYSTEM] = await navigator
          .mediaDevices
          .getUserMedia(_getMediaConstraints(audio: true, video: false));
      //var devices = await navigator.mediaDevices.enumerateDevices();
      //Helper.selectAudioInput(devices[0].deviceId);
    }
    pc = await createRTCPeerConnection();
    releaseLock();

    if (StreamedManager.localAudioStreams[AUDIO_SYSTEM] != null) {
      StreamedManager.localAudioStreams[AUDIO_SYSTEM]!
          .getAudioTracks()
          .forEach((track) async {
        audioSender = (await pc!
            .addTrack(track, StreamedManager.localAudioStreams[AUDIO_SYSTEM]!));
        StreamedManager.audioSenderCount++;
      });
    }

    pc!.onIceCandidate = (candidate) async {
      Map<String, dynamic> mapData = {
        'candidate': {
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        },
      };
      RTCDataChannelMessage msg = RTCDataChannelMessage(jsonEncode(mapData));
      await Future.delayed(
          const Duration(seconds: 1),
          //controller's candidate
          () => channel.send(msg));
    };

    //await了的话 理论上进不来。如果进来说明有bug
    while (candidates.isNotEmpty) {
      VLOG0("-----warning:this should not be triggered.");
      await pc!.addCandidate(candidates[0]);
      candidates.removeAt(0);
    }

    var transceivers = await pc?.getTransceivers();

    var acaps = await getRtpSenderCapabilities('audio');
    transceivers?.forEach((transceiver) {
      if (transceiver.sender.senderId != audioSender?.senderId) return;
      var codecs = acaps?.codecs
              ?.where((element) =>
                  element.mimeType.toLowerCase().contains('OPUS'.toLowerCase()))
              .toList() ??
          [];
      transceiver.setCodecPreferences(codecs);
    });

    final oaConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };

    RTCSessionDescription sdp = await pc!.createOffer(oaConstraints);

    await pc!.setLocalDescription(sdp);

    Map<String, dynamic> mapData = {
      'offer': {'sdp': sdp.sdp, 'type': sdp.type}
    };
    RTCDataChannelMessage msg = RTCDataChannelMessage(jsonEncode(mapData));
    channel.send(msg);
  }

  Future<void> onOfferReceived(Map offer) async {
    await pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']));

    final oaConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };
    RTCSessionDescription sdp = await pc!.createAnswer(oaConstraints);

    await pc!.setLocalDescription(sdp);
    while (candidates.isNotEmpty) {
      await pc!.addCandidate(candidates[0]);
      candidates.removeAt(0);
    }
    Map<String, dynamic> mapData = {
      'answer': {'sdp': sdp.sdp, 'type': sdp.type}
    };
    RTCDataChannelMessage msg = RTCDataChannelMessage(jsonEncode(mapData));
    channel.send(msg);
  }

  void onAnswerReceived(Map<String, dynamic> anwser) async {
    await pc!.setRemoteDescription(
        RTCSessionDescription(anwser['sdp'], anwser['type']));
  }

/*
  RTCSessionDescription _fixSdp(RTCSessionDescription s) {
    var sdp = s.sdp;
    sdp = sdp!.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032');
    s.sdp = sdp;
    return s;
  }
*/
  Future<void> addCandidate(RTCIceCandidate candidate) async {
    acquireLock();
    if (pc == null) {
      // This can not be triggered if we await properly. Keep this and We may resue this list in the future.
      VLOG0("-----warning:this should not be triggered.");
      candidates.add(candidate);
    } else {
      VLOG0("adding candidate");
      await pc!.addCandidate(candidate);
    }
    releaseLock();
  }

  //TODO(haichao): answer,dispose, offer&answer in sessions.dart.
  Future<void> dispose() async {
    if (controlled.websocketSessionid == AppStateService.websocketSessionid) {
      StreamedManager.audioSenderCount--;
      if (StreamedManager.audioSenderCount == 0) {
        if (StreamedManager.localAudioStreams.containsKey(AUDIO_SYSTEM)) {
          StreamedManager.localAudioStreams[AUDIO_SYSTEM]?.dispose();
          StreamedManager.localAudioStreams.remove(AUDIO_SYSTEM);
        }
      }
    }
    pc?.close();
    pc?.dispose();
  }
}
