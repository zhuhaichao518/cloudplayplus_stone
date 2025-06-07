import 'package:flutter/material.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_remote_mouse.dart';
import 'dart:typed_data';

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

  // 创建一个测试用的光标buffer
  final Uint8List _buffer = Uint8List.fromList([
    9, // 光标数据类型
    0, 0, 0, 32, // 宽度 32
    0, 0, 0, 32, // 高度 32
    0, 0, 0, 16, // 热点x 16
    0, 0, 0, 16, // 热点y 16
    0, 0, 0, 0, // hash值
    // 32x32的BGRA图像数据 - 创建一个简单的箭头形状
    ...List.generate(32 * 32 * 4, (index) {
      final x = (index ~/ 4) % 32;
      final y = (index ~/ 4) ~/ 32;
      final channel = index % 4;
      
      // 创建一个简单的箭头形状
      if (channel == 3) { // Alpha通道
        if (x >= 16 && x <= 24 && y >= 8 && y <= 24) return 255; // 箭头主体
        if (x >= 8 && x <= 32 && y >= 16 && y <= 20) return 255; // 箭头头部
        return 0;
      } else if (channel == 0) { // Blue通道
        return 255;
      } else if (channel == 1) { // Green通道
        return 0;
      } else { // Red通道
        return 0;
      }
    }),
  ]);

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
              cursorBuffer: _buffer,
              deltax: _deltax,
              deltay: _deltay,
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