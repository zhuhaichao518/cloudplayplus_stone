import 'package:cloudplayplus/services/app_init_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/init_page.dart';
import 'services/secure_storage_manager.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';

void main() async {
  await AppInitService.init();
  await SharedPreferencesManager.init();
  SecureStorageManager.init();
  runApp(const MyApp());
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
          );
        },
      ),
    );
  }
}
