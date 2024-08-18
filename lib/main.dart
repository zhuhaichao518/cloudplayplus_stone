import 'package:cloudplayplus/services/app_init_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/init_page.dart';
import 'services/app_info_service.dart';
import 'services/login_service.dart';
import 'services/secure_storage_manager.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';
import'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  LoginService.init();
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesManager.init();
  SecureStorageManager.init();
  //AppInitService depends on SharedPreferencesManager
  await AppInitService.init();
  runApp(const MyApp());
  if (AppPlatform.isWindows || AppPlatform.isMacos || AppPlatform.isLinux) {
    doWhenWindowReady(() {
      const initialSize = Size(400, 450);
      appWindow.minSize = initialSize;
      //appWindow.size = initialSize;
      //appWindow.titleBarButtonSize = Size(60,60);
      //appWindow.titleBarHeight = 60;
      appWindow.alignment = Alignment.center;
      appWindow.show();
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
