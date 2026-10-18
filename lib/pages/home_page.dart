// eCAT 首页「今天」页面
// 模块：问候区 / 猫咪切换行 / 当前猫咪档案卡 / 今日喂食进度 / 健康提醒 / 无猫咪空态
// 数据全部来自 CatStore（按当前猫咪隔离）；快捷记录复用 openQuickRecord。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart' show CatSwitcher;
import '../models/cat.dart';
import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'quick_record.dart';

// 转出快捷记录入口：main.dart 通过本文件即可使用 openQuickRecord
export 'quick_record.dart' show openQuickRecord;

/// 每日建议喂食量默认值（g），仅用于无猫咪时的兜底展示
const double kDailyFoodGoal = Cat.defaultDailyFoodGoal;

/// 首页「今天」：一眼看清今天喂了多少、体重如何、有什么提醒
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final now = DateTime.now();

    // 无猫咪档案：整页可爱空态
    if (store.isEmpty) {
      return const SafeArea(child: _NoCatEmpty());
    }

    final cat = store.currentCat!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _Greeting(now: now),
          const SizedBox(height: 12),
          // 猫咪切换行：仅多猫时显示
          if (store.cats.length > 1) ...[
            const CatSwitcher(),
            const SizedBox(height: 12),
          ],
          _CatProfileCard(cat: cat, latestWeight: store.latestWeight),
          const SizedBox(height: 20),
          _TodayFeedSection(
            feeds: store.feedsOn(now),
            grams: store.todayFoodGrams(now),
          ),
          const SizedBox(height: 20),
          _HealthRemindSection(
            reminders: store.upcomingReminders.take(3).toList(),
            now: now,
          ),
        ],
      ),
    );
  }
}

/// 问候区：按时段问候 + 中文日期（奶油白背景）
class _Greeting extends StatelessWidget {
  final DateTime now;
  const _Greeting({required this.now});

