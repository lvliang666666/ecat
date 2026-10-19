// 快捷记录入口：喂食 / 体重 / 健康 三合一弹窗
// 供首页 FAB 与记录页共用；所有写入都挂载到当前猫咪（数据隔离）。
// 编辑模式：传入待编辑的 log（editFeed/editWeight/editHealth）即预填表单走更新。
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

/// 编辑喂食记录（记录页长按进入）
Future<void> editFeedRecord(BuildContext context, FeedLog log) async {
  await showCuteSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickRecordSheet.editFeed(log),
  );
}

/// 编辑体重记录
Future<void> editWeightRecord(BuildContext context, WeightLog log) async {
  await showCuteSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickRecordSheet.editWeight(log),
  );
}

/// 编辑健康记录
Future<void> editHealthRecord(BuildContext context, HealthLog log) async {
  await showCuteSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickRecordSheet.editHealth(log),
  );
}

class _QuickRecordSheet extends StatefulWidget {
  final int initialTab;
  final FeedLog? editFeed;
  final WeightLog? editWeight;
  final HealthLog? editHealth;

  const _QuickRecordSheet({this.initialTab = 0})
      : editFeed = null,
        editWeight = null,
        editHealth = null;

  const _QuickRecordSheet.editFeed(FeedLog log)
      : initialTab = 0,
        editFeed = log,
        editWeight = null,
        editHealth = null;

  const _QuickRecordSheet.editWeight(WeightLog log)
      : initialTab = 1,
        editFeed = null,
        editWeight = log,
        editHealth = null;

  const _QuickRecordSheet.editHealth(HealthLog log)
      : initialTab = 2,
        editFeed = null,
        editWeight = null,
        editHealth = log;

  @override
  State<_QuickRecordSheet> createState() => _QuickRecordSheetState();
}

class _QuickRecordSheetState extends State<_QuickRecordSheet> {
  late int _tab = widget.initialTab;
  bool get _isEditing =>
      widget.editFeed != null || widget.editWeight != null || widget.editHealth != null;

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
                _isEditing
                    ? '修改「${cat.name}」的记录'
                    : '给「${cat.name}」记一笔',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 编辑模式下锁定类型 Tab（改喂食记录不会变成改体重）
          if (!_isEditing) ...[
            ChipChoice<int>(
              values: const [0, 1, 2],
              selected: _tab,
              onSelect: (v) => setState(() => _tab = v),
              labels: const {0: '喂食', 1: '体重', 2: '健康'},
              emojis: const {0: '🍚', 1: '⚖️', 2: '💊'},
            ),
            const SizedBox(height: 20),
          ],
          if (_tab == 0) _FeedForm(cat: cat, editing: widget.editFeed),
          if (_tab == 1) _WeightForm(cat: cat, editing: widget.editWeight),
          if (_tab == 2) _HealthForm(cat: cat, editing: widget.editHealth),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------- 喂食表单 ----------------
class _FeedForm extends StatefulWidget {
  final Cat cat;
  final FeedLog? editing; // 非 null = 编辑模式
  const _FeedForm({required this.cat, this.editing});

  @override
  State<_FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<_FeedForm> {
  late String _type = widget.editing?.type ?? FeedLog.types.first;
  late final _amountCtrl = TextEditingController(
    text: widget.editing == null
        ? ''
        : _fmtAmount(widget.editing!.amount),
  );
  late final _noteCtrl =
      TextEditingController(text: widget.editing?.note ?? '');

  static const _typeEmoji = {
    '干粮': '🍖', '湿粮罐头': '🥫', '冻干': '🐟', '零食': '🍪', '饮水': '💧',
  };

  static String _fmtAmount(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

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
          label: widget.editing == null ? '记好啦 🐾' : '保存修改 🐾',
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
    final editing = widget.editing;
    if (editing != null) {
      store.updateFeed(FeedLog(
        id: editing.id,
        catId: editing.catId,
        time: editing.time, // 编辑不改时间（记录页展示的是原时间）
        type: _type,
        amount: amount,
        note: _noteCtrl.text.trim(),
      ));
      if (mounted) {
        Navigator.pop(context);
        showCuteToast(context, '记录已更新 ✏️');
      }
      return;
    }
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
  final WeightLog? editing;
  const _WeightForm({required this.cat, this.editing});

  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  late final _weightCtrl = TextEditingController(
    text: widget.editing?.weight.toStringAsFixed(1) ?? '',
  );
  late DateTime _date = widget.editing?.date ?? DateTime.now();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.pinkDeep),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final latest = widget.editing == null ? store.latestWeight : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '上次记录：${latest.weight} kg（${DateFormat('MM月dd日').format(latest.date)}）',
              style: TextStyle(color: AppColors.mintDeep),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
        // 编辑模式：可改称重日期
        if (widget.editing != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    '称重日期：${DateFormat('yyyy年MM月dd日').format(_date)}',
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        PawButton(
          label: widget.editing == null ? '记好啦 🐾' : '保存修改 🐾',
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
    final editing = widget.editing;
    if (editing != null) {
      store.updateWeight(WeightLog(
        id: editing.id,
        catId: editing.catId,
        date: _date,
        weight: w,
      ));
      if (mounted) {
        Navigator.pop(context);
        showCuteToast(context, '体重记录已更新 ✏️');
      }
      return;
    }
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
  final HealthLog? editing;
  const _HealthForm({required this.cat, this.editing});

  @override
  State<_HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<_HealthForm> {
  late String _category = widget.editing?.category ?? 'vaccine';
  late final _titleCtrl =
      TextEditingController(text: widget.editing?.title ?? '');
  late final _noteCtrl =
      TextEditingController(text: widget.editing?.note ?? '');
  late DateTime? _nextDue = widget.editing?.nextDue;
  late DateTime _logDate = widget.editing?.date ?? DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

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
        // 记录日期（编辑模式可改）
        if (widget.editing != null) ...[
          GestureDetector(
            onTap: _pickLogDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    '记录日期：${DateFormat('yyyy年MM月dd日').format(_logDate)}',
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSub),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PawButton(
          label: widget.editing == null ? '记好啦 🐾' : '保存修改 🐾',
          icon: Icons.check_rounded,
          onTap: _submit,
        ),
      ],
    );
  }

  Future<void> _pickLogDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.pinkDeep),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _logDate = d);
  }

  Future<void> _pickNextDue() async {
    final d = await showDatePicker(
      context: context,
      initialDate:
          _nextDue ?? DateTime.now().add(const Duration(days: 30)),
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
    final editing = widget.editing;
    if (editing != null) {
      store.updateHealth(HealthLog(
        id: editing.id,
        catId: editing.catId,
        date: _logDate,
        category: _category,
        title: title,
        note: _noteCtrl.text.trim(),
        nextDue: _nextDue,
      ));
      if (mounted) {
        Navigator.pop(context);
        showCuteToast(context, '健康记录已更新 ✏️');
      }
      return;
    }
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
