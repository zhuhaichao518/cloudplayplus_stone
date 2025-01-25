import 'package:cloudplayplus/controller/screen_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class OnScreenVirtualMouse extends StatefulWidget {
    final Offset initialPosition;
  final Function(Offset)? onPositionChanged;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onLeftReleased;
  final VoidCallback? onRightPressed;
  final VoidCallback? onRightReleased;

  const OnScreenVirtualMouse({super.key, 
    this.initialPosition = const Offset(100, 100),
    this.onPositionChanged,
    this.onLeftPressed,
    this.onLeftReleased,
    this.onRightPressed,
    this.onRightReleased,
  });

  @override
  State<OnScreenVirtualMouse> createState() => _VirtualMouseState();
}

class _VirtualMouseState extends State<OnScreenVirtualMouse> {
  Offset position = Offset.zero;
  bool _leftPressed = false;
  bool _rightPressed = false;
  double _angle = 0;
  double _width = 100, _height = 100;
  void _rotate() {
    setState(() {
      _angle += pi / 2;
    });
  }

  Offset _transformDelta(Offset delta, double angle) {
    final steps = ((angle / (pi / 2)).round()) % 4;
    switch (steps) {
      case 1:
        return Offset(-delta.dy, delta.dx);
      case 2:
        return Offset(-delta.dx, -delta.dy);
      case 3:
        return Offset(delta.dy, -delta.dx);
      default:
        return delta;
    }
  }

  void _updatePosition(Offset newPosition) {
    setState(() => position = newPosition);
    final steps = ((_angle / (pi / 2)).round()) % 4;
    double deltax = 0, deltay = 0;
    switch (steps) {
      case 1:
        deltax = _width;
        break;
      case 2:
        deltax = _width;
        deltay = _height;
        break;
      case 3:
        deltay = _height;
        break;
      default:
        break;
    }
    widget.onPositionChanged
        ?.call(Offset(newPosition.dx + deltax, newPosition.dy + deltay));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVirtualMouse, // 监听键盘显示状态
      builder: (context, showMouse, child) {
        if (!showMouse) return const SizedBox(); // 如果不显示键盘，返回空控件
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.rotate(
            angle: _angle,
            child: GestureDetector(
              onPanUpdate: (details) {
                final transformedDelta = _transformDelta(details.delta, _angle);
                _updatePosition(position + transformedDelta);
              },
              onPanEnd: (_) {
                if (_leftPressed) {
                  setState(() {
                    _leftPressed = false;
                    widget.onLeftReleased?.call();
                  });
                }
                if (_rightPressed) {
                  setState(() {
                    _rightPressed = false;
                    widget.onRightReleased?.call();
                  });
                }
              },
              child: Container(
                width: _width,
                height: _height,
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: CustomPaint(
                        size: const Size(40, 40),
                        painter: CursorTrianglePainter(),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      top: 50,
                      child: GestureDetector(
                        onTapDown: (_) {
                          setState(() => _leftPressed = true);
                          widget.onLeftPressed?.call();
                        },
                        onTapUp: (_) {
                          setState(() => _leftPressed = false);
                          widget.onLeftReleased?.call();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _leftPressed ? Colors.blue[800] : Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 50,
                      top: 5,
                      child: GestureDetector(
                        onTapDown: (_) {
                          setState(() => _rightPressed = true);
                          widget.onRightPressed?.call();
                        },
                        onTapUp: (_) {
                          setState(() => _rightPressed = false);
                          widget.onRightReleased?.call();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _rightPressed ? Colors.red[800] : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.rotate_right),
                        onPressed: _rotate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class CursorTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 3, size.height);
    path.lineTo(size.width, size.height / 3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}