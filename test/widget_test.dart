// eCAT 基础冒烟测试：App 能正常构建并显示首页问候。
//
// 注意：CatStore.load() / SettingsStore.load() 依赖 SharedPreferences
// 平台通道，测试中用 SharedPreferences.setMockInitialValues 提供内存实现。
// 首次启动会进引导页，主界面测试需预置 ecat_onboarding_done = true。
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecat/store/agent_store.dart';
import 'package:ecat/store/cat_store.dart';
import 'package:ecat/store/settings_store.dart';
import 'package:ecat/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App 启动冒烟测试：空数据时显示欢迎空态', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'ecat_onboarding_done': true});
    final store = CatStore();
    await store.load();
    final settings = SettingsStore();
    await settings.load();
    final agentStore = AgentStore();
    await agentStore.load();

    await tester.pumpWidget(EcatApp(store: store, settings: settings, agentStore: agentStore));
    await tester.pumpAndSettle();

    // 空数据时首页应显示「还没有猫咪档案」空态
    expect(find.text('还没有猫咪档案'), findsOneWidget);
  });

  testWidgets('首次启动显示引导页，跳过后进入主界面', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = CatStore();
    await store.load();
    final settings = SettingsStore();
    await settings.load();
    final agentStore = AgentStore();
    await agentStore.load();

    await tester.pumpWidget(EcatApp(store: store, settings: settings, agentStore: agentStore));
    await tester.pumpAndSettle();

    // 首次启动应显示引导页
    expect(find.text('欢迎来到喵喵管家'), findsOneWidget);

    // 点「跳过」→ 写入引导标记并进入主界面
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    expect(find.text('还没有猫咪档案'), findsOneWidget);
    expect(settings.onboardingDone, isTrue);
  });

  testWidgets('引导页「下一步」翻页后出现最后一页文案', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = CatStore();
    await store.load();
    final settings = SettingsStore();
    await settings.load();
    final agentStore = AgentStore();
    await agentStore.load();

    await tester.pumpWidget(EcatApp(store: store, settings: settings, agentStore: agentStore));
    await tester.pumpAndSettle();

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('一猫一档，互不干扰'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('疫苗驱虫，不再错过'), findsOneWidget);
    expect(find.text('开始使用 🐾'), findsOneWidget);
  });
}
