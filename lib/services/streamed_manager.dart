import 'dart:async';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/utils/hash_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hardware_simulator/display_data.dart';
import 'package:synchronized/synchronized.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../base/logging.dart';
import '../entities/device.dart';
import '../entities/session.dart';
import 'app_info_service.dart';

// ignore: constant_identifier_names
const int AUDIO_SYSTEM = 255;

class StreamedManager {
  static Map<String, StreamingSession> sessions = {};

  //We put localstream here because we want sessions share a local stream.
  //Screenid to MediaStream
  static Map<int, MediaStream> localVideoStreams = {};
  static Map<int, int> localVideoStreamsCount = {};

  //255: system audio
  //0~n: local microphones
  //AUDIO_SYSTEM = 255;
  static Map<int, MediaStream> localAudioStreams = {};
  static int audioSenderCount = 0;

  //auto increment. used for cursor hooks.
  static int cursorImageHookID = 0;
  static int cursorPositionUpdatedHookID = 0;

  static ValueNotifier<int> currentlyStreamedCount = ValueNotifier(0);
  static void setCurrentStreamedState(int value) {
    //if (isCurrentlyStreamed.value != value) {
    currentlyStreamedCount.value = value;
    //}
  }

  // Map from real screen id to virtual display id
  static Map<int, int> virtualDisplayIds = {};

  // 创建虚拟显示器
  static Future<int?> _createVirtualDisplay(int width, int height) async {
    try {
      // 初始化parsec-vdd
      bool initialized = await HardwareSimulator.initParsecVdd();
      if (!initialized) {
        VLOG0('初始化parsec-vdd失败');
        return null;
      }

      // 创建虚拟显示器
      int displayId = await HardwareSimulator.createDisplay();
      //refresh display list.
      await HardwareSimulator.getAllDisplays();
      if (displayId >= 0) {
        VLOG0('创建虚拟显示器成功,ID: $displayId');
        final customConfigs = await HardwareSimulator.getCustomDisplayConfigs();

        List<Map<String, dynamic>> newConfigs = List.from(customConfigs);
        
        bool isresolutionExist = false;

        for (var config in newConfigs) {
          if (config['width'] == width && config['height'] == height) {
            isresolutionExist = true;
            break;
          }
        }
        if (!isresolutionExist) {
          if (newConfigs.length > 4) {
            newConfigs.removeAt(0);
          }

          newConfigs.add({
            'width': width,
            'height': height,
            'refreshRate': 60,
          });

          bool success = await HardwareSimulator.setCustomDisplayConfigs(newConfigs);
          if (success) {
            VLOG0('添加虚拟显示器分辨率成功: ${width}x${height}');
          } else {
            VLOG0('添加虚拟显示器分辨率失败');
          }
        }
        // 设置虚拟显示器分辨率
        bool success = await HardwareSimulator.changeDisplaySettings(
          displayId, width, height, 60);
        if (success) {
          VLOG0('设置虚拟显示器分辨率成功: ${width}x${height}');
        } else {
          VLOG0('设置虚拟显示器分辨率失败');
        }
        
        return displayId;
      } else {
        VLOG0('创建虚拟显示器失败');
        return null;
      }
    } catch (e) {
      VLOG0('创建虚拟显示器异常: $e');
      return null;
    }
  }

  // 移除指定的虚拟显示器
  static Future<void> _removeVirtualDisplay(int displayId) async {
    try {
      bool removed = await HardwareSimulator.removeDisplay(displayId);
      if (removed) {
        //refresh display list.
        await HardwareSimulator.getAllDisplays();
        VLOG0('删除虚拟显示器成功,ID: $displayId');
      } else {
        VLOG0('删除虚拟显示器失败,ID: $displayId');
      }
    } catch (e) {
      VLOG0('删除虚拟显示器异常: $e');
    }
  }

  Future<void> _loadCurrentMultiDisplayMode() async {
    try {
      MultiDisplayMode mode = await HardwareSimulator.getCurrentMultiDisplayMode();
      print('Current multi-display mode: $mode');
    } catch (e) {
      print('Failed to load current multi-display mode: $e');
    }
  }

  Future<void> _setMultiDisplayMode(MultiDisplayMode mode) async {
      await HardwareSimulator.setMultiDisplayMode(mode);
      await _loadCurrentMultiDisplayMode();
  }