  String get _hello {
    final h = now.hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cream,
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_hello，铲屎官 🐱',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('M月d日 EEEE', 'zh_CN').format(now),
            style: const TextStyle(fontSize: 13, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

/// 当前猫咪档案大卡片：头像 + 名字 + 基础信息 + 体重与目标对比
class _CatProfileCard extends StatelessWidget {
  final Cat cat;
  final WeightLog? latestWeight;
  const _CatProfileCard({required this.cat, this.latestWeight});

  @override
  Widget build(BuildContext context) {
    final isBoy = cat.gender == Cat.genderBoy;
    return CuteCard(
      child: Row(
        children: [
          CatAvatar(emoji: cat.avatar, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名字 + 绝育标记
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (cat.neutered) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pinkLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '已绝育',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.pinkDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // 品种 · 猫龄 · 性别（♀/♂ 带色）
                Text.rich(
                  TextSpan(
                    text: '${cat.breed} · ${cat.ageText()} · ',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                    ),
                    children: [
                      TextSpan(
                        text: isBoy ? '♂' : '♀',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isBoy ? AppColors.skyDeep : AppColors.pinkDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _weightRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 最新体重 + 目标体重对比行
  Widget _weightRow() {
    final w = latestWeight;
    final target = cat.targetWeight;
    return Row(
      children: [
        const Icon(
          Icons.monitor_weight_outlined,
          size: 16,
          color: AppColors.textSub,
        ),
        const SizedBox(width: 4),
        Text(
          w == null ? '还没称重' : '${w.weight.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: w == null ? AppColors.textSub : AppColors.textMain,
          ),
        ),
        // 目标对比：有体重比差值，没体重只提示目标
        if (target != null) ...[
          const SizedBox(width: 8),
          Text(
            w == null
                ? '目标 ${target.toStringAsFixed(1)}kg'
                : _targetText(w.weight, target),
            style: const TextStyle(fontSize: 12, color: AppColors.mintDeep),
          ),
        ],
      ],
    );
  }

  static String _targetText(double weight, double target) {
    final diff = target - weight;
    if (diff.abs() < 0.05) return '已达目标 🎉';
    if (diff > 0) return '距目标还差 ${diff.toStringAsFixed(1)}kg';
    return '比目标多 ${(-diff).toStringAsFixed(1)}kg';
  }
}

/// 今日喂食进度卡：总克数 + 粉色圆角进度条 + 明细列表
class _TodayFeedSection extends StatelessWidget {
  final List<FeedLog> feeds;
  final double grams;
  const _TodayFeedSection({required this.feeds, required this.grams});

  // 喂食类型 → emoji
  static const Map<String, String> _feedEmoji = {
    '干粮': '🍖', '湿粮罐头': '🥫', '冻干': '🐟', '零食': '🍪', '饮水': '💧',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '今日喂食',
          emoji: '🍚',
          trailing: GestureDetector(
            onTap: () => openQuickRecord(context, initialTab: 0),
            child: const Text(
              '＋ 记一笔',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.pinkDeep,
              ),
            ),
          ),
        ),
        CuteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总量 + 建议量
              Row(
                children: [
                  Text(
                    '今日已喂 ${_fmtG(grams)}g',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '建议 60g/日',
                    style: TextStyle(fontSize: 12, color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _progressBar(),
              const SizedBox(height: 14),
              if (feeds.isEmpty)
                _emptyHint(context)
              else
                ...feeds.map(_feedTile),
            ],
          ),
        ),
      ],
    );
  }

  /// 粉色圆角进度条（相对每日建议量）
  Widget _progressBar() {
    final p = (grams / kDailyFoodGoal).clamp(0.0, 1.0).toDouble();
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: p,
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  /// 单条喂食明细：emoji + 类型 + 份量 + 时间
  Widget _feedTile(FeedLog f) {
    final unit = f.type == '饮水' ? 'ml' : 'g';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(_feedEmoji[f.type] ?? '🍚', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              f.type,
              style: const TextStyle(fontSize: 14, color: AppColors.textMain),
            ),
          ),
          Text(
            '${_fmtG(f.amount)}$unit',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.pinkDeep,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('HH:mm').format(f.time),
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }

  /// 空态：今天还没喂饭（点击可直接记一笔）
  Widget _emptyHint(BuildContext context) {
    return GestureDetector(
      onTap: () => openQuickRecord(context, initialTab: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.pinkLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🍚', style: TextStyle(fontSize: 28)),
            SizedBox(height: 6),
            Text(
              '今天还没喂饭哦',
              style: TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }

  /// 克数格式化：整数不带小数，其余保留 1 位
  static String _fmtG(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// 健康提醒区：最近 3 条 nextDue 提醒 + 倒计时
class _HealthRemindSection extends StatelessWidget {
  final List<HealthLog> reminders;
  final DateTime now;
  const _HealthRemindSection({required this.reminders, required this.now});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '健康提醒', emoji: '💊'),
        if (reminders.isEmpty) _emptyBox() else ...reminders.map(_remindCard),
      ],
    );
  }

  /// 单条提醒卡：emoji + 标题 + 分类 + 倒计时
  Widget _remindCard(HealthLog h) {
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            HealthLog.categoryEmoji[h.category] ?? '💊',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  HealthLog.categories[h.category] ?? '健康',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          _countdownChip(h),
        ],
      ),
    );
  }

  /// 倒计时胶囊：已过期红色 / 今天奶黄 / 未来薄荷绿
  Widget _countdownChip(HealthLog h) {
    final due = h.nextDue!;
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    final String text;
    final Color bg;
    final Color fg;
    if (diff < 0) {
      text = '已过期${-diff}天';
      bg = AppColors.danger.withValues(alpha: 0.12);
      fg = AppColors.danger;
    } else if (diff == 0) {
      text = '就是今天！';
      bg = AppColors.butter;
      fg = AppColors.butterDeep;
    } else {
      text = '还有$diff天';
      bg = AppColors.mint;
      fg = AppColors.mintDeep;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  /// 空态：暂无健康提醒
  Widget _emptyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💊', style: TextStyle(fontSize: 30)),
          SizedBox(height: 8),
          Text(
            '暂无健康提醒',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '记录疫苗、驱虫时设置下次提醒，这里会帮你倒数 🐾',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

/// 无猫咪档案时的整页空态
class _NoCatEmpty extends StatelessWidget {
  const _NoCatEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyState(
            emoji: '🐱',
            title: '还没有猫咪档案',
            subtitle: '去「猫咪」页添加你的小主子吧',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: PawButton(
              label: '去添加小主子 🐾',
              icon: Icons.pets_rounded,
              onTap: () => showCuteToast(
                context,
                '点击底部「猫咪」标签，添加你的小主子吧 🐱',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
