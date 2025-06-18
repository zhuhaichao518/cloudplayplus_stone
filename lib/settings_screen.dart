import 'package:cloudplayplus/controller/hardware_input_controller.dart';
import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/global_settings/streaming_settings.dart';
import 'package:cloudplayplus/pages/login_screen.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/login_service.dart';
import 'package:cloudplayplus/services/secure_storage_manager.dart';
import 'package:cloudplayplus/services/websocket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'plugins/flutter_settings_ui/flutter_settings_ui.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';
import 'utils/navigation.dart';
import 'utils/widgets/virtual_gamepad/virtual_gamepad_settings_screen.dart';
import 'utils/widgets/virtual_gamepad/control_manager.dart';

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
      appBar: AppBar(title: const Text('设置')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('串流设置'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.volume_up),
                title: const Text('音视频/剪贴板设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: const StreamingSettingsScreen(),
                    style: NavigationRouteStyle.cupertino,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.network_check),
                title: const Text('网络设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: const NetworkSettingsScreen(),
                    style: NavigationRouteStyle.cupertino,
                  );
                },
              ),
              //if (!AppPlatform.isMobile)
              SettingsTile.navigation(
                leading: const Icon(Icons.mouse),
                title: const Text('键鼠设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: const CursorSettingsScreen(),
                    style: NavigationRouteStyle.cupertino,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.gamepad),
                title: const Text('屏幕按键设置'),
                onPressed: (context) {
                  Navigation.navigateTo(
                    context: context,
                    screen: VirtualGamepadSettingsPage(
                      controlManager: ControlManager(),
                    ),
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
                    SharedPreferencesManager.setInt('ControlMsgResendCount', 2);
                    InputController.resendCount = 2;
                    StreamingSettings.autoHideLocalCursor = false;
                    SharedPreferencesManager.setBool(
                        "autoHideLocalCursor", false);
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
                    SharedPreferencesManager.setInt('ControlMsgResendCount', 6);
                    InputController.resendCount = 6;
                    StreamingSettings.autoHideLocalCursor = true;
                    SharedPreferencesManager.setBool(
                        "autoHideLocalCursor", true);
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
                              if (DevelopSettings.useSecureStorage) {
                                SecureStorageManager.clear();
                              }
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
                              //TODO:断开所有webrtc连接
                              WebSocketService.disconnect();
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
                              SharedPreferencesManager.setBool(
                                  'is_logged_in', false);
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
              SettingsTile(
                title: const Text('删除账户', style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.warning),
                onPressed: (BuildContext context) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('删除账户',
                              style: TextStyle(color: Colors.red)),
                          content: const Text('确定要删除账户吗?此操作无法恢复！',
                              style: TextStyle(color: Colors.red)),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (await LoginService().deleteAccount()) {
                                  WebSocketService.disconnect();
                                  if (DevelopSettings.useSecureStorage) {
                                    SecureStorageManager.clear();
                                  }
                                  SharedPreferencesManager.clear();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('删除失败,请检查网络连接'), // 提示内容
                                      duration: Duration(seconds: 2), // 自动消失时间
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('删除账户',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('取消'),
                            ),
                          ],
                        );
                      });
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('官方网站'),
            tiles: <SettingsTile>[
              SettingsTile(
                title: const Text('https://www.cloudplayplus.com'),
                leading: const Icon(Icons.link),
                onPressed: (BuildContext context) async {
                  final url = Uri.parse('https://www.cloudplayplus.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  return null;
                },
              ),
            ],
          ),
          SettingsSection(title: const Text('版本号'), tiles: <SettingsTile>[
            SettingsTile(
              title: const Text('1.0.6'),
              leading: const Icon(Icons.sunny),
            ),
            if (AppPlatform.isMobile)
              SettingsTile(
                title: const Text('苏ICP备2024135000号-2A'),
                leading: const Icon(Icons.numbers),
              ),
          ]),
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
  bool _useClipBoard = true;
  int _bitrate = 80000;
  int _audioBitrate = 32;
  int _frameRate = 60;
  String _codec = 'default';
  double _cursorScale = 100.0;
  final List<double> _scaleValues = [12.5, 25, 50, 75, 100, 125, 150, 200, 250, 300, 400, 500];

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
  final Map<int, String> audioBitrates = {
    32: '32',
    64: '64',
    128: '128',
    256: '256',
  };
  final Map<int, String> frameRates = {
    10: '10',
    15: '15',
    20: '20',
    30: '30',
    45: '45',
    60: '60',
  };

  // 将实际值映射到滑块位置（0-1之间）
  double _mapValueToPosition(double value) {
    int index = _scaleValues.indexOf(value);
    if (index == -1) {
      // 如果值不在列表中，找到最接近的值
      index = _scaleValues.indexWhere((v) => v > value) - 1;
      if (index < 0) index = 0;
      if (index >= _scaleValues.length - 1) index = _scaleValues.length - 2;
    }
    return index / (_scaleValues.length - 1);
  }

  // 将滑块位置（0-1之间）映射回实际值
  double _mapPositionToValue(double position) {
    int index = (position * (_scaleValues.length - 1)).round();
    return _scaleValues[index];
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _haveAudio = SharedPreferencesManager.getBool('haveAudio') ?? true;
    _bitrate = SharedPreferencesManager.getInt('bitRate') ?? 80000;
    _audioBitrate = SharedPreferencesManager.getInt('audioBitRate') ?? 32;
    _frameRate = SharedPreferencesManager.getInt('frameRate') ?? 60;
    _codec = SharedPreferencesManager.getString('codec') ?? 'default';
    if (AppPlatform.isDeskTop) {
      _useClipBoard = SharedPreferencesManager.getBool('useClipBoard') ?? true;
    } else {
      _useClipBoard = SharedPreferencesManager.getBool('useClipBoard') ?? false;
    }
    // 加载保存的缩放值，默认值为50
    double savedValue = SharedPreferencesManager.getDouble('cursorScale') ?? 50.0;
    // 找到最接近的预设值
    _cursorScale = _scaleValues.reduce((a, b) => 
      (a - savedValue).abs() < (b - savedValue).abs() ? a : b);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '音视频/剪贴板设置',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          //platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: const Text('视频设置'),
              tiles: [
                SettingsTile(
                  title: const Text('编码器(自行测试效果)'),
                  trailing: Material(child: Text('当前: $_codec')),
                  leading: const Icon(Icons.video_settings),
                  onPressed: (BuildContext context) async {
                    final codec = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: const Text('编码器设置')),
                        body: SettingsList(
                          sections: [
                            SettingsSection(
                              title: const Text('编码器'),
                              tiles: [
                                SettingsTile(
                                  title: const Text('默认'),
                                  onPressed: (context) {
                                    Navigator.of(context).pop('default');
                                  },
                                ),
                                SettingsTile(
                                  title: const Text('H.264'),
                                  onPressed: (context) {
                                    Navigator.of(context).pop('h264');
                                  },
                                ),
                                SettingsTile(
                                  title: const Text('VP9'),
                                  onPressed: (context) {
                                    Navigator.of(context).pop('vp9');
                                  },
                                ),
                                SettingsTile(
                                  title: const Text('VP8'),
                                  onPressed: (context) {
                                    Navigator.of(context).pop('vp8');
                                  },
                                ),
                                SettingsTile(
                                  title: const Text('AV1'),
                                  onPressed: (context) {
                                    Navigator.of(context).pop('av1');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      style: NavigationRouteStyle.cupertino,
                    );
                    if (codec != null) {
                      setState(() {
                        _codec = codec;
                      });
                      await SharedPreferencesManager.setString('codec', _codec);
                      StreamingSettings.codec = _codec;
                    }
                  },
                ),
                SettingsTile(
                  title: const Text('码率 (bps)'),
                  trailing:
                      Material(child: Text('当前: ${bitrates[_bitrate]} bps')),
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
                  trailing: Material(child: Text('当前: $_frameRate fps')),
                  leading: const Icon(Icons.videocam),
                  onPressed: (BuildContext context) async {
                    final framerate = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: const Text('帧数设置')),
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
              title: const Text('音频设置'),
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
                SettingsTile(
                  title: const Text('音频码率 (kbps)'),
                  trailing: Material(child: Text('当前: ${audioBitrates[_audioBitrate]} kbps')),
                  leading: const Icon(Icons.audiotrack),
                  onPressed: (BuildContext context) async {
                    final audioBitrate = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: const Text('音频码率设置')),
                        body: SettingsList(
                          sections: [
                            SettingsSection(
                              title: const Text('音频码率'),
                              tiles: audioBitrates.keys.map((bitrateKey) {
                                final bitrateValue = audioBitrates[bitrateKey];
                                return SettingsTile(
                                  title: Text('$bitrateValue kbps'),
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
                    if (audioBitrate != null) {
                      setState(() {
                        _audioBitrate = audioBitrate;
                      });
                      await SharedPreferencesManager.setInt('audioBitRate', _audioBitrate);
                      StreamingSettings.audioBitrate = _audioBitrate;
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('剪贴板'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('使用剪贴板'),
                  leading: const Icon(Icons.copy),
                  initialValue: _useClipBoard,
                  onToggle: (bool value) {
                    setState(() {
                      _useClipBoard = value;
                      SharedPreferencesManager.setBool('useClipBoard', value);
                      StreamingSettings.useClipBoard = _useClipBoard;
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

  //Turn server info
  late TextEditingController _addressController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  final Map<int, String> resendTimesMap = {
    0: '0',
    1: '1',
    2: '2',
    3: '3',
    4: '4',
    6: '6',
    8: '8',
    10: '10',
    12: '12',
    15: '15',
    20: '20',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _addressController = TextEditingController(text: customTurnServerAddress);
    _usernameController = TextEditingController(text: customTurnServerUsername);
    _passwordController = TextEditingController(text: customTurnServerPassword);
  }

  @override
  void dispose() {
    // 释放控制器
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    _addressController.text = customTurnServerAddress;
    _usernameController.text = customTurnServerUsername;
    _passwordController.text = customTurnServerPassword;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '网络设置',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          //platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: const Text('键鼠/手柄指令重发次数(如果网络环境导致输入操作有延迟，但画面流畅，可提高此值)'),
              tiles: [
                SettingsTile(
                  title: const Text('键鼠/手柄指令重发次数 (fps)'),
                  trailing: Material(
                      child: Text('重发: ${InputController.resendCount} 次')),
                  leading: const Icon(Icons.repeat),
                  onPressed: (BuildContext context) async {
                    final resendCount = await Navigation.navigateTo(
                      context: context,
                      screen: Scaffold(
                        appBar: AppBar(title: const Text('重发次数')),
                        body: SettingsList(
                          sections: [
                            SettingsSection(
                              title: const Text('重发次数'),
                              tiles: resendTimesMap.keys.map((resendCountKey) {
                                final frameratevalue =
                                    resendTimesMap[resendCountKey];
                                return SettingsTile(
                                  title: Text(frameratevalue!),
                                  onPressed: (context) {
                                    Navigator.of(context).pop(resendCountKey);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      style: NavigationRouteStyle.cupertino,
                    );
                    if (resendCount != null) {
                      setState(() {
                        SharedPreferencesManager.setInt(
                            'ControlMsgResendCount', resendCount);
                        InputController.resendCount = resendCount;
                      });
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('turn服务器设置'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('使用turn中继服务器'),
                  leading: const Icon(Icons.network_ping),
                  initialValue: useTurnServer,
                  onToggle: (bool value) {
                    setState(() {
                      useTurnServer = value;
                      StreamingSettings.useTurnServer = value;
                      SharedPreferencesManager.setBool('useTurnServer', value);
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
                            controller: _addressController,
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
                            controller: _usernameController,
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
                            controller: _passwordController,
                            obscureText: true,
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // Update the values when the user presses the save button
                                setState(() {
                                  customTurnServerAddress =
                                      _addressController.text.trim();
                                  customTurnServerUsername =
                                      _usernameController.text.trim();
                                  customTurnServerPassword =
                                      _passwordController.text.trim();
                                  StreamingSettings.customTurnServerAddress =
                                      customTurnServerAddress;
                                  StreamingSettings.customTurnServerUsername =
                                      customTurnServerUsername;
                                  StreamingSettings.customTurnServerPassword =
                                      customTurnServerPassword;
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

class CursorSettingsScreen extends StatefulWidget {
  const CursorSettingsScreen({super.key});

  @override
  _CursorSettingsScreenState createState() => _CursorSettingsScreenState();
}

class _CursorSettingsScreenState extends State<CursorSettingsScreen> {
  bool revertCursorWheel = true;
  bool autoHideLocalCursor = true;
  bool _renderRemoteCursor = false;
  bool _switchCmdCtrl = false;
  bool _useTouchForTouch = true;
  double _cursorScale = 50.0;
  final List<double> _scaleValues = [12.5, 25, 50, 75, 100, 125, 150, 200, 250, 300, 400, 500];

  // 将实际值映射到滑块位置（0-1之间）
  double _mapValueToPosition(double value) {
    int index = _scaleValues.indexOf(value);
    if (index == -1) {
      // 如果值不在列表中，找到最接近的值
      index = _scaleValues.indexWhere((v) => v > value) - 1;
      if (index < 0) index = 0;
      if (index >= _scaleValues.length - 1) index = _scaleValues.length - 2;
    }
    return index / (_scaleValues.length - 1);
  }

  // 将滑块位置（0-1之间）映射回实际值
  double _mapPositionToValue(double position) {
    int index = (position * (_scaleValues.length - 1)).round();
    return _scaleValues[index];
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    autoHideLocalCursor = StreamingSettings.autoHideLocalCursor;
    revertCursorWheel = StreamingSettings.revertCursorWheel;
    _renderRemoteCursor =
        SharedPreferencesManager.getBool('renderRemoteCursor') ?? false;
    _switchCmdCtrl = StreamingSettings.switchCmdCtrl;
    _useTouchForTouch = StreamingSettings.useTouchForTouch;
    // 加载保存的缩放值，默认值为100
    double savedValue = StreamingSettings.cursorScale;
    // 找到最接近的预设值
    _cursorScale = _scaleValues.reduce((a, b) => 
      (a - savedValue).abs() < (b - savedValue).abs() ? a : b);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '键鼠设置',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          sections: [
            SettingsSection(
              title: const Text('自动隐藏本地鼠标'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('反转鼠标滚轮'),
                  leading: const Icon(Icons.mouse),
                  initialValue: revertCursorWheel,
                  onToggle: (bool value) {
                    setState(() {
                      revertCursorWheel = value;
                      StreamingSettings.revertCursorWheel = value;
                      SharedPreferencesManager.setBool(
                          "revertCursorWheel", value);
                    });
                  },
                ),
                SettingsTile.switchTile(
                  title: const Text('远程鼠标隐藏时，自动锁定本地鼠标(第一人称游戏建议开启)'),
                  leading: const Icon(Icons.mouse),
                  initialValue: autoHideLocalCursor,
                  onToggle: (bool value) {
                    setState(() {
                      autoHideLocalCursor = value;
                      StreamingSettings.autoHideLocalCursor = value;
                      SharedPreferencesManager.setBool(
                          "autoHideLocalCursor", value);
                    });
                  },
                ),
                SettingsTile.switchTile(
                  title: const Text('显示远程鼠标(仅使用不支持硬件加速的windows设备)'),
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
                SettingsTile.switchTile(
                  title: const Text('(MacOS)交换command和control'),
                  leading: const Icon(Icons.keyboard),
                  initialValue: _switchCmdCtrl,
                  onToggle: (bool value) {
                    setState(() {
                      _switchCmdCtrl = value;
                      SharedPreferencesManager.setBool('switchCmdCtrl', value);
                      StreamingSettings.switchCmdCtrl = value;
                    });
                  },
                ),
                SettingsTile.switchTile(
                  title: const Text('使用触摸而不是鼠标消息(触摸设备控制windows)'),
                  leading: const Icon(Icons.touch_app),
                  initialValue: _useTouchForTouch,
                  onToggle: (bool value) {
                    setState(() {
                      _useTouchForTouch = value;
                      SharedPreferencesManager.setBool(
                          'useTouchForTouch', value);
                      StreamingSettings.useTouchForTouch = value;
                    });
                  },
                ),
                if (AppPlatform.isMobile)
                CustomSettingsTile(
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '本地指针缩放倍率',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_cursorScale.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          CupertinoSlider(
                            value: _mapValueToPosition(_cursorScale),
                            min: 0.0,
                            max: 1.0,
                            divisions: _scaleValues.length - 1,
                            onChanged: (position) {
                              double newValue = _mapPositionToValue(position);
                              setState(() {
                                _cursorScale = newValue;
                                SharedPreferencesManager.setDouble(
                                    'cursorScale', newValue);
                                StreamingSettings.cursorScale = newValue;
                              });
                            },
                          ),
                          const Text(
                            '拖动滑块调整缩放倍率',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
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
