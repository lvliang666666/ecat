// eCAT 全局状态与本地持久化
// 所有数据按 catId 隔离存储；切换当前猫咪即切换整套数据视图。
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';

class CatStore extends ChangeNotifier {
  List<Cat> _cats = [];
  String? _currentCatId;
  List<FeedLog> _feeds = [];
  List<WeightLog> _weights = [];
  List<HealthLog> _healths = [];
  bool _loaded = false;

  List<Cat> get cats => List.unmodifiable(_cats);
  Cat? get currentCat =>
      _cats.where((c) => c.id == _currentCatId).firstOrNull ?? _cats.firstOrNull;
  bool get loaded => _loaded;
  bool get isEmpty => _cats.isEmpty;

  // 当前猫咪的数据视图（已隔离）
  List<FeedLog> get feeds =>
      List.unmodifiable(_feeds.where((f) => f.catId == _currentCatId));
  List<WeightLog> get weights =>
      List.unmodifiable(_weights.where((w) => w.catId == _currentCatId));
  List<HealthLog> get healths =>
      List.unmodifiable(_healths.where((h) => h.catId == _currentCatId));

  // ---------- 按 catId 取数（查看类页面用，不依赖 currentCat） ----------

  List<FeedLog> feedsOf(String catId) =>
      List.unmodifiable(_feeds.where((f) => f.catId == catId));
  List<WeightLog> weightsOf(String catId) =>
      List.unmodifiable(_weights.where((w) => w.catId == catId));
  List<HealthLog> healthsOf(String catId) =>
      List.unmodifiable(_healths.where((h) => h.catId == catId));

