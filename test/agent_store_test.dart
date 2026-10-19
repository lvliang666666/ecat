// P8 · Agent 多 API 配置 + 按猫独立会话 单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecat/store/agent_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AgentApiConfig api(String id, String name) => AgentApiConfig(
        id: id,
        name: name,
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'sk-$id',
        model: 'test-model',
      );

  group('多 API 配置管理', () {
    test('新增首个 API 自动设为当前生效', () async {
      final s = AgentStore();
      await s.load();
      expect(s.configured, isFalse);

      await s.addApi(api('a1', '公司 API'));
      expect(s.apis.length, 1);
      expect(s.activeApiId, 'a1');
      expect(s.configured, isTrue);
      expect(s.activeApi?.name, '公司 API');
    });

    test('新增第二个 API 不改变当前生效项', () async {
      final s = AgentStore();
      await s.load();
      await s.addApi(api('a1', '公司 API'));
      await s.addApi(api('a2', 'DeepSeek'));
      expect(s.apis.length, 2);
      expect(s.activeApiId, 'a1');
    });

    test('手动切换生效 API 并持久化', () async {
      final s = AgentStore();
      await s.load();
      await s.addApi(api('a1', '公司 API'));
      await s.addApi(api('a2', 'DeepSeek'));

      await s.setActiveApi('a2');
      expect(s.activeApi?.name, 'DeepSeek');

      // 重新 load 后仍保持
      final s2 = AgentStore();
      await s2.load();
      expect(s2.activeApiId, 'a2');
    });

    test('删除当前生效 API 回落到第一个', () async {
      final s = AgentStore();
      await s.load();
      await s.addApi(api('a1', '公司 API'));
      await s.addApi(api('a2', 'DeepSeek'));
      await s.setActiveApi('a2');

      await s.removeApi('a2');
      expect(s.apis.length, 1);
      expect(s.activeApiId, 'a1');
      expect(s.configured, isTrue);
    });

    test('删光所有 API 后 configured 为 false', () async {
      final s = AgentStore();
      await s.load();
      await s.addApi(api('a1', '公司 API'));
      await s.removeApi('a1');
      expect(s.apis, isEmpty);
      expect(s.configured, isFalse);
    });

    test('更新 API 配置保留 id', () async {
      final s = AgentStore();
      await s.load();
      await s.addApi(api('a1', '公司 API'));

      await s.updateApi(api('a1', '公司 API v2'));
      expect(s.apis.length, 1);
      expect(s.apis.first.name, '公司 API v2');
      expect(s.activeApiId, 'a1');
    });

    test('API 配置 JSON 往返', () {
      final c = api('x', '测试');
      final back = AgentApiConfig.fromJson(c.toJson());
      expect(back.id, 'x');
      expect(back.name, '测试');
      expect(back.baseUrl, c.baseUrl);
      expect(back.apiKey, c.apiKey);
      expect(back.model, c.model);
    });
  });

  group('按猫独立聊天上下文', () {
    AgentMessage msg(String role, String content) => AgentMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: role,
          content: content,
          time: DateTime.now(),
        );

    test('不同猫的会话互不干扰', () async {
      final s = AgentStore();
      await s.load();

      await s.addMessage('catA', msg('user', '咪咪今天吃什么'));
      await s.addMessage('catB', msg('user', '橘子今天吃什么'));

      expect(s.messagesOf('catA').length, 1);
      expect(s.messagesOf('catA').first.content, '咪咪今天吃什么');
      expect(s.messagesOf('catB').first.content, '橘子今天吃什么');
      expect(s.messagesOf('catC'), isEmpty); // 没聊过的猫是空会话
    });

    test('通用会话（catId 为空）独立存在', () async {
      final s = AgentStore();
      await s.load();

      await s.addMessage('', msg('user', '新手养猫要准备什么'));
      await s.addMessage('catA', msg('user', '咪咪今天吃什么'));

      expect(s.messages.length, 1); // 兼容 getter 走通用会话
      expect(s.messagesOf('catA').length, 1);
    });

    test('updateLastMessage 只改指定猫的最后一条', () async {
      final s = AgentStore();
      await s.load();
      await s.addMessage('catA', msg('assistant', ''));
      await s.addMessage('catB', msg('assistant', ''));

      await s.updateLastMessage('catA', '流式回复内容');

      expect(s.messagesOf('catA').last.content, '流式回复内容');
      expect(s.messagesOf('catB').last.content, '');
    });

    test('clearMessages 只清指定猫的会话', () async {
      final s = AgentStore();
      await s.load();
      await s.addMessage('catA', msg('user', 'a'));
      await s.addMessage('catB', msg('user', 'b'));

      await s.clearMessages('catA');
      expect(s.messagesOf('catA'), isEmpty);
      expect(s.messagesOf('catB').length, 1);
    });

    test('purgeCat 级联清理（删除猫咪场景）', () async {
      final s = AgentStore();
      await s.load();
      await s.addMessage('catA', msg('user', 'a'));
      await s.addMessage('catB', msg('user', 'b'));

      await s.purgeCat('catA');
      expect(s.messagesOf('catA'), isEmpty);
      expect(s.messagesOf('catB').length, 1);
    });

    test('会话按猫持久化与恢复', () async {
      final s = AgentStore();
      await s.load();
      await s.addMessage('catA', msg('user', '咪咪的话'));
      await s.addMessage('catB', msg('user', '橘子的话'));

      final s2 = AgentStore();
      await s2.load();
      expect(s2.messagesOf('catA').first.content, '咪咪的话');
      expect(s2.messagesOf('catB').first.content, '橘子的话');
    });
  });

  group('长期记忆（全局共享）', () {
    test('记忆不按猫隔离，去重生效', () async {
      final s = AgentStore();
      await s.load();

      await s.addMemory('咪咪对鸡肉过敏');
      await s.addMemory('咪咪对鸡肉过敏'); // 重复不存
      expect(s.memories.length, 1);

      await s.addMemory('橘子爱冻干');
      expect(s.memories.length, 2);
    });

    test('记忆上限 100 条，超出删最旧', () async {
      final s = AgentStore();
      await s.load();
      for (int i = 0; i < 105; i++) {
        await s.addMemory('事实 $i');
      }
      expect(s.memories.length, 100);
      expect(s.memories.first.content, '事实 5'); // 最旧的 5 条被挤掉
      expect(s.memories.last.content, '事实 104');
    });
  });
}
