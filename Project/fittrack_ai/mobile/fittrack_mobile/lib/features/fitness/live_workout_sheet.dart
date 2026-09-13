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
  final intelligence = <String, Map<String, dynamic>?>{};
  final preferences = <String, String>{};
  final announcedRecords = <String>{};

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
      try {
        final preferenceRaw = await api.get('/workouts/exercise-preferences');
        for (final item in _list(preferenceRaw)) {
          preferences[item['exerciseId'].toString()] =
              item['preference']?.toString() ?? 'NORMAL';
        }
      } catch (_) {
        // Preference is optional context; a failed request must not block a workout.
      }
      if (exercises.isNotEmpty) {
        final first = _DraftExercise(exercises.first['id'].toString());
        draft = [first];
        await _loadIntelligence(first);
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

  Future<void> _loadIntelligence(_DraftExercise exercise) async {
    final key = exercise.intelligenceKey;
    if (intelligence.containsKey(key)) return;
    try {
      final raw = await context.read<ApiClient>().get(
        '/workouts/intelligence',
        queryParameters: {
          'exerciseId': exercise.exerciseId,
          'targetSets': exercise.targetSets,
          'minReps': exercise.minReps,
          'maxReps': exercise.maxReps,
          'targetRir': exercise.targetRir,
        },
      );
      if (!mounted) return;
      setState(() {
        intelligence[key] = raw is Map ? Map<String, dynamic>.from(raw) : null;
      });
    } catch (_) {
      if (mounted) setState(() => intelligence[key] = null);
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
        targetSets: targetSets,
        minReps: (((item['targetReps'] as num?)?.toInt() ?? 10) - 2).clamp(
          1,
          500,
        ),
        maxReps: (item['targetReps'] as num?)?.toInt() ?? 10,
        targetRir: (item['targetRir'] as num?)?.toInt() ?? 2,
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
      unawaited(_loadIntelligence(exercise));
    }
  }

  Future<void> _setPreference(String exerciseId, String preference) async {
    final oldValue = preferences[exerciseId] ?? 'NORMAL';
    setState(() => preferences[exerciseId] = preference);
    try {
      await context.read<ApiClient>().put(
        '/workouts/exercise-preferences/$exerciseId',
        data: {'preference': preference},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => preferences[exerciseId] = oldValue);
      showMessage(context, displayError(error), error: true);
    }
  }

  Future<void> _showAlternatives(_DraftExercise exercise) async {
    try {
      final raw = await context.read<ApiClient>().get(
        '/workouts/exercises/${exercise.exerciseId}/alternatives',
      );
      final alternatives = _list(raw);
      if (!mounted) return;
      if (alternatives.isEmpty) {
        showMessage(context, 'Chưa có bài thay thế phù hợp đã được duyệt.');
        return;
      }
      final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Chọn bài tương đương',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...alternatives.map((item) {
                final candidate = item['exercise'] is Map
                    ? Map<String, dynamic>.from(item['exercise'] as Map)
                    : <String, dynamic>{};
                return ListTile(
                  leading: Icon(
                    item['preference'] == 'FAVORITE'
                        ? Icons.star
                        : Icons.swap_horiz,
                    color: item['preference'] == 'FAVORITE'
                        ? Colors.amber.shade700
                        : null,
                  ),
                  title: Text(candidate['name']?.toString() ?? 'Bài tập'),
                  subtitle: Text(
                    '${candidate['equipment'] ?? 'Không rõ dụng cụ'}${item['sameEquipment'] == true ? ' · Cùng dụng cụ' : ''}',
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, candidate['id']?.toString()),
                );
              }),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => exercise.exerciseId = selected);
      unawaited(_loadIntelligence(exercise));
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  void _applyProgression(_DraftExercise exercise) {
    final suggestion = intelligence[exercise.intelligenceKey]?['progression'];
    if (suggestion is! Map || suggestion['suggestedWeight'] == null) return;
    final count = ((suggestion['suggestedSets'] as num?)?.toInt() ?? 1).clamp(
      1,
      20,
    );
    setState(() {
      exercise.sets
        ..clear()
        ..addAll(
          List.generate(
            count,
            (_) => _DraftSet(
              weight: (suggestion['suggestedWeight'] as num).toDouble(),
              reps:
                  (suggestion['suggestedMinReps'] as num?)?.toInt() ??
                  exercise.minReps,
              rir:
                  (suggestion['targetRir'] as num?)?.toInt() ??
                  exercise.targetRir,
            ),
          ),
        );
    });
    showMessage(context, 'Đã áp dụng mức đề xuất vào các set.');
  }

  void _announcePotentialRecord(_DraftExercise exercise, _DraftSet set) {
    if (set.setType == 'WARMUP') return;
    final bests = intelligence[exercise.intelligenceKey]?['personalBests'];
    if (bests is! List) return;
    double bestWeight = 0;
    double bestEstimated = 0;
    for (final raw in bests.whereType<Map>()) {
      final value = (raw['value'] as num?)?.toDouble() ?? 0;
      if (raw['type'] == 'HEAVIEST_WEIGHT') bestWeight = value;
      if (raw['type'] == 'ESTIMATED_1RM') bestEstimated = value;
    }
    final estimated = set.weight > 0 && set.reps <= 30
        ? set.weight * (1 + set.reps / 30)
        : 0.0;
    final candidates = <({String key, bool achieved, String message})>[
      (
        key: '${set.key}:weight',
        achieved: set.weight > bestWeight,
        message: 'Có thể là PR mới: ${_number(set.weight)} kg.',
      ),
      (
        key: '${set.key}:e1rm',
        achieved: estimated > bestEstimated,
        message: 'Có thể là PR e1RM mới: ${_number(estimated)} kg.',
      ),
    ];
    for (final candidate in candidates) {
      if (candidate.achieved && announcedRecords.add(candidate.key)) {
        showMessage(context, '🏆 ${candidate.message}');
      }
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
      final result = await context.read<ApiClient>().post(
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
      if (!mounted) return;
      final records = result is Map && result['newPersonalRecords'] is List
          ? result['newPersonalRecords'] as List
          : const [];
      if (records.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
            title: const Text('Kỷ lục cá nhân mới!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: records.map((raw) {
                final record = raw as Map;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${record['exerciseName']}: ${_recordLabel(record['type']?.toString())} ${_number(record['newValue'])} ${record['unit'] ?? ''}',
                  ),
                );
              }).toList(),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tuyệt vời'),
              ),
            ],
          ),
        );
      }
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
                      intelligence: intelligence[entry.value.intelligenceKey],
                      preference:
                          preferences[entry.value.exerciseId] ?? 'NORMAL',
                      canDelete: draft.length > 1,
                      onChanged: () => setState(() {}),
                      onExerciseChanged: (id) {
                        setState(() => entry.value.exerciseId = id);
                        unawaited(_loadIntelligence(entry.value));
                      },
                      onPreferenceChanged: (value) =>
                          _setPreference(entry.value.exerciseId, value),
                      onShowAlternatives: () => _showAlternatives(entry.value),
                      onApplyProgression: () => _applyProgression(entry.value),
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
                        final willComplete = !set.completed;
                        setState(() => set.completed = !set.completed);
                        if (willComplete) {
                          _announcePotentialRecord(entry.value, set);
                          _startRest(entry.value.restSeconds);
                        }
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
                      unawaited(_loadIntelligence(item));
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
    required this.intelligence,
    required this.preference,
    required this.canDelete,
    required this.onChanged,
    required this.onExerciseChanged,
    required this.onPreferenceChanged,
    required this.onShowAlternatives,
    required this.onApplyProgression,
    required this.onMoveUp,
    required this.onDelete,
    required this.onSetCompleted,
  });

  final int index;
  final _DraftExercise exercise;
  final List<Map<String, dynamic>> exercises;
  final Map<String, dynamic>? intelligence;
  final String preference;
  final bool canDelete;
  final VoidCallback onChanged;
  final ValueChanged<String> onExerciseChanged;
  final ValueChanged<String> onPreferenceChanged;
  final VoidCallback onShowAlternatives;
  final VoidCallback onApplyProgression;
  final VoidCallback? onMoveUp;
  final VoidCallback? onDelete;
  final ValueChanged<_DraftSet> onSetCompleted;

  @override
  Widget build(BuildContext context) {
    final previous = intelligence?['previousPerformance'];
    final previousSets = previous is Map && previous['sets'] is List
        ? previous['sets'] as List
        : const [];
    final progression = intelligence?['progression'];
    final bests = intelligence?['personalBests'] is List
        ? intelligence!['personalBests'] as List
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
                previous is! Map
                    ? 'Chưa có dữ liệu lần tập trước'
                    : 'Lần gần nhất ${previous['sessionDate']}: ${previousSets.map((raw) {
                        final set = raw as Map;
                        return '${set['weight']}kg × ${set['reps']}';
                      }).join(' · ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (progression is Map) ...[
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _progressionLabel(
                              progression['action']?.toString(),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (progression['suggestedWeight'] != null)
                          TextButton(
                            onPressed: onApplyProgression,
                            child: Text(
                              'Áp dụng ${_number(progression['suggestedWeight'])} kg',
                            ),
                          ),
                      ],
                    ),
                    Text(
                      progression['explanation']?.toString() ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else
                    Text(
                      'Đang tải đề xuất...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (bests.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: bests.map((raw) {
                        final best = raw as Map;
                        return Chip(
                          avatar: const Icon(Icons.emoji_events, size: 15),
                          label: Text(
                            '${_recordLabel(best['type']?.toString())}: ${_number(best['value'])}',
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PopupMenuButton<String>(
                  initialValue: preference,
                  onSelected: onPreferenceChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'FAVORITE',
                      child: Text('★ Yêu thích'),
                    ),
                    PopupMenuItem(value: 'NORMAL', child: Text('Bình thường')),
                    PopupMenuItem(value: 'LESS', child: Text('Ít ưu tiên')),
                    PopupMenuItem(
                      value: 'EXCLUDED',
                      child: Text('Không đề xuất'),
                    ),
                  ],
                  child: Chip(
                    avatar: Icon(
                      preference == 'FAVORITE' ? Icons.star : Icons.tune,
                      size: 17,
                    ),
                    label: Text(_preferenceLabel(preference)),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 17),
                  label: const Text('Đổi bài tương đương'),
                  onPressed: onShowAlternatives,
                ),
              ],
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
  _DraftExercise(
    this.exerciseId, {
    List<_DraftSet>? sets,
    this.targetSets = 3,
    this.minReps = 8,
    this.maxReps = 12,
    this.targetRir = 2,
  }) : key = '${DateTime.now().microsecondsSinceEpoch}-${_nextKey++}',
       sets = sets ?? List.generate(3, (_) => _DraftSet());

  static int _nextKey = 0;
  final String key;
  String exerciseId;
  int restSeconds = 90;
  final int targetSets;
  final int minReps;
  final int maxReps;
  final int targetRir;
  final List<_DraftSet> sets;

  String get intelligenceKey =>
      '$exerciseId:$targetSets:$minReps:$maxReps:$targetRir';
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

String _progressionLabel(String? action) => switch (action) {
  'INCREASE_WEIGHT' => 'Sẵn sàng tăng tạ',
  'BUILD_REPS' => 'Tiếp tục tăng số lần lặp',
  'DECREASE_OR_HOLD' => 'Giữ hoặc giảm nhẹ mức tạ',
  _ => 'Mốc khởi đầu',
};

String _preferenceLabel(String value) => switch (value) {
  'FAVORITE' => 'Yêu thích',
  'LESS' => 'Ít ưu tiên',
  'EXCLUDED' => 'Không đề xuất',
  _ => 'Bình thường',
};

String _recordLabel(String? type) => switch (type) {
  'HEAVIEST_WEIGHT' => 'Mức tạ cao nhất',
  'MAX_REPS_AT_WEIGHT' => 'Số lần lặp cao nhất',
  'ESTIMATED_1RM' => 'e1RM ước tính',
  'MAX_SESSION_VOLUME' => 'Volume buổi cao nhất',
  _ => 'Kỷ lục',
};

String _number(dynamic value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return '-';
  return NumberFormat('#,##0.#', 'vi_VN').format(number);
}
