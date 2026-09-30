import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <_ChatMessage>[
    const _ChatMessage(
      role: 'assistant',
      content: 'Chào bạn, tôi là FitTrack PT. Tôi có thể tư vấn và chuẩn bị buổi tập, bữa ăn hoặc đơn cơm để bạn xác nhận.',
    ),
  ];
  Map<String, dynamic>? privacy;
  Object? error;
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrivacy());
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacy() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await context.read<ApiClient>().get('/assistant/privacy');
      if (mounted)
        setState(() => privacy = Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setConsent(bool consented) async {
    try {
      final raw = await context.read<ApiClient>().put(
        '/assistant/privacy',
        data: {'consented': consented},
      );
      if (!mounted) return;
      setState(() {
        privacy = Map<String, dynamic>.from(raw as Map);
        if (!consented) {
          messages
            ..clear()
            ..add(
              const _ChatMessage(
                role: 'assistant',
                content: 'Dữ liệu trò chuyện đã được ngắt khỏi trợ lý AI.',
              ),
            );
        }
      });
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending || privacy?['consented'] != true) return;
    setState(() {
      messages.add(_ChatMessage(role: 'user', content: text));
      input.clear();
      sending = true;
    });
    _scrollToEnd();
    try {
      final payload = messages
          .map((message) => {'role': message.role, 'content': message.content})
          .toList();
      final raw = await context.read<ApiClient>().post(
        '/assistant/chat',
        data: {
          'messages': payload.length > 20
              ? payload.sublist(payload.length - 20)
              : payload,
        },
      );
      final response = Map<String, dynamic>.from(raw as Map);
      final action = response['proposedAction'];
      if (!mounted) return;
      setState(
        () => messages.add(
          _ChatMessage(
            role: 'assistant',
            content:
                response['reply']?.toString() ??
                'Tôi chưa có câu trả lời phù hợp.',
            action: action is Map ? Map<String, dynamic>.from(action) : null,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => messages.add(
            _ChatMessage(role: 'assistant', content: displayError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
      _scrollToEnd();
    }
  }

  Future<void> _execute(int index) async {
    final action = messages[index].action;
    if (action == null) return;
    try {
      final raw = await context.read<ApiClient>().post(
        '/assistant/actions/execute',
        data: {'type': action['type'], 'arguments': action['arguments'] ?? {}},
      );
      if (!mounted) return;
      final result = Map<String, dynamic>.from(raw as Map);
      setState(() {
        messages[index] = messages[index].copyWith(actionDone: true);
        messages.add(
          _ChatMessage(
            role: 'assistant',
            content: result['message']?.toString() ?? 'Đã cập nhật dữ liệu.',
          ),
        );
      });
      showMessage(context, 'Đã thực hiện sau khi bạn xác nhận.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _clearHistory() async {
    try {
      await context.read<ApiClient>().delete('/assistant/history');
      if (!mounted) return;
      setState(() {
        messages
          ..clear()
          ..add(
            const _ChatMessage(
              role: 'assistant',
              content: 'Đã xóa lịch sử trợ lý trên máy chủ.',
            ),
          );
      });
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const LoadingView(label: 'Đang kiểm tra quyền riêng tư...');
    if (error != null)
      return ErrorView(message: displayError(error!), onRetry: _loadPrivacy);
    final consented = privacy?['consented'] == true;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
          child: Row(
            children: [
              const Expanded(
                child: PageIntro(
                  title: 'FitTrack PT',
                  subtitle: 'Trợ lý chỉ thao tác dữ liệu sau khi bạn xác nhận.',
                ),
              ),
              IconButton(
                tooltip: 'Xóa lịch sử',
                onPressed: consented ? _clearHistory : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        if (!consented)
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Cho phép sử dụng trợ lý AI?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'FitTrack chỉ gửi dữ liệu cần thiết cho câu hỏi hiện tại tới Gemini; không gửi email hoặc tên của bạn.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _setConsent(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Tôi đồng ý'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else ...[
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length + (sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final message = messages[index];
                final mine = message.role == 'user';
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: mine
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(color: mine ? Colors.white : null),
                        ),
                        if (message.action != null && !message.actionDone) ...[
                          const SizedBox(height: 10),
                          Text(
                            message.action!['summary']?.toString() ??
                                'Thao tác được đề xuất',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => _execute(index),
                                child: const Text('Xác nhận thực hiện'),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => messages[index] = message.copyWith(
                                    actionDone: true,
                                  ),
                                ),
                                child: const Text('Bỏ qua'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi hoặc yêu cầu...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.content,
    this.action,
    this.actionDone = false,
  });

  final String role;
  final String content;
  final Map<String, dynamic>? action;
  final bool actionDone;

  _ChatMessage copyWith({bool? actionDone}) => _ChatMessage(
    role: role,
    content: content,
    action: action,
    actionDone: actionDone ?? this.actionDone,
  );
}
