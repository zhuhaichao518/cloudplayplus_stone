import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudplayplus/controller/hardware_input_controller.dart';
import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/entities/audiosession.dart';
import 'package:cloudplayplus/entities/device.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/streaming_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:cloudplayplus/utils/notifications/notification_manager.dart';
import 'package:cloudplayplus/utils/widgets/message_box.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../base/logging.dart';
import '../global_settings/streaming_settings.dart';
import '../services/app_info_service.dart';
import '../services/webrtc_service.dart';
import '../webrtctest/rtc_service_impl.dart';
import '../utils/rtc_utils.dart';
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
  // TODO: use RTCPeerConnectionState instead.
  connecting,
  connected,
  disconnecting,
  disconnected,
}

enum SelfSessionType {
  none,
  controller,
  controlled,
}

//目前使用lock来防止我close的过程中使用了peerconnection.
//还有一种方法是close的一开始就把pc等变量设为null,用一个临时pc存储和继续析构流程
//这样别的异步调用进来的时候pc？就会是null 所以也应该没问题
class StreamingSession {
  StreamingSessionConnectionState connectionState =
      StreamingSessionConnectionState.free;
  SelfSessionType selfSessionType = SelfSessionType.none;
  Device controller, controlled;
  RTCPeerConnection? pc;
  //late RTCPeerConnection audio;

  //MediaStream? _localVideoStream;
  //MediaStream? _localAudioStream;
  //MediaStreamTrack? _localStreamTrack;

  RTCRtpSender? videoSender;
  //RTCRtpSender? audioSender;

  //used to send reliable messages.
  RTCDataChannel? channel;

  int datachannelMessageIndex = 0;

  bool useUnsafeDatachannel = false;
  //Controller channel
  //use unreliable channel because there is noticeable latency on data loss.
  //work like udp.
  // ignore: non_constant_identifier_names
  RTCDataChannel? UDPChannel;

  InputController? inputController;

  //This is the common settings on both.
  StreamedSettings? streamSettings;

  List<RTCIceCandidate> candidates = [];

  int screenId = 0;

  int cursorImageHookID = 0;

  AudioSession? audioSession;

  final _lock = Lock();

  Timer? _clipboardTimer;
  String _lastClipboardContent = '';

  // 添加生命周期监听器
  static final _lifecycleObserver = _AppLifecycleObserver();

  StreamingSession(this.controller, this.controlled) {
    connectionState = StreamingSessionConnectionState.free;
    // 注册生命周期监听器
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
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
    screenId = StreamingSettings.targetScreenId!;
    await _lock.synchronized(() async {
      restartPingTimeoutTimer(10);
      controlled.connectionState.value =
          StreamingSessionConnectionState.connceting; // typo: connceting -> connecting

      streamSettings = StreamedSettings.fromJson(StreamingSettings.toJson());
      connectionState = StreamingSessionConnectionState.requestSent;
      pc = await createRTCPeerConnection();

      pc!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          controlled.connectionState.value =
              StreamingSessionConnectionState.connceting; // typo: connceting -> connecting
        }
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          //有些时候即使未能建立连接也报connected，因此依然需要pingpong message.
          // controlled.connectionState.value =
          //     StreamingSessionConnectionState.connected; // This will be set by ping-pong
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          controlled.connectionState.value =
              StreamingSessionConnectionState.disconnected;
          MessageBoxManager()
              .showMessage("已断开或未能建立连接。请切换网络重试或在设置中启动turn服务器。", "连接失败");
          close();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          controlled.connectionState.value =
              StreamingSessionConnectionState.disconnected;
        }
      };

      pc!.onIceCandidate = (candidate) async {
        // We are controller so source is ourself
        // MODIFIED: Removed Future.delayed and added null check
        if (candidate != null) {
          VLOG0("Controller sending ICE candidate: ${candidate.candidate}");
          WebSocketService.send('candidate2', {
            'source_connectionid': controller.websocketSessionid,
            'target_uid': controlled.uid,
            'target_connectionid': controlled.websocketSessionid,
            'candidate': {
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'sdpMid': candidate.sdpMid,
              'candidate': candidate.candidate,
            },
          });
        } else {
          VLOG0("Controller ICE gathering complete.");
        }
      };

