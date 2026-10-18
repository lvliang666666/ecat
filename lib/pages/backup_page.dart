// eCAT · 数据备份页：JSON 导出 / 导入
// 导出：file_selector 保存对话框 → 全量 JSON 落盘
// 导入：file_selector 打开对话框 → 校验 → 整体替换当前数据（带二次确认）
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 数据备份页（从猫咪页右上角设置进入）
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatStore>();
    final catCount = store.cats.length;
    final feedCount = store.feeds.length;
    final weightCount = store.weights.length;
    final healthCount = store.healths.length;

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
                      '数据备份 🗂️',
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
            const SizedBox(height: 20),

            // 数据概览卡
            CuteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前数据',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('🐱', '$catCount', '猫咪'),
                      _stat('🍚', '$feedCount', '喂食'),
                      _stat('⚖️', '$weightCount', '体重'),
                      _stat('💊', '$healthCount', '健康'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 导出
            CuteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📤', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text(
                        '导出备份',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '把全部数据保存为一个 JSON 文件，换设备、重装系统前先备份一份。',
                    style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  PawButton(
                    label: '导出到文件',
                    icon: Icons.save_alt_rounded,
                    onTap: () => _export(context, store),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 导入
            CuteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📥', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text(
                        '导入恢复',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '从备份文件恢复。注意：导入会覆盖当前的全部数据，操作前请先导出一份现在的数据。',
                    style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  PawButton(
                    label: '从文件导入',
                    icon: Icons.file_open_rounded,
                    color: AppColors.mintDeep,
                    onTap: () => _import(context, store),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String emoji, String num, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          num,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
      ],
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

  /// 导出：保存对话框 → 写文件
  Future<void> _export(BuildContext context, CatStore store) async {
    final now = DateTime.now();
    final suggestedName =
        'ecat-backup-${DateFormat('yyyyMMdd-HHmmss').format(now)}.json';

    final saveLocation = await getSaveLocation(suggestedName: suggestedName);
    if (saveLocation == null) return; // 用户取消

    try {
      final json = const JsonEncoder.withIndent('  ').convert(store.exportJson());
      await File(saveLocation.path).writeAsString(json, flush: true);
      if (!context.mounted) return;
      showPawCelebration(context, emoji: '📦');
      showCuteToast(context, '备份已导出 📤');
    } catch (e) {
      if (!context.mounted) return;
      showCuteToast(context, '导出失败：$e');
    }
  }

  /// 导入：二次确认 → 打开对话框 → 校验恢复
  Future<void> _import(BuildContext context, CatStore store) async {
    // 危险操作二次确认：导入会覆盖现有数据
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入会覆盖现有数据 ⚠️'),
        content: const Text(
          '导入后，当前的猫咪档案和全部记录都会被备份文件里的内容替换。\n\n建议先导出一份现在的数据再继续。',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('再想想', style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('继续导入', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return; // 用户取消

    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      await store.importJson(data);
      if (!context.mounted) return;
      showPawCelebration(context, emoji: '🎉');
      showCuteToast(context, '数据已恢复 📥');
    } on FormatException catch (e) {
      if (!context.mounted) return;
      showCuteToast(context, '导入失败：${e.message}');
    } catch (e) {
      if (!context.mounted) return;
      showCuteToast(context, '导入失败：文件格式不对或已损坏');
    }
  }
}
