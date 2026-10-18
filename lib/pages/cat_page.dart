// eCAT · 猫咪档案页（多猫管理 + 详情 + 体重曲线）
// 模块：猫咪列表 / 添加·编辑表单（底部弹窗）/ 猫咪详情（信息卡 + fl_chart 体重曲线 + 健康时间线 + 危险区）
// 数据全部来自 CatStore（provider），本文件不定义任何模型与存储逻辑
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/cat.dart';
import '../store/cat_store.dart';
import '../store/photo_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'backup_page.dart';
import 'stats_page.dart';

// ==================== 私有小工具 ====================

/// yyyy年MM月dd日
String _fmtDate(DateTime d) =>
    '${d.year}年${d.month.toString().padLeft(2, '0')}月${d.day.toString().padLeft(2, '0')}日';

/// M/d（曲线横轴、下次到期胶囊）
String _fmtShort(DateTime d) => '${d.month}/${d.day}';

/// yyyy.MM.dd（健康时间线）
String _fmtDot(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 由生日计算猫龄（与 Cat.ageText 同规则；表单里还没有 Cat 对象时使用）
String _ageTextOf(DateTime birthday) {
  final n = DateTime.now();
  int months = (n.year - birthday.year) * 12 + n.month - birthday.month;
  if (n.day < birthday.day) months--;
  if (months < 0) months = 0;
  final y = months ~/ 12;
  final m = months % 12;
  if (y <= 0) return '$m个月';
  if (m == 0) return '$y岁';
  return '$y岁$m个月';
}

/// 性别徽章：弟弟♂蓝 / 妹妹♀粉
Widget _genderBadge(String gender) {
  final boy = gender == Cat.genderBoy;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: boy ? AppColors.sky : AppColors.pinkLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      boy ? '♂ 弟弟' : '♀ 妹妹',
      style: TextStyle(
        color: boy ? AppColors.skyDeep : AppColors.pinkDeep,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// 绝育小标签
Widget _neuteredBadge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '已绝育',
        style: TextStyle(
          color: AppColors.mintDeep,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

// ==================== 主列表页 ====================

/// 猫咪档案页：多猫管理入口（底部导航「猫咪」Tab）
class CatPage extends StatefulWidget {
  const CatPage({super.key});

  @override
  State<CatPage> createState() => _CatPageState();
}

class _CatPageState extends State<CatPage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final cats = store.cats;

    // 空状态：还没有猫咪档案
    if (cats.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyState(
                  emoji: '🐈',
                  title: '还没有猫咪档案',
                  subtitle: '添加你的第一只小主子吧',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: PawButton(
                    label: '添加猫咪',
                    icon: Icons.add_rounded,
                    onTap: () => _openForm(context, null),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // 标题栏 + 数据备份入口
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '我的猫咪 🐈',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📊', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          '统计',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🗂️', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          '备份',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '共 ${cats.length} 只小主子 · 绿框是当前记录对象，长按卡片可切换',
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 18),
            // 猫咪卡片列表
            for (final cat in cats)
              GestureDetector(
                onLongPress: () => _switchRecordingTarget(context, cat),
                child: _catCard(context, store, cat),
              ),
            const SizedBox(height: 6),
            PawButton(
              label: '添加猫咪',
              icon: Icons.add_rounded,
              onTap: () => _openForm(context, null),
            ),
          ],
        ),
      ),
    );
  }

  /// 单只猫咪卡片
  Widget _catCard(BuildContext context, CatStore store, Cat cat) {
    final isRecordingTarget = cat.id == store.currentCat?.id;
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 14),
      // 记录对象用薄荷绿描边标识（不用角标，避免遮挡头像和名字）
      border: isRecordingTarget
          ? Border.all(color: AppColors.mintDeep, width: 2)
          : null,
      onTap: () => _openDetail(context, cat),
      child: Stack(
        children: [
          Row(
            children: [
              CatAvatar(emoji: cat.avatar, size: 58, photoPath: cat.photoPath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _genderBadge(cat.gender),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cat.breed} · ${cat.ageText()}',
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (cat.neutered) ...[
                          _neuteredBadge(),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            _weightLine(store, cat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSub, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 52), // 给右上角「编辑」留位
            ],
          ),
          // 右上角「编辑」小按钮
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _openForm(context, cat),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.pinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '编辑',
                  style: TextStyle(
                    color: AppColors.pinkDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 卡片体重文案：当前猫咪显示最新体重，其余回退到目标体重
  String _weightLine(CatStore store, Cat cat) {
    final w = store.latestWeightOf(cat.id);
    if (w != null) return '⚖️ 最新 ${w.weight.toStringAsFixed(1)} kg';
    final t = cat.targetWeight;
    if (t != null) return '🎯 目标 ${t.toStringAsFixed(1)} kg';
    return '⚖️ 体重待记录';
  }

  /// 进入详情页（详情页按 catId 取数，不改变记录对象）
  Future<void> _openDetail(BuildContext context, Cat cat) async {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CatDetailPage(catId: cat.id)),
    );
  }

  /// 切换记录对象：带确认弹窗（记录归属变更需要用户明确确认）
  Future<void> _switchRecordingTarget(BuildContext context, Cat cat) async {
    final store = context.read<CatStore>();
    if (cat.id == store.currentCat?.id) return; // 已是记录对象
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('把记录对象切换为「${cat.name}」？'),
        content: const Text(
          '之后「记一笔」喂食、体重、健康记录都会记到 TA 名下。\n\n浏览数据不受影响，随时可以再切换。',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('再想想', style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('切换到 ${cat.name}',
                style: const TextStyle(
                    color: AppColors.pinkDeep, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.selectCat(cat.id);
    if (context.mounted) showCuteToast(context, '记录对象已切换为 ${cat.avatar} ${cat.name}');
  }

  /// 打开添加 / 编辑表单（cat 为 null 表示新增）
  Future<void> _openForm(BuildContext context, Cat? cat) {
    return showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CatFormSheet(cat: cat),
    );
  }
}

// ==================== 添加 / 编辑表单 ====================

/// 可选头像 emoji（8-10 个）
const List<String> _avatarChoices = [
  '🐱', '🐈', '😺', '😸', '😻', '😼', '😽', '🙀', '😿', '😹',
];

/// 常用品种快捷胶囊
const List<String> _breedChoices = ['田园猫', '英短', '美短', '布偶', '暹罗', '橘猫'];

/// 常见毛色快捷胶囊
const List<String> _furColorChoices = [
  '橘色', '黑白', '奶牛', '三花', '狸花', '白猫', '蓝猫', '其他',
];

/// 添加 / 编辑猫咪表单（showCuteSheet 弹出）
class _CatFormSheet extends StatefulWidget {
  final Cat? cat; // 非 null = 编辑模式

  const _CatFormSheet({this.cat});

  @override
  State<_CatFormSheet> createState() => _CatFormSheetState();
}

class _CatFormSheetState extends State<_CatFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _foodGoalCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _birthday;
  late String _gender;
  late bool _neutered;
  late String _avatar;
  late String _furColor;
  String? _photoPath; // 已保存的照片文件名（编辑模式回显）
  String? _pendingPhotoSource; // 本次新选的照片源路径（保存时才复制）
  String? _photoToRemove; // 待删除的旧照片文件名
  String? _error; // 名字校验提示

  bool get _isEdit => widget.cat != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cat;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _breedCtrl = TextEditingController(text: c?.breed ?? '田园猫');
    _targetCtrl = TextEditingController(
      text: c?.targetWeight == null ? '' : c!.targetWeight!.toStringAsFixed(1),
    );
    _foodGoalCtrl = TextEditingController(
      text: c?.dailyFoodGoal.toStringAsFixed(0) ?? '',
    );
    _allergiesCtrl = TextEditingController(text: c?.allergies.join('，') ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _birthday = c?.birthday ??
        DateTime.now().subtract(const Duration(days: 365 * 2)); // 默认 2 年前
    _gender = c?.gender ?? Cat.genderGirl;
    _neutered = c?.neutered ?? false;
    _avatar = c?.avatar ?? '🐱';
    _furColor = c?.furColor ?? '橘色';
    _photoPath = c?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _targetCtrl.dispose();
    _foodGoalCtrl.dispose();
    _allergiesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// 选择生日
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday.isAfter(now) ? now : _birthday,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  /// 选照片做头像：系统相册/文件选择器，先预览，保存时才复制
  Future<void> _pickPhoto() async {
    const typeGroup = XTypeGroup(
      label: '图片',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return; // 用户取消
    setState(() {
      _pendingPhotoSource = file.path;
      // 新照片覆盖旧照片
      if (_photoPath != null) {
        _photoToRemove = _photoPath;
        _photoPath = null;
      }
    });
  }

  /// 保存：校验名字非空 → addCat / updateCat
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '给小主子取个名字吧～');
      return;
    }
    final store = context.read<CatStore>();
    final target =
        double.tryParse(_targetCtrl.text.trim()); // 解析失败视为未设置目标体重
    // 每日喂食目标：留空回退默认 60g；非法/非正数同样回退
    final foodGoal = double.tryParse(_foodGoalCtrl.text.trim());
    final effectiveFoodGoal =
        (foodGoal == null || foodGoal <= 0) ? null : foodGoal;
    final allergies = _allergiesCtrl.text
        .split(RegExp('[,，、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_isEdit) {
      final c = widget.cat!;
      // 照片处理：新选的照片先复制进应用目录，再清理被替换的旧照片
      String? photoPath = _photoPath;
      if (_pendingPhotoSource != null) {
        try {
          photoPath = await PhotoStore.saveFrom(_pendingPhotoSource!, c.id);
        } catch (_) {
          // 复制失败则保持原照片不变
          photoPath = _photoPath;
        }
      }
      // 编辑模式：保留原 id，回写可变字段
      c.name = name;
      c.breed = _breedCtrl.text.trim().isEmpty ? '田园猫' : _breedCtrl.text.trim();
      c.birthday = _birthday;
      c.gender = _gender;
      c.neutered = _neutered;
      c.furColor = _furColor;
      c.avatar = _avatar;
      c.photoPath = photoPath;
      c.targetWeight = target;
      c.dailyFoodGoal = effectiveFoodGoal ?? Cat.defaultDailyFoodGoal;
      c.allergies = allergies;
      c.notes = _notesCtrl.text.trim();
      await store.updateCat(c);
      // 保存成功后清理被替换/移除的旧照片文件
      if (_photoToRemove != null && _photoToRemove != photoPath) {
        await PhotoStore.delete(_photoToRemove);
      }
    } else {
      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      // 新增模式：照片复制进应用目录
      String? photoPath;
      if (_pendingPhotoSource != null) {
        try {
          photoPath = await PhotoStore.saveFrom(_pendingPhotoSource!, newId);
        } catch (_) {
          photoPath = null; // 复制失败则回退 emoji 头像
        }
      }
      await store.addCat(Cat(
        id: newId,
        name: name,
        breed: _breedCtrl.text.trim().isEmpty ? '田园猫' : _breedCtrl.text.trim(),
        birthday: _birthday,
        gender: _gender,
        neutered: _neutered,
        furColor: _furColor,
        avatar: _avatar,
        photoPath: photoPath,
        targetWeight: target,
        dailyFoodGoal: effectiveFoodGoal,
        allergies: allergies,
        notes: _notesCtrl.text.trim(),
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showPawCelebration(context, emoji: _isEdit ? '✨' : '🎉');
    showCuteToast(context, _isEdit ? '档案更新好啦 🐾' : '欢迎新小主子 🐾');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 弹窗标题
          Center(
            child: Text(
              _isEdit ? '编辑档案 ✏️' : '添加猫咪 🐾',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ---- 头像选择 ----
          const _FormLabel('选个头像'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in _avatarChoices)
                GestureDetector(
                  onTap: () => setState(() {
                    _avatar = e;
                    // 选 emoji 即回到 emoji 头像
                    if (_photoPath != null || _pendingPhotoSource != null) {
                      _photoToRemove = _photoPath;
                      _photoPath = null;
                      _pendingPhotoSource = null;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (_avatar == e && _photoPath == null && _pendingPhotoSource == null)
                          ? AppColors.pinkLight
                          : AppColors.cream,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (_avatar == e && _photoPath == null && _pendingPhotoSource == null)
                            ? AppColors.pinkDeep
                            : AppColors.pinkLight,
                        width: (_avatar == e && _photoPath == null && _pendingPhotoSource == null)
                            ? 2
                            : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ---- 照片头像 ----
          Row(
            children: [
              // 照片预览（有照片或已选新照片时显示）
              if (_pendingPhotoSource != null)
                ClipOval(
                  child: Image.file(
                    File(_pendingPhotoSource!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('📷', style: TextStyle(fontSize: 22)),
                  ),
                )
              else if (_photoPath != null)
                CatAvatar(emoji: _avatar, size: 44, photoPath: _photoPath),
              if (_pendingPhotoSource != null || _photoPath != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _photoToRemove = _photoPath;
                    _photoPath = null;
                    _pendingPhotoSource = null;
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    textStyle: const TextStyle(fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('移除照片'),
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(
                  _pendingPhotoSource != null || _photoPath != null
                      ? '换一张'
                      : '用照片做头像',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pinkDeep,
                  side: const BorderSide(color: AppColors.pink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- 名字 ----
          _FormLabel('名字', required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            maxLength: 12,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: 'TA 叫什么呀？',
              counterText: '',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),

          // ---- 品种 ----
          _FormLabel('品种'),
          const SizedBox(height: 8),
          TextField(
            controller: _breedCtrl,
            decoration: const InputDecoration(hintText: '例如：英短蓝猫'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in _breedChoices)
                GestureDetector(
                  onTap: () => setState(() => _breedCtrl.text = b),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butter,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- 生日 ----
          _FormLabel('生日'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickBirthday,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🎂', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_fmtDate(_birthday)} · ${_ageTextOf(_birthday)}',
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded,
                      color: AppColors.textSub, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- 性别 ----
          _FormLabel('性别'),
          const SizedBox(height: 8),
          ChipChoice<String>(
            values: const [Cat.genderBoy, Cat.genderGirl],
            selected: _gender,
            onSelect: (v) => setState(() => _gender = v),
            labels: const {Cat.genderBoy: '弟弟', Cat.genderGirl: '妹妹'},
            emojis: const {Cat.genderBoy: '👦', Cat.genderGirl: '👧'},
          ),
          const SizedBox(height: 16),

          // ---- 绝育 ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('✂️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '已绝育',
                    style: TextStyle(color: AppColors.textMain, fontSize: 15),
                  ),
                ),
                Switch(
                  value: _neutered,
                  activeThumbColor: AppColors.pinkDeep,
                  activeTrackColor: AppColors.pink,
                  onChanged: (v) => setState(() => _neutered = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- 毛色 ----
          _FormLabel('毛色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _furColorChoices)
                GestureDetector(
                  onTap: () => setState(() => _furColor = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _furColor == f
                          ? AppColors.pinkLight
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _furColor == f
                            ? AppColors.pinkDeep
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: _furColor == f
                            ? AppColors.pinkDeep
                            : AppColors.textMain,
                        fontSize: 12,
                        fontWeight: _furColor == f
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- 目标体重 ----
          _FormLabel('目标体重（kg，可选）'),
          const SizedBox(height: 8),
          TextField(
            controller: _targetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}')),
            ],
            decoration: const InputDecoration(hintText: '例如：4.5'),
          ),
          const SizedBox(height: 16),

          // ---- 每日喂食目标 ----
          _FormLabel('每日喂食目标（g，可选）'),
          const SizedBox(height: 8),
          TextField(
            controller: _foodGoalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
            ],
            decoration: const InputDecoration(
              hintText: '默认 60g，例如：80',
              suffixText: 'g/日',
            ),
          ),
          const SizedBox(height: 16),

          // ---- 过敏 / 禁忌 ----
          _FormLabel('过敏 / 禁忌（可选，逗号分隔）'),
          const SizedBox(height: 8),
          TextField(
            controller: _allergiesCtrl,
            decoration: const InputDecoration(hintText: '例如：鸡肉，牛奶'),
          ),
          const SizedBox(height: 16),

          // ---- 备注 ----
          _FormLabel('备注（性格、习惯、病史）'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: '写点 TA 的小秘密吧～',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),

          // ---- 保存 ----
          PawButton(
            label: _isEdit ? '保存修改' : '保存',
            icon: Icons.pets_rounded,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

/// 表单小标签（必填项带红星）
class _FormLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FormLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(color: AppColors.danger, fontSize: 14)),
      ],
    );
  }
}

// ==================== 猫咪详情页 ====================

/// 猫咪详情页：信息卡 + 体重曲线 + 健康时间线 + 危险区
/// 通过 catId 从 CatStore 实时取数据（删除后 store 里找不到会自动退回列表）
class CatDetailPage extends StatefulWidget {
  final String catId;

  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    // 详情页按 catId 取数（查看不改变记录对象）；找不到（刚被删除）时退回列表
    final cat =
        store.cats.where((c) => c.id == widget.catId).firstOrNull;
    if (cat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final weights = store.weightsOf(cat.id); // 该猫体重（日期升序）
    final healths = store.healthsOf(cat.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 健康记录按日期倒序

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
                      '猫咪档案 🐾',
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
            const SizedBox(height: 14),

            // ---- 头部大卡片 ----
            _headerCard(cat),
            const SizedBox(height: 20),

            // ---- 体重曲线 ----
            SectionTitle(
              title: '体重曲线',
              emoji: '⚖️',
              trailing: GestureDetector(
                onTap: weights.isEmpty
                    ? null
                    : () => _openWeightHistory(context, store),
                child: const Text(
                  '历史体重 ›',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pinkDeep,
                  ),
                ),
              ),
            ),
            _weightChartCard(cat, weights),
            const SizedBox(height: 20),

            // ---- 健康时间线 ----
            SectionTitle(title: '健康时间线', emoji: '💉'),
            if (healths.isEmpty)
              const CuteCard(
                child: EmptyState(
                  emoji: '🌱',
                  title: '还没有健康记录',
                  subtitle: '疫苗、驱虫、就医都可以记在这里',
                ),
              )
            else
              ...healths.map(_healthTile),
            const SizedBox(height: 24),

            // ---- 危险区 ----
            Center(
              child: TextButton(
                onPressed: () => _confirmDelete(context, store, cat),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('删除这只猫咪的档案'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 圆形小图标按钮（返回键）
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

  /// 头部大卡片：头像 + 基础信息 + 过敏标签 + 备注
  Widget _headerCard(Cat cat) {
    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CatAvatar(emoji: cat.avatar, size: 84, photoPath: cat.photoPath),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _genderBadge(cat.gender),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('🏷️', '品种', cat.breed),
          _infoRow('🎂', '生日', _fmtDate(cat.birthday)),
          _infoRow('⏳', '猫龄', cat.ageText()),
          _infoRow('🎨', '毛色', cat.furColor),
          _infoRow('✂️', '绝育', cat.neutered ? '已绝育' : '未绝育'),
          if (cat.targetWeight != null)
            _infoRow(
                '🎯', '目标体重', '${cat.targetWeight!.toStringAsFixed(1)} kg'),
          // 过敏标签（红色小胶囊）
          if (cat.allergies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in cat.allergies)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '⚠️ 过敏：$a',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          // 备注
          if (cat.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.butter,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '📝 ${cat.notes}',
                style: const TextStyle(
                    color: AppColors.textMain, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 信息行：emoji + 标签 + 值
  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 体重曲线卡片（fl_chart LineChart）：固定展示最近 7 次记录
  Widget _weightChartCard(Cat cat, List<WeightLog> weights) {
    // 曲线只取最近 7 次（weights 已按日期升序），横轴即这 7 次的日期
    final recent = weights.length <= 7 ? weights : weights.sublist(weights.length - 7);
    return CuteCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: recent.length < 2
                // 数据不足：可爱提示
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📈', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text(
                          '再记录一次就能看到曲线啦',
                          style: TextStyle(
                              color: AppColors.textSub, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: _buildLineChart(recent),
                  ),
          ),
          const SizedBox(height: 12),
          PawButton(
            label: '记录体重',
            icon: Icons.monitor_weight_outlined,
            expanded: false,
            onTap: () => _openWeightSheet(context, cat),
          ),
        ],
      ),
    );
  }

  /// fl_chart 1.x 折线图：x = 记录序号，y = 体重 kg（固定 0~30 量程）
  Widget _buildLineChart(List<WeightLog> weights) {
    final spots = <FlSpot>[
      for (var i = 0; i < weights.length; i++)
        FlSpot(i.toDouble(), weights[i].weight),
    ];

    // y 轴固定 0~30kg 均匀分布，刻度清晰不随数据抖动
    const double minY = 0;
    const double maxY = 30;

    final target = context.read<CatStore>().currentCat?.targetWeight;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (weights.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5, // 与左轴刻度一致：0/5/10/15/20/25/30
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
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          // 左轴：0~30kg 整数刻度
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 5,
              getTitlesWidget: _yTitle,
            ),
          ),
          // 底轴：MM/dd 日期（按记录数动态抽稀）
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _xTitle(value, meta, weights),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.pinkDeep,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${_fmtShort(weights[s.x.toInt()].date)}\n${s.y.toStringAsFixed(2)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: AppColors.pink,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, x, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeColor: AppColors.pinkDeep,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.pink.withValues(alpha: 0.12),
            ),
          ),
        ],
        // 目标体重参考虚线
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (target != null && target >= minY && target <= maxY)
              HorizontalLine(
                y: target,
                color: AppColors.mintDeep,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: AppColors.mintDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (line) =>
                      '目标 ${line.y.toStringAsFixed(1)}kg',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 左轴刻度：整数 kg（0/5/10/15/20/25/30）
  static Widget _yTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(color: AppColors.textSub, fontSize: 11),
      ),
    );
  }

  /// 底轴日期标签：曲线固定最近 7 次记录，7 个标签全部显示
  static Widget _xTitle(double value, TitleMeta meta, List<WeightLog> weights) {
    final i = value.toInt();
    if (i < 0 || i >= weights.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      child: Text(
        _fmtShort(weights[i].date),
        style: const TextStyle(color: AppColors.textSub, fontSize: 10),
      ),
    );
  }

  /// 记录体重弹窗（记录到当前查看的这只猫）
  Future<void> _openWeightSheet(BuildContext context, Cat cat) {
    return showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WeightSheet(catId: cat.id, catName: cat.name),
    );
  }

  /// 历史体重弹窗：全部记录倒序列表，支持长按删除
  void _openWeightHistory(BuildContext context, CatStore store) {
    showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WeightHistorySheet(store: store),
    );
  }

  /// 健康时间线条目
  Widget _healthTile(HealthLog h) {
    final emoji = HealthLog.categoryEmoji[h.category] ?? '🐾';
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.pinkLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        h.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    Text(
                      _fmtDot(h.date),
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11),
                    ),
                  ],
                ),
                if (h.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    h.note,
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12, height: 1.4),
                  ),
                ],
                if (h.nextDue != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '下次：${_fmtShort(h.nextDue!)}',
                      style: const TextStyle(
                        color: AppColors.mintDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 删除二次确认（温柔文案），确认后 pop 回列表
  Future<void> _confirmDelete(
      BuildContext context, CatStore store, Cat cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('要和 TA 说再见吗？😿'),
        content: Text(
          '这会删除「${cat.name}」的全部记录，确定吗？',
          style: const TextStyle(color: AppColors.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('再想想',
                style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定删除',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.removeCat(cat.id);
    if (!mounted) return;
    final nav = Navigator.of(this.context); // 先取 navigator，再跨异步使用
    nav.pop(); // 删除后回到列表
    showCuteToast(this.context, '档案已删除，愿 TA 一切安好 🌈');
  }
}

// ==================== 记录体重弹窗 ====================

/// 简单体重输入 sheet（记录到指定猫咪）
class _WeightSheet extends StatefulWidget {
  final String catId;
  final String catName;

  const _WeightSheet({required this.catId, required this.catName});

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final w = double.tryParse(_ctrl.text.trim());
    if (w == null || w <= 0 || w > 30) {
      setState(() => _error = '请输入合理的体重（0-30 kg）');
      return;
    }
    final store = context.read<CatStore>();
    store.addWeight(WeightLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      catId: widget.catId,
      date: DateTime.now(),
      weight: w,
    ));
    Navigator.of(context).pop();
    showPawCelebration(context, emoji: '⚖️');
    showCuteToast(context, '${widget.catName}的体重记好啦 ⚖️');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '记录${widget.catName}的体重 ⚖️',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,2}')),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: '今天称了多少 kg 呀？',
              suffixText: 'kg',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          PawButton(label: '保存', icon: Icons.check_rounded, onTap: _submit),
        ],
      ),
    );
  }
}

// ==================== 历史体重弹窗 ====================

/// 全部体重记录倒序列表：日期 + 体重 + 与上次对比，长按删除
class _WeightHistorySheet extends StatelessWidget {
  final CatStore store;

  const _WeightHistorySheet({required this.store});

  @override
  Widget build(BuildContext context) {
    // 实时监听：删除后列表立即刷新
    final weights = context.watch<CatStore>().weights.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 倒序：最新在上

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '历史体重 ⚖️（共 ${weights.length} 次）',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '长按某条记录可删除',
              style: TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
          ),
          const SizedBox(height: 14),
          if (weights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                emoji: '⚖️',
                title: '还没有体重记录',
                subtitle: '去曲线下方「记录体重」记第一条吧',
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < weights.length; i++)
                        _historyTile(context, weights[i], i == 0, weights),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 单条历史记录：日期 + 体重 + 与上一条（更早那条）的对比
  Widget _historyTile(
      BuildContext context, WeightLog w, bool isLatest, List<WeightLog> all) {
    // all 是倒序的：当前条的下一项（idx+1）就是更早的那次记录
    WeightLog? earlier;
    final idx = all.indexOf(w);
    if (idx >= 0 && idx + 1 < all.length) earlier = all[idx + 1];

    String? diffText;
    Color? diffColor;
    if (earlier != null) {
      final diff = w.weight - earlier.weight;
      if (diff.abs() < 0.01) {
        diffText = '持平';
        diffColor = AppColors.textSub;
      } else if (diff > 0) {
        diffText = '↑${diff.toStringAsFixed(2)}';
        diffColor = AppColors.butterDeep;
      } else {
        diffText = '↓${(-diff).toStringAsFixed(2)}';
        diffColor = AppColors.mintDeep;
      }
    }

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, w),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isLatest ? AppColors.pinkLight.withValues(alpha: 0.6) : AppColors.cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (isLatest) ...[
              const Text('🆕', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
            ],
            Text(
              _fmtDot(w.date),
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${w.weight.toStringAsFixed(2)} kg',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            if (diffText != null) ...[
              const SizedBox(width: 10),
              Text(
                diffText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 删除二次确认
  Future<void> _confirmDelete(BuildContext context, WeightLog w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条体重记录？'),
        content: Text(
          '${_fmtDot(w.date)} 的 ${w.weight.toStringAsFixed(2)} kg 将被删除',
          style: const TextStyle(color: AppColors.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('再想想', style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.removeWeight(w.id);
      if (context.mounted) showCuteToast(context, '记录已删除 🗑️');
    }
  }
}
