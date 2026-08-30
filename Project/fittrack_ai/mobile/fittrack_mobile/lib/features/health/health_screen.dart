import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> measurements = [];
  List<Map<String, dynamic>> reminders = [];
  bool loading = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
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
      final result = await Future.wait([
        api.get('/health-management/summary', queryParameters: {'days': 30}),
        api.get('/body-measurements'),
        api.get('/reminders'),
      ]);
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(result[0] as Map);
        measurements = _asList(result[1]);
        reminders = _asList(result[2]);
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    final raw = value is Map && value['content'] is List
        ? value['content']
        : value;
    return raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingView(label: 'Đang tổng hợp dữ liệu sức khỏe...');
    }
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Sức khỏe toàn diện',
                subtitle: 'Tổng hợp dinh dưỡng, vận động, chỉ số cơ thể và lời nhắc trong 30 ngày.',
              ),
              const SizedBox(height: 14),
              TabBar(
                controller: tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Tổng hợp'),
                  Tab(text: 'Chỉ số cơ thể'),
                  Tab(text: 'Nhắc nhở'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _SummaryTab(data: summary!),
              _BodyTab(items: measurements, onReload: _load),
              _ReminderTab(items: reminders, onReload: _load),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final nutrients = data['nutrients'] is List
        ? data['nutrients'] as List
        : const [];
    final insights = data['insights'] is List
        ? data['insights'] as List
        : const [];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: _HealthMetric(
                label: data['provisionalScore'] == true
                    ? 'Điểm tạm thời'
                    : 'Điểm sức khỏe',
                value: '${data['overallScore'] ?? 0}/100',
                icon: Icons.favorite_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HealthMetric(
                label: 'BMI',
                value: '${data['bmi'] ?? '-'}',
                icon: Icons.monitor_weight_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HealthMetric(
                label: 'Buổi tập',
                value: '${data['workoutSessions'] ?? 0}',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HealthMetric(
                label: 'Ngày dinh dưỡng đủ',
                value:
                    '${data['completeNutritionDays'] ?? 0}/${data['periodDays'] ?? 30}',
                icon: Icons.restaurant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          color: data['provisionalScore'] == true
              ? Colors.amber.shade50
              : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Độ tin cậy dữ liệu: ${data['nutritionConfidencePercent'] ?? 0}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  data['provisionalScore'] == true
                      ? 'Điểm hiện tại là tạm thời vì số ngày ghi đầy đủ còn thấp.'
                      : 'Dữ liệu đủ ổn định để tham khảo xu hướng.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  '${data['partialNutritionDays'] ?? 0} ngày ghi thiếu • ${data['unloggedNutritionDays'] ?? 0} ngày chưa ghi',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dinh dưỡng',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...nutrients.map((raw) {
          final item = raw as Map;
          final progress =
              ((item['progressPercent'] as num?)?.toDouble() ?? 0).clamp(
                0,
                100,
              ) /
              100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['label']?.toString() ??
                                item['key']?.toString() ??
                                'Dinh dưỡng',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${item['average'] ?? 0}/${item['target'] ?? 0} ${item['unit'] ?? ''}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 7),
                    Text(
                      '${_nutrientStatus(item['status'])} • Độ phủ dữ liệu ${item['coveragePercent'] ?? 0}%',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Nhận xét',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...insights.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(e.toString()),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          data['disclaimer']?.toString() ??
              'Dữ liệu chỉ mang tính tham khảo và không thay thế tư vấn y tế.',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );
}

class _BodyTab extends StatelessWidget {
  const _BodyTab({required this.items, required this.onReload});
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onReload;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onReload,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final saved = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddBodySheet(),
            );
            if (saved == true) onReload();
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm chỉ số cơ thể'),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(
            icon: Icons.monitor_weight_outlined,
            title: 'Chưa có chỉ số',
            subtitle: 'Ghi số đo đầu tiên để theo dõi thay đổi theo thời gian.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.monitor_weight_outlined),
                  ),
                  title: Text(
                    '${item['weight'] ?? '-'} kg • ${_formatDate(item['recordDate'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Eo ${item['waist'] ?? '-'} cm • Ngực ${item['chest'] ?? '-'} cm • Tay ${item['arm'] ?? '-'} cm • Đùi ${item['thigh'] ?? '-'} cm',
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ReminderTab extends StatelessWidget {
  const _ReminderTab({required this.items, required this.onReload});
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onReload;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onReload,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final saved = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddReminderSheet(),
            );
            if (saved == true) onReload();
          },
          icon: const Icon(Icons.add_alarm),
          label: const Text('Tạo lời nhắc'),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(
            icon: Icons.alarm_outlined,
            title: 'Chưa có lời nhắc',
            subtitle: 'Tạo lịch uống nước, ăn uống hoặc luyện tập.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    item['enabled'] == true
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                  title: Text(
                    item['title']?.toString() ?? 'Lời nhắc',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item['reminderTime'] ?? ''} • ${_days(item['daysOfWeek'])}\n${item['message'] ?? ''}',
                  ),
                  isThreeLine: item['message']?.toString().isNotEmpty == true,
                  trailing: IconButton(
                    onPressed: () async {
                      try {
                        await context.read<ApiClient>().delete(
                          '/reminders/${item['id']}',
                        );
                        await onReload();
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, displayError(e), error: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _AddBodySheet extends StatefulWidget {
  const _AddBodySheet();
  @override
  State<_AddBodySheet> createState() => _AddBodySheetState();
}

class _AddBodySheetState extends State<_AddBodySheet> {
  final fields = {
    for (final key in ['weight', 'waist', 'chest', 'arm', 'thigh'])
      key: TextEditingController(),
  };
  bool busy = false;
  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (fields.values.any((c) => double.tryParse(c.text) == null)) {
      return showMessage(context, 'Nhập đầy đủ các số đo hợp lệ.', error: true);
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/body-measurements',
        data: {
          ...fields.map(
            (key, value) => MapEntry(key, double.parse(value.text)),
          ),
          'recordDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'weight': 'Cân nặng (kg)',
      'waist': 'Vòng eo (cm)',
      'chest': 'Vòng ngực (cm)',
      'arm': 'Vòng tay (cm)',
      'thigh': 'Vòng đùi (cm)',
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm chỉ số cơ thể',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đo cùng thời điểm trong ngày để dữ liệu dễ so sánh.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...fields.entries.expand(
              (entry) => [
                TextField(
                  controller: entry.value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: labels[entry.key],
                    hintText: entry.key == 'weight'
                        ? 'Ví dụ: 60.5'
                        : 'Ví dụ: 78',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(busy ? 'Đang lưu...' : 'Lưu chỉ số'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final title = TextEditingController();
  final message = TextEditingController();
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  String type = 'WATER';
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) {
      return showMessage(context, 'Nhập tiêu đề lời nhắc.', error: true);
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/reminders',
        data: {
          'type': type,
          'title': title.text.trim(),
          'message': message.text.trim(),
          'reminderTime':
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'daysOfWeek': const [
            'MONDAY',
            'TUESDAY',
            'WEDNESDAY',
            'THURSDAY',
            'FRIDAY',
            'SATURDAY',
            'SUNDAY',
          ],
          'enabled': true,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tạo lời nhắc hằng ngày',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Nhóm nhắc nhở'),
            items: const [
              DropdownMenuItem(value: 'WATER', child: Text('Uống nước')),
              DropdownMenuItem(value: 'MEAL', child: Text('Ăn uống')),
              DropdownMenuItem(value: 'WORKOUT', child: Text('Luyện tập')),
              DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
            ],
            onChanged: (v) => setState(() => type = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: title,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Ví dụ: Uống một cốc nước',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: message,
            decoration: const InputDecoration(
              labelText: 'Nội dung (không bắt buộc)',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) setState(() => time = picked);
            },
            icon: const Icon(Icons.schedule),
            label: Text('Giờ nhắc: ${time.format(context)}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? 'Đang lưu...' : 'Tạo lời nhắc'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);
}

String _days(dynamic value) {
  if (value is List && value.length == 7) return 'Hằng ngày';
  return value is List ? '${value.length} ngày/tuần' : '';
}

String _nutrientStatus(dynamic value) => switch (value?.toString()) {
  'GOOD' => 'Cân bằng',
  'LOW' => 'Còn thấp',
  'HIGH' => 'Cao',
  'NO_TARGET' => 'Chưa có mục tiêu',
  'INSUFFICIENT_COVERAGE' => 'Chưa đủ dữ liệu để đánh giá',
  _ => 'Không có dữ liệu',
};
