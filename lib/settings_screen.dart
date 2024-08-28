import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/theme_provider.dart';

const colorizeColors = [
  Colors.red,
  Colors.blue,
];

const colorizeTextStyle = TextStyle(
  fontSize: 50.0,
  fontFamily: 'Horizon',
);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _haveAudio = true;
  bool _renderRemoteCursor = true;
  String _bitrate = '80000';
  int _frameRate = 60;
  int _themeIndex = 0;
  int _streamingmode = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    //_saveSettings();
  }

  Future<void> _loadSettings() async {
    _haveAudio = SharedPreferencesManager.getBool('haveAudio') ?? true;
    _bitrate = SharedPreferencesManager.getString('bitRate') ?? '80000';
    _frameRate = SharedPreferencesManager.getInt('frameRate') ?? 60;
    _renderRemoteCursor =
        SharedPreferencesManager.getBool('renderRemoteCursor') ?? false;
    _themeIndex = SharedPreferencesManager.getInt('themeIndex') ?? 0;
    _streamingmode = SharedPreferencesManager.getInt('streamingMode') ?? 0;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await SharedPreferencesManager.setBool('haveAudio', _haveAudio);
    await SharedPreferencesManager.setString('bitRate', _bitrate);
    await SharedPreferencesManager.setInt('frameRate', _frameRate);
    await SharedPreferencesManager.setBool(
        'renderRemoteCursor', _renderRemoteCursor);
    await SharedPreferencesManager.setInt('themeIndex', _themeIndex);
    await SharedPreferencesManager.setInt('streamingMode', _streamingmode);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('主题设置'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToggleButtons(
                  isSelected: [
                    _themeIndex == 0,
                    _themeIndex == 1,
                    _themeIndex == 2
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _themeIndex = index;
                      SharedPreferencesManager.setInt(
                          'themeIndex', _themeIndex);
                      themeProvider.setThemeMode(index);
                    });
                  },
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('日间'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('跟随系统'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('夜间'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToggleButtons(
                  isSelected: [_streamingmode == 0, _streamingmode == 1],
                  onPressed: (int index) {
                    setState(() {
                      _streamingmode = index;
                      SharedPreferencesManager.setInt(
                          'streamingMode', _streamingmode);
                      themeProvider.setStreamingMode(_streamingmode);
                    });
                  },
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('办公'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('游戏'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('社交'),
            children: [
              ListTile(
                title: const Text('个人信息'),
                onTap: () {
                  /*Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PersonalInfoPage()),
                  );*/
                },
              ),
              ListTile(
                title: const Text('登出'),
                onTap: () async {},
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('音频设置'),
            children: [
              ListTile(
                title: const Text('打开音频'),
                trailing: Switch(
                  value: _haveAudio,
                  onChanged: (bool value) {
                    setState(() {
                      _haveAudio = value;
                    });
                    SharedPreferencesManager.setBool('haveAudio', value);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('视频设置'),
            children: [
              ListTile(
                title: const Text('隐藏远程鼠标'),
                trailing: Switch(
                  value: _renderRemoteCursor,
                  onChanged: (bool value) {
                    setState(() {
                      _renderRemoteCursor = value;
                    });
                    SharedPreferencesManager.setBool(
                        'renderRemoteCursor', value);
                  },
                ),
              ),
              ListTile(
                title: const Text('码率 (bps)'),
                subtitle: const Text('提示: 1080p 30fps 约为10000 bps'),
                trailing: DropdownButton<String>(
                  value: _bitrate,
                  onChanged: (String? newValue) {
                    setState(() {
                      _bitrate = newValue ?? _bitrate;
                    });
                    SharedPreferencesManager.setString(
                        'renderRemoteCursor', newValue!);
                  },
                  items: [
                    '2500',
                    '5000',
                    '10000',
                    '20000',
                    '40000',
                    '80000',
                    '160000',
                    '无限'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('$value bps'),
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                title: const Text('帧率 (fps)'),
                trailing: DropdownButton<int>(
                  value: _frameRate,
                  onChanged: (int? newValue) {
                    setState(() {
                      _frameRate = newValue ?? _frameRate;
                    });
                    SharedPreferencesManager.setInt('frameRate', newValue!);
                  },
                  items: [10, 15, 20, 30, 45, 60]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value fps'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