  static void startStreaming(Device target, StreamedSettings settings) async {
    bool allowConnect = ApplicationInfo
        .connectable; // || (AppPlatform.isWindows && ApplicationInfo.isSystem);
    if (!allowConnect) return;
    // 旧版本可能不传这个值，或者bug导致没有传connectPassword
    if (settings.connectPassword == null) return;
    if (StreamingSettings.connectPasswordHash !=
        HashUtil.hash(settings.connectPassword!)) return;
    
    bool shouldWait = false;
    Completer<void>? displayCallbackCompleter;

    await _lock.synchronized(() async {
      if (sessions.containsKey(target.websocketSessionid)) {
        VLOG0(
            "Starting session which is already started: $target.websocketSessionid");
        return;
      }
      if (settings.streamMode != null && settings.streamMode == 1) {
        // 独占模式，暂时视为串流到新增的screenid 稍后重置为0
        bool hasPending = await HardwareSimulator.hasPendingConfiguration();
        if (hasPending) {
          VLOG0("已经被其他设备使用了独占显示器模式，无法连接");
          return;
        }
        settings.screenId = ApplicationInfo.screencount;
      }
      // 处理虚拟显示器模式
      if (settings.streamMode != null && settings.streamMode! > 0) {
        //远端负责给我们传screenId, id应当等于目前显示器数量, 否则可能未及时同步，拒绝创建虚拟显示器
        if (settings.screenId != ApplicationInfo.screencount) {
          VLOG0('远端传的screenId不等于目前显示器数量，拒绝创建虚拟显示器');
          return;
        }
        // 独占模式或扩展屏模式，需要创建虚拟显示器
        int width = settings.customScreenWidth ?? 1920;
        int height = settings.customScreenHeight ?? 1080;
        
        // 创建全局的Completer来等待显示器数量变化回调
        ApplicationInfo.displayCountChangedCompleter = Completer<void>();
        displayCallbackCompleter = ApplicationInfo.displayCountChangedCompleter;
        
        int? virtualDisplayId = await _createVirtualDisplay(width, height);
        if (virtualDisplayId != null) {
          // 使用虚拟显示器的ID作为screenId
          shouldWait = true;
          if (settings.streamMode == 1) {
            virtualDisplayIds[0] = virtualDisplayId;
          }
          if (settings.streamMode == 2) {
            virtualDisplayIds[settings.screenId!] = virtualDisplayId;
          }
          VLOG0('使用虚拟显示器模式，显示器ID: $virtualDisplayId');
        } else {
          VLOG0('创建虚拟显示器失败');
          return;
        }
      }
    });
    
    //Give Windows time to create virtual display and wait for display count change callback.
    if (shouldWait && displayCallbackCompleter != null) {
      // 等待显示器数量变化回调被触发，然后等待500ms
      await displayCallbackCompleter!.future;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await _lock.synchronized(() async {
      if (!localVideoStreams.containsKey(settings.screenId!)) {
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
          int retryCount = 0;
          while (sources.length <= settings.screenId!) {
            retryCount++;
            if (retryCount > 10) {
              VLOG0('创建虚拟显示器后 等待超时');
              //也许不用remove？
              if (virtualDisplayIds.containsKey(settings.screenId)) {
                _removeVirtualDisplay(virtualDisplayIds[settings.screenId]!);
                virtualDisplayIds.remove(settings.screenId);
              }
              return;
            }
            await Future.delayed(const Duration(milliseconds: 500));
            sources = await desktopCapturer.getSources(types: [SourceType.Screen]);
          }
          // 独占模式，其实需要重置新显示器为主显示器
          if (settings.streamMode == 1 && sources.length != 1) {
            //await HardwareSimulator.setMultiDisplayMode(MultiDisplayMode.primaryOnly);
            await HardwareSimulator.setPrimaryDisplayOnly(virtualDisplayIds[0]!);
            retryCount = 0;
            while (sources.length != 1) {
              retryCount++;
              if (retryCount > 10) {
                VLOG0('创建虚拟显示器后 等待超时');
                HardwareSimulator.restoreDisplayConfiguration();
                return;
              }
              await Future.delayed(const Duration(milliseconds: 500));
              sources = await desktopCapturer.getSources(types: [SourceType.Screen]);
            }
            settings.screenId = 0;
          }
          final source = sources[settings.screenId!];
          mediaConstraints = <String, dynamic>{
            'video': {
              'deviceId': {'exact': source.id},
              'mandatory': {
                'frameRate': settings.framerate,
                //Todo(haichao): currently disable this because it will cause crash on some devices.
                'hasCursor': false//settings.showRemoteCursor
              }
            },
            'audio': false
          };
        }
        try {
          localVideoStreams[settings.screenId!] =
              await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
          localVideoStreamsCount[settings.screenId!] = 1;
        } catch (e) {
          //This happens on Web when user choose not to share the content.
          VLOG0("getDisplayMedia failed.$e");
          return;
        }
      } else {
        localVideoStreamsCount[settings.screenId!] =
            localVideoStreamsCount[settings.screenId!]! + 1;
      }
      StreamingSession session =
          StreamingSession(target, ApplicationInfo.thisDevice);
      cursorImageHookID++;
      session.cursorImageHookID = cursorImageHookID;
      cursorPositionUpdatedHookID++;
      session.cursorPositionUpdatedHookID = cursorPositionUpdatedHookID;
      session.acceptRequest(settings);
      sessions[target.websocketSessionid] = session;
      setCurrentStreamedState(sessions.length);
    });
  }

  static final _lock = Lock();

  static void stopStreaming(Device target) {
    _lock.synchronized(() {
      if (sessions.containsKey(target.websocketSessionid)) {
        StreamingSession? session = sessions[target.websocketSessionid];
        session?.stop();
        int screenId = session!.streamSettings!.screenId!;
        sessions.remove(target.websocketSessionid);
        localVideoStreamsCount[screenId] =
            localVideoStreamsCount[screenId]! - 1;
        if (localVideoStreamsCount[screenId] == 0) {
          if (localVideoStreams[screenId] != null) {
            localVideoStreams[screenId]?.getTracks().forEach((track) {
              track.stop();
            });
            localVideoStreams.remove(screenId);
          }
          
          // 如果这个screenId对应的是虚拟显示器，则移除它
          if (virtualDisplayIds.containsKey(screenId)) {
            _removeVirtualDisplay(virtualDisplayIds[screenId]!);
            virtualDisplayIds.remove(screenId);
            if (session.streamSettings?.streamMode == 1) {
              //虚拟显示器模式结束，恢复之前的屏幕设置。
              HardwareSimulator.restoreDisplayConfiguration();
            }
          }
        }
        if (sessions.isEmpty) {
          //TODO(Haichao): maybe restart app to save memory? 给用户一个按钮来重启app.
        }
      } else {
        VLOG0("No session found with sessionId: $target.websocketSessionid");
      }
      setCurrentStreamedState(sessions.length);
    });
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
