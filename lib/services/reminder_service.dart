// eCAT · 本地提醒通知服务
// 疫苗/驱虫等健康事项 nextDue 到期时发系统通知：
// - Android：zonedSchedule 定时到到期日 09:00（inexactAllowWhileIdle，免精确闹钟权限）
// - Windows：同样支持一次性定时调度（插件原生实现），与 Android 统一走定时路径；
//   另在启动/数据变化时对「今天到期或已过期且未提醒过」的条目立即补发一条，
//   覆盖「应用没在运行时定时通知丢失」的场景（Windows 非常驻进程尤其需要）。
// 去重：每条 HealthLog 只补发一次，标记存 SharedPreferences（ecat_notified_<logId>）。
// 每日喂食提醒（P5-3）：
// - Android：matchDateTimeComponents.time 每日重复（系统级，一次排定永久生效）
// - Windows：插件不支持周期调度 → 预排未来 7 天的一次性通知，
//   每次启动/数据变化时 resync 重排，滚动覆盖。
// 猫咪生日提醒（P5-4）：每只猫排「提前3天」+「当天」两条一次性通知，
// 周年日期自动计算（2/29 生日在平年落到 2/28）；错过的一样走补发去重。
library;

import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/cat.dart';

/// 下一个生日（周年）的提醒时刻：生日当天 09:00（offset=当天）或提前 offset 天。
/// 2/29 生日在平年落到 2/28；返回 null 表示计算异常。
/// 公开纯函数（无副作用），便于单元测试周年滚动与闰年边界。
DateTime? nextBirthdayAt(DateTime birthday, DateTime now, int offsetDays) {
  final today = DateTime(now.year, now.month, now.day);
  // 尝试今年的周年；若生日是 2/29 且今年平年，落到 2/28
  var candidate = _anniversaryIn(birthday, now.year);
  // 提醒时刻 = 周年 - offset 天；若已过 → 滚到明年再算一次
  var reminder = candidate.subtract(Duration(days: offsetDays));
  if (reminder.isBefore(today)) {
    candidate = _anniversaryIn(birthday, now.year + 1);
    reminder = candidate.subtract(Duration(days: offsetDays));
  }
  return DateTime(reminder.year, reminder.month, reminder.day, 9);
}

/// 指定年份的周年日期（处理 2/29 → 平年 2/28）
DateTime _anniversaryIn(DateTime birthday, int year) {
  final day = (birthday.month == 2 && birthday.day == 29)
      ? (_isLeapYear(year) ? 29 : 28)
      : birthday.day;
  return DateTime(year, birthday.month, day);
}

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

class ReminderService {
  ReminderService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 通知渠道（Android）
  static const _channelId = 'ecat_health_reminders';
  static const _channelName = '健康提醒';
  static const _channelDesc = '疫苗、驱虫等健康事项到期提醒';

  /// 喂食提醒渠道（Android，独立渠道便于用户单独关闭）
  static const _feedChannelId = 'ecat_feed_reminders';
  static const _feedChannelName = '喂食提醒';
  static const _feedChannelDesc = '每天固定时间提醒给猫咪喂饭';

  /// Windows 通知的应用标识（固定 GUID 标识本应用的 toast）
  static const _winAppName = 'eCAT 喵喵管家';
  static const _winAppUserModelId = 'com.lvproject.ecat';
  static const _winGuid = '7C9E6D8A-3B24-4F5E-9A81-2D6C0B4E7F13';

  /// 提醒通知 id 基数：与未来可能的其他通知类型区分
  static int _idOf(String logId) => logId.hashCode & 0x7fffffff;

  /// 喂食提醒固定 id（单条每日提醒，重复排定会覆盖同 id）
  static const _feedReminderId = 2;

  /// Windows 预排喂食提醒的天数（滚动覆盖窗口）
  static const _feedWindowsDays = 7;

