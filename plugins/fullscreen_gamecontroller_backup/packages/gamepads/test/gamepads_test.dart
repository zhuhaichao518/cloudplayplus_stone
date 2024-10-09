import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamepads/gamepads.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:gamepads_platform_interface/method_channel_gamepads_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  const channel = MethodChannel('haichaoz/gamepads');
  channel.setMockMethodCallHandler((MethodCall call) async {
    calls.add(call);
    return <GamepadController>[];
  });

  void clear() {
    calls.clear();
  }

  MethodCall popCall() {
    return calls.removeAt(0);
  }

  MethodCall popLastCall() {
    expect(calls, hasLength(1));
    return popCall();
  }

  final platformInterface = GamepadsPlatformInterface.instance
      as MethodChannelGamepadsPlatformInterface;

  setUp(clear);

  test('invokes listGamepads through platform interface', () async {
    expect(await Gamepads.list(), <GamepadController>[]);
    expect(popLastCall().method, 'listGamepads');
  });

  test('can listen to events through platform interface', () async {
    final listener = Gamepads.events.first;
    final millis = DateTime.now().millisecondsSinceEpoch;
    await platformInterface.platformCallHandler(
      MethodCall(
        'onGamepadEvent',
        <String, dynamic>{
          'gamepadId': '1',
          'time': millis,
          'type': 'button',
          'key': 'a',
          'value': 1.0,
        },
      ),
    );
    final event = await listener;
    expect(event.gamepadId, '1');
    expect(event.timestamp, millis);
    expect(event.type, KeyType.button);
    expect(event.key, 'a');
    expect(event.value, 1.0);
  });

  test(
    'can listen to gamepad-specific events through platform interface',
    () async {
      final listener = Gamepads.eventsByGamepad('1').first;
      final millis = DateTime.now().millisecondsSinceEpoch;
      await platformInterface.platformCallHandler(
        MethodCall(
          'onGamepadEvent',
          <String, dynamic>{
            'gamepadId': '1',
            'time': millis,
            'type': 'button',
            'key': 'a',
            'value': 1.0,
          },
        ),
      );
      final event = await listener;
      expect(event.gamepadId, '1');
      expect(event.timestamp, millis);
      expect(event.type, KeyType.button);
      expect(event.key, 'a');
      expect(event.value, 1.0);
    },
  );
}
