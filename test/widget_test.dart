// eCAT 基础冒烟测试：App 能正常构建并显示首页问候。
//
// 注意：CatStore.load() 依赖 SharedPreferences 平台通道，
// 测试中用 SharedPreferences.setMockInitialValues 提供内存实现。
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecat/store/cat_store.dart';
import 'package:ecat/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App 启动冒烟测试：空数据时显示欢迎空态', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = CatStore();
    await store.load();

    await tester.pumpWidget(EcatApp(store: store));
    await tester.pumpAndSettle();

    // 空数据时首页应显示「还没有猫咪档案」空态
    expect(find.text('还没有猫咪档案'), findsOneWidget);
  });
}
