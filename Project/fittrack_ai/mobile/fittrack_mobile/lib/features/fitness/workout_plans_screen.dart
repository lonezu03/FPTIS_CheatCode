import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/module_draft_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import '../catalog/catalog_exercise_picker.dart';
import '../catalog/catalog_image.dart';
import 'live_workout_sheet.dart';
import 'training_data.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});
  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  List<Map<String, dynamic>> plans = [];
  bool loading = true;
  Object? error;
  int page = 0, pages = 0;
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
      final raw = await context.read<ApiClient>().get(
        '/workout-plans/page',
        queryParameters: {'page': page, 'size': 12},
      );
      if (!mounted) return;
      setState(() {
        plans = trainingList(raw);
        pages = (raw['totalPages'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([
    Map<String, dynamic>? plan,
    bool duplicate = false,
  ]) async {
    final copy = plan == null ? null : trainingCopy(plan);
    if (duplicate && copy != null) {
      copy.remove('id');
      copy.remove('version');
      copy['name'] = '${copy['name']} (bản sao)';
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlanEditor(initial: copy),
    );
    if (saved == true) load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: load);
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PageIntro(
            title: 'Giáo án',
            subtitle: 'Thiết lập ngày tập, chọn nhiều bài và bắt đầu tập mà chưa ghi vào lịch sử.',
          ),
          FilledButton.icon(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Tạo giáo án'),
          ),
          if (plans.isEmpty)
            const EmptyView(
              icon: Icons.fitness_center,
              title: 'Chưa có giáo án',
              subtitle: 'Tạo lịch tập phù hợp với mục tiêu của bạn.',
            ),
          ...plans.map(
            (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      p['name']?.toString() ?? 'Giáo án',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(p['description']?.toString() ?? ''),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => edit(p),
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa'),
                        ),
                        TextButton.icon(
                          onPressed: () => edit(p, true),
                          icon: const Icon(Icons.copy),
                          label: const Text('Nhân bản'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Xóa giáo án?'),
                                content: const Text(
                                  'Buổi tập đã lưu không bị xóa.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Hủy'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (yes != true || !context.mounted) return;
                            try {
                              await context.read<ApiClient>().delete(
                                '/workout-plans/${p['id']}',
                              );
                              await load();
                            } catch (e) {
                              if (context.mounted) {
                                showMessage(
                                  context,
                                  displayError(e),
                                  error: true,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                    ...trainingList(p['days']).map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(d['name']?.toString() ?? 'Ngày tập'),
                        subtitle: Text(
                          '${trainingList(d['exercises']).length} bài tập',
                        ),
                        trailing: IconButton(
                          tooltip: 'Bắt đầu tập',
                          icon: const Icon(Icons.play_circle_outline),
                          onPressed: () => showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => LiveWorkoutSheet(planDay: d),
                          ),
                        ),
                      ),
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
              Text('${page + 1}/${pages == 0 ? 1 : pages}'),
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
        ],
      ),
    );
  }
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({this.initial});
  final Map<String, dynamic>? initial;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  late Map<String, dynamic> plan;
  bool busy = true;
  String owner = '';
  String get slot => 'workout-plan:${widget.initial?['id'] ?? 'new'}';
  @override
  void initState() {
    super.initState();
    plan = widget.initial == null
        ? {'name': '', 'description': '', 'days': <Map<String, dynamic>>[]}
        : trainingCopy(widget.initial!);
    WidgetsBinding.instance.addPostFrameCallback((_) => restore());
  }

  Future<void> restore() async {
    owner = context.read<AuthSession>().user?.id ?? '';
    try {
      final saved = await ModuleDraftStore.read(owner, slot);
      if (!mounted) return;
      if (saved != null) {
        // A draft may not overwrite a newer server version silently.
        final stale = saved['version'] != plan['version'];
        final yes = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              stale ? 'Bản nháp đã cũ' : 'Khôi phục giáo án đang soạn?',
            ),
            content: Text(
              stale
                  ? 'Giáo án trên máy chủ đã đổi. Bản nháp sẽ được mở thành bản sao mới.'
                  : 'Tiếp tục từ bản nháp riêng trên thiết bị.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Bỏ nháp'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Khôi phục'),
              ),
            ],
          ),
        );
        if (yes == true) {
          plan = saved;
          if (stale) {
            plan.remove('id');
            plan.remove('version');
          }
        } else {
          await ModuleDraftStore.remove(owner, slot);
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Map<String, dynamic>> get days =>
      (plan['days'] as List).cast<Map<String, dynamic>>();
  void move(List list, int index, int delta) {
    final item = list.removeAt(index);
    list.insert(index + delta, item);
    setState(() {});
  }

  Future<void> save({bool draft = false}) async {
    setState(() => busy = true);
    try {
      if (draft) {
        await ModuleDraftStore.write(owner, slot, plan);
      } else {
        if (plan['name'].toString().trim().isEmpty ||
            days.isEmpty ||
            days.any(
              (d) =>
                  d['name'].toString().trim().isEmpty ||
                  trainingList(d['exercises']).isEmpty,
            )) {
          throw StateError(
            'Điền tên giáo án, tên ngày và ít nhất một bài trong mỗi ngày.',
          );
        }
        final api = context.read<ApiClient>();
        final payload = trainingPlanPayload(plan);
        if (plan['id'] == null) {
          await api.post('/workout-plans', data: payload);
        } else {
          await api.put('/workout-plans/${plan['id']}', data: payload);
        }
        await ModuleDraftStore.remove(owner, slot);
      }
      if (mounted) Navigator.pop(context, !draft);
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(
    Map<String, dynamic> item,
    String field,
    String label, {
    bool decimal = false,
    bool text = false,
  }) => SizedBox(
    width: text ? double.infinity : 140,
    child: TextFormField(
      key: ValueKey('${identityHashCode(item)}:$field'),
      initialValue: '${item[field] ?? ''}',
      decoration: InputDecoration(labelText: label),
      maxLines: text ? null : 1,
      keyboardType: text
          ? TextInputType.text
          : TextInputType.numberWithOptions(decimal: decimal),
      onChanged: (v) => item[field] = text
          ? v
          : decimal
          ? double.tryParse(v)
          : int.tryParse(v),
    ),
  );
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .94,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thiết lập giáo án',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: busy,
                child: ListView(
                  children: [
                    input(plan, 'name', 'Tên giáo án *', text: true),
                    const SizedBox(height: 10),
                    input(plan, 'description', 'Mục tiêu / mô tả', text: true),
                    ...days.asMap().entries.map((entry) {
                      final d = entry.value;
                      final exercises = (d['exercises'] as List)
                          .cast<Map<String, dynamic>>();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              input(d, 'name', 'Tên ngày tập *', text: true),
                              Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Lên',
                                    onPressed: entry.key > 0
                                        ? () =>
                                              move(plan['days'], entry.key, -1)
                                        : null,
                                    icon: const Icon(Icons.arrow_upward),
                                  ),
                                  IconButton(
                                    tooltip: 'Xuống',
                                    onPressed: entry.key + 1 < days.length
                                        ? () => move(plan['days'], entry.key, 1)
                                        : null,
                                    icon: const Icon(Icons.arrow_downward),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => (plan['days'] as List).add(
                                        trainingCopy(d),
                                      ),
                                    ),
                                    child: const Text('Nhân bản ngày'),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa ngày',
                                    onPressed: () => setState(
                                      () => (plan['days'] as List).removeAt(
                                        entry.key,
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              ...exercises.asMap().entries.map((exerciseEntry) {
                                final e = exerciseEntry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        e['exerciseName']?.toString() ??
                                            'Bài tập',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${e['muscleGroup'] ?? ''} · ${e['equipment'] ?? ''}',
                                      ),
                                      if (e['imageUrl']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        CatalogImage(
                                          e['imageUrl'].toString(),
                                          height: 100,
                                          fit: BoxFit.contain,
                                        ),
                                      if (e['description']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        Text(e['description'].toString()),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 10,
                                        children: [
                                          input(e, 'targetSets', 'Số hiệp *'),
                                          input(
                                            e,
                                            'targetReps',
                                            'Lần lặp/hiệp *',
                                          ),
                                          input(
                                            e,
                                            'targetWeight',
                                            'Mức tạ (kg)',
                                            decimal: true,
                                          ),
                                          input(e, 'targetRir', 'RIR (0–10)'),
                                          input(
                                            e,
                                            'restSeconds',
                                            'Nghỉ (giây)',
                                          ),
                                          input(
                                            e,
                                            'minReps',
                                            'Lần lặp tối thiểu',
                                          ),
                                          input(e, 'maxReps', 'Lần lặp tối đa'),
                                        ],
                                      ),
                                      input(
                                        e,
                                        'coachingNote',
                                        'Ghi chú kỹ thuật',
                                        text: true,
                                      ),
                                      Wrap(
                                        children: [
                                          IconButton(
                                            tooltip: 'Đưa bài lên',
                                            onPressed: exerciseEntry.key > 0
                                                ? () => move(
                                                    d['exercises'],
                                                    exerciseEntry.key,
                                                    -1,
                                                  )
                                                : null,
                                            icon: const Icon(
                                              Icons.arrow_upward,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Đưa bài xuống',
                                            onPressed:
                                                exerciseEntry.key + 1 <
                                                    exercises.length
                                                ? () => move(
                                                    d['exercises'],
                                                    exerciseEntry.key,
                                                    1,
                                                  )
                                                : null,
                                            icon: const Icon(
                                              Icons.arrow_downward,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Xóa bài',
                                            onPressed: () => setState(
                                              () => (d['exercises'] as List)
                                                  .removeAt(exerciseEntry.key),
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final selected =
                                      await showCatalogExercisePicker(
                                        context,
                                        multiple: true,
                                      );
                                  if (!mounted || selected == null) return;
                                  setState(() {
                                    for (final e in selected) {
                                      (d['exercises'] as List).add({
                                        ...e,
                                        'exerciseId': e['id'],
                                        'exerciseName': e['name'],
                                        'targetSets': 3,
                                        'targetReps': 10,
                                        'targetWeight': 0.0,
                                        'targetRir': 2,
                                        'restSeconds': 90,
                                        'minReps': 8,
                                        'maxReps': 12,
                                        'coachingNote': '',
                                      });
                                    }
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Chọn nhiều bài tập'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => (plan['days'] as List).add({
                          'name': 'Ngày ${days.length + 1}',
                          'exercises': <Map<String, dynamic>>[],
                        }),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm ngày tập'),
                    ),
                    const Text(
                      'RIR: số lần còn có thể lặp. Nghỉ giữa hiệp tính bằng giây. Giáo án chỉ là mục tiêu, chưa phải buổi đã hoàn thành.',
                    ),
                  ],
                ),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: busy ? null : () => save(draft: true),
                  child: const Text('Lưu nháp và đóng'),
                ),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: const Text('Lưu giáo án'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
