// eCAT · 设置弹层：通知提醒开关 + 外观（主题模式）选择
// 从猫咪页顶栏 ⚙️ 进入；数据走 SettingsStore（provider）。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reminder_service.dart';
import '../store/cat_store.dart';
import '../store/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 打开设置弹层（猫咪页顶栏入口调用）
Future<void> showSettingsSheet(BuildContext context) {
  return showCuteSheet(context: context, builder: (_) => const _SettingsSheet());
}

/// 分钟数 → 「09:00」文案
String _minutesLabel(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '提醒时间：$h:$m';
}

TimeOfDay _minutesToTime(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final store = context.watch<CatStore>();

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '设置 ⚙️',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 20),

        // 通知提醒开关（长按卡片可发测试通知，验证系统通知是否真实弹出）
        CuteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '健康提醒通知',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            subtitle: Text(
              '疫苗、驱虫到期时通知我',
              style: TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
            activeThumbColor: AppColors.pinkDeep,
            value: settings.notificationsEnabled,
            onChanged: (v) async {
              if (v) {
                // 开启：先请求系统通知权限（Android 13+），被拒则不生效
                final granted = await ReminderService.requestPermission();
                if (!granted) {
                  if (!context.mounted) return;
                  showCuteToast(context, '请在系统设置中允许通知权限哦 🙏');
                  return;
                }
              }
              if (!context.mounted) return;
              await context.read<SettingsStore>().setNotificationsEnabled(v);
              // 开/关后立即重排或清空定时通知
              if (v) {
                await ReminderService.resync(store.cats, store.allHealths);
              } else {
                await ReminderService.clearAll();
              }
            },
          ),
        ),
        // 测试通知入口：点这行小字立即发一条（验证通知链路真实可用）
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await ReminderService.sendTestNotification();
            if (!context.mounted) return;
            showCuteToast(context, '测试通知已发送，看看系统通知栏 🐾');
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔔 点此发送测试通知',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pinkDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 每日喂食提醒（总开关关闭时置灰不可用）
        CuteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '每日喂食提醒',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: settings.notificationsEnabled
                        ? AppColors.textMain
                        : AppColors.textSub,
                  ),
                ),
                subtitle: Text(
                  '每天固定时间提醒我喂饭',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                activeThumbColor: AppColors.pinkDeep,
                value: settings.feedReminderEnabled,
                onChanged: settings.notificationsEnabled
                    ? (v) async {
                        await context
                            .read<SettingsStore>()
                            .setFeedReminderEnabled(v);
                        if (v && context.mounted) {
                          showCuteToast(context, '每天会准时喊你喂饭啦 🍚');
                        }
                      }
                    : null,
              ),
              // 时间选择行（子开关开启时才可点）
              if (settings.feedReminderEnabled &&
                  settings.notificationsEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Text('⏰', style: TextStyle(fontSize: 18)),
                  title: Text(
                    _minutesLabel(settings.feedReminderMinutes),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.textSub),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _minutesToTime(
                          settings.feedReminderMinutes),
                    );
                    if (picked == null || !context.mounted) return;
                    await context
                        .read<SettingsStore>()
                        .setFeedReminderMinutes(
                            picked.hour * 60 + picked.minute);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 外观选择
        CuteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '外观 🎨',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              ChipChoice<ThemeMode>(
                values: const [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ],
                selected: settings.themeMode,
                labels: const {
                  ThemeMode.system: '跟随系统',
                  ThemeMode.light: '浅色',
                  ThemeMode.dark: '深色',
                },
                emojis: const {
                  ThemeMode.system: '🌗',
                  ThemeMode.light: '☀️',
                  ThemeMode.dark: '🌙',
                },
                onSelect: (m) =>
                    context.read<SettingsStore>().setThemeMode(m),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
