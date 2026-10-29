import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import '../fitness/food_search_sheet.dart';

const pantryUnits = {'SERVING': 'Khẩu phần', 'GRAM': 'g', 'ML': 'ml'};
String pantryDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Reuse the key for an unchanged retry after a timeout; changed input gets a new key.
class PantryOperationKey {
  PantryOperationKey({
    required String owner,
    required String scope,
    FlutterSecureStorage? storage,
  }) : owner = owner,
       _storage = storage ?? const FlutterSecureStorage(),
       _storageKey =
           'fittrack_pantry_pending_${Uri.encodeComponent(owner)}:${Uri.encodeComponent(scope)}' {
    if (owner.isEmpty)
      throw StateError('Không xác định được tài khoản hiện tại.');
  }

  final String owner;
  final FlutterSecureStorage _storage;
  final String _storageKey;
  static Future<void> _tail = Future<void>.value();

  static Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<Map<String, String>> _read() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<String> forBody(Object body) => _serial(() async {
    final encoded = jsonEncode(body);
    final pending = await _read();
    final result = pending.putIfAbsent(
      encoded,
      () =>
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
    );
    await _storage.write(key: _storageKey, value: jsonEncode(pending));
    return result;
  });

  Future<void> complete(Object body) => _serial(() async {
    final pending = await _read();
    pending.remove(jsonEncode(body));
    if (pending.isEmpty) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(key: _storageKey, value: jsonEncode(pending));
    }
  });
}

Future<Map<String, dynamic>?> pantryPickFood(BuildContext context) =>
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FoodSearchSheet(),
    );

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  static const base = '/nutrition/pantry';
  bool active = true, loading = true, busy = false;
  int page = 0, pages = 0, generation = 0;
  Object? error, suggestionError;
  List<dynamic> rows = [], suggestions = [];
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
      suggestionError = null;
      rows = [];
      suggestions = [];
    });
    try {
      final result = await api.get(
        base,
        queryParameters: {'active': active, 'page': page, 'size': 20},
      );
      if (!mounted || current != generation) return;
      setState(() {
        rows = result['content'] as List;
        pages = (result['totalPages'] as num).toInt();
      });
    } catch (e) {
      if (mounted && current == generation) setState(() => error = e);
    }
    try {
      final result = await api.get('$base/suggestions');
      if (mounted && current == generation)
        setState(() => suggestions = result as List);
    } catch (e) {
      if (mounted && current == generation) setState(() => suggestionError = e);
    }
    if (mounted && current == generation) setState(() => loading = false);
  }

  Future<void> edit([
    Map<String, dynamic>? batch,
    bool operation = false,
  ]) async {
    final owner = context.read<AuthSession>().user?.id ?? '';
    if (owner.isEmpty) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PantryEditor(
        batch: batch,
        operation: operation,
        operationKey: operation || batch == null
            ? PantryOperationKey(
                owner: owner,
                scope: operation ? 'operation:${batch!['id']}' : 'create',
              )
            : null,
      ),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> toggle(Map<String, dynamic> batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(batch['active'] == true ? 'Lưu trữ lô?' : 'Khôi phục lô?'),
        content: const Text('Lô lưu trữ không được gợi ý hoặc nhắc hạn dùng.'),
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
    );
    if (confirmed != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await api.put(
        '$base/${batch['id']}',
        data: {
          'version': batch['version'],
          'location': batch['location'],
          'expiresOn': batch['expiresOn'],
          'note': batch['note'],
          'active': batch['active'] != true,
        },
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> history(Map<String, dynamic> batch) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PantryHistoryDialog(batch: batch),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thực phẩm đang có')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Theo dõi từng lô; thay đổi tồn không tự ghi bữa ăn hay chi tiêu.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Nhập lô thực phẩm'),
          ),
          SwitchListTile(
            title: const Text('Xem lô đã lưu trữ'),
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
            const Text('Chưa có lô thực phẩm.'),
          for (final raw in rows)
            Builder(
              builder: (context) {
                final b = Map<String, dynamic>.from(raw as Map);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b['foodName']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${b['quantity']} ${pantryUnits[b['unit']] ?? b['unit']} · ${b['location']}',
                        ),
                        Text('Hạn dùng: ${b['expiresOn'] ?? 'Chưa nhập'}'),
                        if ((b['note'] ?? '').toString().isNotEmpty)
                          Text('${b['note']}'),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (b['active'] == true)
                              TextButton(
                                onPressed: busy ? null : () => edit(b, true),
                                child: const Text('Thay đổi tồn'),
                              ),
                            TextButton(
                              onPressed: busy ? null : () => edit(b),
                              child: const Text('Sửa'),
                            ),
                            TextButton(
                              onPressed: () => history(b),
                              child: const Text('Lịch sử'),
                            ),
                            TextButton(
                              onPressed: busy ? null : () => toggle(b),
                              child: Text(
                                b['active'] == true ? 'Lưu trữ' : 'Khôi phục',
                              ),
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
            'Gợi ý tận dụng thực phẩm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Chỉ đối chiếu thực phẩm và đơn vị chính xác; luôn tự kiểm tra chất lượng thực phẩm.',
          ),
          if (suggestionError != null)
            TextButton(
              onPressed: load,
              child: Text('Thử lại gợi ý: ${displayError(suggestionError!)}'),
            ),
          for (final s in suggestions)
            ListTile(
              title: Text('${s['name']}'),
              subtitle: Text(
                s['sufficient'] == true
                    ? 'Đủ tồn theo dữ liệu đã nhập'
                    : 'Cần kiểm tra: ${(s['missing'] as List).join(', ')}',
              ),
            ),
        ],
      ),
    ),
  );
}

