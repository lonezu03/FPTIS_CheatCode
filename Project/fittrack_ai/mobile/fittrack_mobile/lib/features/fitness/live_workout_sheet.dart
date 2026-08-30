import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class LiveWorkoutSheet extends StatefulWidget {
  const LiveWorkoutSheet({super.key});

  @override
  State<LiveWorkoutSheet> createState() => _LiveWorkoutSheetState();
}

class _LiveWorkoutSheetState extends State<LiveWorkoutSheet> {
  final title = TextEditingController(text: 'Buổi tập tự do');
  final note = TextEditingController();
  final startedAt = DateTime.now();
  final previous = <String, Map<String, dynamic>?>{};

  List<Map<String, dynamic>> exercises = [];
  List<Map<String, dynamic>> plans = [];
  List<_DraftExercise> draft = [];
  String selectedPlanDay = '';
  bool busy = true;
  int elapsedSeconds = 0;
  int restSeconds = 0;
  Timer? elapsedTimer;
  Timer? restTimer;

  @override
  void initState() {
    super.initState();
    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    elapsedTimer?.cancel();
    restTimer?.cancel();
    title.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final values = await Future.wait([
        api.get('/exercises'),
        api.get('/workout-plans'),
      ]);
      exercises = _list(values[0]);
      plans = _list(values[1]);
      if (exercises.isNotEmpty) {
        final first = _DraftExercise(exercises.first['id'].toString());
        draft = [first];
        await _loadPrevious(first.exerciseId);
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    final raw = value is Map && value['content'] is List
        ? value['content']
        : value;
    return raw is List
        ? raw.map((item) => Map<String, dynamic>.from(item as Map)).toList()
        : [];
  }

  List<_PlanDayOption> get planDays {
    final result = <_PlanDayOption>[];
    for (final plan in plans) {
      final days = plan['days'] is List ? plan['days'] as List : const [];
      for (final rawDay in days) {
        final day = Map<String, dynamic>.from(rawDay as Map);
        result.add(
          _PlanDayOption(
            value: '${plan['id']}:${day['id']}',
            label: '${plan['name']} · ${day['name']}',
            day: day,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _loadPrevious(String exerciseId) async {
    if (previous.containsKey(exerciseId)) return;
    try {
      final raw = await context.read<ApiClient>().get(
        '/workouts/previous-performance',
        queryParameters: {'exerciseId': exerciseId},
      );
      if (!mounted) return;
      setState(() {
        previous[exerciseId] = raw is Map
            ? Map<String, dynamic>.from(raw)
            : null;
      });
    } catch (_) {
      if (mounted) setState(() => previous[exerciseId] = null);
    }
  }

  void _applyPlanDay() {
    _PlanDayOption? selected;
    for (final option in planDays) {
      if (option.value == selectedPlanDay) selected = option;
    }
    if (selected == null) {
      showMessage(context, 'Hãy chọn một ngày trong giáo án.', error: true);
      return;
    }
    final rawExercises = selected.day['exercises'] is List
        ? selected.day['exercises'] as List
        : const [];
    final next = rawExercises.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final targetSets = ((item['targetSets'] as num?)?.toInt() ?? 1).clamp(
        1,
        20,
      );
      return _DraftExercise(
        item['exerciseId'].toString(),
        sets: List.generate(
          targetSets,
          (_) => _DraftSet(
            weight: (item['targetWeight'] as num?)?.toDouble() ?? 0,
            reps: (item['targetReps'] as num?)?.toInt() ?? 10,
            rir: (item['targetRir'] as num?)?.toInt() ?? 2,
          ),
        ),
      );
    }).toList();
    if (next.isEmpty) {
      showMessage(context, 'Ngày tập này chưa có bài tập.', error: true);
      return;
    }
    setState(() {
      title.text = selected!.label;
      draft = next;
    });
    for (final exercise in next) {
      unawaited(_loadPrevious(exercise.exerciseId));
    }
  }

  void _startRest(int seconds) {
    restTimer?.cancel();
    setState(() => restSeconds = seconds.clamp(0, 1800));
    if (restSeconds <= 0) return;
    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (restSeconds <= 1) {
          restSeconds = 0;
          timer.cancel();
        } else {
          restSeconds--;
        }
      });
    });
  }

