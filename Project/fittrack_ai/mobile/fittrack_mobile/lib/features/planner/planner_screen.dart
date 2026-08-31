import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_session.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
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
  Object? todoError;
  Object? scheduleError;
  String todoView = 'TODAY';
  String todoStatus = 'ALL';
  String todoCategory = 'ALL';

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
    if (mounted) {
      setState(() {
        loading = true;
        todoError = null;
        scheduleError = null;
      });
    }
    final api = context.read<ApiClient>();
    if (canTodo) {
      try {
        todos = _list(await api.get('/todos'));
      } catch (e) {
        todoError = e;
      }
    }
    if (canSchedule) {
      try {
        schedules = await _loadCalendar(api);
      } catch (e) {
        scheduleError = e;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<List<Map<String, dynamic>>> _loadCalendar(ApiClient api) async {
    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now().add(const Duration(days: 365));
    try {
      return _list(
        await api.get(
          '/schedule/calendar',
          queryParameters: {'from': _iso(from), 'to': _iso(to)},
        ),
      );
    } on ApiException catch (calendarError) {
      if (calendarError.statusCode == 401 || calendarError.statusCode == 403) {
        rethrow;
      }
      try {
        final legacy = _list(await api.get('/schedule'));
        return legacy.map(_legacyScheduleEntry).toList();
      } catch (_) {
        throw calendarError;
      }
    }
  }

  static Map<String, dynamic> _legacyScheduleEntry(Map<String, dynamic> item) =>
      {
        ...item,
        'occurrenceId': 'EVENT:${item['id']}',
        'sourceType': 'EVENT',
        'sourceId': item['id'],
        'status': item['enabled'] == false ? 'DISABLED' : 'ACTIVE',
        'recurring': item['repeatRule'] != null && item['repeatRule'] != 'NONE',
      };

  static List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : [];

  Future<void> _saveTodo(Map<String, dynamic> payload, {String? id}) async {
    setState(() => busy = true);
    try {
      final api = context.read<ApiClient>();
      if (id == null) {
        await api.post('/todos', data: payload);
      } else {
        await api.patch('/todos/$id', data: payload);
      }
      await _load();
      if (mounted)
        showMessage(
          context,
          id == null ? 'Đã thêm việc cần làm.' : 'Đã cập nhật công việc.',
        );
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openTodoEditor([Map<String, dynamic>? todo]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _TodoEditorDialog(todo: todo),
    );
    if (result == null || !mounted) return;
    await _saveTodo(result, id: todo?['id']?.toString());
  }

  Future<void> _createTodo() => _openTodoEditor();

  Future<void> _deleteTodo(Map<String, dynamic> todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text(
          'Bạn có chắc muốn xóa “${todo['title'] ?? 'công việc này'}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().delete('/todos/${todo['id']}');
      await _load();
      if (mounted) showMessage(context, 'Đã xóa công việc.');
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
      await context.read<ApiClient>().post(
        '/schedule',
        data: {
          'title': title.trim(),
          'category': 'PERSONAL',
          'startAt': _iso(startAt),
          'repeatRule': 'NONE',
          'reminderMinutes': 10,
          'reminderEnabled': true,
          'enabled': true,
        },
      );
      await _load();
      if (mounted) showMessage(context, 'Đã thêm lịch nhắc.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleTodo(Map<String, dynamic> todo, bool done) async {
    if (done) {
      setState(() => busy = true);
      try {
        final api = context.read<ApiClient>();
        try {
          await api.post('/todos/${todo['id']}/complete');
        } on ApiException catch (error) {
          if (error.statusCode != 404 && error.statusCode != 405) rethrow;
          await api.patch(
            '/todos/${todo['id']}',
            data: _todoPayload(todo, status: 'DONE'),
          );
        }
        await _load();
      } catch (e) {
        if (mounted) showMessage(context, displayError(e), error: true);
      } finally {
        if (mounted) setState(() => busy = false);
      }
      return;
    }
    await _saveTodo(
      _todoPayload(todo, status: 'OPEN'),
      id: todo['id']?.toString(),
    );
  }

  Future<void> _skipTodo(Map<String, dynamic> todo) async {
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post('/todos/${todo['id']}/skip');
      await _load();
      if (mounted)
        showMessage(context, 'Đã bỏ qua lần này; lịch tiếp theo vẫn được giữ.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
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

  List<Map<String, dynamic>> get filteredTodos {
    final today = _dateKey(DateTime.now());
    return todos.where((todo) {
      final date = _dateKey(
        _parseDate(todo['dueAt']) ?? _parseDate(todo['startAt']),
      );
      final due = _parseDate(todo['dueAt']);
      final isDone = todo['status'] == 'DONE';
      final matchesView =
          todoView == 'ALL' ||
          (todoView == 'TODAY' && date == today) ||
          (todoView == 'OVERDUE' &&
              !isDone &&
              due != null &&
              due.isBefore(DateTime.now())) ||
          (todoView == 'UPCOMING' && date.compareTo(today) > 0);
      final matchesStatus = todoStatus == 'ALL' || todo['status'] == todoStatus;
      final matchesCategory =
          todoCategory == 'ALL' || todo['category'] == todoCategory;
      return matchesView && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Lịch & việc',
                subtitle: 'Lập kế hoạch với deadline, lời nhắc, lặp lại và checklist.',
              ),
              const SizedBox(height: 14),
              TabBar(
                controller: tabs,
                tabs: const [
                  Tab(
                    text: 'Việc cần làm',
                    icon: Icon(Icons.checklist_outlined),
                  ),
                  Tab(
                    text: 'Thời khóa biểu',
                    icon: Icon(Icons.event_note_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              canTodo
                  ? todoError == null
                        ? _TodoList(
                            items: filteredTodos,
                            allItems: todos,
                            view: todoView,
                            status: todoStatus,
                            category: todoCategory,
                            onViewChanged: (value) =>
                                setState(() => todoView = value),
                            onStatusChanged: (value) =>
                                setState(() => todoStatus = value),
                            onCategoryChanged: (value) =>
                                setState(() => todoCategory = value),
                            onAdd: _createTodo,
                            onEdit: _openTodoEditor,
                            onDelete: _deleteTodo,
                            onToggle: _toggleTodo,
                            onSkip: _skipTodo,
                            busy: busy,
                            onReload: _load,
                          )
                        : ErrorView(
                            message: displayError(todoError!),
                            onRetry: _load,
                          )
                  : const _LockedPanel(label: 'Bạn chưa được cấp quyền Todo.'),
              canSchedule
                  ? scheduleError == null
                        ? _ScheduleList(
                            items: schedules,
                            onAdd: _createSchedule,
                            busy: busy,
                            onReload: _load,
                          )
                        : ErrorView(
                            message: displayError(scheduleError!),
                            onRetry: _load,
                          )
                  : const _LockedPanel(
                      label: 'Bạn chưa được cấp quyền Schedule.',
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.items,
    required this.allItems,
    required this.view,
    required this.status,
    required this.category,
    required this.onViewChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onSkip,
    required this.busy,
    required this.onReload,
  });
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> allItems;
  final String view;
  final String status;
  final String category;
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAdd;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Future<void> Function(Map<String, dynamic>, bool) onToggle;
  final Future<void> Function(Map<String, dynamic>) onSkip;
  final bool busy;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final today = _dateKey(DateTime.now());
    final todayCount = allItems
        .where(
          (item) =>
              _dateKey(
                _parseDate(item['dueAt']) ?? _parseDate(item['startAt']),
              ) ==
              today,
        )
        .length;
    final overdueCount = allItems
        .where(
          (item) =>
              item['status'] != 'DONE' &&
              (_parseDate(item['dueAt'])?.isBefore(DateTime.now()) ?? false),
        )
        .length;
    final upcomingCount = allItems
        .where(
          (item) =>
              _dateKey(_parseDate(item['dueAt']) ?? _parseDate(item['startAt']))
                  .compareTo(today) >
              0,
        )
        .length;
    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: items.isEmpty ? 4 : items.length + 3,
        itemBuilder: (context, index) {
          if (index == 0)
            return _TodoSummary(
              today: todayCount,
              overdue: overdueCount,
              upcoming: upcomingCount,
              done: allItems.where((item) => item['status'] == 'DONE').length,
            );
          if (index == 1)
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.icon(
                onPressed: busy ? null : onAdd,
                icon: const Icon(Icons.add_task),
                label: const Text('Thêm việc cần làm'),
              ),
            );
          if (index == 2)
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TodoFilters(
                view: view,
                status: status,
                category: category,
                onViewChanged: onViewChanged,
                onStatusChanged: onStatusChanged,
                onCategoryChanged: onCategoryChanged,
              ),
            );
          if (items.isEmpty)
            return const EmptyView(
              icon: Icons.checklist_outlined,
              title: 'Chưa có việc trong chế độ này',
              subtitle:
                  'Tạo một việc mới hoặc đổi bộ lọc để xem kế hoạch khác.',
            );
          final todo = items[index - 3];
          return _TodoCard(
            todo: todo,
            busy: busy,
            onEdit: () => onEdit(todo),
            onDelete: () => onDelete(todo),
            onToggle: (done) => onToggle(todo, done),
            onSkip: () => onSkip(todo),
          );
        },
      ),
    );
  }
}

class _TodoSummary extends StatelessWidget {
  const _TodoSummary({
    required this.today,
    required this.overdue,
    required this.upcoming,
    required this.done,
  });
  final int today;
  final int overdue;
  final int upcoming;
  final int done;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryChip(
            icon: Icons.today_outlined,
            label: 'Hôm nay',
            value: today.toString(),
            color: Colors.green,
          ),
          _SummaryChip(
            icon: Icons.warning_amber_outlined,
            label: 'Quá hạn',
            value: overdue.toString(),
            color: Colors.red,
          ),
          _SummaryChip(
            icon: Icons.upcoming_outlined,
            label: 'Sắp tới',
            value: upcoming.toString(),
            color: Colors.blue,
          ),
          _SummaryChip(
            icon: Icons.check_circle_outline,
            label: 'Đã xong',
            value: done.toString(),
            color: Colors.deepPurple,
          ),
        ],
      ),
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(
          '$label $value',
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

class _TodoFilters extends StatelessWidget {
  const _TodoFilters({
    required this.view,
    required this.status,
    required this.category,
    required this.onViewChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });
  final String view;
  final String status;
  final String category;
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['TODAY', 'OVERDUE', 'UPCOMING', 'ALL']
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_viewLabel(item)),
                    selected: view == item,
                    onSelected: (_) => onViewChanged(item),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Mọi trạng thái')),
                DropdownMenuItem(value: 'OPEN', child: Text('Chưa làm')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Đang làm')),
                DropdownMenuItem(value: 'DONE', child: Text('Đã xong')),
              ],
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Mọi danh mục')),
                DropdownMenuItem(value: 'WORK', child: Text('Công việc')),
                DropdownMenuItem(value: 'STUDY', child: Text('Học tập')),
                DropdownMenuItem(value: 'PERSONAL', child: Text('Cá nhân')),
                DropdownMenuItem(value: 'HEALTH', child: Text('Sức khỏe')),
                DropdownMenuItem(value: 'FINANCE', child: Text('Tài chính')),
                DropdownMenuItem(value: 'SHOPPING', child: Text('Mua sắm')),
              ],
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
          ),
        ],
      ),
    ],
  );
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onSkip,
  });
  final Map<String, dynamic> todo;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSkip;
  @override
  Widget build(BuildContext context) {
    final subtasks = _subtasks(todo);
    final doneCount = subtasks
        .where((item) => item['completed'] == true)
        .length;
    final due = _parseDate(todo['dueAt']);
    final overdue =
        todo['status'] != 'DONE' && due != null && due.isBefore(DateTime.now());
    return Card(
      color: overdue ? Colors.red.shade50 : null,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: todo['status'] == 'DONE',
              onChanged: busy ? null : (value) => onToggle(value == true),
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo['title']?.toString() ?? 'Việc cần làm',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: todo['status'] == 'DONE'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(_priorityLabel(todo['priority'])),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(_categoryLabel(todo['category'])),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (todo['estimatedMinutes'] != null)
                            Chip(
                              avatar: const Icon(
                                Icons.timer_outlined,
                                size: 15,
                              ),
                              label: Text('${todo['estimatedMinutes']} phút'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      if (todo['startAt'] != null ||
                          todo['dueAt'] != null ||
                          todo['reminderEnabled'] == true)
                        Text(
                          [
                            if (todo['startAt'] != null)
                              'Bắt đầu ${_dateLabel(todo['startAt'])}',
                            if (todo['dueAt'] != null)
                              'Hạn ${_dateLabel(todo['dueAt'])}',
                            if (todo['reminderEnabled'] == true)
                              'Nhắc ${_dateLabel(todo['reminderAt'])}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: overdue
                                ? Colors.red.shade700
                                : Colors.black54,
                          ),
                        ),
                      if (todo['recurrenceRule'] != null &&
                          todo['recurrenceRule'] != 'NONE')
                        Text(
                          'Lặp ${_recurrenceLabel(todo)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple,
                          ),
                        ),
                      if (subtasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Checklist: $doneCount/${subtasks.length} bước',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (todo['recurrenceRule'] != null &&
                todo['recurrenceRule'] != 'NONE' &&
                todo['status'] != 'DONE' &&
                todo['status'] != 'SKIPPED')
              IconButton(
                onPressed: busy ? null : onSkip,
                icon: const Icon(Icons.skip_next_outlined),
                tooltip: 'Bỏ qua lần này',
              ),
            IconButton(
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa',
            ),
            IconButton(
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa',
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoEditorDialog extends StatefulWidget {
  const _TodoEditorDialog({this.todo});
  final Map<String, dynamic>? todo;
  @override
  State<_TodoEditorDialog> createState() => _TodoEditorDialogState();
}

class _TodoEditorDialogState extends State<_TodoEditorDialog> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController durationController;
  late final TextEditingController intervalController;
  late final TextEditingController maxOccurrencesController;
  DateTime? startAt;
  DateTime? dueAt;
  DateTime? reminderAt;
  String priority = 'MEDIUM';
  String category = 'PERSONAL';
  String recurrence = 'NONE';
  String recurrenceBasis = 'SCHEDULED_DATE';
  DateTime? recurrenceEndAt;
  bool reminderEnabled = false;
  List<String> days = [];
  List<Map<String, dynamic>> subtasks = [];

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    titleController = TextEditingController(
      text: todo?['title']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: todo?['description']?.toString() ?? '',
    );
    durationController = TextEditingController(
      text: todo?['estimatedMinutes']?.toString() ?? '',
    );
    intervalController = TextEditingController(
      text: todo?['recurrenceInterval']?.toString() ?? '1',
    );
    maxOccurrencesController = TextEditingController(
      text: todo?['recurrenceMaxOccurrences']?.toString() ?? '',
    );
    startAt = _parseDate(todo?['startAt']);
    dueAt = _parseDate(todo?['dueAt']);
    reminderAt = _parseDate(todo?['reminderAt']);
    priority = todo?['priority']?.toString() ?? 'MEDIUM';
    category = todo?['category']?.toString() ?? 'PERSONAL';
    recurrence = todo?['recurrenceRule']?.toString() ?? 'NONE';
    recurrenceBasis = todo?['recurrenceBasis']?.toString() ?? 'SCHEDULED_DATE';
    recurrenceEndAt = _parseDate(todo?['recurrenceEndAt']);
    reminderEnabled = todo?['reminderEnabled'] == true;
    days = _stringList(todo?['daysOfWeek']);
    subtasks = _subtasks(todo ?? {})
        .map(
          (item) => {
            'title': item['title']?.toString() ?? '',
            'completed': item['completed'] == true,
          },
        )
        .toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    intervalController.dispose();
    maxOccurrencesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = initial ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    if (startAt != null && dueAt != null && startAt!.isAfter(dueAt!)) return;
    final items = subtasks
        .asMap()
        .entries
        .where((entry) => entry.value['title'].toString().trim().isNotEmpty)
        .map(
          (entry) => {
            'title': entry.value['title'].toString().trim(),
            'completed': entry.value['completed'] == true,
            'sortOrder': entry.key,
          },
        )
        .toList();
    Navigator.pop(context, {
      'title': title,
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'status': widget.todo?['status']?.toString() ?? 'OPEN',
      'priority': priority,
      'startAt': _iso(startAt),
      'dueAt': _iso(dueAt),
      'estimatedMinutes': durationController.text.trim().isEmpty
          ? null
          : int.tryParse(durationController.text.trim()),
      'category': category,
      'recurrenceRule': recurrence,
      'recurrenceInterval': int.tryParse(intervalController.text.trim()) ?? 1,
      'daysOfWeek': days.join(','),
      'recurrenceBasis': recurrenceBasis,
      'recurrenceEndAt': _iso(recurrenceEndAt),
      'recurrenceMaxOccurrences': maxOccurrencesController.text.trim().isEmpty
          ? null
          : int.tryParse(maxOccurrencesController.text.trim()),
      'reminderAt': _iso(reminderAt),
      'reminderEnabled': reminderEnabled && reminderAt != null,
      'subtasks': items,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.todo == null ? 'Thêm công việc' : 'Chỉnh sửa công việc'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên công việc *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả / ghi chú',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Bắt đầu',
                    value: startAt,
                    onTap: () async {
                      final value = await _pickDateTime(startAt);
                      if (value != null) setState(() => startAt = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateButton(
                    label: 'Deadline',
                    value: dueAt,
                    onTap: () async {
                      final value = await _pickDateTime(dueAt);
                      if (value != null) setState(() => dueAt = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Thời lượng (phút)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Ưu tiên'),
                    items: const [
                      DropdownMenuItem(value: 'HIGH', child: Text('Cao')),
                      DropdownMenuItem(
                        value: 'MEDIUM',
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem(value: 'LOW', child: Text('Thấp')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => priority = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: const [
                DropdownMenuItem(value: 'WORK', child: Text('Công việc')),
                DropdownMenuItem(value: 'STUDY', child: Text('Học tập')),
                DropdownMenuItem(value: 'PERSONAL', child: Text('Cá nhân')),
                DropdownMenuItem(value: 'HEALTH', child: Text('Sức khỏe')),
                DropdownMenuItem(value: 'FINANCE', child: Text('Tài chính')),
                DropdownMenuItem(value: 'SHOPPING', child: Text('Mua sắm')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhắc việc'),
              value: reminderEnabled,
              onChanged: (value) => setState(() => reminderEnabled = value),
            ),
            if (reminderEnabled)
              _DateButton(
                label: 'Thời điểm nhắc',
                value: reminderAt,
                onTap: () async {
                  final value = await _pickDateTime(reminderAt ?? dueAt);
                  if (value != null) setState(() => reminderAt = value);
                },
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: recurrence,
              decoration: const InputDecoration(labelText: 'Lặp lại'),
              items: const [
                DropdownMenuItem(value: 'NONE', child: Text('Không lặp')),
                DropdownMenuItem(value: 'DAILY', child: Text('Hàng ngày')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Hàng tuần')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Hàng tháng')),
                DropdownMenuItem(value: 'YEARLY', child: Text('Hàng năm')),
                DropdownMenuItem(
                  value: 'CUSTOM',
                  child: Text('Tùy chỉnh theo ngày'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => recurrence = value ?? 'NONE'),
            ),
            if (recurrence != 'NONE') ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: intervalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lặp mỗi'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recurrence == 'WEEKLY'
                          ? 'tuần'
                          : recurrence == 'MONTHLY'
                          ? 'tháng'
                          : recurrence == 'YEARLY'
                          ? 'năm'
                          : 'ngày',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: recurrenceBasis,
                decoration: const InputDecoration(
                  labelText: 'Tính lần tiếp theo từ',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'SCHEDULED_DATE',
                    child: Text('Lịch cố định'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETION_DATE',
                    child: Text('Ngày hoàn thành'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => recurrenceBasis = value ?? 'SCHEDULED_DATE'),
              ),
              const SizedBox(height: 8),
              _DateButton(
                label: 'Kết thúc lặp (tùy chọn)',
                value: recurrenceEndAt,
                onTap: () async {
                  final value = await _pickDateTime(recurrenceEndAt ?? dueAt);
                  if (value != null) setState(() => recurrenceEndAt = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxOccurrencesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hoặc dừng sau số lần (tùy chọn)',
                ),
              ),
            ],
            if (recurrence == 'WEEKLY')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children:
                      [
                            'MONDAY',
                            'TUESDAY',
                            'WEDNESDAY',
                            'THURSDAY',
                            'FRIDAY',
                            'SATURDAY',
                            'SUNDAY',
                          ]
                          .map(
                            (day) => FilterChip(
                              label: Text(_dayLabel(day)),
                              selected: days.contains(day),
                              onSelected: (selected) => setState(() {
                                if (selected)
                                  days.add(day);
                                else
                                  days.remove(day);
                              }),
                            ),
                          )
                          .toList(),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checklist con',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => setState(
                    () => subtasks.add({'title': '', 'completed': false}),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm bước'),
                ),
              ],
            ),
            ...subtasks.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: entry.value['completed'] == true,
                      onChanged: (value) => setState(
                        () => entry.value['completed'] = value == true,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                                text: entry.value['title']?.toString() ?? '',
                              )
                              ..selection = TextSelection.collapsed(
                                offset:
                                    entry.value['title']?.toString().length ??
                                    0,
                              ),
                        onChanged: (value) => entry.value['title'] = value,
                        decoration: InputDecoration(
                          hintText: 'Bước ${entry.key + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => subtasks.removeAt(entry.key)),
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.todo == null ? 'Tạo công việc' : 'Lưu thay đổi'),
      ),
    ],
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.event_outlined, size: 18),
    label: Text(
      value == null ? label : '$label\n${_dateLabel(value)}',
      textAlign: TextAlign.left,
    ),
  );
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({
    required this.items,
    required this.onAdd,
    required this.busy,
    required this.onReload,
  });
  final List<Map<String, dynamic>> items;
  final VoidCallback onAdd;
  final bool busy;
  final Future<void> Function() onReload;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onReload,
    child: ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0)
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FilledButton.icon(
              onPressed: busy ? null : onAdd,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Thêm lịch nhắc'),
            ),
          );
        if (items.isEmpty)
          return const EmptyView(
            icon: Icons.event_note_outlined,
            title: 'Chưa có lịch',
            subtitle: 'Tạo mốc nhắc để không bỏ quên việc quan trọng.',
          );
        final item = items[index - 1];
        final isTodo = item['sourceType'] == 'TODO';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                isTodo ? Icons.checklist_outlined : Icons.event_outlined,
              ),
            ),
            title: Text(
              item['title']?.toString() ?? 'Hoạt động',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${_dateLabel(item['startAt'])} • ${isTodo ? 'Việc cần làm' : 'Sự kiện'}${item['recurring'] == true ? ' • Lặp lại' : ''}',
            ),
          ),
        );
      },
    ),
  );
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    ),
  );
}

