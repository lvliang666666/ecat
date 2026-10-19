// eCAT · 养猫 Agent 状态与持久化
// 四块数据：
// - API 配置列表：可保存多个 OpenAI 兼容服务（公司私有化 / DeepSeek / Kimi…），
//   手动点选当前生效的一个；Key 仅存本机 SharedPreferences
// - 长期记忆：跨会话沉淀的养猫事实（全局共享，不按猫隔离）
// - 会话历史：按 catId 隔离——每只猫独立聊天上下文，互不串；
//   无猫（或未指定）时走「通用」会话
// 与 CatStore/SettingsStore 同模式：ChangeNotifier + SharedPreferences。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一条对话消息
class AgentMessage {
  final String id;
  final String role; // user / assistant
  final String content;
  final DateTime time;

  const AgentMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'time': time.toIso8601String(),
      };

  factory AgentMessage.fromJson(Map<String, dynamic> j) => AgentMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        time: DateTime.parse(j['time'] as String),
      );
}

/// 一条长期记忆（跨会话沉淀的养猫事实，全局共享）
class AgentMemory {
  final String id;
  final String content;
  final DateTime createdAt;

  const AgentMemory({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'time': createdAt.toIso8601String(),
      };

  factory AgentMemory.fromJson(Map<String, dynamic> j) => AgentMemory(
        id: j['id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['time'] as String),
      );
}

/// 一个 API 配置（OpenAI 兼容服务）
class AgentApiConfig {
  final String id;
  final String name; // 展示名，如「公司 API」「DeepSeek」
  final String baseUrl;
  final String apiKey;
  final String model;

  const AgentApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  AgentApiConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) =>
      AgentApiConfig(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
      };

  factory AgentApiConfig.fromJson(Map<String, dynamic> j) => AgentApiConfig(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        baseUrl: j['baseUrl'] as String? ?? '',
        apiKey: j['apiKey'] as String? ?? '',
        model: j['model'] as String? ?? '',
      );
}

class AgentStore extends ChangeNotifier {
  // ---------- API 配置列表 ----------
  List<AgentApiConfig> _apis = [];
  String _activeApiId = ''; // 当前生效的 API id

  // ---------- 会话（按 catId 隔离）----------
  // key: catId 或 ''（通用会话），value: 消息列表
  Map<String, List<AgentMessage>> _threads = {};

  // ---------- 长期记忆（全局共享）----------
  List<AgentMemory> _memories = [];

  bool _loaded = false;

  List<AgentApiConfig> get apis => List.unmodifiable(_apis);
  String get activeApiId => _activeApiId;
  List<AgentMemory> get memories => List.unmodifiable(_memories);
  bool get loaded => _loaded;

  /// 当前生效的 API（未配置或 id 失效时为 null）
  AgentApiConfig? get activeApi {
    for (final a in _apis) {
      if (a.id == _activeApiId) return a;
    }
    return null;
  }

  /// 是否已配置可用 API（有至少一个配置且选中了生效项）
  bool get configured => activeApi != null;

  /// 取某只猫的会话消息（catId 为空 = 通用会话）
  List<AgentMessage> messagesOf(String catId) {
    final t = _threads[catId];
    return t == null ? const [] : List.unmodifiable(t);
  }

  /// 兼容旧接口：当前猫的会话由页面用 messagesOf 取
  List<AgentMessage> get messages => messagesOf('');

  // ---------- 持久化 key ----------
  static const _kApis = 'ecat_agent_apis';
  static const _kActiveApiId = 'ecat_agent_active_api';
  static const _kThreads = 'ecat_agent_threads';
  static const _kMemories = 'ecat_agent_memories';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _apis = _decodeList(sp.getString(_kApis), AgentApiConfig.fromJson);
    _activeApiId = sp.getString(_kActiveApiId) ?? '';
    // 选中项失效时回落到第一个
    if (activeApi == null && _apis.isNotEmpty) {
      _activeApiId = _apis.first.id;
    }
    _threads = _decodeThreads(sp.getString(_kThreads));
    _memories = _decodeList(sp.getString(_kMemories), AgentMemory.fromJson);
    _loaded = true;
    notifyListeners();
  }

