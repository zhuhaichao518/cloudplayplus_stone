import 'package:cloudplayplus/services/login_service.dart';
import 'package:hardware_simulator/hardware_simulator.dart';

import '../dev_settings.dart/develop_settings.dart';
import 'app_info_service.dart';
import 'shared_preferences_manager.dart';

//这个类决定了app启动的时候进入哪一个页面。
class AppInitService {
  static late Future<int> appInitState;

  // 0:需要加载产品介绍页面
  // 1:需要进登录页面
  // 2:进入登录的主页
  static Future<int> getAppState() async {
    //SharedPreferencesManager.clear();
    //simulate loading time
    await Future.delayed(const Duration(seconds: 1));
    if (DevelopSettings.alwaysShowIntroPage) {
      return 0;
    }
    bool appintroFinished =
        SharedPreferencesManager.getBool('appintroFinished') ?? false;
    ApplicationInfo.deviceNameOverride =
        SharedPreferencesManager.getString('deviceNameOverride');
    if (!appintroFinished) return 0;
    bool isLoggedin = await LoginService.tryLoginWithCachedToken();
    if (!isLoggedin) {
      return 1;
    }
    return 2;
  }

  static Future<void> init() async {
    appInitState = getAppState();
    ApplicationInfo.connectable =
        SharedPreferencesManager.getBool('allowConnect') ?? false;
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
