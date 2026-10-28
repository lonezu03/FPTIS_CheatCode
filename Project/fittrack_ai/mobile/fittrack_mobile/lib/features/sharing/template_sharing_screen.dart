import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';

const _labels = {
  'WORKOUT_PLAN': 'Giáo án',
  'MEAL_COLLECTION': 'Bữa ăn / công thức',
  'MEAL_WEEK': 'Thực đơn tuần',
};
List<Map<String, dynamic>> _rows(dynamic value) => (value as List? ?? [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();
List<String> sharingTemplateLines(dynamic data, Map names) {
  if (data is List) {
    return data.expand((e) => sharingTemplateLines(e, names)).toList();
  }
  if (data is! Map) return [];
  return [
    if (data['name'] != null)
      '${data['dayOffset'] != null ? 'Ngày ${(data['dayOffset'] as num).toInt() + 1} · ' : ''}${data['name']}',
    for (final day in data['days'] as List? ?? [])
      ...sharingTemplateLines(day, names),
    for (final e in _rows(data['exercises']))
      '${names[e['exerciseId']] ?? 'Bài tập không khả dụng'} · ${e['targetSets']} hiệp × ${e['targetReps']} lần · ${e['targetWeight']} kg${e['groupType'] != null ? ' · ${e['groupType'] == 'SUPERSET' ? 'Liên hoàn' : 'Vòng tập'}' : ''}',
    for (final i in _rows(data['items']))
      '${names[i['foodId']] ?? 'Thực phẩm không khả dụng'} · ${i['servingAmount']} ${i['servingUnit'] == 'SERVING'
          ? 'khẩu phần'
          : i['servingUnit'] == 'GRAM'
          ? 'g'
          : 'ml'}',
  ];
}

class TemplateSharingScreen extends StatefulWidget {
  const TemplateSharingScreen({super.key});
  @override
  State<TemplateSharingScreen> createState() => _TemplateSharingScreenState();
}

class _TemplateSharingScreenState extends State<TemplateSharingScreen> {
  final email = TextEditingController();
  String kind = 'WORKOUT_PLAN', source = '', week = '', targetWeek = '';
  bool inbox = true, loading = true, busy = false;
  int page = 0,
      pages = 0,
      sourcePage = 0,
      sourcePages = 0,
      generation = 0,
      sourceGeneration = 0;
  List<Map<String, dynamic>> shares = [], sources = [];
  Map<String, dynamic>? preview;
  Object? error;
  String? operation, fingerprint;
  ApiClient get api => context.read<ApiClient>();
  List<String> get kinds {
    final user = context.read<AuthSession>().user;
    return [
      if (user?.isAdmin == true || user?.fitnessEnabled == true) 'WORKOUT_PLAN',
      if (user?.isAdmin == true || user?.healthEnabled == true) ...[
        'MEAL_COLLECTION',
        'MEAL_WEEK',
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kinds.contains(kind) && kinds.isNotEmpty) kind = kinds.first;
      load();
      loadSources();
    });
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final token = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.get(
        '/template-shares',
        queryParameters: {'inbox': inbox, 'page': page, 'size': 12},
      );
      if (mounted && token == generation) {
        setState(() {
          shares = _rows(data['content']);
          pages = (data['totalPages'] as num).toInt();
        });
      }
    } catch (e) {
      if (mounted && token == generation) setState(() => error = e);
    } finally {
      if (mounted && token == generation) setState(() => loading = false);
    }
  }

  Future<void> loadSources() async {
    final requested = kind;
    final requestedPage = sourcePage;
    final token = ++sourceGeneration;
    setState(() {
      sources = [];
      source = kind == 'MEAL_WEEK' ? week : '';
    });
    try {
      List<Map<String, dynamic>> values = [];
      int count = 0;
      if (kind == 'WORKOUT_PLAN') {
        final data = await api.get(
          '/workout-plans/page',
          queryParameters: {'page': requestedPage, 'size': 20},
        );
        values = _rows(data['content']);
        count = (data['totalPages'] as num).toInt();
      } else if (kind == 'MEAL_COLLECTION') {
        final data = await api.get('/nutrition/convenience');
        values = [..._rows(data['savedMeals']), ..._rows(data['recipes'])];
      }
      if (mounted &&
          kind == requested &&
          sourcePage == requestedPage &&
          token == sourceGeneration) {
        setState(() {
          sources = values;
          sourcePages = count;
        });
      }
    } catch (e) {
      if (mounted && token == sourceGeneration) setState(() => error = e);
    }
  }

  Future<void> mutate(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Xác nhận'),
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
  Future<void> pickWeek(bool target) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final monday = picked.subtract(Duration(days: picked.weekday - 1));
    final text =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    setState(() {
      if (target) {
        targetWeek = text;
      } else {
        week = text;
        source = text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allowed = kinds;
    if (allowed.isEmpty) {
      return const Center(child: Text('Chưa có quyền chia sẻ bản mẫu.'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ bản mẫu')),
      body: AbsorbPointer(
        absorbing: busy,
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Chỉ chia sẻ bản mẫu được chọn tới một tài khoản có quyền. Không gửi lịch sử tập, nhật ký đã ăn, số đo hoặc tài chính. Thu hồi không xóa bản người nhận đã sao chép.',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: allowed.contains(kind)
                            ? kind
                            : allowed.first,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Loại mẫu',
                        ),
                        items: allowed
                            .map(
                              (k) => DropdownMenuItem(
                                value: k,
                                child: Text(_labels[k]!),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            kind = v!;
                            source = '';
                            sourcePage = 0;
                            sources = [];
                          });
                          loadSources();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 254,
                        decoration: const InputDecoration(
                          labelText: 'Email tài khoản người nhận',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (kind == 'MEAL_WEEK')
                        OutlinedButton(
                          onPressed: () => pickWeek(false),
                          child: Text(
                            week.isEmpty ? 'Chọn tuần muốn gửi' : 'Tuần $week',
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$kind/$sourcePage/${sources.length}/$source',
                          ),
                          initialValue: source.isEmpty ? null : source,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Bản mẫu của bạn',
                          ),
                          items: sources
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s['id'] as String,
                                  child: Text(
                                    s['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => source = v!),
                        ),
                        if (kind == 'WORKOUT_PLAN')
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton(
                                onPressed: sourcePage == 0
                                    ? null
                                    : () {
                                        setState(() {
                                          sourcePage--;
                                          source = '';
                                        });
                                        loadSources();
                                      },
                                child: const Text('Trước'),
                              ),
                              Text('Trang ${sourcePage + 1}'),
                              TextButton(
                                onPressed: sourcePage + 1 >= sourcePages
                                    ? null
                                    : () {
                                        setState(() {
                                          sourcePage++;
                                          source = '';
                                        });
                                        loadSources();
                                      },
                                child: const Text('Sau'),
                              ),
                            ],
                          ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: source.isEmpty
                            ? null
                            : () async {
                                if (!email.text.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Nhập email người nhận hợp lệ.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (!await confirm(
                                  'Gửi bản mẫu tới ${email.text.trim()}? Hiệu lực 7 ngày; người nhận có thể tạo bản sao riêng.',
                                )) {
                                  return;
                                }
                                await mutate(() async {
                                  final next =
                                      '$kind/$source/${email.text.trim()}';
                                  if (fingerprint != next) {
                                    fingerprint = next;
                                    operation =
                                        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
                                  }
                                  await api.post(
                                    '/template-shares',
                                    data: {
                                      'kind': kind,
                                      'sourceId': source,
                                      'recipientEmail': email.text.trim(),
                                      'operationId': operation,
                                      'expiresInDays': 7,
                                    },
                                  );
                                  operation = null;
                                  fingerprint = null;
                                });
                              },
                        child: const Text('Gửi bản mẫu — 7 ngày'),
                      ),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('Được chia sẻ'),
                    selected: inbox,
                    onSelected: (_) {
                      setState(() {
                        inbox = true;
                        page = 0;
                        preview = null;
                      });
                      load();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Đã gửi'),
                    selected: !inbox,
                    onSelected: (_) {
                      setState(() {
                        inbox = false;
                        page = 0;
                        preview = null;
                      });
                      load();
                    },
                  ),
                ],
              ),
              if (loading || busy) const LinearProgressIndicator(),
              if (error != null)
                ErrorView(message: displayError(error!), onRetry: load),
              for (final s in shares)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${inbox ? 'Từ ${s['ownerName']}' : 'Tới ${s['recipientName']}'} · ${_labels[s['kind']]}',
                        ),
                        Text(
                          'Hết hạn ${s['expiresAt']} · ${s['active'] != true
                              ? 'Đã thu hồi'
                              : s['copiedAt'] != null
                              ? 'Đã sao chép'
                              : 'Chưa sao chép'}',
                        ),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: () => mutate(() async {
                                final data = await api.get(
                                  '/template-shares/${s['id']}',
                                );
                                if (mounted) {
                                  setState(
                                    () => preview = Map<String, dynamic>.from(
                                      data as Map,
                                    ),
                                  );
                                }
                              }),
                              child: const Text('Xem mẫu'),
                            ),
                            if (!inbox && s['active'] == true)
                              TextButton(
                                onPressed: () async {
                                  if (await confirm(
                                    'Thu hồi quyền truy cập? Bản đã sao chép vẫn được giữ.',
                                  )) {
                                    await mutate(() async {
                                      await api.delete(
                                        '/template-shares/${s['id']}?version=${s['version']}',
                                      );
                                      if (mounted) {
                                        setState(() => preview = null);
                                      }
                                    });
                                  }
                                },
                                child: const Text('Thu hồi'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (shares.isEmpty && !loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có bản mẫu.'),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: page == 0
                        ? null
                        : () {
                            setState(() => page--);
                            load();
                          },
                    child: const Text('Trước'),
                  ),
                  Text('${page + 1}/${max(1, pages)}'),
                  TextButton(
                    onPressed: page + 1 >= pages
                        ? null
                        : () {
                            setState(() => page++);
                            load();
                          },
                    child: const Text('Sau'),
                  ),
                ],
              ),
              if (preview != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          preview!['share']['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final line in sharingTemplateLines(
                          preview!['template'],
                          preview!['itemNames'] as Map? ?? {},
                        ))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(line),
                          ),
                        if ((preview!['unavailableItems'] as List).isNotEmpty)
                          const Text(
                            'Có món / bài tập không còn khả dụng. Nhờ người gửi cập nhật và chia sẻ lại.',
                          ),
                        if (inbox) ...[
                          const Text(
                            'Sao chép không ghi lịch sử tập hoặc nhật ký đã ăn.',
                          ),
                          if (preview!['share']['kind'] == 'MEAL_WEEK')
                            OutlinedButton(
                              onPressed: () => pickWeek(true),
                              child: Text(
                                targetWeek.isEmpty
                                    ? 'Chọn tuần đích'
                                    : targetWeek,
                              ),
                            ),
                          FilledButton(
                            onPressed:
                                (preview!['unavailableItems'] as List)
                                        .isNotEmpty ||
                                    preview!['share']['active'] != true ||
                                    (preview!['share']['kind'] == 'MEAL_WEEK' &&
                                        targetWeek.isEmpty)
                                ? null
                                : () async {
                                    if (!await confirm(
                                      'Tạo bản sao riêng trong tài khoản của bạn?',
                                    )) {
                                      return;
                                    }
                                    await mutate(() async {
                                      await api.post(
                                        '/template-shares/${preview!['share']['id']}/accept',
                                        data: {
                                          if (preview!['share']['kind'] ==
                                              'MEAL_WEEK')
                                            'targetWeek': targetWeek,
                                        },
                                      );
                                      if (mounted) {
                                        setState(() => preview = null);
                                      }
                                    });
                                  },
                            child: const Text('Sao chép vào tài khoản của tôi'),
                          ),
                        ],
                        TextButton(
                          onPressed: () => setState(() => preview = null),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
