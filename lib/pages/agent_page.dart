// eCAT · 养猫 Agent 对话页
// 可爱风气泡流 + SSE 流式打字机效果 + 多 API 管理（手动切换）+ 长期记忆管理。
// 上下文：每只猫独立聊天会话（互不串），每次对话自动带上
// 当前猫咪档案/今日喂食/健康提醒 + 全局长期记忆。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/agent_service.dart';
import '../store/agent_store.dart';
import '../store/cat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 打开养猫助手对话页（知识页入口调用）
Future<void> openAgentPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AgentPage()),
  );
}

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // 等一帧让列表布局完成再滚
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final agentStore = context.read<AgentStore>();
    final catStore = context.read<CatStore>();
    final api = agentStore.activeApi;
    if (api == null) {
      await _openSettings();
      return;
    }
    final catId = catStore.currentCat?.id ?? '';

    final userMsg = AgentMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      time: DateTime.now(),
    );
    final replyId = '${DateTime.now().microsecondsSinceEpoch}r';
    _inputCtrl.clear();
    setState(() => _sending = true);
    await agentStore.addMessage(catId, userMsg);
    // 占位 assistant 消息（流式填充）
    await agentStore.addMessage(catId, AgentMessage(
      id: replyId,
      role: 'assistant',
      content: '',
      time: DateTime.now(),
    ));
    _scrollToBottom();

    try {
      // 流式累积：每个增量片段实时刷进占位消息（打字机效果）
      final buf = StringBuffer();
      await AgentService.chatStream(
        api: api,
        agentStore: agentStore,
        catStore: catStore,
        userText: text,
        onDelta: (delta) {
          buf.write(delta);
          agentStore.updateLastMessage(catId, buf.toString());
          _scrollToBottom();
        },
      );
      await agentStore.persistMessages(catId);

      // 记忆提取（后台轻量调用，不阻塞 UI）
      AgentService.extractMemories(
        api: api,
        userText: text,
        assistantReply: buf.toString(),
      ).then((facts) {
        for (final f in facts) {
          agentStore.addMemory(f);
        }
      });
    } catch (e) {
      // 失败：占位消息改为错误提示
      await agentStore.updateLastMessage(
        catId,
        '喵…我这边出了点问题：\n${e.toString().replaceFirst('Exception: ', '')}',
      );
      await agentStore.persistMessages(catId);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  /// API 管理弹窗（首次进入未配置时自动弹出）
  Future<void> _openSettings() async {
    await showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ApiListSheet(),
    );
  }

  /// 长期记忆管理弹窗
  Future<void> _openMemories() async {
    await showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MemorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentStore = context.watch<AgentStore>();
    final catStore = context.watch<CatStore>();
    final cat = catStore.currentCat;
    final catId = cat?.id ?? '';
    final messages = agentStore.messagesOf(catId);
    final api = agentStore.activeApi;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openSettings,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  cat == null ? '养猫助手' : '${cat.name}的助手',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              // 当前 API 小徽章：点击进管理
              if (api != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pinkLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    api.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkDeep,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 16, color: AppColors.textSub),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Text('🧠', style: TextStyle(fontSize: 18)),
            tooltip: '长期记忆',
            onPressed: _openMemories,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'API 管理',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: api == null
          ? _NotConfigured(onOpenSettings: _openSettings)
          : Column(
              children: [
                // 会话区（当前猫的独立会话）
                Expanded(
                  child: messages.isEmpty
                      ? _Welcome(catName: cat?.name)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: messages.length,
                          itemBuilder: (context, i) => _Bubble(
                            msg: messages[i],
                          ),
                        ),
                ),
                // 输入区
                _InputBar(
                  controller: _inputCtrl,
                  sending: _sending,
                  onSend: _send,
                ),
              ],
            ),
    );
  }
}

