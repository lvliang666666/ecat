// eCAT · 养猫 Agent 状态与持久化
// 三块数据：
// - API 配置：base URL / API Key / 模型名（用户自接主流 OpenAI 兼容服务）
// - 长期记忆：跨会话沉淀的养猫事实（如「咪咪对鸡肉过敏」），每次对话注入 system
// - 会话历史：对话消息列表（持久化，重进 App 可继续聊）
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

/// 一条长期记忆（跨会话沉淀的养猫事实）
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

class AgentStore extends ChangeNotifier {
  // ---------- API 配置 ----------
  String _baseUrl = '';
  String _apiKey = '';
  String _model = '';
  bool _configured = false;

  // ---------- 会话 ----------
  List<AgentMessage> _messages = [];

  // ---------- 长期记忆 ----------
  List<AgentMemory> _memories = [];

  bool _loaded = false;

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  String get model => _model;
  bool get configured => _configured;
  List<AgentMessage> get messages => List.unmodifiable(_messages);
  List<AgentMemory> get memories => List.unmodifiable(_memories);
  bool get loaded => _loaded;

  // ---------- 持久化 key ----------
  static const _kBaseUrl = 'ecat_agent_base_url';
  static const _kApiKey = 'ecat_agent_api_key';
  static const _kModel = 'ecat_agent_model';
  static const _kMessages = 'ecat_agent_messages';
  static const _kMemories = 'ecat_agent_memories';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _baseUrl = sp.getString(_kBaseUrl) ?? '';
    _apiKey = sp.getString(_kApiKey) ?? '';
    _model = sp.getString(_kModel) ?? '';
    _configured = _baseUrl.isNotEmpty && _apiKey.isNotEmpty && _model.isNotEmpty;
    _messages = _decodeList(sp.getString(_kMessages), AgentMessage.fromJson);
    _memories = _decodeList(sp.getString(_kMemories), AgentMemory.fromJson);
    _loaded = true;
    notifyListeners();
  }

  /// 保存 API 配置（base URL 允许带或不带 /v1，统一去掉尾部斜杠）
  Future<void> saveConfig({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _apiKey = apiKey.trim();
    _model = model.trim();
    _configured = _baseUrl.isNotEmpty && _apiKey.isNotEmpty && _model.isNotEmpty;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBaseUrl, _baseUrl);
    await sp.setString(_kApiKey, _apiKey);
    await sp.setString(_kModel, _model);
    notifyListeners();
  }

  /// 追加一条消息并持久化
  Future<void> addMessage(AgentMessage msg) async {
    _messages.add(msg);
    await _persistMessages();
    notifyListeners();
  }

  /// 更新最后一条消息内容（流式输出时逐段追加用）
  Future<void> updateLastMessage(String content) async {
    if (_messages.isEmpty) return;
    final last = _messages.last;
    _messages[_messages.length - 1] = AgentMessage(
      id: last.id,
      role: last.role,
      content: content,
      time: last.time,
    );
    notifyListeners(); // 流式过程中不落盘，结束时 persist
  }

  /// 流式结束后落盘
  Future<void> persistMessages() async {
    await _persistMessages();
    notifyListeners();
  }

  /// 清空当前会话（长期记忆保留）
  Future<void> clearMessages() async {
    _messages = [];
    await _persistMessages();
    notifyListeners();
  }

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

  Future<void> _persistMessages() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _kMessages, jsonEncode(_messages.map((m) => m.toJson()).toList()));
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