  Future<void> _save() async {
    final sets = <Map<String, dynamic>>[];
    for (var exerciseIndex = 0; exerciseIndex < draft.length; exerciseIndex++) {
      final exercise = draft[exerciseIndex];
      var setNumber = 0;
      for (final set in exercise.sets.where((item) => item.completed)) {
        setNumber++;
        sets.add({
          'exerciseId': exercise.exerciseId,
          'exerciseOrder': exerciseIndex + 1,
          'setNumber': setNumber,
          'setType': set.setType,
          'weight': set.weight,
          'reps': set.reps,
          'rir': set.rir,
          'restSeconds': exercise.restSeconds,
          'completed': true,
        });
      }
    }
    if (sets.isEmpty) {
      showMessage(
        context,
        'Hãy đánh dấu hoàn thành ít nhất một set.',
        error: true,
      );
      return;
    }

    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/workouts/sessions',
        data: {
          'sessionDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'note': [
            title.text.trim(),
            note.text.trim(),
          ].where((value) => value.isNotEmpty).join(' · '),
          'durationMinutes': (elapsedSeconds / 60).ceil().clamp(1, 600),
          'sets': sets,
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
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.92,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Workout mode',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: Text(_clock(elapsedSeconds)),
              ),
              IconButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                tooltip: 'Hủy buổi tập',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (restSeconds > 0)
            _RestTimer(
              seconds: restSeconds,
              onSubtract: () => setState(
                () => restSeconds = (restSeconds - 15).clamp(0, 1800),
              ),
              onAdd: () => setState(
                () => restSeconds = (restSeconds + 15).clamp(0, 1800),
              ),
              onSkip: () {
                restTimer?.cancel();
                setState(() => restSeconds = 0);
              },
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Tên buổi tập'),
                ),
                if (planDays.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPlanDay.isEmpty
                              ? null
                              : selectedPlanDay,
                          decoration: const InputDecoration(
                            labelText: 'Tập theo giáo án',
                          ),
                          items: planDays
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.value,
                                  child: Text(
                                    item.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedPlanDay = value ?? ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _applyPlanDay,
                        tooltip: 'Nạp ngày tập',
                        icon: const Icon(Icons.download_done),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (busy)
                  const Center(child: CircularProgressIndicator())
                else if (draft.isEmpty)
                  const EmptyView(
                    icon: Icons.fitness_center,
                    title: 'Kho bài tập đang trống',
                    subtitle: 'Cần ít nhất một bài đã được duyệt để bắt đầu.',
                  )
                else
                  ...draft.asMap().entries.map(
                    (entry) => _ExerciseEditor(
                      key: ValueKey(entry.value.key),
                      index: entry.key,
                      exercise: entry.value,
                      exercises: exercises,
                      previous: previous[entry.value.exerciseId],
                      canDelete: draft.length > 1,
                      onChanged: () => setState(() {}),
                      onExerciseChanged: (id) {
                        setState(() => entry.value.exerciseId = id);
                        unawaited(_loadPrevious(id));
                      },
                      onMoveUp: entry.key == 0
                          ? null
                          : () => setState(() {
                              final item = draft.removeAt(entry.key);
                              draft.insert(entry.key - 1, item);
                            }),
                      onDelete: draft.length <= 1
                          ? null
                          : () => setState(() => draft.removeAt(entry.key)),
                      onSetCompleted: (set) {
                        setState(() => set.completed = !set.completed);
                        if (set.completed) _startRest(entry.value.restSeconds);
                      },
                    ),
                  ),
                if (!busy && exercises.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      final item = _DraftExercise(
                        exercises.first['id'].toString(),
                      );
                      setState(() => draft.add(item));
                      unawaited(_loadPrevious(item.exerciseId));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bài tập'),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú buổi tập',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: busy ? null : _save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(busy ? 'Đang lưu...' : 'Hoàn thành buổi tập'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    super.key,
    required this.index,
    required this.exercise,
    required this.exercises,
    required this.previous,
    required this.canDelete,
    required this.onChanged,
    required this.onExerciseChanged,
    required this.onMoveUp,
    required this.onDelete,
    required this.onSetCompleted,
  });

  final int index;
  final _DraftExercise exercise;
  final List<Map<String, dynamic>> exercises;
  final Map<String, dynamic>? previous;
  final bool canDelete;
  final VoidCallback onChanged;
  final ValueChanged<String> onExerciseChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onDelete;
  final ValueChanged<_DraftSet> onSetCompleted;

  @override
  Widget build(BuildContext context) {
    final previousSets = previous?['sets'] is List
        ? previous!['sets'] as List
        : const [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 15, child: Text('${index + 1}')),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: exercise.exerciseId,
                    decoration: const InputDecoration(labelText: 'Bài tập'),
                    items: exercises
                        .map(
                          (item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text(
                              item['name']?.toString() ?? 'Bài tập',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onExerciseChanged(value);
                    },
                  ),
                ),
                IconButton(
                  onPressed: onMoveUp,
                  tooltip: 'Đưa bài lên',
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  onPressed: canDelete ? onDelete : null,
                  tooltip: 'Xóa bài',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                previous == null
                    ? 'Chưa có dữ liệu lần tập trước'
                    : 'Lần gần nhất ${previous!['sessionDate']}: ${previousSets.map((raw) {
                        final set = raw as Map;
                        return '${set['weight']}kg × ${set['reps']}';
                      }).join(' · ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Nghỉ giữa set'),
                const SizedBox(width: 10),
                SizedBox(
                  width: 105,
                  child: TextFormField(
                    initialValue: '${exercise.restSeconds}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'giây'),
                    onChanged: (value) {
                      exercise.restSeconds =
                          int.tryParse(value)?.clamp(0, 1800) ?? 90;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...exercise.sets.asMap().entries.map(
              (entry) => _SetEditor(
                key: ValueKey(entry.value.key),
                number: entry.key + 1,
                set: entry.value,
                onChanged: onChanged,
                onCompleted: () => onSetCompleted(entry.value),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final last = exercise.sets.last;
                    exercise.sets.add(
                      _DraftSet(
                        weight: last.weight,
                        reps: last.reps,
                        rir: last.rir,
                      ),
                    );
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm set'),
                ),
                TextButton(
                  onPressed: exercise.sets.length <= 1
                      ? null
                      : () {
                          exercise.sets.removeLast();
                          onChanged();
                        },
                  child: const Text('Bỏ set cuối'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetEditor extends StatelessWidget {
  const _SetEditor({
    super.key,
    required this.number,
    required this.set,
    required this.onChanged,
    required this.onCompleted,
  });

  final int number;
  final _DraftSet set;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: set.completed ? const Color(0xFFE9F8F0) : const Color(0xFFF5F7F6),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              'Set $number',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: set.setType,
                decoration: const InputDecoration(labelText: 'Loại set'),
                items: const [
                  DropdownMenuItem(value: 'WARMUP', child: Text('Khởi động')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('Chính')),
                  DropdownMenuItem(value: 'DROP', child: Text('Drop set')),
                  DropdownMenuItem(value: 'FAILURE', child: Text('Tới ngưỡng')),
                ],
                onChanged: (value) => set.setType = value ?? 'NORMAL',
              ),
            ),
            Checkbox(value: set.completed, onChanged: (_) => onCompleted()),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _decimalInput(
                'Kg',
                set.weight,
                (value) => set.weight = value,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _integerInput(
                'Reps',
                set.reps,
                (value) => set.reps = value.clamp(1, 500),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _integerInput(
                'RIR',
                set.rir,
                (value) => set.rir = value.clamp(0, 10),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({
    required this.seconds,
    required this.onSubtract,
    required this.onAdd,
    required this.onSkip,
  });

  final int seconds;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF073B2C),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nghỉ ${_clock(seconds)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(onPressed: onSubtract, child: const Text('-15s')),
          TextButton(onPressed: onAdd, child: const Text('+15s')),
          IconButton(
            color: Colors.white,
            onPressed: onSkip,
            tooltip: 'Bỏ qua',
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    ),
  );
}

class _PlanDayOption {
  const _PlanDayOption({
    required this.value,
    required this.label,
    required this.day,
  });

  final String value;
  final String label;
  final Map<String, dynamic> day;
}

class _DraftExercise {
  _DraftExercise(this.exerciseId, {List<_DraftSet>? sets})
    : key = '${DateTime.now().microsecondsSinceEpoch}-${_nextKey++}',
      sets = sets ?? [_DraftSet()];

  static int _nextKey = 0;
  final String key;
  String exerciseId;
  int restSeconds = 90;
  final List<_DraftSet> sets;
}

class _DraftSet {
  _DraftSet({this.weight = 10, this.reps = 10, this.rir = 2})
    : key = '${DateTime.now().microsecondsSinceEpoch}-${_nextKey++}';

  static int _nextKey = 0;
  final String key;
  String setType = 'NORMAL';
  double weight;
  int reps;
  int rir;
  bool completed = false;
}

Widget _decimalInput(
  String label,
  double value,
  ValueChanged<double> onChanged,
) => TextFormField(
  initialValue: '$value',
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(labelText: label),
  onChanged: (raw) => onChanged(double.tryParse(raw) ?? 0),
);

Widget _integerInput(String label, int value, ValueChanged<int> onChanged) =>
    TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (raw) => onChanged(int.tryParse(raw) ?? 0),
    );

String _clock(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
