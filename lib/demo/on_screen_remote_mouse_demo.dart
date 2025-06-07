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
  Offset _position = const Offset(100, 100);
  double _deltax = 0;
  double _deltay = 0;
  Uint8List? _cursorBuffer;
  final Map<int, Uint8List> _cachedCursors = {};

  @override
  void initState() {
    super.initState();
    _registerCursorChanged();
  }

  @override
  void dispose() {
    _unregisterCursorChanged();
    super.dispose();
  }

  void _registerCursorChanged() {
    HardwareSimulator.addCursorImageUpdated(
      (int message, int messageInfo, Uint8List cursorImage) {
        if (message == HardwareSimulator.CURSOR_UPDATED_IMAGE) {
          _cachedCursors[messageInfo] = cursorImage;
          setState(() {
            _cursorBuffer = _cachedCursors[messageInfo];
          });
        } else if (message == HardwareSimulator.CURSOR_UPDATED_CACHED) {
          if (_cachedCursors.containsKey(messageInfo)) {
            setState(() {
              _cursorBuffer = _cachedCursors[messageInfo];
            });
          }
        }
      },
      1,
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
              position: _position,
              cursorBuffer: _cursorBuffer,
              deltax: _deltax,
              deltay: _deltay,
              onPositionChanged: (percentage) {
                print('鼠标位置百分比: x=${percentage.dx.toStringAsFixed(2)}, y=${percentage.dy.toStringAsFixed(2)}');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _deltax += 10;
              });
            },
            child: const Icon(Icons.arrow_right),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _deltax -= 10;
              });
            },
            child: const Icon(Icons.arrow_left),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _deltay -= 10;
              });
            },
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _deltay += 10;
              });
            },
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }
} 