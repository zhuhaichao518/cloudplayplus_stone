import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:cloudplayplus/utils/system_tray_manager.dart';
import 'package:flutter/material.dart';
import '../settings_screen.dart';
import 'devices_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  initState() {
    super.initState();
    WebSocketService.init();
    if (ApplicationInfo.isSystem){
      SystemTrayManager().initialize();
    }
    _children = [
      DevicesPage(),
      //Grouped(),
      //const Text("test"), //Grouped(),
      Scaffold(
        appBar: AppBar(title: const Text('我的好友')),
        body: const Center(
          child: Text(
            '暂未开放 敬请期待',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
      const SettingsScreen(), //GamesPage(),
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: _children,
              ),
            ],
          ),
          // 使用 ValueListenableBuilder 监听 showBottomNav 的状态
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: ScreenController.showBottomNav,
            builder: (context, showNavBar, child) {
              if (!showNavBar) return const SizedBox();
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                onTap: onTabTapped,
                currentIndex: _currentIndex,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.computer),
                    label: 'Devices',
                  ),
                  /*BottomNavigationBarItem(
                    icon: Icon(Icons.games_rounded),
                    label: 'Games',
                  ),*/
                  BottomNavigationBarItem(
                    icon: Icon(Icons.group),
                    label: 'Friends',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(), //Text('GamesPage Page'),
    );
  }
}
