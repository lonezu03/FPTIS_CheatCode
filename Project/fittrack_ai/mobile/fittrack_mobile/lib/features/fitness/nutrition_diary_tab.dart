import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class NutritionDiaryTab extends StatefulWidget {
  const NutritionDiaryTab({super.key});

  @override
  State<NutritionDiaryTab> createState() => _NutritionDiaryTabState();
}

class _NutritionDiaryTabState extends State<NutritionDiaryTab> {
  DateTime date = DateTime.now();
  Map<String, dynamic>? diary;
  List<Map<String, dynamic>> foods = [];
  Object? error;
  bool loading = true;

  String get dateValue => DateFormat('yyyy-MM-dd').format(date);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final api = context.read<ApiClient>();
      final values = await Future.wait([
        api.get('/nutrition/diary', queryParameters: {'date': dateValue}),
        api.get('/nutrition/foods'),
      ]);
      if (!mounted) return;
      setState(() {
        diary = Map<String, dynamic>.from(values[0] as Map);
        foods = (values[1] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await context.read<ApiClient>().put(
        '/nutrition/days/$dateValue/status',
        data: {'status': status},
      );
      await _load();
    } catch (exception) {
      if (mounted) showMessage(context, displayError(exception), error: true);
    }
  }

  Future<void> _addWater(int amount) async {
    try {
      await context.read<ApiClient>().post(
        '/nutrition/water-logs',
        data: {'amountMl': amount, 'loggedAt': '${dateValue}T12:00:00'},
      );
      await _load();
    } catch (exception) {
      if (mounted) showMessage(context, displayError(exception), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null || diary == null) {
      return ErrorView(
        message: displayError(error ?? 'Không có dữ liệu'),
        onRetry: _load,
      );
    }
    final meals = _list(diary!['meals']);
    final consumed = _map(diary!['consumed']);
    final targets = _map(diary!['targets']);
    final remaining = _map(diary!['remaining']);
    final status = diary!['status']?.toString() ?? 'UNLOGGED';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateSelector(
            date: date,
            onPrevious: () {
              setState(() => date = date.subtract(const Duration(days: 1)));
              _load();
            },
            onNext: () {
              setState(() => date = date.add(const Duration(days: 1)));
              _load();
            },
            onPick: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (value != null) {
                setState(() => date = value);
                _load();
              }
            },
          ),
          const SizedBox(height: 10),
          _StatusBanner(status: status),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.35,
            children: [
              _MacroCard(
                label: 'Năng lượng',
                value: consumed['calories'],
                target: targets['calories'],
                remaining: remaining['calories'],
                unit: 'kcal',
              ),
              _MacroCard(
                label: 'Chất đạm',
                value: consumed['protein'],
                target: targets['protein'],
                remaining: remaining['protein'],
                unit: 'g',
              ),
              _MacroCard(
                label: 'Tinh bột',
                value: consumed['carbs'],
                target: targets['carbs'],
                remaining: remaining['carbs'],
                unit: 'g',
              ),
              _MacroCard(
                label: 'Chất béo',
                value: consumed['fat'],
                target: targets['fat'],
                remaining: remaining['fat'],
                unit: 'g',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WaterCard(
            current: (diary!['waterMl'] as num?)?.toInt() ?? 0,
            target: (diary!['waterTargetMl'] as num?)?.toInt() ?? 2000,
            onAdd: _addWater,
          ),
          const SizedBox(height: 12),
          for (final type in const ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealGroup(
                type: type,
                meals: meals.where((meal) => meal['mealType'] == type).toList(),
                onAdd: () async {
                  final saved = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _MealLoggerSheet(
                      date: dateValue,
                      mealType: type,
                      foods: foods,
                    ),
                  );
                  if (saved == true) _load();
                },
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chất lượng dữ liệu ngày',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Chỉ xác nhận đầy đủ sau khi đã ghi toàn bộ đồ ăn và thức uống có năng lượng.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: meals.isEmpty
                        ? null
                        : () => _setStatus('COMPLETE'),
                    child: const Text('Đã ghi đầy đủ'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setStatus('PARTIAL'),
                    child: const Text('Ghi chưa đầy đủ'),
                  ),
                  if (meals.isEmpty)
                    OutlinedButton(
                      onPressed: () => _setStatus('FASTING'),
                      child: const Text('Ngày nhịn ăn'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });
  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('dd/MM/yyyy').format(date)),
        ),
      ),
      IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (label, color, description) = switch (status) {
      'COMPLETE' => (
        'Đã ghi đầy đủ',
        Colors.green,
        'Được dùng cho báo cáo và khuyến nghị.',
      ),
      'PARTIAL' => (
        'Ghi chưa đầy đủ',
        Colors.orange,
        'Không dùng để kết luận bạn ăn quá ít.',
      ),
      'FASTING' => (
        'Ngày nhịn ăn',
        Colors.blue,
        'Đã xác nhận nhịn ăn có chủ đích.',
      ),
      _ => (
        'Chưa ghi',
        Colors.blueGrey,
        'Chưa có dữ liệu dinh dưỡng trong ngày.',
      ),
    };
    return Card(
      color: color.withAlpha(20),
      child: ListTile(
        leading: Icon(Icons.data_usage, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(description),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.remaining,
    required this.unit,
  });
  final String label;
  final dynamic value;
  final dynamic target;
  final dynamic remaining;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final current = (value as num?)?.toDouble() ?? 0;
    final goal = (target as num?)?.toDouble() ?? 0;
    final left = (remaining as num?)?.toDouble() ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Spacer(),
            Text(
              '${_number(current)} / ${_number(goal)} $unit',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: goal <= 0 ? 0 : (current / goal).clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: 5),
            Text(
              left >= 0
                  ? 'Còn ${_number(left)} $unit'
                  : '+${_number(-left)} $unit',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.current,
    required this.target,
    required this.onAdd,
  });
  final int current;
  final int target;
  final ValueChanged<int> onAdd;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.lightBlue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                'Nước hôm nay',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$current / $target ml',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [250, 350, 500]
                .map(
                  (amount) => OutlinedButton(
                    onPressed: () => onAdd(amount),
                    child: Text('+$amount ml'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}

class _MealGroup extends StatelessWidget {
  const _MealGroup({
    required this.type,
    required this.meals,
    required this.onAdd,
  });
  final String type;
  final List<Map<String, dynamic>> meals;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<num>(
      0,
      (sum, meal) => sum + ((meal['totalCalories'] as num?) ?? 0),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mealLabel(type),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${_number(calories)} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Ghi món'),
                ),
              ],
            ),
            if (meals.isEmpty)
              const Text('Chưa có món', style: TextStyle(color: Colors.black45))
            else
              ...meals.expand(
                (meal) => _list(meal['items']).map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      meal['sourceType'] == 'LUNCH_ORDER'
                          ? Icons.lunch_dining
                          : Icons.restaurant_outlined,
                    ),
                    title: Text(item['foodName']?.toString() ?? 'Món ăn'),
                    subtitle: Text(
                      '${item['servingAmount'] ?? item['quantity']} ${_unit(item['servingUnit'])}',
                    ),
                    trailing: Text('${_number(item['calories'])} kcal'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MealLoggerSheet extends StatefulWidget {
  const _MealLoggerSheet({
    required this.date,
    required this.mealType,
    required this.foods,
  });
  final String date;
  final String mealType;
  final List<Map<String, dynamic>> foods;
  @override
  State<_MealLoggerSheet> createState() => _MealLoggerSheetState();
}

class _MealLoggerSheetState extends State<_MealLoggerSheet> {
  final selected = <String, _FoodAmount>{};
  String search = '';
  bool busy = false;

  Future<void> _save() async {
    if (selected.isEmpty) {
      return showMessage(context, 'Chọn ít nhất một món.', error: true);
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post(
        '/nutrition/meal-logs',
        data: {
          'mealType': widget.mealType,
          'logDate': widget.date,
          'items': selected.entries.map((entry) {
            final food = widget.foods.firstWhere(
              (item) => item['id'] == entry.key,
            );
            final size = (food['servingSizeGrams'] as num?)?.toDouble();
            final factor = entry.value.unit == 'SERVING' || size == null
                ? entry.value.amount
                : entry.value.amount / size;
            return {
              'foodId': entry.key,
              'quantity': factor,
              'servingAmount': entry.value.amount,
              'servingUnit': entry.value.unit,
            };
          }).toList(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) showMessage(context, displayError(exception), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.foods
        .where(
          (food) => food['name'].toString().toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .take(30)
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        children: [
          Text(
            'Ghi nhiều món · ${_mealLabel(widget.mealType)}',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Tìm thực phẩm',
            ),
            onChanged: (value) => setState(() => search = value),
          ),
          const SizedBox(height: 10),
          ...visible.map((food) {
            final id = food['id'].toString();
            final value = selected[id];
            return Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: value != null,
                    title: Text(food['name'].toString()),
                    subtitle: Text(
                      '${food['unit'] ?? 'khẩu phần'}${food['verified'] == true ? ' · Đã xác minh' : ' · Tham khảo'}',
                    ),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        selected[id] = _FoodAmount();
                      } else {
                        selected.remove(id);
                      }
                    }),
                  ),
                  if (value != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '${value.amount}',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Số lượng',
                              ),
                              onChanged: (raw) =>
                                  value.amount = double.tryParse(raw) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: value.unit,
                              decoration: const InputDecoration(
                                labelText: 'Đơn vị',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'SERVING',
                                  child: Text('Khẩu phần'),
                                ),
                                if (food['servingSizeGrams'] != null)
                                  const DropdownMenuItem(
                                    value: 'GRAM',
                                    child: Text('Gram'),
                                  ),
                                if (food['servingSizeGrams'] != null)
                                  const DropdownMenuItem(
                                    value: 'ML',
                                    child: Text('ml'),
                                  ),
                              ],
                              onChanged: (unit) => setState(
                                () => value.unit = unit ?? 'SERVING',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? 'Đang lưu...' : 'Lưu ${selected.length} món'),
          ),
        ],
      ),
    );
  }
}

class _FoodAmount {
  double amount = 1;
  String unit = 'SERVING';
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value.map((item) => Map<String, dynamic>.from(item as Map)).toList()
    : [];
String _mealLabel(String type) =>
    const {
      'BREAKFAST': 'Bữa sáng',
      'LUNCH': 'Bữa trưa',
      'DINNER': 'Bữa tối',
      'SNACK': 'Ăn phụ',
    }[type] ??
    'Bữa ăn';
String _unit(dynamic value) => value == 'GRAM'
    ? 'g'
    : value == 'ML'
    ? 'ml'
    : 'khẩu phần';
String _number(dynamic value) {
  final number = (value as num?)?.toDouble() ?? 0;
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toStringAsFixed(1);
}
