// eCAT · 首次引导页：3 页 onboarding（欢迎 / 一猫一档 / 提醒与备份）
// 仅首次启动显示；完成或跳过时写入 SettingsStore.onboardingDone。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 首次引导：PageView 三页 + 圆点指示器 + 跳过 / 下一步
class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingPage({super.key, required this.onFinished});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPageData(
      emoji: '🐱',
      title: '欢迎来到喵喵管家',
      subtitle: '记录小主子的每一天：喂饭、称重、健康，\n都交给这只粉色小猫爪吧 🐾',
    ),
    _OnboardPageData(
      emoji: '🏠',
      title: '一猫一档，互不干扰',
      subtitle: '每只猫有独立档案和记录，多猫家庭\n切换查看，喂食目标也各自单独设置',
    ),
    _OnboardPageData(
      emoji: '⏰',
      title: '疫苗驱虫，不再错过',
      subtitle: '记录健康事项时设个下次提醒，到期\n会通知你；数据可随时导出备份',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsStore>().completeOnboarding();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    '跳过',
                    style: TextStyle(color: AppColors.textSub, fontSize: 14),
                  ),
                ),
              ),
            ),
            // 页面内容
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final d = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.pinkLight.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(d.emoji,
                              style: const TextStyle(fontSize: 64)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          d.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          d.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 圆点指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.pink
                          : AppColors.pinkLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            // 下一步 / 开始使用
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: PawButton(
                label: isLast ? '开始使用 🐾' : '下一步',
                icon: isLast ? Icons.pets_rounded : Icons.arrow_forward_rounded,
                onTap: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单页文案数据
class _OnboardPageData {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardPageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
