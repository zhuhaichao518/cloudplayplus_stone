import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamepads Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<GamepadEvent>? _subscription;

  List<GamepadController> _gamepads = [];
  List<GamepadEvent> _lastEvents = [];
  bool loading = false;

  Future<void> _getValue() async {
    setState(() => loading = true);
    final response = await Gamepads.list();
    setState(() {
      _gamepads = response;
      loading = false;
    });
  }

  void _clear() {
    setState(() => _lastEvents = []);
  }

  int count = 0;

  @override
  void initState() {
    super.initState();
    _subscription = Gamepads.events.listen((event) {
      setState(() {
        count++;
        print(count);
        final newEvents = [
          event,
          ..._lastEvents,
        ];
        if (newEvents.length > 3) {
          newEvents.removeRange(3, newEvents.length);
        }
        _lastEvents = newEvents;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamepads Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Last Events:'),
            ..._lastEvents.map((e) => Text(e.toString())),
            TextButton(
              onPressed: _clear,
              child: const Text('clear events'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _getValue,
              child: const Text('listGamepads()'),
            ),
            const Text('Gamepads:'),
            if (loading)
              const CircularProgressIndicator()
            else
              ..._gamepads.map((e) => Text('${e.id} - ${e.name}'))
          ],
        ),
      ),
    );
  }
}
