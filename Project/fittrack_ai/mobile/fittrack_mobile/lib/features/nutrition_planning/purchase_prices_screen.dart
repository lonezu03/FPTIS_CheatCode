import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import 'meal_planning_screen.dart' show planningMonday;
import 'pantry_screen.dart';

class PurchasePricesScreen extends StatefulWidget {
  const PurchasePricesScreen({super.key});
  @override
  State<PurchasePricesScreen> createState() => _PurchasePricesScreenState();
}

class _PurchasePricesScreenState extends State<PurchasePricesScreen> {
  static const base = '/nutrition/purchase-prices';
  bool active = true, loading = true, busy = false;
  int page = 0, pages = 0, generation = 0;
  String? foodId, foodName;
  DateTime week = planningMonday(DateTime.now()), reference = DateTime.now();
  List<dynamic> rows = [];
  Map<String, dynamic>? cost;
  Object? error, costError;
  ApiClient get api => context.read<ApiClient>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
      costError = null;
      cost = null;
      rows = [];
    });
    try {
      final r = await api.get(
        base,
        queryParameters: {
          'active': active,
          'page': page,
          'size': 20,
          if (foodId != null) 'foodId': foodId,
        },
      );
      if (mounted && current == generation)
        setState(() {
          rows = r['content'] as List;
          pages = (r['totalPages'] as num).toInt();
        });
    } catch (e) {
      if (mounted && current == generation) setState(() => error = e);
    }
    try {
      final r = await api.get(
        '$base/week-cost',
        queryParameters: {
          'week': pantryDate(week),
          'referenceDate': pantryDate(reference),
        },
      );
      if (mounted && current == generation)
        setState(() => cost = Map<String, dynamic>.from(r as Map));
    } catch (e) {
      if (mounted && current == generation) setState(() => costError = e);
    }
    if (mounted && current == generation) setState(() => loading = false);
  }

  Future<void> edit([Map<String, dynamic>? price]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => PurchasePriceEditor(price: price),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> archive(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lưu trữ giá mua?'),
        content: const Text('Giá này sẽ không dùng trong ước tính.'),
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
    if (ok != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await api.delete('$base/${p['id']}?version=${p['version']}');
      if (mounted) await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> chooseDate(bool chooseWeek) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: chooseWeek ? week : reference,
      firstDate: DateTime(2000),
      lastDate: chooseWeek ? DateTime(2100, 12, 31) : now,
    );
    if (picked != null && mounted) {
      setState(() {
        if (chooseWeek) {
          week = planningMonday(picked);
        } else {
          reference = picked;
        }
      });
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Giá mua thực phẩm')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Lưu giá tham khảo bằng VND. Không tự tạo chi tiêu hoặc thay đổi tồn kho.',
          ),
          FilledButton.icon(
            onPressed: busy ? null : () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Ghi giá mua'),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () async {
                  final f = await pantryPickFood(context);
                  if (f != null && mounted) {
                    setState(() {
                      foodId = '${f['id']}';
                      foodName = '${f['name']}';
                      page = 0;
                    });
                    await load();
                  }
                },
                child: const Text('Lọc theo thực phẩm'),
              ),
              if (foodId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      foodId = null;
                      foodName = null;
                      page = 0;
                    });
                    load();
                  },
                  child: Text('Bỏ lọc: $foodName'),
                ),
            ],
          ),
          SwitchListTile(
            title: const Text('Giá đã lưu trữ'),
            value: !active,
            onChanged: loading
                ? null
                : (v) {
                    setState(() {
                      active = !v;
                      page = 0;
                    });
                    load();
                  },
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            TextButton(
              onPressed: load,
              child: Text('Thử lại: ${displayError(error!)}'),
            ),
          if (!loading && error == null && rows.isEmpty)
            const Text('Chưa có giá mua.'),
          for (final raw in rows)
            Builder(
              builder: (context) {
                final p = Map<String, dynamic>.from(raw as Map);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['foodName']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${p['totalPrice']} đ / ${p['amount']} ${pantryUnits[p['unit']] ?? p['unit']}',
                        ),
                        Text(
                          'Đơn giá: ${p['unitPrice']} đ · ${p['purchasedOn']}',
                        ),
                        Text('${p['store'] ?? 'Chưa ghi nơi mua'}'),
                        if ((p['note'] ?? '').toString().isNotEmpty)
                          Text('${p['note']}'),
                        if (p['active'] == true)
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: busy ? null : () => edit(p),
                                child: const Text('Sửa'),
                              ),
                              TextButton(
                                onPressed: busy ? null : () => archive(p),
                                child: const Text('Lưu trữ'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: loading || page == 0
                    ? null
                    : () {
                        setState(() => page--);
                        load();
                      },
                child: const Text('Trước'),
              ),
              Text('Trang ${page + 1}/${max(1, pages)}'),
              TextButton(
                onPressed: loading || page + 1 >= pages
                    ? null
                    : () {
                        setState(() => page++);
                        load();
                      },
                child: const Text('Sau'),
              ),
            ],
          ),
          const Divider(),
          const Text(
            'Ước tính chi phí thực đơn tuần',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextButton(
            onPressed: () => chooseDate(true),
            child: Text('Tuần từ: ${pantryDate(week)}'),
          ),
          TextButton(
            onPressed: () => chooseDate(false),
            child: Text('Chọn giá tại ngày: ${pantryDate(reference)}'),
          ),
          const Text(
            'Giá gần nhất cùng đơn vị, tại hoặc trước ngày đã chọn. Chi phí chưa biết không được tính là 0.',
          ),
          if (costError != null)
            TextButton(
              onPressed: load,
              child: Text('Thử lại: ${displayError(costError!)}'),
            ),
          if (cost != null) ...[
            Text('Phần đã có giá: ${cost!['knownSubtotal']} đ'),
            Text(
              'Bao phủ ${cost!['pricedLines']}/${cost!['totalLines']} dòng (${cost!['coverage']}%)',
            ),
            for (final item in cost!['items'] as List)
              ListTile(
                title: Text(
                  '${item['foodName']} · ${item['amount']} ${pantryUnits[item['unit']] ?? item['unit']}',
                ),
                subtitle: Text(
                  item['estimatedCost'] == null
                      ? 'Chưa biết chi phí · ${item['reason'] ?? ''}'
                      : '${item['estimatedCost']} đ · giá ngày ${item['priceDate']}',
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class PurchasePriceEditor extends StatefulWidget {
  const PurchasePriceEditor({super.key, this.price});
  final Map<String, dynamic>? price;
  @override
  State<PurchasePriceEditor> createState() => _PurchasePriceEditorState();
}

class _PurchasePriceEditorState extends State<PurchasePriceEditor> {
  final form = GlobalKey<FormState>();
  late String foodId, foodName, amount, unit, total, date, store, note;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final p = widget.price;
    foodId = '${p?['foodId'] ?? ''}';
    foodName = '${p?['foodName'] ?? ''}';
    amount = '${p?['amount'] ?? 1}';
    unit = '${p?['unit'] ?? 'SERVING'}';
    final storedTotal = p?['totalPrice'];
    total = storedTotal is num
        ? storedTotal.toInt().toString()
        : '${storedTotal ?? 10000}';
    date = '${p?['purchasedOn'] ?? pantryDate(DateTime.now())}';
    store = '${p?['store'] ?? ''}';
    note = '${p?['note'] ?? ''}';
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate() || foodId.isEmpty) return;
    form.currentState!.save();
    final p = widget.price;
    final body = <String, dynamic>{
      if (p != null) 'version': p['version'],
      'foodId': foodId,
      'amount': double.parse(amount),
      'unit': unit,
      'totalPrice': int.parse(total),
      'purchasedOn': date,
      'store': store,
      'note': note,
    };
    final owner = context.read<AuthSession>().user?.id ?? '';
    final keyBody = Map<String, dynamic>.from(body);
    setState(() => busy = true);
    try {
      final key = PantryOperationKey(
        owner: owner,
        scope: 'purchase-price:${p?['id'] ?? 'create'}',
      );
      body['operationId'] = await key.forBody(keyBody);
      if (!mounted) return;
      if (context.read<AuthSession>().user?.id != owner) {
        throw StateError('Tài khoản đã thay đổi. Vui lòng mở lại màn hình.');
      }
      final api = context.read<ApiClient>();
      if (p == null) {
        await api.post('/nutrition/purchase-prices', data: body);
      } else {
        await api.put('/nutrition/purchase-prices/${p['id']}', data: body);
      }
      await key.complete(keyBody);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.price == null ? 'Ghi giá mua' : 'Sửa giá mua'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final f = await pantryPickFood(context);
                      if (f != null && mounted)
                        setState(() {
                          foodId = '${f['id']}';
                          foodName = '${f['name']}';
                        });
                    },
              child: Text(foodName.isEmpty ? 'Chọn thực phẩm' : foodName),
            ),
            TextFormField(
              initialValue: amount,
              enabled: !busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Số lượng mua'),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return n == null || !n.isFinite || n <= 0 || n > 1000000000
                    ? 'Nhập số lượng hợp lệ'
                    : null;
              },
              onSaved: (v) => amount = v!,
            ),
            DropdownButtonFormField<String>(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'Đơn vị'),
              items: pantryUnits.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: busy ? null : (v) => setState(() => unit = v!),
            ),
            TextFormField(
              initialValue: total,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tổng tiền mua (VND)',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 || n > 9000000000000
                    ? 'Nhập số tiền nguyên hợp lệ'
                    : null;
              },
              onSaved: (v) => total = v!,
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && mounted)
                        setState(() => date = pantryDate(picked));
                    },
              child: Text('Ngày mua: $date'),
            ),
            TextFormField(
              initialValue: store,
              enabled: !busy,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Nơi mua'),
              onSaved: (v) => store = v ?? '',
            ),
            TextFormField(
              initialValue: note,
              enabled: !busy,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              onSaved: (v) => note = v ?? '',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: busy ? null : submit,
        child: Text(busy ? 'Đang lưu…' : 'Lưu'),
      ),
    ],
  );
}