      pc!.onTrack = (event) {
        // connectionState = StreamingSessionConnectionState.connected; // This state should be set by ping-pong
        /*controlled.connectionState.value =
          StreamingSessionConnectionState.connected;*/
        //tell the device tile page to render the rtc video.
        //StreamingManager.runUserViewCallback();
        WebrtcService.addStream(controlled.websocketSessionid, event);
        //rtcvideoKey.currentState?.updateVideoRenderer(event.track.kind!, event.streams[0]);
        //We used to this function to render the control. Currently we use overlay for convenience.
        //onAddRemoteStream?.call(event.track.kind!, event.streams[0]);
      };
      pc!.onDataChannel = (newchannel) async {
        if (newchannel.label == "userInputUnsafe") {
          UDPChannel = newchannel;
          inputController = InputController(UDPChannel!, false, screenId);
          //This channel is only used to send unsafe user input
          /*
        channel?.onMessage = (msg) {
        };*/
        } else {
          channel = newchannel;
          if (!useUnsafeDatachannel) {
            inputController = InputController(channel!, true, screenId);
          }
          channel?.onMessage = (msg) {
            processDataChannelMessageFromHost(msg);
          };

          channel?.onDataChannelState = (state) async {
            if (state == RTCDataChannelState.RTCDataChannelOpen) {
              // Connection considered established when data channel is open and first ping sent
              controlled.connectionState.value = StreamingSessionConnectionState.connected;
              connectionState = StreamingSessionConnectionState.connected;
              await channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PING])));
              if (StreamingSettings.streamAudio!) {
                audioSession = AudioSession(channel!, controller, controlled);
                await audioSession!.requestAudio();
              }
            }
          };
        }

        if (StreamingSettings.useClipBoard) {
          startClipboardSync();
        }
      };
      // read the latest settings from user settings.
      WebSocketService.send('requestRemoteControl', {
        'target_uid': ApplicationInfo.user.uid, // Should this be controller.uid?
        'target_connectionid': controlled.websocketSessionid,
        'settings': StreamingSettings.toJson(),
      });
    });
  }

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
        'iceServers': [cloudPlayPlusStun] // Ensure cloudPlayPlusStun is defined
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

  void onRequestRejected() {
    controlled.connectionState.value =
        StreamingSessionConnectionState.disconnected;
    MessageBoxManager().showMessage("未能建立连接。密码错误或者该设备不允许被连接。", "连接失败");
    close();
  }

  //accept request and send offer to the peer. you should verify this is authorized before calling this funciton.
  //We are the 'controlled'.
  void acceptRequest(StreamedSettings settings) async {
    await _lock.synchronized(() async {
      if (settings.hookCursorImage == true && AppPlatform.isDeskTop) {
        HardwareSimulator.addCursorImageUpdated(
            onLocalCursorImageMessage, cursorImageHookID);
      }
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
      restartPingTimeoutTimer(10); // Ping timeout starts earlier
      streamSettings = settings;

      pc = await createRTCPeerConnection();
      
      screenId = settings.screenId!;

      if (StreamedManager.localVideoStreams[settings.screenId] != null) {
        // one track expected.
        StreamedManager.localVideoStreams[settings.screenId]!
            .getTracks()
            .forEach((track) async {
          videoSender = (await pc!.addTrack(
              track, StreamedManager.localVideoStreams[settings.screenId]!));
        });
      }
      
      pc!.onIceCandidate = (candidate) async {
        // We are controlled so source is ourself
        // MODIFIED: Removed Future.delayed and added null check
        if (candidate != null) {
          VLOG0("Controlled sending ICE candidate: ${candidate.candidate}");
          WebSocketService.send('candidate', {
            'source_connectionid': controlled.websocketSessionid,
            'target_uid': controller.uid,
            'target_connectionid': controller.websocketSessionid,
            'candidate': {
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'sdpMid': candidate.sdpMid,
              'candidate': candidate.candidate,
            },
          });
        } else {
          VLOG0("Controlled ICE gathering complete.");
        }
      };

      pc!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          // Connection state should be managed by DataChannel open and ping-pong
          if (AppPlatform.isWindows) {
            //HardwareSimulator.showNotification(controller.nickname); // Consider if this is still needed here
          }
          if (settings.useClipBoard == true) {
              startClipboardSync();
          }
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          close();
        }
      };

      //create data channel
      RTCDataChannelInit reliableDataChannelDict = RTCDataChannelInit()
        ..maxRetransmitTime = 100
        ..ordered = true;
      channel =
          await pc!.createDataChannel('userInput', reliableDataChannelDict);

      channel?.onMessage = (RTCDataChannelMessage msg) {
        processDataChannelMessageFromClient(msg);
      };

      // Added DataChannel open state handler for controlled side as well
      channel?.onDataChannelState = (state) async {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          // Connection considered established when data channel is open and first ping sent
          controller.connectionState.value = StreamingSessionConnectionState.connected; // Update controller's view of controlled
          connectionState = StreamingSessionConnectionState.connected;
           await channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PONG]))); // Controlled sends PONG first in response to PING
          if (AppPlatform.isDeskTop &&
              !ApplicationInfo.isSystem &&
              selfSessionType == SelfSessionType.controlled) {
            // NotificationManager().initialize(); // Should be initialized once
            NotificationManager().showSimpleNotification(
                title: "${controller.nickname} (${controller.devicetype})的连接",
                body: "${controller.devicename}连接到了本设备");
          }
        }
      };


      if (useUnsafeDatachannel) {
        RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
          ..maxRetransmits = 0
          ..ordered = false;
        UDPChannel =
            await pc!.createDataChannel('userInputUnsafe', dataChannelDict);

        UDPChannel?.onMessage = (RTCDataChannelMessage msg) {
          processDataChannelMessageFromClient(msg);
        };
        inputController = InputController(UDPChannel!, false, screenId);
      } else {
        inputController = InputController(channel!, true, screenId);
      }

      RTCSessionDescription sdp = await pc!.createOffer({
        'mandatory': {
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': true,
        },
        'optional': [],
      });

      if (selfSessionType == SelfSessionType.controlled) {
        if (settings.codec == null || settings.codec == "default") {
          if (AppPlatform.isMacos) {
            setPreferredCodec(sdp, audio: 'opus', video: 'av1');
          } else {
            setPreferredCodec(sdp, audio: 'opus', video: 'h264');
          }
        } else {
          setPreferredCodec(sdp, audio: 'opus', video: settings.codec!);
        }
      }

      await pc!.setLocalDescription(_fixSdp(sdp, settings.bitrate!));

      // Send pending candidates that might have arrived before setLocalDescription
      // This is generally not needed if onIceCandidate is set up before createOffer/Answer
      // and candidates are sent as they arrive.
      // However, if candidates were queued due to pc being null earlier, this would handle them.
      // With the current structure, this candidates list might not be populated much here.
      while (candidates.isNotEmpty) {
        VLOG0("Controlled: Adding a pending early candidate.");
        await pc!.addCandidate(candidates.removeAt(0));
      }

      WebSocketService.send('offer', {
        'source_connectionid': controlled.websocketSessionid,
        'target_uid': controller.uid,
        'target_connectionid': controller.websocketSessionid,
        'description': {'sdp': sdp.sdp, 'type': sdp.type},
        'bitrate': settings.bitrate,
      });

      connectionState = StreamingSessionConnectionState.offerSent;
    });
  }

  RTCSessionDescription _fixSdp(RTCSessionDescription s, int bitrate) {
    var sdp = s.sdp;
    sdp = sdp!.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032'); // Example, specific H264 profile

    // More robust way to add bitrate:
    // Find the video media section
    List<String> sdpLines = sdp.split('\r\n');
    bool inVideoSection = false;
    for (int i = 0; i < sdpLines.length; i++) {
        if (sdpLines[i].startsWith('m=video')) {
            inVideoSection = true;
        }
        if (inVideoSection && (sdpLines[i].isEmpty || sdpLines[i].startsWith('m=')) && !sdpLines[i].startsWith('m=video')) {
            inVideoSection = false; // Exited video section or new media section
        }
        if (inVideoSection && sdpLines[i].startsWith('c=IN')) {
            // Insert b=AS:bitrate after c=IN line for video
            // Ensure bitrate is in Kbps for b=AS
            sdpLines.insert(i + 1, 'b=AS:${bitrate ~/ 1000}'); // Assuming bitrate is in bps
            break; // Added for video, can break or continue if audio also needs it
        }
    }
    // Add x-google bitrate attributes to H264 fmtp lines
    for (int i = 0; i < sdpLines.length; i++) {
        if (sdpLines[i].contains('a=rtpmap:') && sdpLines[i].toLowerCase().contains('h264')) {
            // Find the corresponding fmtp line
            String payloadType = sdpLines[i].split(' ')[0].substring('a=rtpmap:'.length);
            for (int j = 0; j < sdpLines.length; j++) {
                if (sdpLines[j].startsWith('a=fmtp:$payloadType')) {
                    if (!sdpLines[j].contains('x-google-max-bitrate')) {
                         sdpLines[j] += ';x-google-start-bitrate=${bitrate ~/ 1000};x-google-min-bitrate=${bitrate ~/ 1000};x-google-max-bitrate=${bitrate ~/ 1000}';
                    }
                    break;
                }
            }
        }
    }
    s.sdp = sdpLines.join('\r\n');
    return s;
  }

  //controller
  void onOfferReceived(Map offer) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received offer on disconnection. Dropping");
      return;
    }
    await _lock.synchronized(() async {
      if (pc == null) { // Ensure pc is initialized
        VLOG0("Controller PC is null in onOfferReceived. This should not happen if startRequest was called.");
        // Potentially re-initialize or handle error
        // For now, we assume pc is valid if startRequest was successful.
        // If pc can legitimately be null here, need to ensure startRequest robustly creates it or handles failure.
         return;
      }
      await pc!.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']));

      RTCSessionDescription sdp = await pc!.createAnswer({
        'mandatory': {
          'OfferToReceiveAudio': false, // Assuming controller doesn't receive audio this way
          'OfferToReceiveVideo': true,  // Controller wants to receive video
        },
        'optional': [],
      });
      // Apply bitrate modification to answer SDP as well if needed (usually offerer controls this)
      await pc!.setLocalDescription(_fixSdp(sdp, streamSettings!.bitrate!)); 
      
      // Send pending candidates that might have arrived before setLocalDescription
      while (candidates.isNotEmpty) {
        VLOG0("Controller: Adding a pending early candidate.");
        await pc!.addCandidate(candidates.removeAt(0));
      }

      WebSocketService.send('answer', {
        'source_connectionid': controller.websocketSessionid,
        'target_uid': controlled.uid,
        'target_connectionid': controlled.websocketSessionid,
        'description': {'sdp': sdp.sdp, 'type': sdp.type},
      });
      connectionState = StreamingSessionConnectionState.answerSent;
    });
  }

  void onAnswerReceived(Map<String, dynamic> anwser) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received answer on disconnection. Dropping");
      return;
    }
    await _lock.synchronized(() async {
      if (pc == null) {
         VLOG0("Controlled PC is null in onAnswerReceived. This should not happen if acceptRequest was called.");
         return;
      }
      await pc!.setRemoteDescription(
          RTCSessionDescription(anwser['sdp'], anwser['type']));
      connectionState = StreamingSessionConnectionState.answerReceived;
      // At this point, the controlled side has set remote description.
      // The connection state should ideally be updated to 'connected'
      // once the DataChannel is open and a ping-pong is successful.
    });
  }

  void onCandidateReceived(Map<String, dynamic> candidateMap) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) {
      VLOG0("received candidate on disconnection. Dropping");
      return;
    }

    await _lock.synchronized(() async {
      RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
          candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
      
      // Candidates might arrive before setLocalDescription or setRemoteDescription.
      // The standard WebRTC API handles queuing candidates internally if addIceCandidate
      // is called before setRemoteDescription is complete, as long as pc is not null.
      // If pc itself is null (meaning createPeerConnection hasn't finished or offer/answer hasn't been processed yet),
      // then queuing them in the `candidates` list is a valid fallback.
      if (pc == null || pc?.getRemoteDescription() == null ) { // More robust check
        VLOG0("PC or remote description not ready, queuing candidate: ${candidate.candidate}");
        candidates.add(candidate);
      } else {
        try {
          VLOG0("Adding received candidate: ${candidate.candidate}");
          await pc!.addCandidate(candidate);
        } catch (e) {
          VLOG0("Error adding received candidate: $e. Candidate: ${candidate.candidate}, sdpMid: ${candidate.sdpMid}, sdpMLineIndex: ${candidate.sdpMLineIndex}");
        }
      }
    });
  }

  void updateRendererCallback(
      Function(String mediatype, MediaStream stream)? callback) {
    onAddRemoteStream = callback;
  }
  
  bool isClosing_ = false;

  void close() {
    if (isClosing_) return;
    isClosing_ = true; // Set flag immediately

    VLOG0("Close called for session with ${selfSessionType == SelfSessionType.controller ? controlled.uid : controller.uid}");


    // Cancel ping timer first to prevent it from re-triggering close/stop
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;
    
    connectionState = StreamingSessionConnectionState.disconnecting; // Update state

    // Update device state value before async lock
     if (selfSessionType == SelfSessionType.controller) {
        controlled.connectionState.value = StreamingSessionConnectionState.disconnecting;
     } else if (selfSessionType == SelfSessionType.controlled) {
        // If controlled, it means the controller initiated close or timeout
        // No direct peer device state to update here, as `controller` is the remote peer
     }


    // Use a copy of pc to close outside the lock if needed, or ensure stop actions are safe.
    // The main concern is pc becoming null inside the lock before all operations are done.
    // However, with isClosing_ flag, other methods should bail out.
    _lock.synchronized(() {
      // The actual stop logic is in stop(), call it.
      // close() is more of an initiator due to timeout or external call.
      // Let stop() handle the detailed cleanup.
      // Avoid direct calls to StreamingManager.stopStreaming or StreamedManager.stopStreaming here
      // if stop() is already doing that, to prevent duplicate calls.
      // The current structure seems like close() can be called by timeout,
      // and stop() is called for intentional stops.
      // If close() is due to timeout, it should also trigger the full stop sequence.
      if (selfSessionType == SelfSessionType.controller) {
         // This call might be redundant if stop() also calls it.
         // Ensure only one manager stop call.
         // StreamingManager.stopStreaming(controlled);
      }
      if (selfSessionType == SelfSessionType.controlled) {
         // StreamedManager.stopStreaming(controller);
      }
    }).then((_) {
        // Call stop to perform the full cleanup.
        // This ensures that even if close is called by timeout, stop's full logic runs.
        stop();
    });
  }


  // stop() should be the definitive method for all cleanup.
  void stop() async {
    // Check connectionState first, then isClosing_ to handle calls from close()
    if (connectionState == StreamingSessionConnectionState.disconnected || 
        connectionState == StreamingSessionConnectionState.disconnecting && isClosing_ /* already stopping */) {
      VLOG0("Stop called but already stopping or disconnected.");
      return;
    }
    
    VLOG0("Stop called for session with ${selfSessionType == SelfSessionType.controller ? controlled.uid : controller.uid}");

    isClosing_ = true; // Ensure flag is set
    connectionState = StreamingSessionConnectionState.disconnecting;

    // Update device state value immediately
     if (selfSessionType == SelfSessionType.controller) {
        controlled.connectionState.value = StreamingSessionConnectionState.disconnecting;
     } else if (selfSessionType == SelfSessionType.controlled) {
        // No direct peer device state to update here for the 'controller' object itself.
        // The 'controller' object in a controlled session refers to the remote peer.
     }

    _pingTimeoutTimer?.cancel(); 
    _pingTimeoutTimer = null;

    await _lock.synchronized(() async {
      audioSession?.dispose();
      audioSession = null;

      candidates.clear(); // Clear any remaining candidates
      // inputController's resources might be tied to channels, close channels first
      // inputController = null; // Nullify after channels are closed

      if (channel != null) {
        try {
          // Send disconnect message reliably if channel is open
          if (channel?.state == RTCDataChannelState.RTCDataChannelOpen) {
             for (int i = 0; i <= InputController.resendCount + 2; i++) {
               await channel?.send(RTCDataChannelMessage.fromBinary(
                 Uint8List.fromList([LP_DISCONNECT, RP_PING]))); // RP_PING here seems odd for disconnect
             }
          }
          await channel?.close();
        } catch (e) {
          VLOG0("Error closing reliable data channel: $e");
        } finally {
          channel = null;
        }
      }
      if (UDPChannel != null) {
        try {
          await UDPChannel?.close();
        } catch (e) {
          VLOG0("Error closing unreliable data channel: $e");
        } finally {
          UDPChannel = null;
        }
      }
      
      inputController = null; // Nullify after channels are handled

      if (pc != null) {
        try {
          // Iterate over senders and remove tracks if they exist
          // This is good practice but pc.close() should also handle it.
          List<RTCRtpSender> senders = await pc!.getSenders();
          for (var sender in senders) {
            if (sender.track != null) {
              // await pc!.removeTrack(sender); // Optional: pc.close() should suffice
            }
          }
          await pc!.close();
        } catch (e) {
          VLOG0("Error closing peer connection: $e");
        } finally {
          pc = null;
        }
      }
      
      if (selfSessionType == SelfSessionType.controller) {
        controlled.connectionState.value = StreamingSessionConnectionState.disconnected;
        // Call manager to stop, ensuring it's the definitive place
        StreamingManager.stopStreaming(controlled); 
      } else if (selfSessionType == SelfSessionType.controlled) {
        // For controlled, its own state reflects the session.
        // The 'controller' object is the remote peer.
        // Its connectionState.value is managed by the controller's perspective.
        // Call manager to stop
        StreamedManager.stopStreaming(controller);
      }
      
      connectionState = StreamingSessionConnectionState.disconnected;
      
      if (streamSettings?.hookCursorImage == true &&
          selfSessionType == SelfSessionType.controlled) {
        if (AppPlatform.isDeskTop) {
          HardwareSimulator.removeCursorImageUpdated(cursorImageHookID);
        }
      }

      // Cursor unlock logic
      // Check if this session is indeed the one currently rendering and locking cursor
      // This check might need to be more robust if multiple sessions can exist
      // but only one is 'active' for rendering.
      if (WebrtcService.currentRenderingSession == this) { // Assuming WebrtcService holds the active session
        if (HardwareSimulator.cursorlocked) {
          if (AppPlatform.isDeskTop || AppPlatform.isWeb) {
            HardwareSimulator.cursorlocked = false;
            HardwareSimulator.unlockCursor();
            HardwareSimulator.removeCursorMoved(
                InputController.cursorMovedCallback); // Ensure these callbacks are correctly managed
          }
          if (AppPlatform.isWeb) {
            HardwareSimulator.removeCursorPressed(
                InputController.cursorPressedCallback);
            HardwareSimulator.removeCursorWheel(
                InputController.cursorWheelCallback);
          }
        }
      }
      
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      stopClipboardSync(); // Moved outside lock to avoid holding lock during async clipboard ops
    });
     isClosing_ = false; // Reset after stop is complete
  }

  Timer? _pingTimeoutTimer;

  void restartPingTimeoutTimer(int second) {
    _pingTimeoutTimer?.cancel(); 
    _pingTimeoutTimer = Timer(Duration(seconds: second), () {
      VLOG0("Ping timeout ($second s) for session with ${selfSessionType == SelfSessionType.controller ? controlled.uid : controller.uid}. Closing connection.");
      close(); // This will call stop()
      if (selfSessionType == SelfSessionType.controller) {
        MessageBoxManager()
            .showMessage("连接超时。请检查网络或对方设备状态。", "连接失败");
      }
    });
  }

  void onLocalCursorImageMessage(
      int message, int messageInfo, Uint8List cursorImage) {
    if (channel == null || channel?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    if (message == HardwareSimulator.CURSOR_UPDATED_IMAGE) {
      channel?.send(RTCDataChannelMessage.fromBinary(cursorImage));
    } else {
      ByteData byteData = ByteData(9);
      byteData.setUint8(0, LP_MOUSECURSOR_CHANGED);
      byteData.setInt32(1, message, Endian.little); // Specify Endian for consistency
      byteData.setInt32(5, messageInfo, Endian.little);
      Uint8List buffer = byteData.buffer.asUint8List();
      channel?.send(RTCDataChannelMessage.fromBinary(buffer));
    }
  }

 void processDataChannelMessageFromClient(RTCDataChannelMessage message) {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) return;

    if (message.isBinary) {
      // VLOG0("Message from Client (binary): type ${message.binary[0]}"); // Can be very verbose
      if (message.binary.isEmpty) {
        VLOG0("Received empty binary message from client.");
        return;
      }
      switch (message.binary[0]) {
        case LP_PING:
          if (message.binary.length == 2 && message.binary[1] == RP_PING) {
            restartPingTimeoutTimer(30);
            // Controlled side receives PING, should send PONG
            Timer(const Duration(milliseconds: 100), () { // Send pong quickly
              if (connectionState == StreamingSessionConnectionState.disconnecting || 
                  connectionState == StreamingSessionConnectionState.disconnected || 
                  channel == null || channel?.state != RTCDataChannelState.RTCDataChannelOpen) return;
              channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PONG])));
            });
          }
          break;
        case LP_MOUSEMOVE_ABSL:
          inputController?.handleMoveMouseAbsl(message);
          break;
        case LP_MOUSEMOVE_RELATIVE:
          inputController?.handleMoveMouseRelative(message);
          break;
        case LP_MOUSEBUTTON:
          inputController?.handleMouseClick(message);
          break;
        case LP_MOUSE_SCROLL:
          inputController?.handleMouseScroll(message);
          break;
        case LP_TOUCH_MOVE_ABSL:
          inputController?.handleTouchMove(message);
          break;
        case LP_TOUCH_BUTTON:
          inputController?.handleTouchButton(message);
          break;
        case LP_KEYPRESSED:
          inputController?.handleKeyEvent(message);
          break;
        case LP_DISCONNECT:
           VLOG0("Received LP_DISCONNECT from client. Closing session.");
          close();
          break;
        case LP_EMPTY:
          // Do nothing for empty message placeholder
          break;
        case LP_AUDIO_CONNECT:
          audioSession = AudioSession(channel!, controller, controlled); // Ensure channel is not null
          audioSession?.audioRequested();
          break;
        default:
          VLOG0("Unhandled binary message from Client: type ${message.binary[0]}. Please debug.");
      }
    } else {
      // VLOG0("Message from Client (text): ${message.text}"); // Can be verbose
      try {
        Map<String, dynamic> data = jsonDecode(message.text);
        if (data.isEmpty || data.keys.isEmpty) {
            VLOG0("Received empty or keyless JSON message from client.");
            return;
        }
        final key = data.keys.first;
        switch (key) {
          case "candidate": // Audio candidate
            var candidateMap = data["candidate"];
            if (candidateMap != null && audioSession != null) {
              RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
                  candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
              audioSession?.addCandidate(candidate);
            } else {
              VLOG0("Audio candidate received but audiosession is null or candidateMap is null.");
            }
            break;
          case "answer": // Audio answer
             if (audioSession != null && data['answer'] != null) {
                audioSession?.onAnswerReceived(data['answer']);
             } else {
                VLOG0("Audio answer received but audiosession is null or answer data is null.");
             }
            break;
          case "gamepad":
            inputController?.handleGamePadEvent(data['gamepad']);
            break;
          case "clipboard":
            final clipboardContent = data['clipboard'] as String?;
            if (clipboardContent != null) {
                Clipboard.setData(ClipboardData(text: clipboardContent));
                _lastClipboardContent = clipboardContent;
            }
            break;
          default:
            VLOG0("Unhandled text message from Client: key '$key'. Please debug.");
        }
      } catch (e) {
        VLOG0("Error processing text message from Client: $e. Message: ${message.text}");
      }
    }
  }

  void processDataChannelMessageFromHost(RTCDataChannelMessage message) async {
    if (connectionState == StreamingSessionConnectionState.disconnecting ||
        connectionState == StreamingSessionConnectionState.disconnected) return;
    
    if (message.isBinary) {
      // VLOG0("Message from Host (binary): type ${message.binary[0]}"); // Can be verbose
      if (message.binary.isEmpty) {
        VLOG0("Received empty binary message from host.");
        return;
      }
      switch (message.binary[0]) {
        case LP_PING:
          if (message.binary.length == 2 && message.binary[1] == RP_PONG) {
            // Controller received PONG from controlled
            restartPingTimeoutTimer(30);
            // Controller sends PING again after a delay
            Timer(const Duration(seconds: 1), () { // Consider making this delay configurable or shorter
              if (connectionState == StreamingSessionConnectionState.disconnecting || 
                  connectionState == StreamingSessionConnectionState.disconnected ||
                  channel == null || channel?.state != RTCDataChannelState.RTCDataChannelOpen) return;
              channel?.send(RTCDataChannelMessage.fromBinary(
                  Uint8List.fromList([LP_PING, RP_PING])));
            });
             // First successful ping-pong can confirm connection for controller
            if (controlled.connectionState.value != StreamingSessionConnectionState.connected) {
                 controlled.connectionState.value = StreamingSessionConnectionState.connected;
                 connectionState = StreamingSessionConnectionState.connected; // Also update session's own state
            }
          }
          break;
        case LP_MOUSECURSOR_CHANGED:
        case LP_MOUSECURSOR_CHANGED_WITHBUFFER: // Assuming this is a valid constant
          if (WebrtcService.currentRenderingSession == this) {
            inputController?.handleCursorUpdate(message);
          }
          break;
        case LP_DISCONNECT:
          VLOG0("Received LP_DISCONNECT from host. Closing session.");
          close();
          break;
        default:
          VLOG0("Unhandled binary message from Host: type ${message.binary[0]}. Please debug.");
      }
    } else {
      // VLOG0("Message from Host (text): ${message.text}"); // Can be verbose
      try {
        Map<String, dynamic> data = jsonDecode(message.text);
         if (data.isEmpty || data.keys.isEmpty) {
            VLOG0("Received empty or keyless JSON message from host.");
            return;
        }
        final key = data.keys.first;
        switch (key) {
          case "candidate": // Audio candidate
            var candidateMap = data['candidate'];
             if (candidateMap != null && audioSession != null) {
                RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
                    candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
                audioSession?.addCandidate(candidate);
             } else {
                VLOG0("Audio candidate received from host but audiosession or candidateMap is null.");
             }
            break;
          case "offer": // Audio offer
            if (audioSession != null && data['offer'] != null) {
                audioSession?.onOfferReceived(data['offer']);
            } else {
                VLOG0("Audio offer received from host but audiosession or offer data is null.");
            }
            break;
          case "clipboard":
            final clipboardContent = data['clipboard'] as String?;
            if (clipboardContent != null) {
                Clipboard.setData(ClipboardData(text: clipboardContent));
                _lastClipboardContent = clipboardContent;
            }
            break;
          default:
            VLOG0("Unhandled text message from Host: key '$key'. Please debug.");
        }
      } catch (e) {
        VLOG0("Error processing text message from Host: $e. Message: ${message.text}");
      }
    }
  }


  void startClipboardSync() {
    if (_clipboardTimer != null || !StreamingSettings.useClipBoard) return; // Check global setting too
    
    // For controlled side, always sync periodically if desktop
    // For controller side, sync on resume might be better to avoid constant polling if it's a mobile controller
    if (AppPlatform.isDeskTop && selfSessionType == SelfSessionType.controlled) {
      _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        await _syncClipboard();
      });
    } else { // Controller, or non-desktop controlled
      _lifecycleObserver.onResume = () async {
        await _syncClipboard();
      };
       // Initial sync when starting
      Future.delayed(Duration(milliseconds: 500), _syncClipboard); // Slight delay for channel to open
    }
  }

  Future<void> _syncClipboard() async {
    if (channel == null || channel?.state != RTCDataChannelState.RTCDataChannelOpen ||
        connectionState == StreamingSessionConnectionState.disconnected ||
        connectionState == StreamingSessionConnectionState.disconnecting) {
      return;
    }

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final currentContent = clipboardData?.text ?? '';
      
      if (currentContent.isNotEmpty && currentContent != _lastClipboardContent) { // Send only if not empty and changed
        _lastClipboardContent = currentContent;
        final message = {
          'clipboard': currentContent
        };
        VLOG0("Syncing clipboard: $currentContent");
        channel?.send(RTCDataChannelMessage(jsonEncode(message)));
      }
    } catch (e) {
        VLOG0("Error during clipboard sync: $e");
        // Potentially stop clipboard sync if it errors repeatedly
    }
  }

  void stopClipboardSync() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
    _lifecycleObserver.onResume = null;
  }
}

// 添加生命周期监听器类
class _AppLifecycleObserver extends WidgetsBindingObserver {
  VoidCallback? onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume?.call();
    }
  }
}

// Ensure this is defined somewhere accessible, e.g. in rtc_utils.dart or here if local
final Map<String, String> cloudPlayPlusStun = {
  'urls': 'stun:stun.cloudflare.com:3478' // Example STUN server
};