/// 未配置 API 的引导态
class _NotConfigured extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _NotConfigured({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐱💬', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '还没连接 AI 服务',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '可保存多个 API 随时切换，\n支持 OpenAI / DeepSeek / Kimi 等主流服务',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.5),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: PawButton(
                label: '去配置 API 🐾',
                icon: Icons.settings_rounded,
                onTap: onOpenSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 欢迎语（会话为空时）
class _Welcome extends StatelessWidget {
  final String? catName;
  const _Welcome({this.catName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              catName == null ? '你好呀，我是养猫助手' : '你好，$catName的家长',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '喂养困惑、行为解读、健康观察…\n关于小主子的都可以问我，我还记得 TA 的情况哦',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一条气泡
class _Bubble extends StatelessWidget {
  final AgentMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.pink : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser ? Colors.white : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

/// 输入区：圆角输入框 + 发送按钮
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: '问问养猫的事…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(sending: sending, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

/// 发送按钮（发送中转圈）
class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onSend;

  const _SendButton({required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return CuteTap(
      onTap: sending ? null : onSend,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.pink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: sending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ==================== API 管理弹窗（列表 + 编辑） ====================

/// API 列表：点条目切换生效，✏️ 编辑，长按删除，底部「新增」
class _ApiListSheet extends StatelessWidget {
  const _ApiListSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AgentStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API 管理 🤖',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '可保存多个服务，点条目切换当前使用；兼容 OpenAI 格式'
            '（OpenAI / DeepSeek / Kimi / 智谱 / 私有化部署…）',
            style: TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (store.apis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '还没有 API，先加一个吧 🐾',
                  style: TextStyle(fontSize: 13, color: AppColors.textSub),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: store.apis.length,
                itemBuilder: (context, i) {
                  final api = store.apis[i];
                  final active = api.id == store.activeApiId;
                  return CuteTap(
                    onTap: () async {
                      await store.setActiveApi(api.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      showCuteToast(context, '已切换到「${api.name}」🐾');
                    },
                    onLongPress: () => _confirmDelete(context, store, api),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.pinkLight.withValues(alpha: 0.7)
                            : AppColors.cream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppColors.pink : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            active ? '✅' : '⚪',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  api.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${api.model} · ${_hostOf(api.baseUrl)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSub,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          CuteTap(
                            onTap: () => _openEditor(context, store, api: api),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.edit_rounded,
                                  size: 18, color: AppColors.textSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          PawButton(
            label: '新增 API 🐾',
            icon: Icons.add_rounded,
            onTap: () => _openEditor(context, store),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, AgentStore store,
      {AgentApiConfig? api}) {
    showCuteSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ApiEditorSheet(existing: api),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AgentStore store, AgentApiConfig api) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这个 API？'),
        content: Text('「${api.name}」将被移除，不影响聊天记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) await store.removeApi(api.id);
  }

  static String _hostOf(String baseUrl) {
    try {
      return Uri.parse(baseUrl).host;
    } catch (_) {
      return baseUrl;
    }
  }
}

/// API 编辑弹窗（新增 / 编辑两用）
class _ApiEditorSheet extends StatefulWidget {
  final AgentApiConfig? existing;
  const _ApiEditorSheet({this.existing});

  @override
  State<_ApiEditorSheet> createState() => _ApiEditorSheetState();
}

class _ApiEditorSheetState extends State<_ApiEditorSheet> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _urlCtrl = TextEditingController(text: widget.existing?.baseUrl);
  late final _keyCtrl = TextEditingController(text: widget.existing?.apiKey);
  late final _modelCtrl = TextEditingController(text: widget.existing?.model);
  bool _testing = false;
  String? _result; // null = 未测，其他 = 结果文案

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  AgentApiConfig _buildConfig() => AgentApiConfig(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        baseUrl: _urlCtrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
        apiKey: _keyCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
      );

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      final msg = await AgentService.testConnection(_buildConfig());
      if (!mounted) return;
      setState(() => _result = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _result = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _urlCtrl.text.trim().isEmpty ||
        _keyCtrl.text.trim().isEmpty ||
        _modelCtrl.text.trim().isEmpty) {
      showCuteToast(context, '四项都要填哦');
      return;
    }
    final store = context.read<AgentStore>();
    final config = _buildConfig();
    if (widget.existing == null) {
      await store.addApi(config); // 新增自动设为生效
    } else {
      await store.updateApi(config);
    }
    if (!mounted) return;
    Navigator.pop(context);
    showCuteToast(context, 'API 已保存，开始聊天吧 🐾');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                widget.existing == null ? '新增 API 🤖' : '编辑 API ✏️',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: '名称，如 公司 API / DeepSeek',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                hintText: 'Base URL，如 https://api.deepseek.com/v1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'API Key（只存在本机，不会上传）',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                hintText: '模型名，如 deepseek-chat / gpt-4o-mini',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: const Text('测试连接'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pinkDeep,
                      side: BorderSide(color: AppColors.pink),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(
                _result!,
                style: TextStyle(
                  fontSize: 12,
                  color: _result!.contains('成功')
                      ? AppColors.mintDeep
                      : AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 16),
            PawButton(
              label: '保存 🐾',
              icon: Icons.check_rounded,
              onTap: _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ==================== 长期记忆管理 ====================

class _MemorySheet extends StatelessWidget {
  const _MemorySheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AgentStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '长期记忆 🧠',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '聊天中提到的重要事实会自动记在这里（所有猫共享），每次对话都会带上。长按条目删除。',
            style: TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (store.memories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '还没有记忆，聊聊天就有了 🐾',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: store.memories.length,
                itemBuilder: (context, i) {
                  final m = store.memories[i];
                  return CuteTap(
                    onLongPress: () => store.removeMemory(m.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSub),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
