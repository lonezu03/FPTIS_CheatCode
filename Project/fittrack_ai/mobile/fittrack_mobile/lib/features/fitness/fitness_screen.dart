import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});
  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  List<Map<String, dynamic>> workouts = [];
  List<Map<String, dynamic>> meals = [];
  Object? error;
  bool loading = true;

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
      final values = await Future.wait([
        api.get('/workouts/sessions'),
        api.get('/nutrition/meal-logs'),
      ]);
      if (!mounted) return;
      setState(() {
        workouts = _list(values[0]);
        meals = _list(values[1]);
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    final raw = value is Map && value['content'] is List
        ? value['content']
        : value;
    return raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
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
                title: 'Luyện tập & dinh dưỡng',
                subtitle: 'Ghi lại buổi tập và bữa ăn bằng dữ liệu rõ ràng, có đơn vị.',
              ),
              const SizedBox(height: 14),
              TabBar(
                controller: tabs,
                tabs: const [
                  Tab(text: 'Buổi tập', icon: Icon(Icons.fitness_center)),
                  Tab(text: 'Nhật ký ăn', icon: Icon(Icons.restaurant_menu)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _WorkoutList(items: workouts, onReload: _load),
              _MealList(items: meals, onReload: _load),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({required this.items, required this.onReload});
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
            final created = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddWorkoutSheet(),
            );
            if (created == true) onReload();
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm buổi tập'),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(
            icon: Icons.fitness_center,
            title: 'Chưa có buổi tập',
            subtitle: 'Thêm buổi tập đầu tiên để theo dõi tiến độ.',
          )
        else
          ...items.map((item) {
            final sets = item['sets'] is List ? item['sets'] as List : const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.fitness_center, size: 20),
                  ),
                  title: Text(
                    _date(item['sessionDate']),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item['durationMinutes'] ?? 0} phút • ${sets.length} hiệp${item['note']?.toString().isNotEmpty == true ? ' • ${item['note']}' : ''}',
                  ),
                  children: sets.map((raw) {
                    final set = raw as Map;
                    return ListTile(
                      title: Text(set['exerciseName']?.toString() ?? 'Bài tập'),
                      subtitle: Text(
                        'Hiệp ${set['setNumber'] ?? '-'} • ${set['weight'] ?? 0} kg × ${set['reps'] ?? 0} lần • RIR ${set['rir'] ?? 0}',
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
      ],
    ),
  );
}

class _MealList extends StatelessWidget {
  const _MealList({required this.items, required this.onReload});
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
            final created = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddMealSheet(),
            );
            if (created == true) onReload();
          },
          icon: const Icon(Icons.add),
          label: const Text('Ghi bữa ăn'),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyView(
            icon: Icons.restaurant_outlined,
            title: 'Chưa có bữa ăn',
            subtitle: 'Các món cơm đã đặt sẽ tự động liên kết với nhật ký dinh dưỡng.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item['sourceType'] == 'LUNCH_ORDER'
                          ? Icons.lunch_dining
                          : Icons.restaurant,
                    ),
                  ),
                  title: Text(
                    '${_mealType(item['mealType'])} • ${_date(item['logDate'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item['totalCalories'] ?? 0} kcal • Đạm ${item['totalProtein'] ?? 0}g • Carb ${item['totalCarbs'] ?? 0}g • Béo ${item['totalFat'] ?? 0}g',
                  ),
                  trailing: item['sourceType'] == 'LUNCH_ORDER'
                      ? const Tooltip(
                          message: 'Tự động từ đơn cơm',
                          child: Icon(Icons.link),
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet();
  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  List<Map<String, dynamic>> exercises = [];
  String? exerciseId;
  final duration = TextEditingController(text: '45');
  final weight = TextEditingController(text: '10');
  final reps = TextEditingController(text: '10');
  final rir = TextEditingController(text: '2');
  final note = TextEditingController();
  bool busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final raw = await context.read<ApiClient>().get('/exercises');
        exercises = raw is List
            ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
        exerciseId = exercises.isEmpty
            ? null
            : exercises.first['id'].toString();
      } catch (e) {
        if (mounted) showMessage(context, displayError(e), error: true);
      } finally {
        if (mounted) setState(() => busy = false);
      }
    });
  }

  @override
  void dispose() {
    duration.dispose();
    weight.dispose();
    reps.dispose();
    rir.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (exerciseId == null) {
      return showMessage(context, 'Kho bài tập chưa có dữ liệu.', error: true);
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/workouts/sessions',
        data: {
          'sessionDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'note': note.text.trim(),
          'durationMinutes': int.tryParse(duration.text) ?? 0,
          'sets': [
            {
              'exerciseId': exerciseId,
              'setNumber': 1,
              'weight': double.tryParse(weight.text) ?? 0,
              'reps': int.tryParse(reps.text) ?? 0,
              'rir': int.tryParse(rir.text) ?? 0,
            },
          ],
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
            'Thêm buổi tập',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: exerciseId,
            decoration: const InputDecoration(
              labelText: 'Bài tập',
              helperText: 'Chọn bài trong kho đã được admin duyệt',
            ),
            items: exercises
                .map(
                  (e) => DropdownMenuItem(
                    value: e['id'].toString(),
                    child: Text(e['name']?.toString() ?? 'Bài tập'),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (value) => setState(() => exerciseId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Thời lượng (phút)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tạ (kg)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: reps,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lần lặp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: rir,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RIR',
                    helperText: 'Lần còn sức',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? 'Đang xử lý...' : 'Lưu buổi tập'),
          ),
        ],
      ),
    ),
  );
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();
  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  List<Map<String, dynamic>> foods = [];
  String? foodId;
  String mealType = 'BREAKFAST';
  final quantity = TextEditingController(text: '1');
  bool busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final raw = await context.read<ApiClient>().get('/nutrition/foods');
        foods = raw is List
            ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
        foodId = foods.isEmpty ? null : foods.first['id'].toString();
      } catch (e) {
        if (mounted) showMessage(context, displayError(e), error: true);
      } finally {
        if (mounted) setState(() => busy = false);
      }
    });
  }

  @override
  void dispose() {
    quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (foodId == null) {
      return showMessage(
        context,
        'Kho thực phẩm chưa có dữ liệu.',
        error: true,
      );
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/nutrition/meal-logs',
        data: {
          'mealType': mealType,
          'logDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'items': [
            {'foodId': foodId, 'quantity': double.tryParse(quantity.text) ?? 1},
          ],
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
            'Ghi bữa ăn',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: mealType,
            decoration: const InputDecoration(labelText: 'Bữa ăn'),
            items: const [
              DropdownMenuItem(value: 'BREAKFAST', child: Text('Bữa sáng')),
              DropdownMenuItem(value: 'LUNCH', child: Text('Bữa trưa')),
              DropdownMenuItem(value: 'DINNER', child: Text('Bữa tối')),
              DropdownMenuItem(value: 'SNACK', child: Text('Bữa phụ')),
            ],
            onChanged: (value) => setState(() => mealType = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: foodId,
            decoration: const InputDecoration(
              labelText: 'Thực phẩm',
              helperText: 'Chỉ hiển thị món đã được duyệt',
            ),
            items: foods
                .map(
                  (e) => DropdownMenuItem(
                    value: e['id'].toString(),
                    child: Text('${e['name']} (${e['unit']})'),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (value) => setState(() => foodId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số lượng khẩu phần',
              helperText: 'Ví dụ: 1 hoặc 1.5 khẩu phần theo đơn vị của món',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? 'Đang xử lý...' : 'Lưu bữa ăn'),
          ),
        ],
      ),
    ),
  );
}

String _date(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null
      ? (value?.toString() ?? '-')
      : DateFormat('dd/MM/yyyy').format(parsed);
}

String _mealType(dynamic value) => switch (value?.toString()) {
  'BREAKFAST' => 'Bữa sáng',
  'LUNCH' => 'Bữa trưa',
  'DINNER' => 'Bữa tối',
  'SNACK' => 'Bữa phụ',
  _ => value?.toString() ?? 'Bữa ăn',
};