Map<String, dynamic> _todoPayload(
  Map<String, dynamic> todo, {
  required String status,
}) => {
  'title': todo['title'],
  'description': todo['description'],
  'status': status,
  'priority': todo['priority'] ?? 'MEDIUM',
  'startAt': todo['startAt'],
  'dueAt': todo['dueAt'],
  'estimatedMinutes': todo['estimatedMinutes'],
  'category': todo['category'] ?? 'PERSONAL',
  'recurrenceRule': todo['recurrenceRule'] ?? 'NONE',
  'recurrenceInterval': todo['recurrenceInterval'] ?? 1,
  'daysOfWeek': _stringList(todo['daysOfWeek']).join(','),
  'recurrenceBasis': todo['recurrenceBasis'] ?? 'SCHEDULED_DATE',
  'recurrenceEndAt': todo['recurrenceEndAt'],
  'recurrenceMaxOccurrences': todo['recurrenceMaxOccurrences'],
  'reminderAt': todo['reminderAt'],
  'reminderEnabled': todo['reminderEnabled'] == true,
  'subtasks': _subtasks(todo),
};

List<Map<String, dynamic>> _subtasks(Map<String, dynamic> todo) =>
    todo['subtasks'] is List
    ? (todo['subtasks'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList()
    : [];
List<String> _stringList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList()
    : value is String && value.isNotEmpty
    ? value.split(',')
    : [];
DateTime? _parseDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
String? _iso(DateTime? value) => value?.toIso8601String().substring(0, 19);
String _dateKey(DateTime? value) => value == null
    ? ''
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _dateLabel(dynamic value) {
  final date = value is DateTime ? value : _parseDate(value);
  return date == null
      ? 'Chưa đặt'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _priorityLabel(dynamic value) => value == 'HIGH'
    ? 'Cao'
    : value == 'LOW'
    ? 'Thấp'
    : 'Trung bình';
String _categoryLabel(dynamic value) =>
    const {
      'WORK': 'Công việc',
      'STUDY': 'Học tập',
      'PERSONAL': 'Cá nhân',
      'HEALTH': 'Sức khỏe',
      'FINANCE': 'Tài chính',
      'SHOPPING': 'Mua sắm',
    }[value] ??
    'Cá nhân';
String _viewLabel(String value) =>
    const {
      'TODAY': 'Hôm nay',
      'OVERDUE': 'Quá hạn',
      'UPCOMING': 'Sắp tới',
      'ALL': 'Tất cả',
    }[value] ??
    value;
String _dayLabel(String value) =>
    const {
      'MONDAY': 'T2',
      'TUESDAY': 'T3',
      'WEDNESDAY': 'T4',
      'THURSDAY': 'T5',
      'FRIDAY': 'T6',
      'SATURDAY': 'T7',
      'SUNDAY': 'CN',
    }[value] ??
    value;
String _recurrenceLabel(Map<String, dynamic> todo) {
  final rule = todo['recurrenceRule'];
  final interval = todo['recurrenceInterval'] ?? 1;
  final unit = rule == 'WEEKLY'
      ? 'tuần'
      : rule == 'MONTHLY'
      ? 'tháng'
      : rule == 'YEARLY'
      ? 'năm'
      : 'ngày';
  return 'mỗi $interval $unit · ${todo['recurrenceBasis'] == 'COMPLETION_DATE' ? 'từ lúc hoàn thành' : 'theo lịch'}';
}
