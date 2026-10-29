import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import 'habit_heatmap.dart';

/// Shared real-API screens; no mock records and no writes to Todo/diary/profile.
class PersonalTrackingScreen extends StatefulWidget {
  const PersonalTrackingScreen({
    super.key,
    this.section = 'goals',
    this.kind = 'BODY',
  });
  final String section;
  final String kind;
  @override
  State<PersonalTrackingScreen> createState() => _PersonalTrackingScreenState();
}

class _PersonalTrackingScreenState extends State<PersonalTrackingScreen> {
  List<Map<String, dynamic>> items = [];
  int page = 0, pages = 0, loadGeneration = 0;
  bool loading = true, archived = false;
  Object? error;
  String get path => widget.section == 'habits'
      ? '/todos/habits'
      : widget.section == 'recovery'
      ? '/health-management/tracking/recovery'
      : widget.kind == 'WORKOUT'
      ? '/workouts/goals'
      : '/health-management/tracking/goals';
  String get title => widget.section == 'habits'
      ? 'Thói quen'
      : widget.section == 'recovery'
      ? 'Giấc ngủ & phục hồi'
      : widget.kind == 'WORKOUT'
      ? 'Mục tiêu thành tích tập'
      : 'Mục tiêu cơ thể';
  String get today =>
      DateFormat('yyyy-MM-dd')
          .format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    if (!mounted) return;
    final generation = ++loadGeneration;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await context.read<ApiClient>().get(
        path,
        queryParameters: {'page': page, 'size': 12, 'archived': archived},
      );
      if (!mounted || generation != loadGeneration) return;
      final data = Map<String, dynamic>.from(value as Map);
      setState(() {
        items = (data['content'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        pages = (data['totalPages'] as num).toInt();
      });
    } catch (e) {
      if (mounted && generation == loadGeneration) setState(() => error = e);
    } finally {
      if (mounted && generation == loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  void fail(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể xử lý: $e')));
    }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    final draft = <String, dynamic>{
      'title': '',
      'startDate': today,
      'weekdays': <int>[],
      'phases': <Map<String, dynamic>>[],
      'archived': false,
      ...?existing,
    };
    final controllers = <String, TextEditingController>{};
    for (final key in [
      'title',
      'note',
      'metric',
      'unit',
      'baseline',
      'target',
      'startDate',
      'targetDate',
      'sleepStart',
      'sleepEnd',
      'quality',
      'fatigue',
      'soreness',
    ]) {
      controllers[key] = TextEditingController(
        text: draft[key]?.toString() ?? '',
      );
    }
    final days = ((draft['weekdays'] as List?) ?? [])
        .map((e) => (e as num).toInt())
        .toSet();
    final phases = ((draft['phases'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    bool saving = false;
    String? localError;
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, change) {
          Widget field(
            String key,
            String label, {
            bool required = false,
            bool number = false,
          }) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: controllers[key],
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              keyboardType: number
                  ? const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    )
                  : TextInputType.text,
              validator: (v) => required && (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập $label'
                  : number && v!.isNotEmpty && double.tryParse(v) == null
                  ? 'Nhập số hợp lệ'
                  : null,
            ),
          );
          return AlertDialog(
            title: Text(existing == null ? 'Thêm $title' : 'Chỉnh sửa'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      field('title', 'Tên', required: true),
                      field('note', 'Ghi chú'),
                      if (widget.section != 'recovery')
                        field(
                          'startDate',
                          'Ngày bắt đầu (yyyy-MM-dd)',
                          required: true,
                        ),
                      if (widget.section == 'goals') ...[
                        field(
                          'metric',
                          'Chỉ số (cân nặng, mức tạ...)',
                          required: true,
                        ),
                        field(
                          'unit',
                          'Đơn vị (kg, cm, lần...)',
                          required: true,
                        ),
                        field(
                          'baseline',
                          'Số đo ban đầu',
                          required: true,
                          number: true,
                        ),
                        field(
                          'target',
                          'Mục tiêu',
                          required: true,
                          number: true,
                        ),
                        field('targetDate', 'Ngày đích (yyyy-MM-dd)'),
                        const Text(
                          'Giai đoạn theo thứ tự ngày; không thay đổi mục tiêu calo của hồ sơ.',
                        ),
                        ...phases.asMap().entries.map(
                          (e) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  TextFormField(
                                    initialValue: e.value['title']?.toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Tên giai đoạn ${e.key + 1}',
                                    ),
                                    onChanged: (v) => e.value['title'] = v,
                                  ),
                                  TextFormField(
                                    initialValue: e.value['targetDate']
                                        ?.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Ngày đích yyyy-MM-dd',
                                    ),
                                    onChanged: (v) => e.value['targetDate'] = v,
                                  ),
                                  TextFormField(
                                    initialValue: e.value['target']?.toString(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Giá trị đích',
                                    ),
                                    onChanged: (v) =>
                                        e.value['target'] = double.tryParse(v),
                                  ),
                                  TextButton(
                                    onPressed: saving
                                        ? null
                                        : () => change(
                                            () => phases.removeAt(e.key),
                                          ),
                                    child: const Text('Xóa giai đoạn'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => change(
                                  () => phases.add({
                                    'title': '',
                                    'targetDate': today,
                                    'target': 0,
                                  }),
                                ),
                          child: const Text('+ Thêm giai đoạn'),
                        ),
                      ],
                      if (widget.section == 'habits') ...[
                        const Text('Ngày thực hiện; không chọn = mỗi ngày'),
                        Wrap(
                          spacing: 6,
                          children: List.generate(
                            7,
                            (i) => FilterChip(
                              label: Text(i == 6 ? 'CN' : 'T${i + 2}'),
                              selected: days.contains(i + 1),
                              onSelected: saving
                                  ? null
                                  : (v) => change(() {
                                      v ? days.add(i + 1) : days.remove(i + 1);
                                    }),
                            ),
                          ),
                        ),
                      ],
                      if (widget.section == 'recovery') ...[
                        const Text(
                          'Nhập giờ Việt Nam, ví dụ 2026-10-27T22:30. Có thể qua nửa đêm; tối đa 24 giờ. Bỏ trống đánh giá nếu chưa biết.',
                        ),
                        field(
                          'sleepStart',
                          'Bắt đầu ngủ yyyy-MM-ddTHH:mm',
                          required: true,
                        ),
                        field(
                          'sleepEnd',
                          'Thức dậy yyyy-MM-ddTHH:mm',
                          required: true,
                        ),
                        field(
                          'quality',
                          'Chất lượng (1 kém → 5 tốt)',
                          number: true,
                        ),
                        field(
                          'fatigue',
                          'Mệt mỏi (1 ít → 5 nhiều)',
                          number: true,
                        ),
                        field(
                          'soreness',
                          'Đau cơ (1 ít → 5 nhiều)',
                          number: true,
                        ),
                      ],
                      if (localError != null)
                        Text(
                          localError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        change(() {
                          saving = true;
                          localError = null;
                        });
                        try {
                          for (final entry in controllers.entries) {
                            final text = entry.value.text.trim();
                            draft[entry.key] = text.isEmpty ? null : text;
                          }
                          for (final key in ['baseline', 'target']) {
                            final text = controllers[key]!.text;
                            draft[key] = text.isEmpty
                                ? null
                                : double.parse(text);
                          }
                          for (final key in [
                            'quality',
                            'fatigue',
                            'soreness',
                          ]) {
                            final text = controllers[key]!.text;
                            draft[key] = text.isEmpty ? null : int.parse(text);
                          }
                          draft['weekdays'] = days.toList()..sort();
                          draft['phases'] = phases;
                          final api = this.context.read<ApiClient>();
                          if (existing == null) {
                            await api.post(path, data: draft);
                          } else {
                            await api.patch(
                              '$path/${existing['id']}',
                              data: draft,
                            );
                          }
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          await load();
                        } catch (e) {
                          change(() {
                            localError = 'Không lưu được: $e';
                            saving = false;
                          });
                        }
                      },
                child: Text(saving ? 'Đang lưu…' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  Future<void> history(Map<String, dynamic> item) async {
    final from = TextEditingController(text: '${today.substring(0, 7)}-01'),
        to = TextEditingController(text: today),
        day = TextEditingController(text: today),
        value = TextEditingController(),
        note = TextEditingController(),
        evidence = TextEditingController();
    List<Map<String, dynamic>> rows = [];
    bool busy = false;
    String? message;
    String? calendarFrom, calendarTo;
    int calendarRevision = 0;
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (context, change) {
          Future<void> fetch() async {
            change(() {
              busy = true;
              message = null;
            });
            try {
              final result = await this.context.read<ApiClient>().get(
                '$path/${item['id']}/checkins',
                queryParameters: {'from': from.text, 'to': to.text},
              );
              if (dc.mounted) {
                change(() {
                  rows = (result as List)
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();
                  if (widget.section == 'habits') {
                    calendarFrom = from.text;
                    calendarTo = to.text;
                    calendarRevision++;
                  }
                });
              }
            } catch (e) {
              if (dc.mounted) change(() => message = e.toString());
            } finally {
              if (dc.mounted) change(() => busy = false);
            }
          }

          Future<void> record(String status) async {
            change(() {
              busy = true;
              message = null;
            });
            try {
              await this.context.read<ApiClient>().put(
                '$path/${item['id']}/checkins/${day.text}',
                data: {
                  'status': status,
                  'value': value.text.isEmpty ? null : double.parse(value.text),
                  'note': note.text,
                  'evidence': evidence.text,
                },
              );
              await fetch();
            } catch (e) {
              if (dc.mounted) {
                change(() {
                  message = e.toString();
                  busy = false;
                });
              }
            }
          }

          return AlertDialog(
            title: Text('${item['title']} — ghi nhận'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: from,
                      decoration: const InputDecoration(
                        labelText: 'Lịch sử từ yyyy-MM-dd',
                      ),
                    ),
                    TextField(
                      controller: to,
                      decoration: const InputDecoration(
                        labelText: 'Đến yyyy-MM-dd',
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : fetch,
                      child: const Text('Xem lịch sử (tối đa 366 ngày)'),
                    ),
                    if (calendarFrom != null && calendarTo != null)
                      HabitHeatmap(
                        id: item['id'].toString(),
                        from: calendarFrom!,
                        to: calendarTo!,
                        revision: '$calendarRevision',
                      ),
                    if (item['archived'] != true) ...[
                      TextField(
                        controller: day,
                        decoration: const InputDecoration(
                          labelText: 'Ngày ghi nhận yyyy-MM-dd',
                        ),
                      ),
                      if (widget.section == 'goals')
                        TextField(
                          controller: value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Giá trị (${item['unit']})',
                          ),
                        ),
                      TextField(
                        controller: note,
                        decoration: const InputDecoration(labelText: 'Ghi chú'),
                      ),
                      if (widget.section == 'goals')
                        TextField(
                          controller: evidence,
                          decoration: const InputDecoration(
                            labelText: 'Minh chứng: mã buổi tập / số đo',
                          ),
                        ),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: busy ? null : () => record('DONE'),
                            child: Text(
                              widget.section == 'habits'
                                  ? 'Đã thực hiện'
                                  : 'Lưu số đo',
                            ),
                          ),
                          if (widget.section == 'habits')
                            TextButton(
                              onPressed: busy ? null : () => record('SKIPPED'),
                              child: const Text('Bỏ qua'),
                            ),
                        ],
                      ),
                    ],
                    if (busy) const LinearProgressIndicator(),
                    if (message != null)
                      Text(message!, style: const TextStyle(color: Colors.red)),
                    if (rows.isEmpty)
                      const Text(
                        'Chưa tải / chưa có dữ liệu; không phải số 0.',
                      ),
                    if (widget.section == 'goals' &&
                        rows.isNotEmpty &&
                        rows.last['value'] != null)
                      Builder(
                        builder: (_) {
                          final baseline = (item['baseline'] as num).toDouble(),
                              target = (item['target'] as num).toDouble(),
                              current = (rows.last['value'] as num).toDouble();
                          final fraction = target == baseline
                              ? 0.0
                              : ((current - baseline) / (target - baseline))
                                    .clamp(0.0, 1.0);
                          return Column(
                            children: [
                              Text('Tiến độ ${(fraction * 100).round()}%'),
                              LinearProgressIndicator(value: fraction),
                            ],
                          );
                        },
                      ),
                    ...rows.map(
                      (r) => ListTile(
                        title: Text(
                          '${r['day']} · ${r['status'] == 'DONE'
                              ? 'Đã thực hiện'
                              : r['status'] == 'SKIPPED'
                              ? 'Bỏ qua'
                              : '${r['value']} ${item['unit']}'}',
                        ),
                        subtitle: Text(
                          '${r['note'] ?? ''} ${r['evidence'] ?? ''}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dc),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
    for (final c in [from, to, day, value, note, evidence]) {
      c.dispose();
    }
  }

  Future<void> archive(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lưu trữ?'),
        content: const Text('Lịch sử vẫn được giữ lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Lưu trữ'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ApiClient>().delete(
        '$path/${item['id']}?version=${item['version']}',
      );
      await load();
    } catch (e) {
      fail(e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.section == 'recovery'
                ? 'Nhập tay, không đồng bộ thiết bị. Thông tin tham khảo, không chẩn đoán bệnh.'
                : widget.section == 'habits'
                ? 'Ngày Việt Nam · độc lập với công việc · không tạo quá hạn.'
                : 'Mục tiêu riêng tư · không tự thay đổi calo hồ sơ.',
          ),
          SwitchListTile(
            title: const Text('Xem đã lưu trữ'),
            value: archived,
            onChanged: (v) {
              setState(() {
                archived = v;
                page = 0;
              });
              load();
            },
          ),
          FilledButton.icon(
            onPressed: loading ? null : () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm mới'),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text('$error', style: const TextStyle(color: Colors.red)),
          ...items.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.section == 'goals')
                      Text(
                        '${item['baseline']} → ${item['target']} ${item['unit']} · ${item['targetDate'] ?? 'Chưa đặt ngày'}',
                      ),
                    if (widget.section == 'goals')
                      ...((item['phases'] as List?) ?? []).map(
                        (p) => Text(
                          '${p['title']}: ${p['target']} ${item['unit']} · ${p['targetDate']}',
                        ),
                      ),
                    if (widget.section == 'habits')
                      Text(
                        (item['weekdays'] as List).isEmpty
                            ? 'Mỗi ngày'
                            : 'Ngày ISO: ${(item['weekdays'] as List).join(', ')}',
                      ),
                    if (widget.section == 'recovery')
                      Text(
                        '${item['sleepStart']} → ${item['sleepEnd']}\nNgủ ${item['quality'] ?? 'Chưa biết'} · Mệt ${item['fatigue'] ?? 'Chưa biết'} · Đau cơ ${item['soreness'] ?? 'Chưa biết'}',
                      ),
                    if (item['note'] != null) Text(item['note'] as String),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () => edit(item),
                          child: const Text('Chỉnh sửa'),
                        ),
                        if (widget.section != 'recovery')
                          TextButton(
                            onPressed: () => history(item),
                            child: const Text('Ghi nhận / lịch sử'),
                          ),
                        if (!archived)
                          TextButton(
                            onPressed: () => archive(item),
                            child: const Text('Lưu trữ'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!loading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Chưa có mục nào.'),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: page == 0 || loading
                    ? null
                    : () {
                        setState(() => page--);
                        load();
                      },
                child: const Text('Trước'),
              ),
              Text('${page + 1}/${pages < 1 ? 1 : pages}'),
              TextButton(
                onPressed: page + 1 >= pages || loading
                    ? null
                    : () {
                        setState(() => page++);
                        load();
                      },
                child: const Text('Sau'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
