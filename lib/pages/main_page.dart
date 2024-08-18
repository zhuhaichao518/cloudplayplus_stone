import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter/material.dart';
import '../settings_screen.dart';
import 'devices_page.dart';
import 'master_detail/views/grouped.dart';
import 'master_detail/views/ungrouped.dart';

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
    _children = [
      DevicesPage(),
      //Grouped(),
      const Text("test"),//Grouped(),
      const Text("test"),//Ungrouped(),
      const SettingsScreen(),//GamesPage(),
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
    return Stack(children: [
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
        bottomNavigationBar: true
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                onTap: onTabTapped,
                currentIndex: _currentIndex,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.computer),
                    label: 'Devices',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.games_rounded),
                    label: 'Games',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.group),
                    label: 'Friends',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              )
            : null,
      ),
    ]);
  }
}

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),//Text('GamesPage Page'),
    );
  }
}