import 'package:flutter_test/flutter_test.dart';
import 'package:cloudplayplus/controller/smooth_mouse_controller.dart';
import 'package:cloudplayplus/utils/widgets/on_screen_remote_mouse.dart';

void main() {
  group('SmoothMouseController Tests', () {
    late OnScreenRemoteMouseController mockMouseController;
    late SmoothMouseController smoothController;

    setUp(() {
      mockMouseController = OnScreenRemoteMouseController();
      smoothController = SmoothMouseController(mockMouseController);
    });

    tearDown(() {
      smoothController.dispose();
    });

    test('should handle direction key down correctly', () {
      // 测试按下右方向键
      smoothController.onDirectionKeyDown(1022); // Right
      
      // 等待一小段时间让定时器执行
      Future.delayed(const Duration(milliseconds: 50), () {
        // 验证鼠标控制器被调用
        expect(mockMouseController.deltax, greaterThan(0));
      });
    });

    test('should handle direction key up correctly', () {
      // 按下右方向键
      smoothController.onDirectionKeyDown(1022);
      
      // 等待一小段时间让速度建立
      Future.delayed(const Duration(milliseconds: 50), () {
        // 释放右方向键，速度应该立即重置为0
        smoothController.onDirectionKeyUp(1022);
        
        // 速度应该立即变为0
        expect(mockMouseController.deltax, 0);
      });
    });

    test('should handle multiple direction keys', () {
      // 同时按下右和下方向键
      smoothController.onDirectionKeyDown(1022); // Right
      smoothController.onDirectionKeyDown(1020); // Down
      
      Future.delayed(const Duration(milliseconds: 50), () {
        expect(mockMouseController.deltax, greaterThan(0));
        expect(mockMouseController.deltay, greaterThan(0));
      });
    });

    test('should reset correctly', () {
      // 按下方向键
      smoothController.onDirectionKeyDown(1022);
      
      // 重置
      smoothController.reset();
      
      // 验证状态被重置
      expect(mockMouseController.deltax, 0);
      expect(mockMouseController.deltay, 0);
    });

    test('should immediately reset speed on key up', () {
      // 按下右方向键
      smoothController.onDirectionKeyDown(1022);
      
      // 等待一小段时间建立速度
      Future.delayed(const Duration(milliseconds: 30), () {
        // 释放按键，速度应该立即重置
        smoothController.onDirectionKeyUp(1022);
        
        // 验证速度立即变为0
        expect(mockMouseController.deltax, 0);
      });
    });
  });
} 