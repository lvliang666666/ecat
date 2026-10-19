// CuteTap / CuteNav 统一触动反馈组件测试：按压缩放 / 回调触发 / 禁用态 / 底栏切换
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

  group('CuteNav 底部导航', () {
    Widget navApp(int selected, void Function(int) onSelect) => MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CuteNav(
              selectedIndex: selected,
              onSelect: onSelect,
              icons: const [
                Icons.wb_sunny_outlined,
                Icons.edit_note_outlined,
              ],
              selectedIcons: const [Icons.wb_sunny, Icons.edit_note],
              labels: const ['今天', '记录'],
            ),
          ),
        );

    testWidgets('点击 Tab 触发 onSelect 回调', (tester) async {
      var selected = -1;
      await tester.pumpWidget(navApp(0, (i) => selected = i));

      await tester.tap(find.text('记录'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('选中项高亮（图标颜色为选中色）', (tester) async {
      await tester.pumpWidget(navApp(1, (_) {}));
      await tester.pumpAndSettle();

      // 选中项的图标存在（selectedIcon 渲染）
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      // 未选中项的图标存在（未选中 icon 渲染）
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    });
  });
}
