// eCAT · 记录簿页 —— 当前猫咪的全部历史记录时间线
// 合并喂食 / 体重 / 健康三类记录，按时间倒序展示，支持类型筛选与长按删除。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cat.dart';
import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 筛选类型：0 全部 / 1 喂食 / 2 体重 / 3 健康
class _Filter {
  static const int all = 0;
  static const int feed = 1;
  static const int weight = 2;
  static const int health = 3;
}

/// 时间线条目：统一包装三类记录，便于合并排序与展示
class _Entry {
  final DateTime time;
  final FeedLog? feed;
  final WeightLog? weight;
  final HealthLog? health;

  const _Entry.feed(FeedLog this.feed, this.time)
      : weight = null,
        health = null;
  const _Entry.weight(WeightLog this.weight, this.time)
      : feed = null,
        health = null;
  const _Entry.health(HealthLog this.health, this.time)
      : feed = null,
        weight = null;

  String get id => feed?.id ?? weight?.id ?? health!.id;
}

/// 记录簿页：时间线式记录总览
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _filter = _Filter.all;

  // 喂食类型 → emoji 映射
  static const Map<String, String> _feedEmoji = {
    '干粮': '🍖',
    '湿粮罐头': '🥫',
    '冻干': '🐟',
    '零食': '🍪',
    '饮水': '💧',
  };

  /// 合并三类记录并按时间倒序，再按筛选类型过滤
  List<_Entry> _buildEntries(CatStore store) {
    final entries = <_Entry>[
      for (final f in store.feeds) _Entry.feed(f, f.time),
      for (final w in store.weights) _Entry.weight(w, w.date),
      for (final h in store.healths) _Entry.health(h, h.date),
    ];
    entries.sort((a, b) => b.time.compareTo(a.time));
    switch (_filter) {
      case _Filter.feed:
        return entries.where((e) => e.feed != null).toList();
      case _Filter.weight:
        return entries.where((e) => e.weight != null).toList();
      case _Filter.health:
        return entries.where((e) => e.health != null).toList();
      default:
        return entries;
    }
  }

  /// 时间文案：今天显示 HH:mm，否则 MM/dd HH:mm
  String _timeText(DateTime t) {
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    return isToday
        ? DateFormat('HH:mm').format(t)
        : DateFormat('MM/dd HH:mm').format(t);
  }

  /// 长按删除确认弹窗
  Future<void> _confirmDelete(_Entry entry) async {
    final store = context.read<CatStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '删除这条记录？',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '删除后就找不回来啦 🥺',
          style: const TextStyle(color: AppColors.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // 按记录类型调用对应删除方法
    if (entry.feed != null) {
      await store.removeFeed(entry.feed!.id);
    } else if (entry.weight != null) {
      await store.removeWeight(entry.weight!.id);
    } else if (entry.health != null) {
      await store.removeHealth(entry.health!.id);
    }
    if (mounted) showCuteToast(context, '记录已删除 🗑️');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final cat = store.currentCat;

    // 无猫咪档案：引导先去「猫咪」页添加
    if (cat == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: EmptyState(
            emoji: '🐱',
            title: '还没有猫咪档案',
            subtitle: '先去「猫咪」页添加小主子吧',
          ),
        ),
      );
    }

    final entries = _buildEntries(store);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- 顶部标题栏 ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '记录簿 📖',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cat.name} 的小日子',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- 筛选胶囊行 ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ChipChoice<int>(
                values: const [_Filter.all, _Filter.feed, _Filter.weight, _Filter.health],
                selected: _filter,
                onSelect: (v) => setState(() => _filter = v),
                labels: const {
                  _Filter.all: '全部',
                  _Filter.feed: '喂食',
                  _Filter.weight: '体重',
                  _Filter.health: '健康',
                },
                emojis: const {
                  _Filter.all: '🐾',
                  _Filter.feed: '🍚',
                  _Filter.weight: '⚖️',
                  _Filter.health: '💊',
                },
              ),
            ),
            const SizedBox(height: 12),

            // ---------- 合并时间线列表 ----------
            Expanded(
              child: entries.isEmpty
                  ? const EmptyState(
                      emoji: '📖',
                      title: '还没有记录',
                      subtitle: '点右下角「记一笔」开始记录吧',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return GestureDetector(
                          onLongPress: () => _confirmDelete(e),
                          child: CuteCard(
                            child: _buildRow(e),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单条记录行内容（按类型分发）
  Widget _buildRow(_Entry e) {
    if (e.feed != null) return _feedRow(e.feed!);
    if (e.weight != null) return _weightRow(e.weight!);
    return _healthRow(e.health!);
  }

  /// 喂食记录行
  Widget _feedRow(FeedLog f) {
    final unit = f.type == '饮水' ? 'ml' : 'g';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_feedEmoji[f.type] ?? '🍚', style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '吃了${f.type} ${_fmtAmount(f.amount)}$unit',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeText(f.time),
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              if (f.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  f.note,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 体重记录行
  Widget _weightRow(WeightLog w) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚖️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '体重 ${w.weight} kg',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM/dd HH:mm').format(w.date),
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 健康记录行
  Widget _healthRow(HealthLog h) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(HealthLog.categoryEmoji[h.category] ?? '💊',
            style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${HealthLog.categories[h.category] ?? '健康'} · ${h.title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  if (h.nextDue != null) ...[
                    const SizedBox(width: 8),
                    // 下次到期小胶囊
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '下次：${DateFormat('MM/dd').format(h.nextDue!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.butterDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM/dd HH:mm').format(h.date),
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              if (h.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  h.note,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 数量格式化：整数不带小数点，小数保留原样
  String _fmtAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.round().toString();
    }
    return amount.toString();
  }
}
