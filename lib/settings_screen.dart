import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/pages/login_screen.dart';
import 'package:cloudplayplus/services/secure_storage_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plugins/flutter_settings_ui/flutter_settings_ui.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';
import 'utils/navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _themeIndex = 0;
  int _streamingmode = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeIndex = SharedPreferencesManager.getInt('themeIndex') ?? 0;
    _streamingmode = SharedPreferencesManager.getInt('streamingMode') ?? 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('串流设置'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.computer),
                title: Text('音视频设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: StreamingSettingsScreen(),
                    style: NavigationRouteStyle.cupertino,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.computer),
                title: Text('网络设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: NetworkSettingsScreen(),
                    style: NavigationRouteStyle.cupertino,
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('主题模式'),
            tiles: [
              SettingsTile(
                title: const Text('办公'),
                leading: const Icon(Icons.work),
                onPressed: (BuildContext context) {
                  setState(() {
                    _streamingmode = 0;
                    SharedPreferencesManager.setInt(
                        'streamingMode', _streamingmode);
                    themeProvider.setStreamingMode(0);
                  });
                },
              ),
              SettingsTile(
                title: const Text('游戏'),
                leading: const Icon(Icons.videogame_asset),
                onPressed: (BuildContext context) {
                  setState(() {
                    _streamingmode = 1;
                    SharedPreferencesManager.setInt(
                        'streamingMode', _streamingmode);
                    themeProvider.setStreamingMode(1);
                  });
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('主题设置'),
            tiles: [
              SettingsTile(
                title: const Text('日间'),
                leading: const Icon(Icons.wb_sunny),
                onPressed: (BuildContext context) {
                  setState(() {
                    _themeIndex = 0;
                    SharedPreferencesManager.setInt('themeIndex', _themeIndex);
                    themeProvider.setThemeMode(0);
                  });
                },
              ),
              SettingsTile(
                title: const Text('跟随系统'),
                leading: const Icon(Icons.settings),
                onPressed: (BuildContext context) {
                  setState(() {
                    _themeIndex = 1;
                    SharedPreferencesManager.setInt('themeIndex', _themeIndex);
                    themeProvider.setThemeMode(1);
                  });
                },
              ),
              SettingsTile(
                title: const Text('夜间'),
                leading: const Icon(Icons.nights_stay),
                onPressed: (BuildContext context) {
                  setState(() {
                    _themeIndex = 2;
                    SharedPreferencesManager.setInt('themeIndex', _themeIndex);
                    themeProvider.setThemeMode(2);
                  });
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('账号管理'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.logout),
                title: const Text('退出登陆'),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('退出'),
                        content: const Text('确定要退出登陆吗?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              WebSocketService.disconnect();
                              SharedPreferencesManager.clear();
                              SharedPreferencesManager.setBool(
                                  'appintroFinished', true);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text('登出并清除数据'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (DevelopSettings.useSecureStorage) {
                                SecureStorageManager.setString(
                                    'access_token', "");
                                SecureStorageManager.setString(
                                    'refresh_token', "");
                              } else {
                                SharedPreferencesManager.setString(
                                    'access_token', "");
                                SharedPreferencesManager.setString(
                                    'refresh_token', "");
                              }
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text('仅登出'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('取消'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StreamingSettingsScreen extends StatefulWidget {
  const StreamingSettingsScreen({Key? key}) : super(key: key);

  @override
  _StreamingSettingsScreen createState() => _StreamingSettingsScreen();
}

class _StreamingSettingsScreen extends State<StreamingSettingsScreen> {
  bool _haveAudio = true;
  bool _renderRemoteCursor = false;
  int _bitrate = 80000;
  int _frameRate = 60;
  final Map<int, String> bitrates = {
    2500: '2500',
    5000: '5000',
    10000: '10000',
    20000: '20000',
    40000: '40000',
    80000: '80000',
    160000: '160000',
    //0: '无限',
  };
  final Map<int, String> frameRates = {
    10: '10',
    15: '15',
    20: '20',
    30: '30',
    45: '45',
    60: '60',
  };
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _haveAudio = SharedPreferencesManager.getBool('haveAudio') ?? true;
    _bitrate = SharedPreferencesManager.getInt('bitRate') ?? 80000;
    _frameRate = SharedPreferencesManager.getInt('frameRate') ?? 60;
    _renderRemoteCursor =
        SharedPreferencesManager.getBool('renderRemoteCursor') ?? false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('音视频设置')),
      child: SafeArea(
        bottom: false,
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          //platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: const Text('视频设置'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('显示远程鼠标'),
                  leading: const Icon(Icons.mouse),
                  initialValue: _renderRemoteCursor,
                  onToggle: (bool value) {
                    setState(() {
                      _renderRemoteCursor = value;
                      SharedPreferencesManager.setBool(
                          'renderRemoteCursor', value);
                      StreamingSettings.showRemoteCursor = value;
                    });
                  },
                ),
                SettingsTile(
                  title: const Text('码率 (bps)'),
                  trailing: Text('当前: ${bitrates[_bitrate]} bps'),
                  leading: const Icon(Icons.network_cell),
                  onPressed: (BuildContext context) async {
                    final bitrate = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: Text('Bitrate')),
                        body: SettingsList(
                          sections: [
                            SettingsSection(
                              title: Text('Bitrate'),
                              tiles: bitrates.keys.map((bitrateKey) {
                                final bitrateValue = bitrates[bitrateKey];
                                return SettingsTile(
                                  title: Text(bitrateValue!),
                                  onPressed: (context) {
                                    Navigator.of(context).pop(bitrateKey);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      style: NavigationRouteStyle.cupertino,
                    );
                    if (bitrate != null) {
                      setState(() {
                        _bitrate = bitrate;
                      });
                      await SharedPreferencesManager.setInt(
                          'bitRate', _bitrate);
                      StreamingSettings.bitrate = _bitrate;
                    }
                  },
                ),
                SettingsTile(
                  title: const Text('帧率 (fps)'),
                  trailing: Text('当前: $_frameRate fps'),
                  leading: const Icon(Icons.videocam),
                  onPressed: (BuildContext context) async {
                    final framerate = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: Text('帧数设置')),
                        body: SettingsList(
                          sections: [
                            SettingsSection(
                              title: const Text('fps'),
                              tiles: frameRates.keys.map((frameratekey) {
                                final frameratevalue = frameRates[frameratekey];
                                return SettingsTile(
                                  title: Text(frameratevalue!),
                                  onPressed: (context) {
                                    Navigator.of(context).pop(frameratekey);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      style: NavigationRouteStyle.cupertino,
                    );
                    if (framerate != null) {
                      setState(() {
                        _frameRate = framerate;
                      });
                      await SharedPreferencesManager.setInt(
                          'frameRate', framerate);
                      StreamingSettings.framerate = framerate;
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('音屏设置'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('打开音频'),
                  leading: const Icon(Icons.volume_up),
                  initialValue: _haveAudio,
                  onToggle: (bool value) {
                    setState(() {
                      _haveAudio = value;
                      SharedPreferencesManager.setBool('haveAudio', value);
                      StreamingSettings.streamAudio = _haveAudio;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  _NetworkSettingsScreenState createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  bool useTurnServer = false;
  String customTurnServerAddress = "";
  String customTurnServerUsername = "";
  String customTurnServerPassword = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    useTurnServer = StreamingSettings.useTurnServer;
    customTurnServerAddress =
        SharedPreferencesManager.getString('customTurnServerAddress') ??
            'turn:106.14.91.137:3478';
    customTurnServerUsername =
        SharedPreferencesManager.getString('customTurnServerUsername') ??
            'haichaozhu';
    customTurnServerPassword =
        SharedPreferencesManager.getString('customTurnServerPassword') ??
            'pdhcppturn123';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('网络设置')),
      child: SafeArea(
        bottom: false,
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          //platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: const Text('turn服务器设置'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('使用turn中继服务器'),
                  leading: const Icon(Icons.mouse),
                  initialValue: useTurnServer,
                  onToggle: (bool value) {
                    setState(() {
                      //默认关着 就不持久化了
                      useTurnServer = value;
                      StreamingSettings.useTurnServer = value;
                    });
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('中继服务器信息(默认为官方 WebRTC TURN 服务器，流量不稳定，请查询教程搭建)'),
              tiles: [
                CustomSettingsTile(
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TURN 服务器地址',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: '请输入自定义 TURN 服务器地址',
                            ),
                            controller: TextEditingController(
                                text: customTurnServerAddress),
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'TURN 服务器用户名',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: '请输入自定义用户名',
                            ),
                            controller: TextEditingController(
                                text: customTurnServerUsername),
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'TURN 服务器密码',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: '请输入自定义密码',
                            ),
                            controller: TextEditingController(
                                text: customTurnServerPassword),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // Update the values when the user presses the save button
                                setState(() {
                                  customTurnServerAddress =
                                      (TextEditingController(
                                                  text: customTurnServerAddress)
                                              .text)
                                          .trim();
                                  customTurnServerUsername =
                                      (TextEditingController(
                                                  text:
                                                      customTurnServerUsername)
                                              .text)
                                          .trim();
                                  customTurnServerPassword =
                                      (TextEditingController(
                                                  text:
                                                      customTurnServerPassword)
                                              .text)
                                          .trim();
                                  SharedPreferencesManager.setString(
                                      'customTurnServerAddress',
                                      customTurnServerAddress);
                                  SharedPreferencesManager.setString(
                                      'customTurnServerUsername',
                                      customTurnServerUsername);
                                  SharedPreferencesManager.setString(
                                      'customTurnServerPassword',
                                      customTurnServerPassword);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('保存成功'),
                                        content: const Text('TURN 服务器信息已保存。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                });
                              },
                              child: const Text('保存'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
