import 'package:cloudplayplus/services/login_service.dart';

import 'shared_preferences_manager.dart';

class AppInitService {
  static late Future<int> appInitState;

  // 0:需要加载产品介绍页面
  // 1:需要进登录页面
  // 2:进入登录的主页
  static Future<int> getAppState() async {
    //simulate loading time
    await Future.delayed(const Duration(seconds: 2));
    bool appintroFinished =
        SharedPreferencesManager.getBool('appintroFinished') ?? false;
    if (!appintroFinished) return 0;
    bool isLoggedin = await LoginService.tryLoginWithCachedInfo();
    if (!isLoggedin) {
      return 1;
    }
    return 2;
  }

  static Future<void> init() async {
    appInitState = getAppState();
  }
}