  // ==================== API 配置管理 ====================

  /// 新增 API 配置并设为当前生效（首个配置自动生效）
  Future<void> addApi(AgentApiConfig config) async {
    _apis.add(config);
    if (_apis.length == 1) _activeApiId = config.id;
    await _persistApis();
    notifyListeners();
  }

  /// 更新 API 配置
  Future<void> updateApi(AgentApiConfig config) async {
    final i = _apis.indexWhere((a) => a.id == config.id);
    if (i == -1) return;
    _apis[i] = config;
    await _persistApis();
    notifyListeners();
  }

  /// 删除 API 配置；删的是当前生效项时回落到第一个
  Future<void> removeApi(String id) async {
    _apis.removeWhere((a) => a.id == id);
    if (_activeApiId == id) {
      _activeApiId = _apis.isEmpty ? '' : _apis.first.id;
    }
    await _persistApis();
    notifyListeners();
  }

  /// 切换当前生效的 API
  Future<void> setActiveApi(String id) async {
    if (!_apis.any((a) => a.id == id)) return;
    _activeApiId = id;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kActiveApiId, id);
    notifyListeners();
  }

  Future<void> _persistApis() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kApis, jsonEncode(_apis.map((a) => a.toJson()).toList()));
    await sp.setString(_kActiveApiId, _activeApiId);
  }

  // ==================== 会话（按 catId 隔离）====================

  /// 追加一条消息到指定猫的会话并持久化
  Future<void> addMessage(String catId, AgentMessage msg) async {
    (_threads[catId] ??= []).add(msg);
    await _persistThreads();
    notifyListeners();
  }

  /// 更新指定猫会话的最后一条消息内容（流式输出时逐段追加用）
  Future<void> updateLastMessage(String catId, String content) async {
    final t = _threads[catId];
    if (t == null || t.isEmpty) return;
    final last = t.last;
    t[t.length - 1] = AgentMessage(
      id: last.id,
      role: last.role,
      content: content,
      time: last.time,
    );
    notifyListeners(); // 流式过程中不落盘，结束时 persist
  }

  /// 流式结束后落盘
  Future<void> persistMessages(String catId) async {
    await _persistThreads();
    notifyListeners();
  }

  /// 清空指定猫的会话（长期记忆保留）
  Future<void> clearMessages(String catId) async {
    _threads.remove(catId);
    await _persistThreads();
    notifyListeners();
  }

  /// 删除猫咪时级联清理其会话（由 CatStore.photoDeleter 同款模式调用）
  Future<void> purgeCat(String catId) async {
    _threads.remove(catId);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> _persistThreads() async {
    final sp = await SharedPreferences.getInstance();
    final raw = <String, dynamic>{};
    _threads.forEach((k, v) {
      raw[k] = v.map((m) => m.toJson()).toList();
    });
    await sp.setString(_kThreads, jsonEncode(raw));
  }

  // ==================== 长期记忆（全局共享）====================

  /// 添加长期记忆（去重：内容相同不重复存）
  Future<void> addMemory(String content) async {
    final c = content.trim();
    if (c.isEmpty) return;
    if (_memories.any((m) => m.content == c)) return;
    _memories.add(AgentMemory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: c,
      createdAt: DateTime.now(),
    ));
    // 上限保护：最多 100 条，超出删最旧的
    while (_memories.length > 100) {
      _memories.removeAt(0);
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _kMemories, jsonEncode(_memories.map((m) => m.toJson()).toList()));
    notifyListeners();
  }

  /// 删除一条长期记忆
  Future<void> removeMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _kMemories, jsonEncode(_memories.map((m) => m.toJson()).toList()));
    notifyListeners();
  }

  // ==================== 反序列化工具 ====================

  Map<String, List<AgentMessage>> _decodeThreads(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map;
      final out = <String, List<AgentMessage>>{};
      map.forEach((k, v) {
        out[k as String] = (v as List)
            .map((e) => AgentMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) f) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
