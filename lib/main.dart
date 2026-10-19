// eCAT · 喵喵管家 —— 养猫女生的可爱记录助手
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'services/reminder_service.dart';
import 'store/agent_store.dart';
import 'store/cat_store.dart';
import 'store/settings_store.dart';
import 'store/photo_store.dart';
import 'widgets/common.dart' show photoResolver, CuteNav, PawButton;
import 'pages/home_page.dart';
import 'pages/record_page.dart';
import 'pages/cat_page.dart';
import 'pages/knowledge_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/quick_record.dart' show openQuickRecord;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  photoResolver = PhotoStore.resolve; // 照片头像路径解析
  CatStore.photoDeleter = PhotoStore.delete; // 删除猫咪时级联清理照片
  final store = CatStore();
  await store.load();
  final settings = SettingsStore();
  await settings.load();
  final agentStore = AgentStore();
  await agentStore.load();
  CatStore.agentThreadPurger = agentStore.purgeCat; // 删除猫咪时级联清理其聊天会话

  // 本地提醒通知：初始化 + 启动补发错过的到期提醒 + 全量排定未来提醒
  await ReminderService.init();
  if (settings.notificationsEnabled) {
    await ReminderService.deliverMissed(store.cats, store.allHealths);
    await ReminderService.resync(store.cats, store.allHealths);
    // 数据变化（增删改健康记录 / 导入恢复）时重排
    store.addListener(() {
      ReminderService.resync(store.cats, store.allHealths);
    });
  }
  // 每日喂食提醒：启动排定 + 随猫咪/设置变化重排
  Future<void> syncFeedReminder() async {
    await ReminderService.resyncFeedReminder(
      enabled: settings.notificationsEnabled && settings.feedReminderEnabled,
      minutesOfDay: settings.feedReminderMinutes,
      cats: store.cats,
    );
  }
  await syncFeedReminder();
  store.addListener(syncFeedReminder);
  settings.addListener(syncFeedReminder);

  runApp(EcatApp(
    store: store,
    settings: settings,
    agentStore: agentStore,
  ));
}

class EcatApp extends StatelessWidget {
  final CatStore store;
  final SettingsStore settings;
  final AgentStore agentStore;
  const EcatApp({
    super.key,
    required this.store,
    required this.settings,
    required this.agentStore,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: agentStore),
      ],
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          // 调色板跟随主题模式：system 时按平台亮度
          final brightness =
              MediaQuery.platformBrightnessOf(context);
          AppColors.apply(settings.themeMode, brightness);
          return MaterialApp(
            title: 'eCAT 喵喵管家',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const _EntryGate(),
          );
        },
      ),
    );
  }
}

/// 入口门控：首次启动先进引导页，完成后进入主界面
class _EntryGate extends StatelessWidget {
  const _EntryGate();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    if (settings.onboardingDone) return const HomePage();
    return OnboardingPage(
      onFinished: () {}, // 完成时 completeOnboarding 已触发重建，此处无需额外动作
    );
  }
}

/// 底部导航骨架：今天 / 记录 / 猫咪 / 知识
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    if (!store.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      const TodayPage(),
      const RecordPage(),
      KnowledgePage(), // 第3位：养猫百科 + Agent 入口
      const CatPage(), // 第4位：猫咪档案（更像设置）
    ];

    return Scaffold(
      body: pages[_index],
      // 右下角悬浮「记一笔」：快捷记录弹窗（喂食/体重/健康三合一）
      // 仅「今天」「记录」两个 Tab 显示（知识/猫咪页不出现）
      floatingActionButton: _index == 0 || _index == 1
          ? Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: PawButton(
                label: '记一笔',
                icon: Icons.add_rounded,
                expanded: false,
                onTap: () => openQuickRecord(context),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // 底栏：CuteNav 每项独立按压反馈（放大 + 震动）
      // 顺序：今天 / 记录 / 知识（Agent 入口）/ 猫咪（档案设置）
      bottomNavigationBar: CuteNav(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        icons: const [
          Icons.wb_sunny_outlined,
          Icons.edit_note_outlined,
          Icons.menu_book_outlined,
          Icons.pets_outlined,
        ],
        selectedIcons: const [
          Icons.wb_sunny,
          Icons.edit_note,
          Icons.menu_book,
          Icons.pets,
        ],
        labels: const ['今天', '记录', '知识', '猫咪'],
      ),
    );
  }
}