class PantryEditor extends StatefulWidget {
  const PantryEditor({
    super.key,
    this.batch,
    this.operation = false,
    this.operationKey,
  });
  final Map<String, dynamic>? batch;
  final bool operation;
  final PantryOperationKey? operationKey;
  @override
  State<PantryEditor> createState() => _PantryEditorState();
}

class _PantryEditorState extends State<PantryEditor> {
  final form = GlobalKey<FormState>();
  late final PantryOperationKey key;
  late String foodId, foodName, location, unit, note, amount, expiry;
  String type = 'CONSUME';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    key =
        widget.operationKey ??
        PantryOperationKey(
          owner: context.read<AuthSession>().user?.id ?? '',
          scope: widget.operation
              ? 'operation:${widget.batch!['id']}'
              : 'create',
        );
    final b = widget.batch;
    foodId = '${b?['foodId'] ?? ''}';
    foodName = '${b?['foodName'] ?? ''}';
    location = '${b?['location'] ?? 'Tủ lạnh'}';
    unit = '${b?['unit'] ?? 'SERVING'}';
    note = '${b?['note'] ?? ''}';
    amount = '1';
    expiry = '${b?['expiresOn'] ?? ''}';
  }

  Future<void> submit() async {
    if (busy ||
        !form.currentState!.validate() ||
        (!widget.operation && widget.batch == null && foodId.isEmpty))
      return;
    form.currentState!.save();
    final b = widget.batch;
    final Map<String, dynamic> body;
    if (widget.operation) {
      body = {
        'version': b!['version'],
        'type': type,
        'amount': double.parse(amount),
        'note': note,
      };
    } else if (b == null) {
      body = {
        'foodId': foodId,
        'location': location,
        'unit': unit,
        'quantity': double.parse(amount),
        'expiresOn': expiry.isEmpty ? null : expiry,
        'note': note,
      };
    } else {
      body = {
        'version': b['version'],
        'location': location,
        'expiresOn': expiry.isEmpty ? null : expiry,
        'note': note,
        'active': b['active'],
      };
    }
    final keyBody = Map<String, dynamic>.from(body);
    setState(() => busy = true);
    try {
      if (widget.operation || b == null)
        body['operationId'] = await key.forBody(keyBody);
      if (!mounted) return;
      if (context.read<AuthSession>().user?.id != key.owner) {
        throw StateError('Tài khoản đã thay đổi. Vui lòng mở lại màn hình.');
      }
      final api = context.read<ApiClient>();
      if (widget.operation) {
        await api.post('/nutrition/pantry/${b!['id']}/operations', data: body);
      } else if (b == null) {
        await api.post('/nutrition/pantry', data: body);
      } else {
        await api.put('/nutrition/pantry/${b['id']}', data: body);
      }
      if (widget.operation || b == null) await key.complete(keyBody);
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
    title: Text(
      widget.operation
          ? 'Thay đổi tồn kho'
          : widget.batch == null
          ? 'Nhập lô thực phẩm'
          : 'Sửa lô',
    ),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.batch == null)
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
            if (widget.operation)
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Thao tác'),
                items: const [
                  DropdownMenuItem(value: 'ADD', child: Text('Nhập thêm')),
                  DropdownMenuItem(value: 'CONSUME', child: Text('Đã dùng')),
                  DropdownMenuItem(value: 'DISCARD', child: Text('Hủy bỏ')),
                  DropdownMenuItem(
                    value: 'CORRECTION',
                    child: Text('Đối soát tồn thực tế'),
                  ),
                ],
                onChanged: busy ? null : (v) => setState(() => type = v!),
              ),
            if (widget.operation || widget.batch == null)
              TextFormField(
                initialValue: amount,
                enabled: !busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: type == 'CORRECTION' && widget.operation
                      ? 'Tồn thực tế'
                      : 'Số lượng',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null ||
                          !n.isFinite ||
                          n > 1000000000 ||
                          (type == 'CORRECTION' && widget.operation
                              ? n < 0
                              : n <= 0)
                      ? 'Nhập số lượng hợp lệ'
                      : null;
                },
                onSaved: (v) => amount = v!,
              ),
            if (widget.batch == null)
              DropdownButtonFormField<String>(
                initialValue: unit,
                decoration: const InputDecoration(labelText: 'Đơn vị'),
                items: pantryUnits.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: busy ? null : (v) => setState(() => unit = v!),
              ),
            if (!widget.operation) ...[
              TextFormField(
                initialValue: location,
                enabled: !busy,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Vị trí cất'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nhập vị trí' : null,
                onSaved: (v) => location = v!.trim(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Hạn dùng: ${expiry.isEmpty ? 'Chưa chọn' : expiry}',
                ),
                trailing: IconButton(
                  onPressed: busy ? null : () => setState(() => expiry = ''),
                  icon: const Icon(Icons.clear),
                ),
                onTap: busy
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(expiry) ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (date != null && mounted)
                          setState(() => expiry = pantryDate(date));
                      },
              ),
            ],
            TextFormField(
              initialValue: note,
              enabled: !busy,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: widget.operation && type == 'CORRECTION'
                    ? 'Lý do (bắt buộc)'
                    : 'Ghi chú',
              ),
              validator: (v) =>
                  widget.operation &&
                      type == 'CORRECTION' &&
                      (v ?? '').trim().isEmpty
                  ? 'Nhập lý do đối soát'
                  : null,
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

