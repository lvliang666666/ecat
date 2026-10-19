// eCAT · 养猫 Agent 服务
// OpenAI 兼容协议（/v1/chat/completions），SSE 流式输出（打字机效果）。
// 上下文注入：
// - 系统提示词：养猫专家人设 + App 数据快照（当前猫档案/今日喂食/健康提醒）
// - 长期记忆：跨会话沉淀的养猫事实（全局共享），注入 system
// - 近期对话：当前猫的独立会话历史（每猫不串）
// 记忆提取：每轮对话后让模型判断是否值得记住（独立轻量调用，非流式）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../store/agent_store.dart';
import '../store/cat_store.dart';

class AgentService {
  AgentService._();

  static const _timeout = Duration(seconds: 60);

  /// 养猫专家人设 + App 数据快照
  static String buildSystemPrompt(CatStore catStore, AgentStore agentStore) {
    final buf = StringBuffer();
    buf.write('你是「喵喵管家」App 里的养猫助手，一位温柔、专业、有耐心的养猫专家。'
        '回答要口语化、亲切，适当用 emoji，避免过长段落。'
        '涉及疾病症状时给出观察建议，但始终提醒：异常持续请及时就医，你不替代兽医。\n');

    // App 数据快照（当前记录对象的猫）
    final cat = catStore.currentCat;
    if (cat != null) {
      buf.write('\n【当前猫咪档案】\n');
      buf.write('- 名字：${cat.name}（${cat.gender}，${cat.ageText()}）\n');
      buf.write('- 品种：${cat.breed}，毛色：${cat.furColor}\n');
      if (cat.neutered) buf.write('- 已绝育\n');
      final w = catStore.latestWeightOf(cat.id);
      if (w != null) {
        buf.write('- 最新体重：${w.weight} kg'
            '（${w.date.month}/${w.date.day} 记录）\n');
      }
      if (cat.targetWeight != null) {
        buf.write('- 目标体重：${cat.targetWeight} kg\n');
      }
      buf.write('- 每日喂食目标：${cat.dailyFoodGoal} g\n');
      if (cat.allergies.isNotEmpty) {
        buf.write('- ⚠️ 过敏/禁忌：${cat.allergies.join('、')}\n');
      }
      if (cat.notes.isNotEmpty) buf.write('- 备注：${cat.notes}\n');

      // 今日喂食
      final now = DateTime.now();
      final grams = catStore.todayFoodGramsOf(cat.id, now);
      final feeds = catStore.feedsOnOf(cat.id, now);
      buf.write('\n【今日喂食】已喂 ${grams.toStringAsFixed(0)} g'
          '（目标 ${cat.dailyFoodGoal} g），共 ${feeds.length} 笔\n');
      for (final f in feeds.take(5)) {
        buf.write('- ${f.type} ${f.amount} g（${f.time.hour}:${f.time.minute.toString().padLeft(2, '0')}）\n');
      }

      // 即将到期的健康提醒
      final reminders = catStore.upcomingRemindersOf(cat.id).take(3).toList();
      if (reminders.isNotEmpty) {
        buf.write('\n【健康提醒】\n');
        for (final h in reminders) {
          final due = h.nextDue!;
          buf.write('- ${h.title}：${due.month}/${due.day} 到期\n');
        }
      }
    }

    // 长期记忆
    if (agentStore.memories.isNotEmpty) {
      buf.write('\n【你记住的长期记忆】\n');
      for (final m in agentStore.memories) {
        buf.write('- ${m.content}\n');
      }
    }

    buf.write('\n回答时优先结合以上信息，让建议贴合这只猫的实际情况。');
    return buf.toString();
  }

  /// 流式对话：逐段回调增量文本（SSE data: {...} 解析）。
  /// 返回完整回复文本；失败抛异常由调用方提示。
  static Future<String> chatStream({
    required AgentApiConfig api,
    required AgentStore agentStore,
    required CatStore catStore,
    required String userText,
    required void Function(String delta) onDelta,
  }) async {
    final url = Uri.parse('${api.baseUrl}/chat/completions');
    final history = agentStore.messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final body = jsonEncode({
      'model': api.model,
      'messages': [
        {'role': 'system', 'content': buildSystemPrompt(catStore, agentStore)},
        ...history,
        {'role': 'user', 'content': userText},
      ],
      'stream': true,
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer ${api.apiKey}'
        ..body = body;

      final response =
          await client.send(request).timeout(_timeout);

      if (response.statusCode != 200) {
        final err = await response.stream.bytesToString();
        throw Exception('API ${response.statusCode}: ${_shortError(err)}');
      }

      final full = StringBuffer();
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices.first as Map<String, dynamic>)['delta']
                  as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            full.write(content);
            onDelta(content);
          }
        } catch (_) {
          // 单行解析失败跳过（心跳/注释行等）
        }
      }
      return full.toString();
    } finally {
      client.close();
    }
  }

  /// 记忆提取：让模型从这轮对话中判断是否值得长期记住。
  /// 返回要记住的事实列表（可能为空）；失败静默返回空（不打断对话）。
  static Future<List<String>> extractMemories({
    required AgentApiConfig api,
    required String userText,
    required String assistantReply,
  }) async {
    try {
      final url = Uri.parse('${api.baseUrl}/chat/completions');
      final body = jsonEncode({
        'model': api.model,
        'messages': [
          {
            'role': 'system',
            'content': '你从养猫对话中提取值得长期记住的事实（如猫咪偏好、过敏、'
                '健康状况、生活习惯、主人的喂养安排）。只输出事实列表，每行一条，'
                '不超过 3 条；没有值得记的就输出空。不要输出任何解释或序号。',
          },
          {
            'role': 'user',
            'content': '主人说：$userText\n\n你回答了：$assistantReply\n\n'
                '提取值得长期记住的事实：',
          },
        ],
        'stream': false,
        'max_tokens': 200,
      });

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${api.apiKey}',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return [];
      final content =
          ((choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>)['content'] as String? ?? '';

      return content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && l.length > 2 && l.length < 100)
          .take(3)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 测试 API 连通性（设置页保存前验证）
  static Future<String> testConnection(AgentApiConfig api) async {
    final url = Uri.parse('${api.baseUrl}/chat/completions');
    final body = jsonEncode({
      'model': api.model,
      'messages': [
        {'role': 'user', 'content': '喵'}
      ],
      'max_tokens': 5,
    });
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${api.apiKey}',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) return '连接成功 🎉';
    throw Exception('API ${response.statusCode}: ${_shortError(response.body)}');
  }

  /// 错误信息截断（避免弹超长 JSON）
  static String _shortError(String raw) {
    final s = raw.trim();
    if (s.length <= 120) return s;
    return '${s.substring(0, 120)}…';
  }
}
