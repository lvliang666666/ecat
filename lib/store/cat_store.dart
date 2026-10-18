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
    _cats.removeWhere((c) => c.id == id);
    _feeds.removeWhere((f) => f.catId == id);
    _weights.removeWhere((w) => w.catId == id);
    _healths.removeWhere((h) => h.catId == id);
    if (_currentCatId == id) _currentCatId = _cats.firstOrNull?.id;
    await _persist();
    notifyListeners();
  }

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

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
