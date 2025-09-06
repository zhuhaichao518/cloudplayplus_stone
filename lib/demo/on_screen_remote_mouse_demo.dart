import 'package:flutter/material.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_remote_mouse.dart';
import 'dart:typed_data';
import 'package:hardware_simulator/hardware_simulator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnScreenRemoteMouse Demo',
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
  final Map<int, Uint8List> _cachedCursors = {};
  late final OnScreenRemoteMouseController _mouseController;

  @override
  void initState() {
    super.initState();
    _mouseController = OnScreenRemoteMouseController();
    _registerCursorChanged();
  }

  @override
  void dispose() {
    _unregisterCursorChanged();
    _mouseController.dispose();
    super.dispose();
  }

  void _registerCursorChanged() {
    HardwareSimulator.addCursorImageUpdated(
      (int message, int messageInfo, Uint8List cursorImage) {
        if (message == HardwareSimulator.CURSOR_UPDATED_IMAGE) {
          _cachedCursors[messageInfo] = cursorImage;
          _mouseController.setCursorBuffer(_cachedCursors[messageInfo]);
        } else if (message == HardwareSimulator.CURSOR_UPDATED_CACHED) {
          if (_cachedCursors.containsKey(messageInfo)) {
            _mouseController.setCursorBuffer(_cachedCursors[messageInfo]);
          }
        }
      },
      1,
      false,
    );
  }

  void _unregisterCursorChanged() {
    HardwareSimulator.removeCursorImageUpdated(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OnScreenRemoteMouse Demo'),
      ),
      body: Stack(
        children: [
          // 添加一些背景元素以便观察光标移动
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('移动区域'),
              ),
            ),
          ),
          
          // 远程鼠标控件
          Positioned(
            left: 0,
            top: 0,
            child: OnScreenRemoteMouse(
              controller: _mouseController,
              onPositionChanged: (percentage) {
                print('鼠标位置百分比: x=${percentage.dx.toStringAsFixed(2)}, y=${percentage.dy.toStringAsFixed(2)}');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 相对移动控制
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('相对移动'),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "delta_right",
                onPressed: () {
                  _mouseController.moveDelta(10, 0);
                },
                child: const Icon(Icons.arrow_right),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "delta_left",
                onPressed: () {
                  _mouseController.moveDelta(-10, 0);
                },
                child: const Icon(Icons.arrow_left),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "delta_up",
                onPressed: () {
                  _mouseController.moveDelta(0, -10);
                },
                child: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "delta_down",
                onPressed: () {
                  _mouseController.moveDelta(0, 10);
                },
                child: const Icon(Icons.arrow_downward),
              ),
            ],
          ),
          
          // 绝对位置控制
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('绝对位置'),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "abs_center",
                onPressed: () {
                  _mouseController.moveAbsl(0.5, 0.5);
                },
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "abs_topleft",
                onPressed: () {
                  _mouseController.moveAbsl(0.0, 0.0);
                },
                child: const Icon(Icons.north_west),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "abs_topright",
                onPressed: () {
                  _mouseController.moveAbsl(1.0, 0.0);
                },
                child: const Icon(Icons.north_east),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "abs_bottomleft",
                onPressed: () {
                  _mouseController.moveAbsl(0.0, 1.0);
                },
                child: const Icon(Icons.south_west),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "abs_bottomright",
                onPressed: () {
                  _mouseController.moveAbsl(1.0, 1.0);
                },
                child: const Icon(Icons.south_east),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 