  /// 指定猫咪的最新体重（日期升序取末位）
  WeightLog? latestWeightOf(String catId) {
    final ws = _weights.where((w) => w.catId == catId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return ws.isEmpty ? null : ws.last;
  }

  /// 指定猫咪某天的喂食记录（时间倒序）
  List<FeedLog> feedsOnOf(String catId, DateTime day) =>
      feedsOf(catId).where((f) => _sameDay(f.time, day)).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  /// 指定猫咪今日喂食总克数（饮水除外）
  double todayFoodGramsOf(String catId, [DateTime? now]) {
    final n = now ?? DateTime.now();
    return feedsOnOf(catId, n)
        .where((f) => f.type != '饮水')
        .fold(0.0, (s, f) => s + f.amount);
  }

  /// 指定猫咪的即将到期提醒（nextDue 升序，含已过期）
  List<HealthLog> upcomingRemindersOf(String catId) => healthsOf(catId)
      .where((h) => h.nextDue != null)
      .toList()
    ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));

  // ---------- 持久化 ----------
  static const _kCats = 'ecat_cats';
  static const _kCur = 'ecat_current_cat';
  static const _kFeeds = 'ecat_feeds';
  static const _kWeights = 'ecat_weights';
  static const _kHealths = 'ecat_healths';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _cats = _decodeList(sp.getString(_kCats), Cat.decode);
    _feeds = _decodeList(
        sp.getString(_kFeeds), (s) => FeedLog.fromJson(jsonDecode(s)));
    _weights = _decodeList(
        sp.getString(_kWeights), (s) => WeightLog.fromJson(jsonDecode(s)));
    _healths = _decodeList(
        sp.getString(_kHealths), (s) => HealthLog.fromJson(jsonDecode(s)));
    _currentCatId = sp.getString(_kCur);
    if (_currentCatId != null && !_cats.any((c) => c.id == _currentCatId)) {
      _currentCatId = null;
    }
    _loaded = true;
    notifyListeners();
  }

  List<T> _decodeList<T>(String? raw, T Function(String) f) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => f(jsonEncode(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _kCats, jsonEncode(_cats.map((c) => c.toJson()).toList()));
    await sp.setString(_kCur, _currentCatId ?? '');
    await sp.setString(
        _kFeeds, jsonEncode(_feeds.map((f) => f.toJson()).toList()));
    await sp.setString(
        _kWeights, jsonEncode(_weights.map((w) => w.toJson()).toList()));
    await sp.setString(
        _kHealths, jsonEncode(_healths.map((h) => h.toJson()).toList()));
  }

  // ---------- 猫咪档案管理 ----------
  Future<void> addCat(Cat cat) async {
    _cats.add(cat);
    _currentCatId = cat.id; // 新建后自动聚焦
    await _persist();
    notifyListeners();
  }

  Future<void> updateCat(Cat cat) async {
    final i = _cats.indexWhere((c) => c.id == cat.id);
    if (i >= 0) _cats[i] = cat;
    await _persist();
    notifyListeners();
  }

  Future<void> removeCat(String id) async {
    // 级联清理照片文件（在移除档案前取出文件名）
    final photo = _cats.where((c) => c.id == id).firstOrNull?.photoPath;
    _cats.removeWhere((c) => c.id == id);
    _feeds.removeWhere((f) => f.catId == id);
    _weights.removeWhere((w) => w.catId == id);
    _healths.removeWhere((h) => h.catId == id);
    if (_currentCatId == id) _currentCatId = _cats.firstOrNull?.id;
    await _persist();
    notifyListeners();
    if (photo != null) {
      // 延迟导入避免 store 层直接依赖 photo_store 造成循环；直接调用即可（无循环）
      await _deletePhoto(photo);
    }
  }

  /// 删除照片文件（失败静默）
  Future<void> _deletePhoto(String fileName) async {
    try {
      final photoStore = _photoStoreInstance;
      if (photoStore != null) await photoStore(fileName);
    } catch (_) {}
  }

  /// 照片删除回调（main.dart 注入，避免循环依赖）
  static Future<void> Function(String)? _photoStoreInstance;
  static set photoDeleter(Future<void> Function(String)? f) =>
      _photoStoreInstance = f;

  Future<void> selectCat(String id) async {
    if (_currentCatId == id) return;
    _currentCatId = id;
    await _persist();
    notifyListeners();
  }

  // ---------- 喂食 ----------
  Future<void> addFeed(FeedLog log) async {
    _feeds.add(log);
    await _persist();
    notifyListeners();
  }

  Future<void> removeFeed(String id) async {
    _feeds.removeWhere((f) => f.id == id);
    await _persist();
    notifyListeners();
  }

  // ---------- 体重 ----------
  Future<void> addWeight(WeightLog log) async {
    _weights
        .removeWhere((w) => w.catId == log.catId && _sameDay(w.date, log.date));
    _weights.add(log);
    _weights.sort((a, b) => a.date.compareTo(b.date));
    await _persist();
    notifyListeners();
  }

  Future<void> removeWeight(String id) async {
    _weights.removeWhere((w) => w.id == id);
    await _persist();
    notifyListeners();
  }

  // ---------- 健康 ----------
  Future<void> addHealth(HealthLog log) async {
    _healths.add(log);
    await _persist();
    notifyListeners();
  }

  Future<void> removeHealth(String id) async {
    _healths.removeWhere((h) => h.id == id);
    await _persist();
    notifyListeners();
  }

  // ---------- 数据备份：导出 / 导入 ----------

  /// 导出全部数据为 JSON（含所有猫咪及其全部记录），供备份/迁移。
  /// 返回的 Map 结构带 schema 版本号，便于未来格式升级时兼容旧备份。
  Map<String, dynamic> exportJson() => {
        'schema': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'cats': _cats.map((c) => c.toJson()).toList(),
        'currentCatId': _currentCatId,
        'feeds': _feeds.map((f) => f.toJson()).toList(),
        'weights': _weights.map((w) => w.toJson()).toList(),
        'healths': _healths.map((h) => h.toJson()).toList(),
      };

  /// 从备份 JSON 恢复全部数据（整体替换当前数据）。
  /// 校验 schema 与关键字段，格式不对抛 FormatException，由调用方提示用户。
  Future<void> importJson(Map<String, dynamic> data) async {
    final schema = data['schema'];
    if (schema is! int || schema > 1) {
      throw const FormatException('不支持的备份文件版本');
    }
    final cats = (data['cats'] as List?)
        ?.map((e) => Cat.decode(jsonEncode(e)))
        .toList();
    if (cats == null) {
      throw const FormatException('备份文件缺少猫咪档案');
    }
    final feeds = (data['feeds'] as List?)
            ?.map((e) => FeedLog.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final weights = (data['weights'] as List?)
            ?.map((e) => WeightLog.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final healths = (data['healths'] as List?)
            ?.map((e) => HealthLog.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    // 全部解析成功后才替换内存数据并持久化（避免半导入状态）
    _cats = cats;
    _feeds = feeds;
    _weights = weights;
    _healths = healths;
    final cur = data['currentCatId'];
    _currentCatId =
        (cur is String && _cats.any((c) => c.id == cur)) ? cur : _cats.firstOrNull?.id;
    await _persist();
    notifyListeners();
  }

  // ---------- 派生查询（当前猫咪） ----------
  List<FeedLog> feedsOn(DateTime day) =>
      feeds.where((f) => _sameDay(f.time, day)).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  WeightLog? get latestWeight {
    final ws = weights;
    return ws.isEmpty ? null : ws.last;
  }

  // 即将到期的健康提醒（按 nextDue 升序，含已过期）
  List<HealthLog> get upcomingReminders => healths
      .where((h) => h.nextDue != null)
      .toList()
    ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));

  // 今日喂食总克数（饮水除外）
  double todayFoodGrams([DateTime? now]) {
    final n = now ?? DateTime.now();
    return feedsOn(n)
        .where((f) => f.type != '饮水')
        .fold(0.0, (s, f) => s + f.amount);
  }

  /// 统计：最近 n 天的喂食总量（饮水除外），按天分组（key = yyyy-MM-dd）
  /// 返回 [每天克数, 每天记录数]；只含有记录的天
  Map<String, double> foodGramsByDay(int days, [DateTime? now]) {
    final catId = _currentCatId;
    if (catId == null) return {};
    return foodGramsByDayOf(catId, days, now);
  }

  /// 统计：指定猫咪最近 n 天喂食量按天分组
  Map<String, double> foodGramsByDayOf(String catId, int days, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day)
        .subtract(Duration(days: days - 1));
    final result = <String, double>{};
    for (final f in feedsOf(catId)) {
      if (f.type == '饮水') continue;
      final day = DateTime(f.time.year, f.time.month, f.time.day);
      if (day.isBefore(start)) continue;
      final key =
          '${f.time.year}-${f.time.month.toString().padLeft(2, '0')}-${f.time.day.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + f.amount;
    }
    return result;
  }

  /// 统计：最近 n 天喂食总量（饮水除外）
  double foodGramsInDays(int days, [DateTime? now]) {
    final catId = _currentCatId;
    if (catId == null) return 0;
    return foodGramsInDaysOf(catId, days, now);
  }

  /// 统计：指定猫咪最近 n 天喂食总量（饮水除外）
  double foodGramsInDaysOf(String catId, int days, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day)
        .subtract(Duration(days: days - 1));
    return feedsOf(catId)
        .where((f) =>
            f.type != '饮水' &&
            !DateTime(f.time.year, f.time.month, f.time.day).isBefore(start))
        .fold(0.0, (s, f) => s + f.amount);
  }

  /// 体重周报：最近 7 天内与上一个 7 天的体重对比。
  /// 返回 null 表示没有足够数据（最近 7 天无记录）。
  /// [latestInPeriod, diff]：diff = 最近体重 - 上期体重（上期无记录时为 null）
  (WeightLog, double?)? weeklyWeightReport([DateTime? now]) {
    final catId = _currentCatId;
    if (catId == null) return null;
    return weeklyWeightReportOf(catId, now);
  }

  /// 体重周报：指定猫咪版本
  (WeightLog, double?)? weeklyWeightReportOf(String catId, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    WeightLog? latest;
    for (final w in weightsOf(catId)) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      if (!day.isBefore(weekStart)) {
        if (latest == null || w.date.isAfter(latest.date)) latest = w;
      }
    }
    if (latest == null) return null;

    // 上期（8~14 天前）最新一条
    WeightLog? prev;
    for (final w in weightsOf(catId)) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      if (!day.isBefore(lastWeekStart) && day.isBefore(weekStart)) {
        if (prev == null || w.date.isAfter(prev.date)) prev = w;
      }
    }
    return (latest, prev == null ? null : latest.weight - prev.weight);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
