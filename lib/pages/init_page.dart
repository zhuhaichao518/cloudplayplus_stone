import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloudplayplus/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../services/app_init_service.dart';
import '../theme/fixed_colors.dart';

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: AppInitService.appInitState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              color: Colors.transparent, // 设置背景颜色
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      child: AnimatedTextKit(
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
                    ),
                    const SizedBox(height: 20),
                    const SpinKitCircle(size: 51.0, color: Colors.white),
                  ],
                ),
              ));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          int appStatus = snapshot.data ?? 0;
          if (appStatus == 0) {
            return const IntroScreen();
          } else if (appStatus == 1) {
            return const Text('login');
          } else {
            return const Text('devices');
          }
        }
      },
    );
  }
}
