import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/health/health_connect_service.dart';

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
  List<Map<String, dynamic>> progressPhotos = [];
  List<Map<String, dynamic>> reminders = [];
  Map<String, dynamic>? healthConnect;
  Map<String, dynamic>? weeklyCoach;
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
        api.get('/health-connect/day'),
        api.get('/progress-photos'),
      ]);
      Map<String, dynamic>? coach;
      try {
        coach = Map<String, dynamic>.from(
          await api.get('/recommendations/check-ins/current') as Map,
        );
      } catch (_) {
        coach = null;
      }
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(result[0] as Map);
        measurements = _asList(result[1]);
        reminders = _asList(result[2]);
        healthConnect = Map<String, dynamic>.from(result[3] as Map);
        progressPhotos = _asList(result[4]);
        weeklyCoach = coach;
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
              _SummaryTab(
                data: summary!,
                healthConnect: healthConnect ?? const {},
                weeklyCoach: weeklyCoach,
                onReload: _load,
              ),
              _BodyTab(
                items: measurements,
                photos: progressPhotos,
                onReload: _load,
              ),
              _ReminderTab(items: reminders, onReload: _load),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.data,
    required this.healthConnect,
    required this.weeklyCoach,
    required this.onReload,
  });
  final Map<String, dynamic> data;
  final Map<String, dynamic> healthConnect;
  final Map<String, dynamic>? weeklyCoach;
  final Future<void> Function() onReload;

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
        _HealthConnectCard(data: healthConnect, onReload: onReload),
        const SizedBox(height: 12),
        if (weeklyCoach != null) ...[
          _WeeklyCoachCard(data: weeklyCoach!, onReload: onReload),
          const SizedBox(height: 12),
        ],
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

class _WeeklyCoachCard extends StatefulWidget {
  const _WeeklyCoachCard({required this.data, required this.onReload});
  final Map<String, dynamic> data;
  final Future<void> Function() onReload;
  @override
  State<_WeeklyCoachCard> createState() => _WeeklyCoachCardState();
}

class _WeeklyCoachCardState extends State<_WeeklyCoachCard> {
  bool busy = false;
  Future<void> decide(String decision) async {
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/recommendations/check-ins/${widget.data['id']}/decision',
        data: {'decision': decision},
      );
      if (mounted)
        showMessage(
          context,
          decision == 'ACCEPT'
              ? 'Đã áp dụng mục tiêu tuần mới.'
              : 'Đã giữ mục tiêu hiện tại.',
        );
      await widget.onReload();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FitTrack Coach · Check-in tuần',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(widget.data['rationale']?.toString() ?? ''),
          const SizedBox(height: 8),
          Text(
            '${widget.data['completeDays'] ?? 0}/7 ngày đủ dữ liệu · độ tin cậy ${widget.data['confidencePercent'] ?? 0}%',
          ),
          Text(
            'Năng lượng ${widget.data['currentCalories'] ?? 0} → ${widget.data['proposedCalories'] ?? 0} kcal',
          ),
          Text(
            'Chất đạm ${widget.data['currentProtein'] ?? 0} → ${widget.data['proposedProtein'] ?? 0} g',
          ),
          if (widget.data['status'] == 'PENDING')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: busy || widget.data['canApply'] != true
                        ? null
                        : () => decide('ACCEPT'),
                    child: const Text('Áp dụng'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => decide('IGNORE'),
                    child: const Text('Giữ hiện tại'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _HealthConnectCard extends StatefulWidget {
  const _HealthConnectCard({required this.data, required this.onReload});
  final Map<String, dynamic> data;
  final Future<void> Function() onReload;
  @override
  State<_HealthConnectCard> createState() => _HealthConnectCardState();
}

class _HealthConnectCardState extends State<_HealthConnectCard> {
  bool syncing = false;

  Future<void> sync() async {
    setState(() => syncing = true);
    try {
      final result = await HealthConnectService(context.read<ApiClient>())
          .syncLastSevenDays();
      if (mounted)
        showMessage(
          context,
          'Đã đồng bộ ${result['imported'] ?? 0} bản ghi mới; bỏ qua ${result['duplicates'] ?? 0} bản trùng.',
        );
      await widget.onReload();
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.teal.shade50,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined),
              SizedBox(width: 8),
              Text(
                'Health Connect',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chỉ đọc bước chân, cân nặng, nhịp tim và buổi tập sau khi bạn đồng ý.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('${widget.data['steps'] ?? 0} bước'),
              Text(
                widget.data['latestWeightKg'] == null
                    ? 'Chưa có cân nặng'
                    : '${widget.data['latestWeightKg']} kg',
              ),
              Text(
                widget.data['averageHeartRate'] == null
                    ? 'Chưa có nhịp tim'
                    : '${widget.data['averageHeartRate']} bpm',
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: syncing ? null : sync,
            icon: const Icon(Icons.sync),
            label: Text(
              syncing ? 'Đang đồng bộ...' : 'Kết nối / đồng bộ 7 ngày',
            ),
          ),
        ],
      ),
    ),
  );
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
  const _BodyTab({
    required this.items,
    required this.photos,
    required this.onReload,
  });
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> photos;
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final saved = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddProgressPhotoSheet(),
            );
            if (saved == true) onReload();
          },
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Thêm ảnh tiến độ'),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final photo = photos[index];
                final api = context.read<ApiClient>();
                final token = api.accessToken;
                final apiBase = api.dio.options.baseUrl.replaceFirst(
                  RegExp(r'/api/?$'),
                  '',
                );
                final imagePath = '${photo['imageUrl'] ?? ''}';
                final imageUrl = imagePath.startsWith('http')
                    ? imagePath
                    : '$apiBase${imagePath.startsWith('/') ? '' : '/'}$imagePath';
                return SizedBox(
                  width: 145,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            headers: token == null
                                ? null
                                : {'Authorization': 'Bearer $token'},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${photo['takenDate']} · ${photo['pose']}',
                            maxLines: 1,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

class _AddProgressPhotoSheet extends StatefulWidget {
  const _AddProgressPhotoSheet();
  @override
  State<_AddProgressPhotoSheet> createState() => _AddProgressPhotoSheetState();
}

class _AddProgressPhotoSheetState extends State<_AddProgressPhotoSheet> {
  PlatformFile? file;
  String pose = 'FRONT';
  final note = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final selected = await FilePicker.pickFile(type: FileType.image);
    if (selected != null && mounted) setState(() => file = selected);
  }

  Future<void> save() async {
    if (file == null)
      return showMessage(context, 'Hãy chọn một ảnh.', error: true);
    setState(() => busy = true);
    try {
      final bytes = await file!.readAsBytes();
      final extension = (file!.extension ?? 'jpeg').toLowerCase();
      final mime = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
          ? 'image/webp'
          : 'image/jpeg';
      if (!mounted) return;
      await context.read<ApiClient>().post(
        '/progress-photos',
        data: {
          'imageUrl': 'data:$mime;base64,${base64Encode(bytes)}',
          'takenDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'pose': pose,
          'note': note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Thêm ảnh tiến độ',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : pick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(file?.name ?? 'Chọn ảnh'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: pose,
          decoration: const InputDecoration(labelText: 'Góc chụp'),
          items: const [
            DropdownMenuItem(value: 'FRONT', child: Text('Chính diện')),
            DropdownMenuItem(value: 'SIDE', child: Text('Nghiêng')),
            DropdownMenuItem(value: 'BACK', child: Text('Phía sau')),
            DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
          ],
          onChanged: (value) => setState(() => pose = value!),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: note,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (không bắt buộc)',
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Đang tải...' : 'Lưu ảnh'),
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
