import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import 'training_data.dart';
import 'live_workout_sheet.dart';

Future<void> openTrainingAppointment(BuildContext context, String id) async {
  try {
    final value = await context.read<ApiClient>().get(
      '/workout-plans/appointments/$id',
    );
    if (!context.mounted) return;
    final a = Map<String, dynamic>.from(value as Map);
    if (a['completedSessionId'] != null) {
      showMessage(
        context,
        'Lần tập đã hoàn thành. Xem/chỉnh trong lịch sử buổi tập.',
      );
      return;
    }
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LiveWorkoutSheet(
        appointmentId: id,
        planDay: Map<String, dynamic>.from(a['day'] as Map),
      ),
    );
  } catch (e) {
    if (context.mounted) showMessage(context, displayError(e), error: true);
  }
}

class TrainingProgramsScreen extends StatefulWidget {
  const TrainingProgramsScreen({super.key});
  @override
  State<TrainingProgramsScreen> createState() => _TrainingProgramsState();
}

class _TrainingProgramsState extends State<TrainingProgramsScreen> {
  List<Map<String, dynamic>> cycles = [], appointments = [], plans = [];
  bool loading = true, busy = false;
  Object? error;
  int page = 0, pages = 1;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  bool get canSchedule {
    final u = context.read<AuthSession>().user;
    return u?.isAdmin == true || u?.scheduleEnabled == true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final c = await api.get(
        '/workout-plans/cycles',
        queryParameters: {'page': page, 'size': 12},
      );
      final p = await api.get('/workout-plans');
      final a = canSchedule
          ? await api.get(
              '/workout-plans/appointments',
              queryParameters: {
                'from': month.toIso8601String().substring(0, 19),
                'to': DateTime(
                  month.year,
                  month.month + 1,
                ).toIso8601String().substring(0, 19),
              },
            )
          : [];
      if (mounted) {
        setState(() {
          cycles = trainingList(c);
          pages = (c['totalPages'] as num?)?.toInt() ?? 1;
          plans = trainingList(p);
          appointments = trainingList(a);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> action(Future<dynamic> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await fn();
      if (mounted) {
        showMessage(context, 'Đã lưu');
        await load();
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> edit([Map<String, dynamic>? current]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _CycleEditor(initial: current)),
    );
    if (saved == true) load();
  }

  Future<void> schedule() async {
    if (plans.isEmpty) {
      showMessage(context, 'Tạo giáo án trước khi lên lịch.');
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScheduleTrainingForm(plans: plans, cycles: cycles),
    );
    if (saved == true) load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chu kỳ và lịch tập')),
    body: loading
        ? const LoadingView()
        : error != null
        ? ErrorView(message: displayError(error!), onRetry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Kế hoạch không ghi hoàn thành. Mức tải do bạn xác nhận; hệ thống không tự tăng tạ.',
                ),
                FilledButton.icon(
                  onPressed: busy ? null : () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo chu kỳ 4–12 tuần'),
                ),
                ...cycles.map(
                  (c) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            c['name'].toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${c['startDate']} · ${trainingList(c['weeks']).length} tuần · ${c['completedSessions']}/${c['plannedSessions']} buổi thực tế/lịch',
                          ),
                          ExpansionTile(
                            title: const Text('Chỉ tiêu và kết quả từng tuần'),
                            children: [
                              for (final w in trainingList(c['weeks']))
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    "Tuần ${w['number']}${w['deload'] == true ? ' (giảm tải)' : ''} · ${(c['completedByWeek'] as Map?)?[w['number'].toString()] ?? 0}/${w['targetSessions']} buổi",
                                  ),
                                  subtitle: Text(
                                    w['targetNote']?.toString() ??
                                        'Chưa ghi mục tiêu tải',
                                  ),
                                ),
                            ],
                          ),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: busy ? null : () => edit(c),
                                child: const Text('Chỉnh chu kỳ'),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (await confirm(
                                          'Xóa chu kỳ?',
                                          'Snapshot lịch tập và lịch sử thực tế được giữ.',
                                        )) {
                                          action(
                                            () => context.read<ApiClient>().delete(
                                              '/workout-plans/cycles/${c['id']}?version=${c['version']}',
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: page > 0
                          ? () {
                              page--;
                              load();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Trang ${page + 1}'),
                    IconButton(
                      onPressed: page + 1 < pages
                          ? () {
                              page++;
                              load();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (canSchedule) ...[
                  OutlinedButton.icon(
                    onPressed: busy ? null : schedule,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Lên lịch ngày giáo án'),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          month = DateTime(month.year, month.month - 1);
                          load();
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MM/yyyy').format(month),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          month = DateTime(month.year, month.month + 1);
                          load();
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  ...appointments.map(
                    (a) => Card(
                      child: ListTile(
                        title: Text(a['title'].toString()),
                        subtitle: Text(
                          '${a['startAt']} · ${a['completedSessionId'] == null ? 'Chưa tập' : 'Đã tập'}${a['weekNumber'] != null ? ' · Tuần ${a['weekNumber']}' : ''}',
                        ),
                        onTap: () async {
                          await openTrainingAppointment(
                            context,
                            a['id'].toString(),
                          );
                          if (mounted) load();
                        },
                        trailing: a['completedSessionId'] == null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (await confirm(
                                          'Xóa lịch tập?',
                                          'Chỉ xóa lần tập này.',
                                        )) {
                                          action(
                                            () => context.read<ApiClient>().delete(
                                              '/workout-plans/appointments/${a['id']}?version=${a['version']}',
                                            ),
                                          );
                                        }
                                      },
                              )
                            : const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ),
                ] else
                  const Text('Cần quyền thời khóa biểu để lên lịch tập.'),
              ],
            ),
          ),
  );
}

class _CycleEditor extends StatefulWidget {
  const _CycleEditor({this.initial});
  final Map<String, dynamic>? initial;
  @override
  State<_CycleEditor> createState() => _CycleEditorState();
}

class _CycleEditorState extends State<_CycleEditor> {
  late final TextEditingController name, date;
  late List<Map<String, dynamic>> weeks;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(
      text: widget.initial?['name']?.toString() ?? 'Chu kỳ tăng cơ',
    );
    date = TextEditingController(
      text:
          widget.initial?['startDate']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    weeks = widget.initial == null
        ? List.generate(
            4,
            (i) => {
              'number': i + 1,
              'deload': i == 3,
              'targetSessions': 3,
              'targetNote': '',
            },
          )
        : trainingList(trainingCopy(widget.initial!)['weeks']);
  }

  @override
  void dispose() {
    name.dispose();
    date.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (name.text.trim().isEmpty || DateTime.tryParse(date.text) == null) {
      showMessage(context, 'Điền tên và ngày YYYY-MM-DD hợp lệ.', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      final payload = {
        'name': name.text.trim(),
        'startDate': date.text,
        'weeks': weeks,
        'version': widget.initial?['version'],
      };
      final api = context.read<ApiClient>();
      if (widget.initial == null) {
        await api.post('/workout-plans/cycles', data: payload);
      } else {
        await api.put(
          '/workout-plans/cycles/${widget.initial!['id']}',
          data: payload,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thiết lập chu kỳ')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          maxLength: 180,
          decoration: const InputDecoration(labelText: 'Tên chu kỳ'),
        ),
        TextField(
          controller: date,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(date.text) ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              date.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
          decoration: const InputDecoration(
            labelText: 'Ngày bắt đầu (YYYY-MM-DD)',
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: weeks.length,
          decoration: const InputDecoration(labelText: 'Số tuần'),
          items: [
            for (int i = 4; i <= 12; i++)
              DropdownMenuItem(value: i, child: Text('$i tuần')),
          ],
          onChanged: (n) {
            if (n != null) {
              setState(
                () => weeks = List.generate(
                  n,
                  (i) => i < weeks.length
                      ? weeks[i]
                      : {
                          'number': i + 1,
                          'deload': false,
                          'targetSessions': 3,
                          'targetNote': '',
                        },
                ),
              );
            }
          },
        ),
        ...weeks.map(
          (w) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('Tuần ${w['number']}'),
                  SwitchListTile(
                    title: const Text('Tuần giảm tải'),
                    value: w['deload'] == true,
                    onChanged: (v) => setState(() => w['deload'] = v),
                  ),
                  TextFormField(
                    key: ValueKey('sessions-${w['number']}'),
                    initialValue: w['targetSessions'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chỉ tiêu buổi (1–14)',
                    ),
                    onChanged: (v) =>
                        w['targetSessions'] = int.tryParse(v) ?? 0,
                  ),
                  TextFormField(
                    key: ValueKey('note-${w['number']}'),
                    initialValue: w['targetNote']?.toString(),
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu tải / số hiệp / lần lặp',
                    ),
                    onChanged: (v) => w['targetNote'] = v,
                  ),
                ],
              ),
            ),
          ),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Đang lưu...' : 'Lưu chu kỳ'),
        ),
      ],
    ),
  );
}

class _ScheduleTrainingForm extends StatefulWidget {
  const _ScheduleTrainingForm({required this.plans, required this.cycles});
  final List<Map<String, dynamic>> plans, cycles;
  @override
  State<_ScheduleTrainingForm> createState() => _ScheduleTrainingFormState();
}

class _ScheduleTrainingFormState extends State<_ScheduleTrainingForm> {
  String? selected, cycle;
  int repeat = 1;
  bool busy = false;
  final at = TextEditingController(
    text: DateFormat("yyyy-MM-dd'T'18:00").format(DateTime.now()),
  );
  @override
  void dispose() {
    at.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (selected == null || DateTime.tryParse(at.text) == null) {
      showMessage(context, 'Chọn ngày giáo án và giờ hợp lệ.', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      final ids = selected!.split(':');
      await context.read<ApiClient>().post(
        '/workout-plans/appointments',
        data: {
          'planId': ids[0],
          'dayId': ids[1],
          'startAt': DateTime.parse(at.text).toIso8601String().substring(0, 19),
          'repeatWeeks': repeat,
          'cycleId': cycle,
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
      16,
      24,
      16,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lên lịch snapshot giáo án',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Thay giáo án sau này không tự thay lịch. Chỉ lưu buổi tập thực tế mới đánh hoàn thành.',
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Ngày tập'),
            items: [
              for (final p in widget.plans)
                for (final d in trainingList(p['days']))
                  DropdownMenuItem(
                    value: "${p['id']}:${d['id']}",
                    child: Text(
                      "${p['name']} · ${d['name']}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: (v) => selected = v,
          ),
          TextField(
            controller: at,
            readOnly: true,
            onTap: () async {
              final initial = DateTime.tryParse(at.text) ?? DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d == null || !context.mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
              );
              if (t != null) {
                at.text = DateFormat("yyyy-MM-dd'T'HH:mm")
                    .format(DateTime(d.year, d.month, d.day, t.hour, t.minute));
              }
            },
            decoration: const InputDecoration(
              labelText: 'Bắt đầu (YYYY-MM-DDTHH:mm)',
            ),
          ),
          TextFormField(
            initialValue: '1',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Lặp hằng tuần (1–12 lần)',
            ),
            onChanged: (v) => repeat = int.tryParse(v) ?? 0,
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: '',
            decoration: const InputDecoration(
              labelText: 'Gắn chu kỳ (tùy chọn)',
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Không gắn')),
              for (final c in widget.cycles)
                DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(
                    c['name'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => cycle = v == '' ? null : v,
          ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Đang lưu...' : 'Lên lịch'),
          ),
        ],
      ),
    ),
  );
}
