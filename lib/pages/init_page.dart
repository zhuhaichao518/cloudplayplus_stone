import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloudplayplus/intro_screen.dart';
import 'package:cloudplayplus/pages/login_screen.dart';
import 'package:cloudplayplus/pages/main_page.dart';
import 'package:cloudplayplus/pages/reconnect_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_init_service.dart';
import '../services/app_info_service.dart';
import '../services/login_service.dart';
import '../services/shared_preferences_manager.dart';
import '../theme/fixed_colors.dart';

/// 更新提示页面
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  static const String _websiteUrl = 'https://www.cloudplayplus.com';

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse(_websiteUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentVersion = ApplicationInfo.currentVersion;
    final String latestVersion = UpdateInfo.latestVersion ?? '未知';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 更新图标
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.system_update,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // 标题
              const Text(
                '发现新版本',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              // 版本信息
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVersionChip('当前', currentVersion, const Color(0xFF718096)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, color: Color(0xFFA0AEC0)),
                    ),
                    _buildVersionChip('最新', latestVersion, const Color(0xFF48BB78)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 描述文字
              const Text(
                '建议更新到最新版本以获得更好的体验和新功能',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // 按钮区域
              Column(
                children: [
                  // 前往下载按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchWebsite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '前往官网下载',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 跳过此版本按钮
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        // 保存跳过的版本
                        if (UpdateInfo.latestVersion != null) {
                          await SharedPreferencesManager.setString(
                            'skipped_version',
                            UpdateInfo.latestVersion!,
                          );
                        }
                        // 重新初始化应用状态
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const _ContinueInitPage(),
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF718096),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '跳过此版本',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionChip(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 跳过更新后继续初始化的页面
class _ContinueInitPage extends StatelessWidget {
  const _ContinueInitPage();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitState>(
      future: _getContinueState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.transparent,
            child: const Center(
              child: SpinKitCircle(size: 51.0, color: Colors.white),
            ),
          );
        } else if (snapshot.hasError) {
          return const ReconnectScreen();
        } else {
          AppInitState appStatus = snapshot.data ?? AppInitState.firstTime;
          if (appStatus == AppInitState.firstTime) {
            return const IntroScreen();
          } else if (appStatus == AppInitState.needLogin) {
            return const LoginScreen();
          } else if (appStatus == AppInitState.loggedin) {
            return const MainScreen();
          } else {
            return const ReconnectScreen();
          }
        }
      },
    );
  }

  /// 获取跳过更新后的应用状态（排除更新检查）
  Future<AppInitState> _getContinueState() async {
    bool appintroFinished =
        SharedPreferencesManager.getBool('appintroFinished') ?? false;
    ApplicationInfo.deviceNameOverride =
        SharedPreferencesManager.getString('deviceNameOverride');
    if (!appintroFinished) return AppInitState.firstTime;

    bool wasLoggedin =
        SharedPreferencesManager.getBool('is_logged_in') ?? false;
    if (wasLoggedin) {
      bool isLoggedin = await LoginService.tryLoginWithCachedToken();
      if (!isLoggedin) {
        return AppInitState.needReconnect;
      }
      return AppInitState.loggedin;
    }
    return AppInitState.needLogin;
  }
}

/// updateScreen 函数 - 返回更新提示页面
Widget updateScreen() {
  return const UpdateScreen();
}

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitState>(
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
          // When failed host lookup, exception may occur. Reconnect for this case
          return const ReconnectScreen();
          //return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          AppInitState appStatus = snapshot.data ?? AppInitState.firstTime;
          if (appStatus == AppInitState.firstTime) {
            return const IntroScreen();
          } else if (appStatus == AppInitState.needLogin) {
            return const LoginScreen();
          } else if (appStatus == AppInitState.loggedin) {
            return const MainScreen();
          } else if (appStatus == AppInitState.haveUpdate){
            return updateScreen();
          } else {
            // AppInitState.needReconnect
            return const ReconnectScreen();
          }
        }
      },
    );
  }
}
