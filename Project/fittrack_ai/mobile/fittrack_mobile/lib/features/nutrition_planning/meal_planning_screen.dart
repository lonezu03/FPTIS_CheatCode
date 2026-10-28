import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../fitness/food_search_sheet.dart';

const _base = '/nutrition/planning';
const _mealTypes = {
  'BREAKFAST': 'Bữa sáng',
  'LUNCH': 'Bữa trưa',
  'DINNER': 'Bữa tối',
  'SNACK': 'Bữa phụ',
};
const _units = {'SERVING': 'Khẩu phần', 'GRAM': 'g', 'ML': 'ml'};
String planningDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime planningMonday(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: date.weekday - 1));
List<Map<String, dynamic>> _maps(dynamic raw) => (raw as List? ?? [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

/// Standalone owner-scoped subpage. Navigation is exposed only inside Nutrition.
class MealPlanningScreen extends StatefulWidget {
  const MealPlanningScreen({super.key});
  @override
  State<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen> {
  DateTime week = planningMonday(DateTime.now());
  int page = 0, totalPages = 0, loadGeneration = 0;
  List<Map<String, dynamic>> meals = [];
  Map<String, dynamic> groceries = {'version': 0, 'items': []};
  Map<String, dynamic>? summary;
  bool loading = true, busy = false;
  Object? error;
  final copyOperations = <String, String>{};
  ApiClient get api => context.read<ApiClient>();
  String get weekText => planningDate(week);
  int get version => (groceries['version'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final generation = ++loadGeneration;
    setState(() {
      loading = true;
      error = null;
      meals = [];
      groceries = {'version': 0, 'items': []};
      summary = null;
      totalPages = 0;
    });
    try {
      final result = await Future.wait([
        api.get(
          '$_base/meals',
          queryParameters: {
            'from': weekText,
            'to': planningDate(week.add(const Duration(days: 6))),
            'page': page,
            'size': 30,
          },
        ),
        api.get('$_base/groceries', queryParameters: {'week': weekText}),
        api.get('$_base/summary', queryParameters: {'week': weekText}),
      ]);
      if (!mounted || generation != loadGeneration) return;
      setState(() {
        meals = _maps(result[0]['content']);
        totalPages = (result[0]['totalPages'] as num).toInt();
        groceries = Map<String, dynamic>.from(result[1] as Map);
        summary = Map<String, dynamic>.from(result[2] as Map);
      });
    } catch (e) {
      if (mounted && generation == loadGeneration) setState(() => error = e);
    } finally {
      if (mounted && generation == loadGeneration) {
        setState(() => loading = false);
      }
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

  Future<bool> confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(text),
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
  Future<void> pickWeek({bool copy = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: copy ? week.add(const Duration(days: 7)) : week,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null || !mounted) return;
    final monday = planningMonday(picked);
    if (!copy) {
      setState(() {
        week = monday;
        page = 0;
      });
      await load();
      return;
    }
    final target = planningDate(monday);
    if (target == weekText ||
        !await confirm(
          'Sao chép mẫu ăn sang tuần $target? Không ghi nhật ký và không thay bữa đã có.',
        )) {
      return;
    }
    final key = '$weekText/$target';
    final op = copyOperations.putIfAbsent(
      key,
      () =>
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
    );
    await mutate(() async {
      await api.post(
        '$_base/copy-week',
        data: {'fromWeek': weekText, 'toWeek': target, 'operationId': op},
      );
    });
  }

  Future<void> edit([Map<String, dynamic>? meal]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PlannedMealEditor(date: weekText, meal: meal),
      ),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> addManual() async {
    final name = TextEditingController(),
        amount = TextEditingController(text: '1'),
        unit = TextEditingController(text: 'phần');
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm mục mua riêng'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Tên thực phẩm / vật dụng',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                ),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n <= 0 || n > 1000000
                        ? 'Nhập số dương, tối đa 1 triệu'
                        : null;
                  },
                ),
                TextFormField(
                  controller: unit,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị (kg, gói…)',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập đơn vị' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, {
                  'name': name.text.trim(),
                  'amount': double.parse(amount.text),
                  'unit': unit.text.trim(),
                });
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    // Defer disposal until the closing dialog finishes its reverse animation.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      name.dispose();
      amount.dispose();
      unit.dispose();
    });
    if (result != null && mounted) {
      await mutate(() async {
        await api.post(
          '$_base/groceries/items',
          data: {'week': weekText, 'version': version, ...result},
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thực đơn tuần')),
    body: SafeArea(
      child: AbsorbPointer(
        absorbing: busy,
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageIntro(
                title: 'Thực đơn & danh sách mua',
                subtitle: 'Kế hoạch chưa phải nhật ký. Chỉ ghi nhận khi xác nhận thực sự đã ăn; không tự đánh dấu ngày đầy đủ.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => pickWeek(),
                    icon: const Icon(Icons.calendar_month),
                    label: Text('Tuần $weekText'),
                  ),
                  FilledButton.icon(
                    onPressed: () => edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bữa'),
                  ),
                  OutlinedButton(
                    onPressed: () => pickWeek(copy: true),
                    child: const Text('Sao chép tuần'),
                  ),
                ],
              ),
              if (loading || busy) const LinearProgressIndicator(),
              if (error != null)
                ErrorView(message: displayError(error!), onRetry: load),
              if (summary != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng dinh dưỡng dự kiến cả tuần',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${summary!['plannedMealCount']} bữa · ${_number(summary!['totals']['calories'])} kcal · ${_number(summary!['totals']['protein'])} g đạm · ${_number(summary!['totals']['carbs'])} g tinh bột · ${_number(summary!['totals']['fat'])} g béo',
                        ),
                        Text(
                          'Vi chất có dữ liệu ${summary!['totals']['knownMicronutrientValues']}/${summary!['totals']['possibleMicronutrientValues']}. Bao gồm mọi trang của tuần, không phải lượng đã ăn hoặc trung bình nhật ký.',
                        ),
                      ],
                    ),
                  ),
                ),
              if (!loading && error == null && meals.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có bữa dự kiến trong tuần.'),
                ),
              for (final meal in meals)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meal['date']} · ${_mealTypes[meal['mealType']] ?? meal['mealType']}',
                        ),
                        Text(
                          '${meal['name']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if ((meal['notes'] ?? '').toString().isNotEmpty)
                          Text('${meal['notes']}'),
                        for (final item in _maps(meal['items']))
                          Text(
                            '• ${item['foodName']} · ${item['servingAmount']} ${_units[item['servingUnit']] ?? item['servingUnit']}',
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Dự kiến: ${_number(meal['totals']['calories'])} kcal · ${_number(meal['totals']['protein'])} g đạm · ${_number(meal['totals']['carbs'])} g tinh bột · ${_number(meal['totals']['fat'])} g béo',
                        ),
                        Text(
                          'Snapshot lúc lập/sửa · Vi chất có dữ liệu ${meal['totals']['knownMicronutrientValues']}/${meal['totals']['possibleMicronutrientValues']}. Thiếu dữ liệu không phải bằng 0.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (meal['loggedMealId'] != null)
                          const Text(
                            'Đã ghi nhật ký',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed:
                                    '${meal['date']}'.compareTo(
                                          planningDate(DateTime.now()),
                                        ) >
                                        0
                                    ? null
                                    : () async {
                                        if (await confirm(
                                          'Thực sự đã ăn toàn bộ bữa này? Nhật ký sẽ tính lại theo kho hiện tại (có thể khác dự kiến), chỉ ghi một lần.',
                                        )) {
                                          await mutate(() async {
                                            await api.post(
                                              '$_base/meals/${meal['id']}/log',
                                              data: {
                                                'version': meal['version'],
                                              },
                                            );
                                          });
                                        }
                                      },
                                child: const Text('Đã ăn → nhật ký'),
                              ),
                              TextButton(
                                onPressed: () => edit(meal),
                                child: const Text('Sửa'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (await confirm('Xóa bữa dự kiến này?')) {
                                    await mutate(
                                      () => api.delete(
                                        '$_base/meals/${meal['id']}?version=${meal['version']}',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: page == 0 || loading
                        ? null
                        : () {
                            page--;
                            load();
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Trang ${page + 1}/${max(1, totalPages)}'),
                  IconButton(
                    onPressed: loading || page + 1 >= totalPages
                        ? null
                        : () {
                            page++;
                            load();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const Divider(),
              Text(
                'Danh sách mua thực phẩm',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Cộng gộp cùng thực phẩm + đơn vị; không suy nguyên liệu món chế biến sẵn hoặc đổi gram thành ml. Tạo lại giữ mục tự thêm và đã mua.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: loading || error != null
                        ? null
                        : () => mutate(() async {
                            await api.post(
                              '$_base/groceries/regenerate',
                              data: {'week': weekText, 'version': version},
                            );
                          }),
                    child: const Text('Tạo lại từ cả tuần'),
                  ),
                  TextButton(
                    onPressed: loading || error != null ? null : addManual,
                    child: const Text('Thêm mục riêng'),
                  ),
                ],
              ),
              for (final item in _maps(groceries['items']))
                Card(
                  child: CheckboxListTile(
                    value: item['checked'] == true,
                    onChanged: loading
                        ? null
                        : (checked) => mutate(() async {
                            await api.put(
                              '$_base/groceries/items/${item['id']}',
                              data: {
                                'week': weekText,
                                'version': version,
                                'checked': checked,
                              },
                            );
                          }),
                    title: Text(
                      '${item['name']} · ${_number(item['amount'])} ${_units[item['unit']] ?? item['unit']}',
                      style: TextStyle(
                        decoration: item['checked'] == true
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      item['manual'] == true
                          ? 'Tự thêm'
                          : item['stale'] == true
                          ? 'Đã mua · kế hoạch thay đổi, kiểm tra lại số lượng / nhu cầu'
                          : 'Từ thực đơn',
                    ),
                    secondary: IconButton(
                      tooltip: 'Xóa mục',
                      onPressed: loading
                          ? null
                          : () => mutate(
                              () => api.delete(
                                '$_base/groceries/items/${item['id']}?week=$weekText&version=$version',
                              ),
                            ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _number(dynamic value) => ((value as num?) ?? 0).toStringAsFixed(1);

class _PlannedMealEditor extends StatefulWidget {
  const _PlannedMealEditor({required this.date, this.meal});
  final String date;
  final Map<String, dynamic>? meal;
  @override
  State<_PlannedMealEditor> createState() => _PlannedMealEditorState();
}

class _PlannedMealEditorState extends State<_PlannedMealEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, notes, servings;
  late String date, type;
  String? collectionId;
  List<Map<String, dynamic>> items = [], collections = [];
  bool saving = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    name = TextEditingController(text: meal?['name']?.toString() ?? '');
    notes = TextEditingController(text: meal?['notes']?.toString() ?? '');
    servings = TextEditingController(text: '1');
    date = meal?['date']?.toString() ?? widget.date;
    type = meal?['mealType']?.toString() ?? 'BREAKFAST';
    items = _maps(meal?['items']);
    WidgetsBinding.instance.addPostFrameCallback((_) => loadCollections());
  }

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    servings.dispose();
    super.dispose();
  }

  Future<void> loadCollections() async {
    try {
      final raw = await context.read<ApiClient>().get('/nutrition/convenience');
      if (mounted) {
        setState(
          () => collections = [
            ..._maps(raw['savedMeals']),
            ..._maps(raw['recipes']),
          ],
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> addFood() async {
    final food = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FoodSearchSheet(),
    );
    if (food != null && mounted) {
      setState(
        () => items.add({
          'foodId': food['id'],
          'foodName': food['name'],
          'servingAmount': 1.0,
          'servingUnit': 'SERVING',
        }),
      );
    }
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;
    formKey.currentState!.save();
    if (collectionId == null && items.isEmpty) {
      setState(() => error = 'Chọn ít nhất một thực phẩm');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final api = context.read<ApiClient>();
    final payload = {
      'date': date,
      'name': name.text.trim(),
      'notes': notes.text.trim(),
      'mealType': type,
      if (widget.meal != null) 'version': widget.meal!['version'],
      if (collectionId != null) ...{
        'collectionId': collectionId,
        'servings': double.parse(servings.text),
      },
      'items': items
          .map(
            (i) => {
              'foodId': i['foodId'],
              'servingAmount': i['servingAmount'],
              'servingUnit': i['servingUnit'],
            },
          )
          .toList(),
    };
    try {
      if (widget.meal == null) {
        await api.post('$_base/meals', data: payload);
      } else {
        await api.put('$_base/meals/${widget.meal!['id']}', data: payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.meal == null ? 'Thêm bữa dự kiến' : 'Sửa bữa dự kiến'),
    ),
    body: AbsorbPointer(
      absorbing: saving,
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Lưu kế hoạch không ghi nhận đã ăn. Sửa sẽ tính lại snapshot từ kho hiện tại.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Tên bữa'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tên bữa' : null,
            ),
            TextFormField(
              controller: notes,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(date),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100, 12, 31),
                );
                if (selected != null && mounted) {
                  setState(() => date = planningDate(selected));
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('Ngày: $date'),
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Loại bữa'),
              items: _mealTypes.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: collectionId ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Bữa ăn / công thức đã lưu',
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Chọn thực phẩm riêng'),
                ),
                ...collections.map(
                  (c) => DropdownMenuItem(
                    value: '${c['id']}',
                    child: Text(
                      '${c['name']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) =>
                  setState(() => collectionId = v == '' ? null : v),
            ),
            if (collectionId != null)
              TextFormField(
                controller: servings,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Số khẩu phần'),
                validator: (v) => _amountError(v, 1000),
              ),
            if (collectionId == null) ...[
              const SizedBox(height: 12),
              for (int i = 0; i < items.length; i++)
                Card(
                  key: ObjectKey(items[i]),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${items[i]['foodName']}')),
                            IconButton(
                              tooltip: 'Bỏ món',
                              onPressed: () =>
                                  setState(() => items.removeAt(i)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: '${items[i]['servingAmount']}',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Số lượng',
                          ),
                          validator: (v) => _amountError(v, 100000),
                          onSaved: (v) =>
                              items[i]['servingAmount'] = double.parse(v!),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue:
                              items[i]['servingUnit']?.toString() ?? 'SERVING',
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị',
                          ),
                          items: _units.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => items[i]['servingUnit'] = v),
                        ),
                      ],
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: items.length >= 100 ? null : addFood,
                icon: const Icon(Icons.add),
                label: const Text('Thêm thực phẩm'),
              ),
              const Text(
                'Gram/ml chỉ hợp lệ khi khẩu phần của thực phẩm đúng loại; không tự đổi gram thành ml.',
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  displayError(error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Đang lưu…' : 'Lưu kế hoạch'),
            ),
          ],
        ),
      ),
    ),
  );
  String? _amountError(String? v, double max) {
    final n = double.tryParse(v ?? '');
    return n == null || !n.isFinite || n <= 0 || n > max
        ? 'Nhập số dương, tối đa $max'
        : null;
  }
}
