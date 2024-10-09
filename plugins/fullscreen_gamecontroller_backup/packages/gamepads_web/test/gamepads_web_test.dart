import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads_web/gamepads_web.dart';
import 'package:gamepads_web/gamepads_web_platform_interface.dart';
import 'package:gamepads_web/gamepads_web_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGamepadsWebPlatform
    with MockPlatformInterfaceMixin
    implements GamepadsWebPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GamepadsWebPlatform initialPlatform = GamepadsWebPlatform.instance;

  test('$MethodChannelGamepadsWeb is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGamepadsWeb>());
  });

  test('getPlatformVersion', () async {
    GamepadsWeb gamepadsWebPlugin = GamepadsWeb();
    MockGamepadsWebPlatform fakePlatform = MockGamepadsWebPlatform();
    GamepadsWebPlatform.instance = fakePlatform;

    expect(await gamepadsWebPlugin.getPlatformVersion(), '42');
  });
}
