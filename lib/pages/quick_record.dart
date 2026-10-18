// 快捷记录入口：喂食 / 体重 / 健康 三合一弹窗
// 供首页 FAB 与记录页共用；所有写入都挂载到当前猫咪（数据隔离）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/cat.dart';
import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 打开快捷记录弹窗（自动处理无猫咪场景）
Future<void> openQuickRecord(BuildContext context, {int initialTab = 0}) async {
  final store = context.read<CatStore>();
  if (store.currentCat == null) {
    showCuteToast(context, '先去「猫咪」页添加你的小猫吧 🐱');
    return;
  }
  await showCuteSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickRecordSheet(initialTab: initialTab),
  );
}

class _QuickRecordSheet extends StatefulWidget {
  final int initialTab;
  const _QuickRecordSheet({this.initialTab = 0});

  @override
  State<_QuickRecordSheet> createState() => _QuickRecordSheetState();
}

class _QuickRecordSheetState extends State<_QuickRecordSheet> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final cat = store.currentCat!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cat.avatar, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '给「${cat.name}」记一笔',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ChipChoice<int>(
            values: const [0, 1, 2],
            selected: _tab,
            onSelect: (v) => setState(() => _tab = v),
            labels: const {0: '喂食', 1: '体重', 2: '健康'},
            emojis: const {0: '🍚', 1: '⚖️', 2: '💊'},
          ),
          const SizedBox(height: 20),
          if (_tab == 0) _FeedForm(cat: cat),
          if (_tab == 1) _WeightForm(cat: cat),
          if (_tab == 2) _HealthForm(cat: cat),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------- 喂食表单 ----------------
class _FeedForm extends StatefulWidget {
  final Cat cat;
  const _FeedForm({required this.cat});

  @override
  State<_FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<_FeedForm> {
  String _type = FeedLog.types.first;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  static const _typeEmoji = {
    '干粮': '🍖', '湿粮罐头': '🥫', '冻干': '🐟', '零食': '🍪', '饮水': '💧',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipChoice<String>(
          values: FeedLog.types,
          selected: _type,
          onSelect: (v) => setState(() => _type = v),
          emojis: _typeEmoji,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  hintText: _type == '饮水' ? '饮水量 (ml)' : '份量 (g)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 常用量快捷按钮
            ...[20, 50, 100].map((v) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('$v'),
                    backgroundColor: AppColors.butter,
                    side: BorderSide.none,
                    onPressed: () => _amountCtrl.text = '$v',
                  ),
                )),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(hintText: '备注（可选）：吃了多少、爱不爱吃…'),
        ),
        const SizedBox(height: 20),
        PawButton(
          label: '记好啦 🐾',
          icon: Icons.check_rounded,
          onTap: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      showCuteToast(context, '先填一下份量哦');
      return;
    }
    final store = context.read<CatStore>();
    store.addFeed(FeedLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      catId: widget.cat.id,
      time: DateTime.now(),
      type: _type,
      amount: amount,
      note: _noteCtrl.text.trim(),
    ));
    if (mounted) {
      Navigator.pop(context);
      showPawCelebration(context, emoji: '🐾');
      showCuteToast(context, '${widget.cat.name}的$_type记好啦 🍚');
    }
  }
}

// ---------------- 体重表单 ----------------
class _WeightForm extends StatefulWidget {
  final Cat cat;
  const _WeightForm({required this.cat});

  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  final _weightCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final latest = store.latestWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '上次记录：${latest.weight} kg（${DateFormat('MM月dd日').format(latest.date)}）',
              style: const TextStyle(color: AppColors.mintDeep),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _weightCtrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,1}\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(hintText: '今天体重 (kg)，如 4.2'),
        ),
        const SizedBox(height: 20),
        PawButton(
          label: '记好啦 🐾',
          icon: Icons.check_rounded,
          onTap: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null || w <= 0 || w > 20) {
      showCuteToast(context, '体重要在 0~20 kg 之间哦');
      return;
    }
    final store = context.read<CatStore>();
    store.addWeight(WeightLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      catId: widget.cat.id,
      date: DateTime.now(),
      weight: w,
    ));
    if (mounted) {
      Navigator.pop(context);
      showPawCelebration(context, emoji: '⚖️');
      showCuteToast(context, '${widget.cat.name}的体重记好啦 ⚖️');
    }
  }
}

// ---------------- 健康表单 ----------------
class _HealthForm extends StatefulWidget {
  final Cat cat;
  const _HealthForm({required this.cat});

  @override
  State<_HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<_HealthForm> {
  String _category = 'vaccine';
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _nextDue;

  @override
  Widget build(BuildContext context) {
    final cats = HealthLog.categories.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipChoice<String>(
          values: cats,
          selected: _category,
          onSelect: (v) => setState(() => _category = v),
          labels: HealthLog.categories,
          emojis: HealthLog.categoryEmoji,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            hintText: _category == 'symptom' ? '症状描述，如：软便、打喷嚏' : '事项名称，如：猫三联第二针',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(hintText: '备注（可选）'),
        ),
        const SizedBox(height: 12),
        // 下次提醒日期
        GestureDetector(
          onTap: _pickNextDue,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  _nextDue == null
                      ? '设置下次提醒（可选）'
                      : '下次提醒：${DateFormat('yyyy年MM月dd日').format(_nextDue!)}',
                  style: TextStyle(
                    color: _nextDue == null
                        ? AppColors.textSub
                        : AppColors.textMain,
                  ),
                ),
                const Spacer(),
                if (_nextDue != null)
                  GestureDetector(
                    onTap: () => setState(() => _nextDue = null),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSub),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PawButton(
          label: '记好啦 🐾',
          icon: Icons.check_rounded,
          onTap: _submit,
        ),
      ],
    );
  }

  Future<void> _pickNextDue() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _nextDue ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.pinkDeep),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _nextDue = d);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      showCuteToast(context, '先填一下事项名称哦');
      return;
    }
    final store = context.read<CatStore>();
    store.addHealth(HealthLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      catId: widget.cat.id,
      date: DateTime.now(),
      category: _category,
      title: title,
      note: _noteCtrl.text.trim(),
      nextDue: _nextDue,
    ));
    if (mounted) {
      Navigator.pop(context);
      showPawCelebration(context, emoji: HealthLog.categoryEmoji[_category] ?? '💊');
      showCuteToast(context, '健康记录记好啦 ${HealthLog.categoryEmoji[_category]}');
    }
  }
}
