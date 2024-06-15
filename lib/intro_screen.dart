import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import 'pages/login_page.dart';
import 'services/shared_preferences_manager.dart';
import 'theme/fixed_colors.dart';
import 'theme/theme_provider.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();  
  int _themeIndex = SharedPreferencesManager.getInt('themeIndex') ?? 0;
  int _streamingmode = SharedPreferencesManager.getInt('streamingMode') ?? 0;
  Color _themeColor = Colors.blue;
  Color _fontColor = Colors.blue;
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _fontColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return Stack(children: [
      IntroductionScreen(
        // 2. Pass that key to the `IntroductionScreen` `key` param
        key: _introKey,
        pages: [
          PageViewModel(
              title: '欢迎使用',
              bodyWidget: Column(
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
                  const Text(
                    '一款跨全平台的高性能',
                    style: TextStyle(fontSize: 43.0),
                  ),
                  const SizedBox(width: 20.0, height: 30.0),
                  SizedBox(
                    width: 250.0,
                    height: 100.0,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: _fontColor,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          RotateAnimatedText('办公'),
                          RotateAnimatedText('协作'),
                          RotateAnimatedText('娱乐'),
                        ],
                        onTap: () {
                          //print("Tap Event");
                        },
                        repeatForever: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20.0, height: 30.0),
                  const Text(
                    '串流工具',
                    style: TextStyle(fontSize: 43.0),
                  ),
                  const SizedBox(width: 20.0, height: 20.0),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.windows,
                        size: 43.0,
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.apple, // This is the icon for macOS and iOS
                        size: 43.0,
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.android,
                        size: 43.0,
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        FontAwesomeIcons.linux,
                        size: 43.0,
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.web, // Web icon
                        size: 43.0,
                      ),
                    ],
                  ),
                ],
              )),
          PageViewModel(
            title: '设置您的主题 & 模式',
            bodyWidget: Column(children: [
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
                      if (_streamingmode == 0) {
                        _themeColor = Colors.blue;
                      } else {
                        _themeColor = const Color.fromARGB(255, 239, 84, 11);
                      }
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
              if (_streamingmode == 0) // Display details if "办公" is selected
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(width: 20.0, height: 40.0),
                      Text('* 4K 30帧', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 低至 100毫秒延迟', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 高清晰度', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 低带宽消耗', style: TextStyle(fontSize: 22.0)),
                    ],
                  ),
                ),
              if (_streamingmode == 1) // Display details if "办公" is selected
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(width: 20.0, height: 40.0),
                      Text('* 最高 4K 60帧', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 低至 40 毫秒延迟', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 高清晰度', style: TextStyle(fontSize: 22.0)),
                      SizedBox(width: 20.0, height: 20.0),
                      Text('* 硬件加速（需显卡支持）', style: TextStyle(fontSize: 22.0)),
                    ],
                  ),
                ),
            ]),
          )
        ],
        back: const Text("上一步"),
        next: const Text("下一步"),
        done: const Text("完成"),
        onDone: () {
          SharedPreferencesManager.setBool('appintroFinished', true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPage()),
          );
        },
        showBackButton: true,
        showNextButton: true,
        showDoneButton: true,
      ),
      Positioned(
        top: 0,
        left: 0,
        child: CustomPaint(
          size: const Size(200, 200), // Size of the triangle
          painter: TrianglePainter(
              color: _themeColor, direction: TriangleDirection.topLeft),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: CustomPaint(
          size: const Size(50, 50), // Size of the triangle
          painter: TrianglePainter(
              color: _themeColor, direction: TriangleDirection.bottomRight),
        ),
      ),
    ]);
  }
}

enum TriangleDirection { topLeft, topRight, bottomLeft, bottomRight }

class TrianglePainter extends CustomPainter {
  final Color color;
  final TriangleDirection direction;

  TrianglePainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    switch (direction) {
      case TriangleDirection.topLeft:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(0, size.height);
        break;
      case TriangleDirection.topRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, 0);
        break;
      case TriangleDirection.bottomLeft:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(0, 0);
        break;
      case TriangleDirection.bottomRight:
        path.moveTo(size.width, size.height);
        path.lineTo(size.width, 0);
        path.lineTo(0, size.height);
        break;
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
