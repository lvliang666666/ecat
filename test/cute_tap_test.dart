// CuteTap 统一触动反馈组件测试：按压缩放 / 回调触发 / 禁用态
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecat/widgets/common.dart';

void main() {
  group('CuteTap 统一触动反馈', () {
    testWidgets('点击触发 onTap 回调', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteTap(
                onTap: () => tapped = true,
                child: const Text('按钮'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('按钮'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('按下时缩小到 pressScale，松手回弹', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteTap(
                onTap: () {},
                child: const Text('按钮'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('按钮')),
      );
      await tester.pump(); // 触发 onTapDown
      await tester.pump(const Duration(milliseconds: 150)); // 缩放动画完成

      // 按下中：缩放生效（宽高 < 原始）
      final pressedSize = tester.getSize(find.byType(AnimatedScale).first);
      expect(pressedSize.width, lessThan(600)); // 屏宽 800，缩放后变小

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('onTap 与 onLongPress 都为 null 时不拦截手势（禁用态）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CuteTap(child: Text('禁用'))),
          ),
        ),
      );

      // 禁用态：点击不报错也不触发任何东西
      await tester.tap(find.text('禁用'));
      await tester.pumpAndSettle();
    });

    testWidgets('长按触发 onLongPress 回调', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteTap(
                onLongPress: () => longPressed = true,
                child: const Text('长按我'),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('长按我'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });
  });
}
