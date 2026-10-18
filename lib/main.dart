// eCAT · 喵喵管家 —— 养猫女生的可爱记录助手
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'store/cat_store.dart';
import 'store/photo_store.dart';
import 'widgets/common.dart' show photoResolver;
import 'pages/home_page.dart';
import 'pages/record_page.dart';
import 'pages/cat_page.dart';
import 'pages/knowledge_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  photoResolver = PhotoStore.resolve; // 照片头像路径解析
  CatStore.photoDeleter = PhotoStore.delete; // 删除猫咪时级联清理照片
  final store = CatStore();
  await store.load();
  runApp(EcatApp(store: store));
}

class EcatApp extends StatelessWidget {
  final CatStore store;
  const EcatApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'eCAT 喵喵管家',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomePage(),
      ),
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
      const KnowledgePage(),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => openQuickRecord(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('记一笔'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.pinkLight,
        height: 68,
        destinations: const [
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

/// 首页顶部猫咪切换器（多猫数据隔离入口）
class CatSwitcher extends StatelessWidget {
  const CatSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    if (store.cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: store.cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = store.cats[i];
          final sel = cat.id == store.currentCat?.id;
          return GestureDetector(
            onTap: () => store.selectCat(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? AppColors.pink : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel ? AppColors.pinkDeep : AppColors.pinkLight,
                ),
              ),
              child: Row(
                children: [
                  Text(cat.avatar, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.textMain,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
