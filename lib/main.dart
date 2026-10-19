// eCAT · 喵喵管家 —— 养猫女生的可爱记录助手
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'services/reminder_service.dart';
import 'store/cat_store.dart';
import 'store/settings_store.dart';
import 'store/photo_store.dart';
import 'widgets/common.dart' show photoResolver;
import 'pages/home_page.dart';
import 'pages/record_page.dart';
import 'pages/cat_page.dart';
import 'pages/knowledge_page.dart';
import 'pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  photoResolver = PhotoStore.resolve; // 照片头像路径解析
  CatStore.photoDeleter = PhotoStore.delete; // 删除猫咪时级联清理照片
  final store = CatStore();
  await store.load();
  final settings = SettingsStore();
  await settings.load();

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

  runApp(EcatApp(store: store, settings: settings));
}

class EcatApp extends StatelessWidget {
  final CatStore store;
  final SettingsStore settings;
  const EcatApp({super.key, required this.store, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: settings),
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
      const CatPage(),
      KnowledgePage(),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => openQuickRecord(context),
              icon: Icon(Icons.edit_rounded),
              label: Text('记一笔'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.pinkLight,
        height: 68,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: AppColors.pinkDeep),
            label: '今天',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note, color: AppColors.pinkDeep),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets, color: AppColors.pinkDeep),
            label: '猫咪',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.pinkDeep),
            label: '知识',
          ),
        ],
      ),
    );
  }
}
