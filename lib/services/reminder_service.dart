// eCAT · 本地提醒通知服务
// 疫苗/驱虫等健康事项 nextDue 到期时发系统通知：
// - Android：zonedSchedule 定时到到期日 09:00（inexactAllowWhileIdle，免精确闹钟权限）
// - Windows：同样支持一次性定时调度（插件原生实现），与 Android 统一走定时路径；
//   另在启动/数据变化时对「今天到期或已过期且未提醒过」的条目立即补发一条，
//   覆盖「应用没在运行时定时通知丢失」的场景（Windows 非常驻进程尤其需要）。
// 去重：每条 HealthLog 只补发一次，标记存 SharedPreferences（ecat_notified_<logId>）。
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/cat.dart';

class ReminderService {
  ReminderService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 通知渠道（Android）
  static const _channelId = 'ecat_health_reminders';
  static const _channelName = '健康提醒';
  static const _channelDesc = '疫苗、驱虫等健康事项到期提醒';

  /// Windows 通知的应用标识（固定 GUID 标识本应用的 toast）
  static const _winAppName = 'eCAT 喵喵管家';
  static const _winAppUserModelId = 'com.lvproject.ecat';
  static const _winGuid = '7C9E6D8A-3B24-4F5E-9A81-2D6C0B4E7F13';

  /// 提醒通知 id 基数：与未来可能的其他通知类型区分
  static int _idOf(String logId) => logId.hashCode & 0x7fffffff;

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

  /// 全量重排：取消全部已排定通知，按当前健康记录重新排定未来的提醒。
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
    } catch (_) {
      // 排定失败静默（如 Windows 无包身份时的部分限制）
    }
  }

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
    } catch (_) {
      // 补发失败静默
    }
  }

  /// 清除全部「已补发」标记（导入恢复后调用，让旧提醒重新可补发）
  static Future<void> clearNotifiedMarks() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final keys = sp.getKeys().where((k) => k.startsWith('ecat_notified_'));
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

  /// 定时通知（未来某天 09:00）
  static Future<void> _schedule({
    required int id,
    required DateTime at,
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
