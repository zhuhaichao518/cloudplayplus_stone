import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/streamed_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:cloudplayplus/theme/fixed_colors.dart';
import 'package:cloudplayplus/utils/system_tray_manager.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
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
    //if (ApplicationInfo.isSystem){
    SystemTrayManager().initialize();
    //}
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
    return ValueListenableBuilder<int>(
        valueListenable: StreamedManager.currentlyStreamedCount,
        builder: (context, streamedcount, child) {
          if (streamedcount != 0 && AppPlatform.isWindows) {
            windowManager.setAsFrameless();
            return Scaffold(
                backgroundColor: Colors.white,
                body: Column(
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        ColorizeAnimatedText(
                          'Cloud Play Plus',
                          textStyle: colorizeTextStyle,
                          colors: colorizeColors,
                        ),
                      ],
                      isRepeatingAnimation: false,
                      onTap: () {
                        //print("Tap Event");
                      },
                    ),
                    const SizedBox(width: 20.0, height: 30.0),
                    const Text('正在被以下客户端远程连接。',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      children: [
                        // 表头
                        const TableRow(
                          //decoration: BoxDecoration(color: Colors.grey),
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('实例名',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('用户昵称',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('操作',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ],
                        ),
                        // 表格数据
                        ...StreamedManager.sessions.values
                            .map((session) => TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                            session.controller.devicename,
                                            textAlign: TextAlign.center),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(session.controller.nickname,
                                            textAlign: TextAlign.center),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            StreamedManager.stopStreaming(
                                                session.controller);
                                          },
                                          child: const Text('断开连接',
                                              style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        SystemTrayManager().hideWindow();
                      },
                      child: const Text('最小化到系统托盘',
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ));
          }
          windowManager.setTitleBarStyle(TitleBarStyle.normal);
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
        });
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
