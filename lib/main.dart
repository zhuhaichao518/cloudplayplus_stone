import 'package:cloudplayplus/controller/hardware_input_controller.dart';
import 'package:cloudplayplus/services/app_init_service.dart';
import 'package:flutter/material.dart';
import 'package:hardware_simulator/hardware_simulator.dart';
import 'package:provider/provider.dart';
import 'base/logging.dart';
import 'controller/screen_controller.dart';
import 'global_settings/streaming_settings.dart';
import 'pages/init_page.dart';
import 'services/app_info_service.dart';
import 'services/login_service.dart';
import 'services/secure_storage_manager.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'utils/system_tray_manager.dart';

void main() async {
  LoginService.init();
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenController.initialize();
  await SharedPreferencesManager.init();
  SecureStorageManager.init();
  //AppInitService depends on SharedPreferencesManager
  await AppInitService.init();
  StreamingSettings.init();
  InputController.init();
  if (AppPlatform.isWeb) {
    setUrlStrategy(null);
  }
  runApp(const MyApp());
  if (AppPlatform.isWindows || AppPlatform.isMacos || AppPlatform.isLinux) {
    doWhenWindowReady(() {
      const initialSize = Size(400, 450);
      appWindow.minSize = initialSize;
      //appWindow.size = initialSize;
      //appWindow.titleBarButtonSize = Size(60,60);
      //appWindow.titleBarHeight = 60;
      appWindow.alignment = Alignment.center;
      //如果用户选择了系统身份启动 直接关闭自己重新以系统身份启动
      if (AppPlatform.isWindows && !ApplicationInfo.isSystem) {
        appWindow.hide();
        AppInitService.appInitState.then((state) async {
          bool runAsSystemOnStart =
              SharedPreferencesManager.getBool('runAsSystemOnStart') ?? false;
          if (runAsSystemOnStart) {
            //无论是否登录成功 都试图重新以系统身份启动
            await HardwareSimulator.registerService();
            Future.delayed(const Duration(seconds: 5), () {
              SystemTrayManager().exitApp();
            });
          }
        }).catchError((error) {
          VLOG0('Error: failed appInitState');
        });
      } else {
        //以系统身份启动 并且开启了串流 假如登录成功 默认最小化
        if (ApplicationInfo.connectable && AppPlatform.isWindows) {
          AppInitService.appInitState.then((state) async {
            if (state == 2) {
              appWindow.hide();
            } else {
              appWindow.show();
            }
          }).catchError((error) {
            VLOG0('Error: failed appInitState 2');
          });
        } else {
          appWindow.show();
        }
      }
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cloudplay Plus',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const InitPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
