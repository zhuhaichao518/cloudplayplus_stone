/*import 'dart:convert';

import 'package:cloudplayplus/services/network/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc/rtc_service_impl.dart';
import 'package:cloudplayplus/utils/widgets/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import '../entities/device_info_native.dart'
    if (dart.library.js) '../../entities/device_info_web.dart';
import '../../entities/user.dart';
import '../../globalsettings/global_settings.dart';
import '../../localstorage/secure_storage.dart';
import '../../pages/login_screen.dart';
import '../../settings/streaming_settings.dart';
import '../../streamchat/streamchat_view.dart';
import '../../utils/websocket.dart'
    if (dart.library.js) '../../utils/websocket_web.dart';
import '../../widgets/global_widgets.dart';
import '../room/room_manager.dart';
import '../webrtc/streaming_service_impl.dart';
import 'rest_network_service_impl.dart';

enum WSConnectionState {
  none,
  connecting, // 请求连接中
  connected, // 已连接
  disconnected, // 断开
}

class WebSocketService {
  SimpleWebSocket? _socket;
  JsonEncoder _encoder = JsonEncoder();
  JsonDecoder _decoder = JsonDecoder();
  ApplicationInfoServiceImpl _appInfo = ApplicationInfoServiceImpl();

  static const String _baseUrl = 'wss://www.cloudplayplus.com/ws/';

  WebSocketService._internal();



  int _reconnectAttempts = 0;

  WSConnectionState _connstate = WSConnectionState.none;

  static final WebSocketServiceImpl _instance =
      WebSocketServiceImpl._internal();

  Function(List<Device> list)? onDeviceListchanged;

  Function(List<Device> list)? onSharedDeviceListchanged;

  //Function()? onRemoteScreenRetrived;
  Function(Device device)? onRemoteScreenRequested;

  //Todo:should in another place.
  Function(MediaStream stream)? onRemoteScreenReceived;

  factory WebSocketServiceImpl() {
    return _instance;
  }

  Future<void> clean() async {
    _socket?.close();
  }

  Future<void> connectToServer() async {
    //final prefs = await SharedPreferences.getInstance();
    //final accessToken = prefs.getString('access_token');
    String? accessToken = await SecureStorage().getAccessToken();

    if (accessToken == null) {
      //await StreamChatServiceImpl().clean();
// ignore: use_build_context_synchronously
      showDialog(
          context: globalnavigatorKey.currentState!.overlay!.context,
          builder: (context) {
            return AlertDialog(
              title: const Text('登录过期'),
              content: const Text('登录已过期。请重新登录。'),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('好的'),
                  onPressed: () {
                    //StreamChatServiceImpl().clean();
                    Navigator.of(context).pop(); // 关闭对话框
                    Navigator.pushReplacement(
                      globalnavigatorKey.currentState!.context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
              ],
            );
          });
    }
    //Todo:handle if token expired
    var url = '$_baseUrl?token=$accessToken';
    if (GlobalSettings.useLocalServer) {
      //flutter run -d chrome --web-browser-flag "--disable-web-security"
      url = 'ws://127.0.0.1:8000/ws/?token=$accessToken';
    }

    _socket = SimpleWebSocket(url);
    _connstate = WSConnectionState.connecting;

    _socket?.onOpen = () {
      _connstate = WSConnectionState.connected;
      _appInfo.initialize();
      send('newconnection', {
        'devicename': _appInfo.deviceName,
        'devicetype': _appInfo.deviceType,
        'appid': _appInfo.appId,
        'connective': _appInfo.connectable
      });
    };

    _socket?.onMessage = (message) {
      onMessage(_decoder.convert(message));
    };

    _socket?.onClose = (int? code, String? reason) async {
      if (code == 1000) return;
      print('Closed by server [$code => $reason]!');
      _connstate = WSConnectionState.disconnected;
      //user should not access to chat service anymore.
      //await StreamChatServiceImpl().clean();
      //todo:test this logic.
      //TODO:handle when token is invalid or expired.
      String? accessToken = await SecureStorage().getAccessToken();
      if (accessToken == null) {
        //await StreamChatServiceImpl().clean();
        // ignore: use_build_context_synchronously
        showDialog(
            context: globalnavigatorKey.currentState!.overlay!.context,
            builder: (context) {
              return AlertDialog(
                title: const Text('登录过期'),
                content: const Text('登录已过期。请重新登录。'),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('好的'),
                    onPressed: () {
                      Navigator.of(context).pop(); // 关闭对话框
                      Navigator.pushReplacement(
                        globalnavigatorKey.currentState!.context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
              );
            });
        return;
      }
      bool stillLoggedIn = await ApiServiceImpl().isLoggedIn();
      if (!stillLoggedIn) {
        // ignore: use_build_context_synchronously
        showDialog(
            context: globalnavigatorKey.currentState!.overlay!.context,
            builder: (context) {
              return AlertDialog(
                title: const Text('登录过期'),
                content: const Text('登录已过期。请重新登录。'),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('好的'),
                    onPressed: () {
                      Navigator.of(context).pop(); // 关闭对话框
                      Navigator.pushReplacement(
                        globalnavigatorKey.currentState!.context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
              );
            });
        return;
      }
      if (_reconnectAttempts < 5 /* && code == 500*/) {
        await Future.delayed(Duration(seconds: 3));
        _reconnectAttempts++;
        _connstate = WSConnectionState.connecting;
        //TODO(Haichao P1):Verify token is valid(locally check time). if not, refresh token;
        //if both fail, disconnect the current stream and go back to login page.
        await _socket?.connect();
      } else {
        //todo:should alert that socket disconnected for several times.
        //await StreamChatServiceImpl().clean();
        // ignore: use_build_context_synchronously
        showDialog(
            context: globalnavigatorKey.currentState!.overlay!.context,
            builder: (context) {
              return AlertDialog(
                title: const Text('网络连接中断'),
                content: const Text('网络连接中断。请重新登录。'),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('好的'),
                    onPressed: () {
                      Navigator.of(context).pop(); // 关闭对话框
                      Navigator.pushReplacement(
                        globalnavigatorKey.currentState!.context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
              );
            });
        print('Failed to reconnect after 5 attempts');
        _reconnectAttempts = 0;
      }
    };

    _connstate = WSConnectionState.connecting;
    await _socket?.connect();
  }

  void requestRemoteScreen(Device device) {
    if (StreamingServiceImpl().streamingstate == LocalStreamingState.none) {
      StreamingServiceImpl().streamingstate = LocalStreamingState.requesting;
      onRemoteScreenRequested?.call(device);
    }
  }
   
  void requestRemoteScreen2(Device device, StreamingSettings settings) {
    send("createroom", {
      "requester": ApplicationInfoServiceImpl().toJson(),
      "target": device.appid,
      "settings": settings.toJson(),
    });
  }

  void sharedDevice(String friend_id) {
    send("share", {
      "friend_id": int.parse(friend_id),
    });
  }

  void requestJoinRemoteScreen(Device device) {
    send("joinroom", {
      "requester": ApplicationInfoServiceImpl().appid,
      "target": device.appid
    });
  }

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

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

  Future<void> createOffer(
      RTCPeerConnection selfpc,
      String media,
      bool hasvideo,
      bool hasaudio,
      String targetappid,
      int roomid,
      int bitrate) async {
    try {
      RTCSessionDescription s = await selfpc.createOffer({
        'mandatory': {
          'OfferToReceiveAudio': hasaudio,
          'OfferToReceiveVideo': hasvideo,
        },
        'optional': [],
      });
      await selfpc.setLocalDescription(_fixSdp(s, bitrate));
      send('offer', {
        'to': targetappid,
        'from': _appInfo.appId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'room_id': roomid,
        'media': media,
        'bitrate': bitrate,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> createAnswer(RTCPeerConnection selfpc, String media,
      String targetpid, int roomid, int bitrate) async {
    try {
      RTCSessionDescription s = await selfpc.createAnswer({
        'mandatory': {
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      });
      await selfpc.setLocalDescription(_fixSdp(s, bitrate));
      send('answer', {
        'to': targetpid,
        'from': _appInfo.appId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'room_id': roomid,
        'media': media,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> CloseSession(String targetappid, int roomid) async {
    try {
      send('closesession', {
        'to': targetappid,
        'from': _appInfo.appId,
        'room_id': roomid,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void send(event, data) {
    print("sending----------");
    print(data);
    var request = {};
    request["type"] = event;
    request["data"] = data;
    _socket?.send(_encoder.convert(request));
  }

  //List<Future<int>> creationtasks=[];
  final _lock = Lock();

  void onMessage(message) async {
    print("--------------------------");
    print(message);
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];
    switch (mapData['type']) {
      case 'connections':
        {
          List<Device> devicelist = [];
          if (data != null) {
            data.forEach((appid, deviceData) {
              if (deviceData is Map<String, dynamic>) {
                //if (appid == _appInfo.appId) {
                //User user = User(uid:deviceData['uid'],nickname:deviceData['nickname']);
                //  _appInfo.updateUser(
                //      deviceData['uid'], deviceData['nickname']);
                //}
                devicelist.add(Device(
                  uid: deviceData['uid'],
                  nickname: deviceData['nickname'],
                  devicename: deviceData['devicename'],
                  devicetype: deviceData['devicetype'],
                  appid: appid,
                  connective: deviceData['connective'],
                ));
                //}
              }
            });
          }
          onDeviceListchanged?.call(devicelist);
        }
        break;
      case 'shareddevices':
        {
          List<Device> devicelist = [];
          if (data != null) {
            data.forEach((appid, deviceData) {
              if (deviceData is Map<String, dynamic>) {
                //if (appid == _appInfo.appId) {
                //User user = User(uid:deviceData['uid'],nickname:deviceData['nickname']);
                //  _appInfo.updateUser(
                //      deviceData['uid'], deviceData['nickname']);
                //}
                devicelist.add(Device(
                  uid: deviceData['uid'],
                  nickname: deviceData['nickname'],
                  devicename: deviceData['devicename'],
                  devicetype: deviceData['devicetype'],
                  appid: appid,
                  connective: deviceData['connective'],
                ));
                //}
              }
            });
          }
          onSharedDeviceListchanged?.call(devicelist);
        }
        break;
      case 'offer':
        {
          await StreamingServiceImpl().onOfferReceived(
              data["from"],
              data["room_id"],
              data["media"],
              data["description"],
              data["bitrate"]);
        }
        break;
      case 'candidate':
        {
          String dtype = data["type"];
          if (dtype == "hscreen" || dtype == "haudio") {
            // candidate from a screen sharing room
            await StreamingServiceImpl().onCandidate(
                data["from"], data["room_id"], dtype, data["candidate"]);
          } else {
            // candidate from a player
            await RoomServiceImpl().onCandidate(
                data["from"], data["room_id"], dtype, data["candidate"]);
          }
        }
        break;
      case 'answer':
        {
          if (data["media"] == "pvideo" || data["media"] == "paudio") {
            // answer from a player
            await RoomServiceImpl().onAnswerReceived(data["from"],
                data["room_id"], data["media"], data["description"]);
          } else {
            // candidate from a player
            //RoomServiceImpl().onCandidate(data["from"],data["room_id"],data["media"],data["description"]);
          }
        }
        break;
      case 'createroom':
        {
          await _lock.synchronized(() async {
            var requesterData = data["requester"];
            Device roommaster = Device(
              uid: requesterData['uid'],
              nickname: requesterData['nickname'],
              devicename: requesterData['devicename'],
              devicetype: requesterData['devicetype'],
              appid: requesterData['appid'],
              connective: requesterData['connective'],
            );
            StreamingSettings settings = StreamingSettings(
                fps: data["settings"]["fps"],
                bitrate: data["settings"]["bitrate"],
                hidecursor: data["settings"]["hidecursor"],
                hasaudio: data["settings"]["hasaudio"],
                useCustomNetwork: data["settings"]["useCustomNetwork"],
                customNetworkIp: data["settings"]["customNetworkIp"]);
            RoomServiceImpl().CreateRoom(roommaster, settings);
            //Future<int> task = RoomServiceImpl().CreateRoom(roommaster, settings);
            //creationtasks.add(task);
          });
        }
        break;
      case 'closesession':
        {
          //we should not close room during creation. use a lock to avoid that.
          //It is possible to happen enter here when creating the task, so
          //I don't use this:
          //await Future.wait(creationtasks);
          await _lock.synchronized(() async {
            await RoomServiceImpl().closeSession(data["room_id"], data["from"]);
          });
        }
        break;
      case 'disconnection':
        {
          //await Future.wait(creationtasks);
          // We should wait creation when remove room or peer.
          await _lock.synchronized(() async {
            await RoomServiceImpl().closeAllSessions(data);
          });
        }
        break;
      default:
        break;
    }
  }
}
*/