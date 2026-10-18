// eCAT · 统计面板页：周/月喂食统计 + 体重周报
// 数据全部来自 CatStore 统计查询（当前猫咪隔离视图）；由猫咪页入口进入。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 统计面板页
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  /// 统计范围：7 天 / 30 天
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // 顶部返回 + 标题
            Row(
              children: [
                _roundIconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      '统计面板 📊',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),

            // 范围切换
            Center(
              child: ChipChoice<int>(
                values: const [7, 30],
                selected: _range,
                onSelect: (v) => setState(() => _range = v),
                labels: const {7: '最近 7 天', 30: '最近 30 天'},
                emojis: const {7: '📅', 30: '🗓️'},
              ),
            ),
            const SizedBox(height: 20),

            // ---- 统计对象：当前猫咪标识条 ----
            _catBanner(store),
            const SizedBox(height: 20),

            // ---- 体重周报 ----
            _weightReportCard(store),
            const SizedBox(height: 20),

            // ---- 喂食统计 ----
            _feedStatsCard(store, now),
            const SizedBox(height: 20),

            // ---- 每日喂食柱状图 ----
            _feedBarChartCard(store, now),
          ],
        ),
      ),
    );
  }

  /// 统计对象标识条：明确当前统计的是哪只猫（多猫切换在首页/猫咪页）
  Widget _catBanner(CatStore store) {
    final cat = store.currentCat;
    final multi = store.cats.length > 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pinkLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CatAvatar(emoji: cat?.avatar ?? '🐱', size: 36, photoPath: cat?.photoPath),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cat == null
                  ? '还没有猫咪档案，以下为空数据'
                  : '以下是「${cat.name}」的统计数据',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (multi)
            const Text(
              '切换猫咪请回首页 🐾',
              style: TextStyle(fontSize: 11, color: AppColors.textSub),
            ),
        ],
      ),
    );
  }

  /// 体重周报卡：「这周胖了 0.2kg 🎉」
  Widget _weightReportCard(CatStore store) {
    final report = store.weeklyWeightReport();
    final cat = store.currentCat;

    String title;
    String subtitle;
    String emoji;
    Color accent;

    if (cat == null) {
      title = '还没有猫咪档案';
      subtitle = '添加猫咪并记录体重后，这里会生成周报';
      emoji = '🐱';
      accent = AppColors.textSub;
    } else if (report == null) {
      title = '本周还没有体重记录';
      subtitle = '记一次体重，周报马上安排 ⚖️';
      emoji = '📈';
      accent = AppColors.textSub;
    } else {
      final (latest, diff) = report;
      if (diff == null) {
        title = '本周 ${latest.weight.toStringAsFixed(2)} kg';
        subtitle = '上周没有记录，下周就能对比啦';
        emoji = '⚖️';
        accent = AppColors.textMain;
      } else {
        final abs = diff.abs();
        if (abs < 0.01) {
          title = '本周体重稳稳的 ${latest.weight.toStringAsFixed(2)} kg';
          subtitle = '和上周几乎一样，保持得不错 👍';
          emoji = '😊';
          accent = AppColors.mintDeep;
        } else if (diff > 0) {
          title = '这周胖了 ${abs.toStringAsFixed(2)} kg 🎉';
          subtitle = '现在 ${latest.weight.toStringAsFixed(2)} kg，吃得香睡得好';
          emoji = '🍰';
          accent = AppColors.butterDeep;
        } else {
          title = '这周瘦了 ${abs.toStringAsFixed(2)} kg';
          subtitle = '现在 ${latest.weight.toStringAsFixed(2)} kg，注意观察食欲哦';
          emoji = '🍃';
          accent = AppColors.mintDeep;
        }
      }
    }

    return CuteCard(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSub, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 喂食统计卡：总克数 + 日均 + 记录次数
  Widget _feedStatsCard(CatStore store, DateTime now) {
    final total = store.foodGramsInDays(_range, now);
    final byDay = store.foodGramsByDay(_range, now);
    final activeDays = byDay.length;
    final dailyAvg = activeDays == 0 ? 0.0 : total / activeDays;
    final catName = store.currentCat?.name;

    String fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍚', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                catName == null ? '喂食统计' : '$catName的喂食统计',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('总喂食', '${fmt(total)}g'),
              _stat('有记录天数', '$activeDays 天'),
              _stat('有记录日均', '${fmt(dailyAvg)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.pinkDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
      ],
    );
  }

  /// 每日喂食柱状图（最近 N 天，饮水除外）
  Widget _feedBarChartCard(CatStore store, DateTime now) {
    final byDay = store.foodGramsByDay(_range, now);
    final days = List.generate(_range, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: _range - 1 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return (date: d, grams: byDay[key] ?? 0.0);
    });
    final maxG = days.map((d) => d.grams).reduce((a, b) => a > b ? a : b);
    final goal = store.currentCat?.dailyFoodGoal ?? 60;
    final catName = store.currentCat?.name;

    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                catName == null ? '每日喂食量' : '$catName的每日喂食量',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              Text(
                '目标线 ${goal.toStringAsFixed(0)}g',
                style: const TextStyle(fontSize: 11, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: _buildBarChart(days, maxG, goal),
            ),
          ),
        ],
      ),
    );
  }

  /// fl_chart 柱状图：x = 天序号，y = 克数；虚线为每日目标
  Widget _buildBarChart(
      List<({DateTime date, double grams})> days, double maxG, double goal) {
    final maxY = (maxG > goal ? maxG : goal) * 1.25 + 10;
    // 30 天时柱太密，标签隔 5 天显示；7 天全显
    final labelStep = days.length <= 7 ? 1 : 5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => const FlLine(
            color: AppColors.pinkLight,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.pinkLight, width: 1),
            left: BorderSide(color: AppColors.pinkLight, width: 1),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: maxY / 4,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 10),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) {
                  return const SizedBox.shrink();
                }
                if (i % labelStep != 0 && i != days.length - 1) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('M/d').format(days[i].date),
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.pinkDeep,
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${DateFormat('M月d日').format(days[group.x].date)}\n${rod.toY.toStringAsFixed(0)}g',
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].grams,
                  width: days.length <= 7 ? 18 : 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: days[i].grams == 0
                      ? AppColors.pinkLight.withValues(alpha: 0.5)
                      : AppColors.pink,
                ),
              ],
            ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal,
              color: AppColors.mintDeep,
              strokeWidth: 1.2,
              dashArray: [5, 4],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textMain),
      ),
    );
  }
}
