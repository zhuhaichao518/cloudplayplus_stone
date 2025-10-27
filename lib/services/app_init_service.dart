import 'package:cloudplayplus/base/logging.dart';
import 'package:cloudplayplus/services/login_service.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../dev_settings.dart/develop_settings.dart';
import 'app_info_service.dart';
import 'shared_preferences_manager.dart';

enum AppInitState {
  firstTime,
  needLogin,
  needReconnect,
  loggedin,
}

//这个类决定了app启动的时候进入哪一个页面。
class AppInitService {
  static late Future<AppInitState> appInitState;

  // 0:需要加载产品介绍页面
  // 1:需要进登录页面
  // 2:进入登录的主页
  // 可能有网络连接的问题（特别是开机的时候暂时无网络）
  // 应当记录上次退出时用户是登录了还是没登录 登录了就说明很可能是网络问题
  static Future<AppInitState> getAppState() async {
    //SharedPreferencesManager.clear();
    //simulate loading time
    await Future.delayed(const Duration(seconds: 1));
    if (DevelopSettings.alwaysShowIntroPage) {
      return AppInitState.firstTime;
    }
    bool appintroFinished =
        SharedPreferencesManager.getBool('appintroFinished') ?? false;
    ApplicationInfo.deviceNameOverride =
        SharedPreferencesManager.getString('deviceNameOverride');
    if (!appintroFinished) return AppInitState.firstTime;

    bool wasLoggedin =
        SharedPreferencesManager.getBool('is_logged_in') ?? false;
    if (wasLoggedin) {
      bool isLoggedin = await LoginService.tryLoginWithCachedToken();
      if (!isLoggedin) {
        return AppInitState.needReconnect;
      }
      return AppInitState.loggedin;
    }
    return AppInitState.needLogin;
  }

  static Future<bool> reconnect() {
    return LoginService.tryLoginWithCachedToken();
  }

  static Future<void> init() async {
    appInitState = getAppState();
    ApplicationInfo.connectable =
        SharedPreferencesManager.getBool('allowConnect') ?? false;
    ApplicationInfo.screencount = await HardwareSimulator.getMonitorCount();
    //TODO:implement for other platforms
    if (AppPlatform.isWindows) {
      HardwareSimulator.initParsecVdd();
      ApplicationInfo.screencount = await HardwareSimulator.getAllDisplays();
      HardwareSimulator.addDisplayCountChangedCallback((displayCount) {
        VLOG0("display count changed: $displayCount");
        ApplicationInfo.screencount = displayCount;
        if (WebSocketService.connectionState == WebSocketConnectionState.connected) {
          WebSocketService.updateDeviceInfo();
        }
        // 完成全局的显示器数量变化Completer
        if (ApplicationInfo.displayCountChangedCompleter != null && 
            !ApplicationInfo.displayCountChangedCompleter!.isCompleted) {
          ApplicationInfo.displayCountChangedCompleter!.complete();
        }
      }, 0);
    }
    bool? isSystem = await HardwareSimulator.isRunningAsSystem();
    if (isSystem == false) {
      ApplicationInfo.isSystem = false;
      //ApplicationInfo.connectable = false;
    }
    /*if (ApplicationInfo.isSystem && AppPlatform.isWindows) {
      ApplicationInfo.connectable = true;
    }*/
  }
}
