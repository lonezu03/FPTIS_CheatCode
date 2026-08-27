import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_session.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> schedules = [];
  bool loading = true;
  bool busy = false;
  Object? error;

  bool get canTodo => widget.user.isAdmin || widget.user.todoEnabled;
  bool get canSchedule => widget.user.isAdmin || widget.user.scheduleEnabled;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<ApiClient>();
      if (canTodo) {
        todos = _list(await api.get('/todos'));
      }
      if (canSchedule) {
        schedules = _list(await api.get('/schedule'));
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : [];

  Future<void> _createTodo() async {
    final controller = TextEditingController();
    final title = await _textDialog(
      title: 'Thêm việc cần làm',
      label: 'Tên công việc',
      controller: controller,
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post('/todos', data: {
        'title': title.trim(),
        'status': 'OPEN',
        'priority': 'MEDIUM',
        'reminderEnabled': false,
      });
      await _load();
      if (mounted) showMessage(context, 'Đã thêm việc cần làm.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _createSchedule() async {
    final controller = TextEditingController();
    final title = await _textDialog(
      title: 'Thêm lịch nhắc',
      label: 'Tên hoạt động',
      controller: controller,
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null || !mounted) return;
    final now = DateTime.now();
    final startAt = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post('/schedule', data: {
        'title': title.trim(),
        'category': 'PERSONAL',
        'startAt': startAt.toIso8601String().substring(0, 19),
        'repeatRule': 'NONE',
        'reminderMinutes': 10,
        'reminderEnabled': true,
        'enabled': true,
      });
      await _load();
      if (mounted) showMessage(context, 'Đã thêm lịch nhắc.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleTodo(Map<String, dynamic> todo, bool done) async {
    try {
      await context.read<ApiClient>().patch('/todos/${todo['id']}', data: {
        'title': todo['title'],
        'description': todo['description'],
        'status': done ? 'DONE' : 'OPEN',
        'priority': todo['priority'] ?? 'MEDIUM',
        'dueAt': todo['dueAt'],
        'reminderAt': todo['reminderAt'],
        'reminderEnabled': todo['reminderEnabled'] == true,
      });
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<String?> _textDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) => showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Tiếp tục'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null) return ErrorView(message: displayError(error!), onRetry: _load);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Lịch & việc',
                subtitle: 'Tập trung các việc cần làm và mốc nhắc trong ngày.',
              ),
              const SizedBox(height: 14),
              TabBar(
                controller: tabs,
                tabs: const [
                  Tab(text: 'Việc cần làm', icon: Icon(Icons.checklist_outlined)),
                  Tab(text: 'Thời khóa biểu', icon: Icon(Icons.event_note_outlined)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              canTodo ? _TodoList(items: todos, onAdd: _createTodo, onToggle: _toggleTodo, busy: busy, onReload: _load) : const _LockedPanel(label: 'Bạn chưa được cấp quyền Todo.'),
              canSchedule ? _ScheduleList(items: schedules, onAdd: _createSchedule, busy: busy, onReload: _load) : const _LockedPanel(label: 'Bạn chưa được cấp quyền Schedule.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({required this.items, required this.onAdd, required this.onToggle, required this.busy, required this.onReload});
  final List<Map<String, dynamic>> items;
  final VoidCallback onAdd;
  final Future<void> Function(Map<String, dynamic>, bool) onToggle;
  final bool busy;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onReload,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FilledButton.icon(onPressed: busy ? null : onAdd, icon: const Icon(Icons.add_task), label: const Text('Thêm việc cần làm')),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(icon: Icons.checklist_outlined, title: 'Chưa có việc', subtitle: 'Thêm một việc nhỏ để bắt đầu ngày rõ ràng hơn.')
        else
          ...items.map((todo) => Card(
            child: CheckboxListTile(
              value: todo['status'] == 'DONE',
              onChanged: busy ? null : (value) => onToggle(todo, value == true),
              title: Text(todo['title']?.toString() ?? 'Việc cần làm', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${todo['priority'] ?? 'MEDIUM'}${todo['dueAt'] != null ? ' • Hạn ${todo['dueAt']}' : ''}'),
            ),
          )),
      ],
    ),
  );
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.items, required this.onAdd, required this.busy, required this.onReload});
  final List<Map<String, dynamic>> items;
  final VoidCallback onAdd;
  final bool busy;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onReload,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FilledButton.icon(onPressed: busy ? null : onAdd, icon: const Icon(Icons.add_alarm), label: const Text('Thêm lịch nhắc')),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(icon: Icons.event_note_outlined, title: 'Chưa có lịch', subtitle: 'Tạo mốc nhắc để không bỏ quên việc quan trọng.')
        else
          ...items.map((item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.notifications_active_outlined)),
              title: Text(item['title']?.toString() ?? 'Hoạt động', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${item['startAt'] ?? ''} • Nhắc trước ${item['reminderMinutes'] ?? 10} phút'),
            ),
          )),
      ],
    ),
  );
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))));
}