class PantryHistoryDialog extends StatefulWidget {
  const PantryHistoryDialog({super.key, required this.batch});
  final Map<String, dynamic> batch;
  @override
  State<PantryHistoryDialog> createState() => _PantryHistoryDialogState();
}

class _PantryHistoryDialogState extends State<PantryHistoryDialog> {
  int page = 0;
  bool loading = true, last = true;
  Object? error;
  List<dynamic> rows = [];
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
      final r = await context.read<ApiClient>().get(
        '/nutrition/pantry/${widget.batch['id']}/operations',
        queryParameters: {'page': page},
      );
      if (mounted)
        setState(() {
          rows = r['content'] as List;
          last = r['last'] == true;
        });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Lịch sử: ${widget.batch['foodName']}'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              TextButton(
                onPressed: load,
                child: Text('Thử lại: ${displayError(error!)}'),
              ),
            for (final r in rows)
              ListTile(
                title: Text('${r['type']} · ${r['amount']}'),
                subtitle: Text(
                  'Tồn sau: ${r['balanceAfter']} · ${r['createdAt']}\n${r['note'] ?? ''}',
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: loading || page == 0
                      ? null
                      : () {
                          page--;
                          load();
                        },
                  child: const Text('Trước'),
                ),
                Text('${page + 1}'),
                TextButton(
                  onPressed: loading || last
                      ? null
                      : () {
                          page++;
                          load();
                        },
                  child: const Text('Sau'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}