  /// 初始化插件（main() 启动时调用一次；失败静默，不影响 App 运行）
  static Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const winInit = WindowsInitializationSettings(
        appName: _winAppName,
        appUserModelId: _winAppUserModelId,
        guid: _winGuid,
      );
      const iosInit = IOSInitializationSettings();

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          windows: winInit,
          iOS: iosInit,
        ),
      );
      _initialized = true;
    } catch (_) {
      // 初始化失败（如平台不支持）不阻塞 App
    }
  }

  /// Android 13+ 通知权限请求（首次开启通知开关时调用）
  static Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await android?.requestNotificationsPermission() ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// 全量重排：取消全部已排定通知，按当前健康记录 + 猫咪生日重新排定未来的提醒。
  /// 在启动、健康记录增删改、导入恢复、开关通知时调用。
  static Future<void> resync(List<Cat> cats, List<HealthLog> healths) async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      final catNameOf = {for (final c in cats) c.id: c.name};

      for (final h in healths) {
        final due = h.nextDue;
        if (due == null) continue;
        final dueDay = DateTime(due.year, due.month, due.day, 9); // 当天 09:00
        if (dueDay.isAfter(now)) {
          await _schedule(
            id: _idOf(h.id),
            at: dueDay,
            title: '${HealthLog.categoryEmoji[h.category] ?? '💊'} ${catNameOf[h.catId] ?? '猫咪'}的提醒',
            body: '${h.title} · ${HealthLog.categories[h.category] ?? '健康'}到期啦，记得处理哦',
          );
        }
      }

      // 猫咪生日提醒：提前3天 + 当天各一条
      for (final c in cats) {
        final b = c.birthday;
        for (final offset in const [3, 0]) {
          final at = _nextBirthdayAt(b, now, offset);
          if (at == null) continue;
          final years = at.year - b.year;
          await _schedule(
            id: _birthdayIdOf(c.id, offset),
            at: at,
            title: '🎂 ${c.name}的生日',
            body: offset == 3
                ? '再过3天就是${c.name}来到世界的第$years年啦，准备点小惊喜？'
                : '今天是${c.name}的$years岁生日，祝小主子生日快乐 🎉',
          );
        }
      }
    } catch (_) {
      // 排定失败静默（如 Windows 无包身份时的部分限制）
    }
  }

  /// 下一个生日（周年）的提醒时刻：生日当天 09:00（offset=当天）或提前 offset 天。
  /// 2/29 生日在平年落到 2/28；返回 null 表示计算异常。
  static DateTime? _nextBirthdayAt(
          DateTime birthday, DateTime now, int offsetDays) =>
      nextBirthdayAt(birthday, now, offsetDays);

  /// 生日提醒通知 id：按猫 + 提前天数区分（避免互相覆盖）
  static int _birthdayIdOf(String catId, int offsetDays) =>
      ('birthday_${catId}_$offsetDays').hashCode & 0x7fffffff;

  /// 启动补发：把「今天到期或已过期 ≤7 天且未提醒过」的条目立即弹一条通知。
  /// 覆盖应用未运行期间错过的定时通知；每条只补发一次（SP 标记去重）。
  static Future<void> deliverMissed(
    List<Cat> cats,
    List<HealthLog> healths,
  ) async {
    if (!_initialized) return;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sp = await SharedPreferences.getInstance();
      final catNameOf = {for (final c in cats) c.id: c.name};

      for (final h in healths) {
        final due = h.nextDue;
        if (due == null) continue;
        final dueDay = DateTime(due.year, due.month, due.day);
        final overdueDays = today.difference(dueDay).inDays;
        // 今天到期（0）或已过期 1~7 天才补发；更久远的过期视为陈旧记录不打扰
        if (overdueDays < 0 || overdueDays > 7) continue;

        final mark = 'ecat_notified_${h.id}';
        if (sp.getBool(mark) ?? false) continue;

        final when = overdueDays == 0 ? '今天' : '已过期$overdueDays天';
        await _show(
          id: _idOf(h.id),
          title: '${HealthLog.categoryEmoji[h.category] ?? '💊'} ${catNameOf[h.catId] ?? '猫咪'}的提醒',
          body: '${h.title} · $when到期啦，记得处理哦',
        );
        await sp.setBool(mark, true);
      }

      // 生日提醒补发：当天（或提前3天窗口内）错过的一次性补上
      for (final c in cats) {
        final b = c.birthday;
        for (final offset in const [3, 0]) {
          final at = _nextBirthdayAt(b, now, offset);
          if (at == null) continue;
          final atDay = DateTime(at.year, at.month, at.day);
          final lateDays = today.difference(atDay).inDays;
          // 只补发「刚错过 0~1 天」的生日提醒（生日过太久就没意义了）
          if (lateDays < 0 || lateDays > 1) continue;

          final mark = 'ecat_notified_birthday_${c.id}_$offset';
          if (sp.getBool(mark) ?? false) continue;

          final years = at.year - b.year;
          await _show(
            id: _birthdayIdOf(c.id, offset),
            title: '🎂 ${c.name}的生日',
            body: offset == 3
                ? '再过3天就是${c.name}来到世界的第$years年啦，准备点小惊喜？'
                : '今天是${c.name}的$years岁生日，祝小主子生日快乐 🎉',
          );
          await sp.setBool(mark, true);
        }
      }
    } catch (_) {
      // 补发失败静默
    }
  }

  /// 清除全部「已补发」标记（导入恢复后调用，让旧提醒重新可补发）
  static Future<void> clearNotifiedMarks() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final keys = sp
          .getKeys()
          .where((k) => k.startsWith('ecat_notified_'));
      for (final k in keys) {
        await sp.remove(k);
      }
    } catch (_) {}
  }

  /// 关闭通知：取消全部已排定的定时通知
  static Future<void> clearAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ---------- 每日喂食提醒（P5-3） ----------

  /// 排定/重排每日喂食提醒。
  /// - enabled=false：只取消喂食提醒（不动健康提醒）
  /// - Android：matchDateTimeComponents.time 每日重复，一次排定
  /// - Windows：预排未来 7 天的一次性通知（插件不支持周期调度），
  ///   每次启动/数据变化时由 resyncFeedReminder 重排滚动覆盖。
  static Future<void> resyncFeedReminder({
    required bool enabled,
    required int minutesOfDay,
    required List<Cat> cats,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _feedReminderId);
      if (!enabled || cats.isEmpty) return;

      final h = minutesOfDay ~/ 60;
      final m = minutesOfDay % 60;
      final catName = cats.length == 1 ? cats.first.name : '猫咪们';
      final title = '🍚 该给$catName喂饭啦';
      final body = '到点啦，看看小主子的饭碗空了没 🐾';

      if (Platform.isAndroid) {
        // 每日重复：排定下一次触发时间 + matchDateTimeComponents.time
        final now = tz.TZDateTime.now(tz.local);
        var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        if (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        final details = NotificationDetails(
          android: const AndroidNotificationDetails(
            _feedChannelId,
            _feedChannelName,
            channelDescription: _feedChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        );
        await _plugin.zonedSchedule(
          id: _feedReminderId,
          title: title,
          body: body,
          scheduledDate: next,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: null,
        );
      } else {
        // Windows：预排未来 7 天的一次性通知（同 id 逐个排会互相覆盖，
        // 所以每天用不同 id：_feedReminderId + dayOffset）
        final now = DateTime.now();
        for (var d = 0; d < _feedWindowsDays; d++) {
          final at = DateTime(now.year, now.month, now.day + d, h, m);
          if (!at.isAfter(now)) continue;
          await _schedule(
            id: _feedReminderId + d,
            at: at,
            title: title,
            body: body,
            channelId: _feedChannelId,
            channelName: _feedChannelName,
            channelDesc: _feedChannelDesc,
          );
        }
      }
    } catch (_) {
      // 排定失败静默
    }
  }

  /// 发送一条测试通知（设置弹层长按触发，用于验证通知链路真实可用）
  static Future<void> sendTestNotification() async {
    if (!_initialized) return;
    try {
      await _show(
        id: 1,
        title: '💊 测试通知',
        body: '喵！通知链路没问题，疫苗驱虫到期时会这样提醒你 🐾',
      );
    } catch (_) {}
  }

  /// 定时通知（未来某天 09:00）
  static Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String channelId = _channelId,
    String channelName = _channelName,
    String channelDesc = _channelDesc,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      windows: const WindowsNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: null,
    );
  }

  /// 立即通知
  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      windows: const WindowsNotificationDetails(),
    );
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }
}
