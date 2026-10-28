import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});
  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<Map<String, dynamic>> goals = [];
  int page = 0, pages = 0, loadGeneration = 0;
  bool loading = true, archived = false;
  Object? error;
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
      final raw = await context.read<ApiClient>().get(
        '/finance/savings',
        queryParameters: {'page': page, 'size': 12, 'archived': archived},
      );
      final data = Map<String, dynamic>.from(raw as Map);
      if (mounted && generation == loadGeneration) {
        setState(() {
          goals = (data['content'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          pages = (data['totalPages'] as num).toInt();
        });
      }
    } catch (e) {
      if (mounted && generation == loadGeneration) setState(() => error = e);
    } finally {
      if (mounted && generation == loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? g]) async {
    final title = TextEditingController(text: g?['title']?.toString() ?? ''),
        target = TextEditingController(text: g?['target']?.toString() ?? ''),
        currency = TextEditingController(
          text: g?['currencyCode']?.toString() ?? 'VND',
        ),
        date = TextEditingController(text: g?['targetDate']?.toString() ?? ''),
        note = TextEditingController(text: g?['note']?.toString() ?? '');
    bool busy = false;
    String? message;
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dc) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(g == null ? 'Tạo mục tiêu tiết kiệm' : 'Chỉnh mục tiêu'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chỉ ghi nhận tiến độ, không khóa tiền hay thay đổi số dư ví.',
                    ),
                    TextFormField(
                      controller: title,
                      maxLength: 160,
                      decoration: const InputDecoration(
                        labelText: 'Tên mục tiêu',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                    ),
                    TextFormField(
                      controller: target,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Số tiền đích',
                      ),
                      validator: (v) =>
                          (double.tryParse(v ?? '') ?? 0) <= 0 ||
                              (double.tryParse(v ?? '') ?? double.infinity) >
                                  1000000000000
                          ? 'Số tiền lớn hơn 0, tối đa 1.000.000.000.000'
                          : null,
                    ),
                    TextFormField(
                      controller: currency,
                      enabled: g == null,
                      decoration: const InputDecoration(
                        labelText: 'Mã tiền tệ (VND)',
                      ),
                      validator: (v) =>
                          RegExp(r'^[A-Za-z]{3}$').hasMatch(v ?? '')
                          ? null
                          : 'Nhập mã 3 chữ cái',
                    ),
                    TextFormField(
                      controller: date,
                      decoration: const InputDecoration(
                        labelText: 'Ngày đích yyyy-MM-dd (tùy chọn)',
                      ),
                    ),
                    TextFormField(
                      controller: note,
                      maxLength: 1000,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    if (message != null)
                      Text(message!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dc),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      change(() {
                        busy = true;
                        message = null;
                      });
                      try {
                        final data = <String, dynamic>{
                          ...?g,
                          'title': title.text.trim(),
                          'target': double.parse(target.text),
                          'currencyCode': currency.text.toUpperCase(),
                          'targetDate': date.text.isEmpty ? null : date.text,
                          'note': note.text,
                          'archived': g?['archived'] ?? false,
                        };
                        final api = this.context.read<ApiClient>();
                        if (g == null) {
                          await api.post('/finance/savings', data: data);
                        } else {
                          await api.patch(
                            '/finance/savings/${g['id']}',
                            data: data,
                          );
                        }
                        if (dc.mounted) Navigator.pop(dc);
                        await load();
                      } catch (e) {
                        if (dc.mounted) {
                          change(() {
                            message = e.toString();
                            busy = false;
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final c in [title, target, currency, date, note]) {
      c.dispose();
    }
  }

  Future<void> operations(Map<String, dynamic> g) async {
    final amount = TextEditingController(), note = TextEditingController();
    String type = 'ADD', operationId = '', fingerprint = '';
    bool busy = false;
    String? message;
    int p = 0, totalPages = 0;
    List<Map<String, dynamic>> history = [];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dc) => StatefulBuilder(
        builder: (context, change) {
          Future<void> fetch() async {
            change(() => busy = true);
            try {
              final raw = await this.context.read<ApiClient>().get(
                '/finance/savings/${g['id']}/operations',
                queryParameters: {'page': p, 'size': 15},
              );
              final data = raw as Map;
              if (dc.mounted) {
                change(() {
                  history = (data['content'] as List)
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();
                  totalPages = (data['totalPages'] as num).toInt();
                });
              }
            } catch (e) {
              if (dc.mounted) change(() => message = e.toString());
            } finally {
              if (dc.mounted) change(() => busy = false);
            }
          }

          return AlertDialog(
            title: Text(g['title'] as String),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Không chuyển tiền thật; không ảnh hưởng thu/chi hay số dư ví.',
                    ),
                    if (g['archived'] != true) ...[
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(
                            value: 'ADD',
                            child: Text('Tăng tiến độ'),
                          ),
                          DropdownMenuItem(
                            value: 'RELEASE',
                            child: Text('Giảm tiến độ'),
                          ),
                        ],
                        onChanged: busy ? null : (v) => change(() => type = v!),
                        decoration: const InputDecoration(
                          labelText: 'Thao tác',
                        ),
                      ),
                      TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Số tiền (${g['currencyCode']})',
                        ),
                      ),
                      TextField(
                        controller: note,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú đối soát',
                        ),
                      ),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final parsed = double.tryParse(amount.text);
                                if (parsed == null ||
                                    !parsed.isFinite ||
                                    parsed <= 0 ||
                                    parsed > 1000000000000) {
                                  change(
                                    () => message = 'Số tiền lớn hơn 0, tối đa 1.000.000.000.000, không quá 2 số thập phân',
                                  );
                                  return;
                                }
                                final current =
                                    '$type|${amount.text}|${note.text}';
                                if (current != fingerprint) {
                                  fingerprint = current;
                                  operationId =
                                      'mobile_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
                                }
                                change(() {
                                  busy = true;
                                  message = null;
                                });
                                try {
                                  await this.context.read<ApiClient>().post(
                                    '/finance/savings/${g['id']}/operations',
                                    data: {
                                      'operationId': operationId,
                                      'type': type,
                                      'amount': parsed,
                                      'currencyCode': g['currencyCode'],
                                      'note': note.text,
                                    },
                                  );
                                  fingerprint = '';
                                  operationId = '';
                                  amount.clear();
                                  note.clear();
                                  await fetch();
                                  await load();
                                } catch (e) {
                                  if (dc.mounted) {
                                    change(() {
                                      message = e.toString();
                                      busy = false;
                                    });
                                  }
                                }
                              },
                        child: const Text('Xác nhận ghi nhận'),
                      ),
                    ],
                    TextButton(
                      onPressed: busy ? null : fetch,
                      child: const Text('Tải lịch sử'),
                    ),
                    if (busy) const LinearProgressIndicator(),
                    if (message != null)
                      Text(message!, style: const TextStyle(color: Colors.red)),
                    ...history.map(
                      (h) => ListTile(
                        title: Text(
                          '${h['type'] == 'ADD' ? '+' : '−'}${h['amount']} ${h['currencyCode']}',
                        ),
                        subtitle: Text('${h['createdAt']}\n${h['note'] ?? ''}'),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: p == 0 || busy
                              ? null
                              : () {
                                  p--;
                                  fetch();
                                },
                          child: const Text('Trước'),
                        ),
                        Text('${p + 1}/${max(1, totalPages)}'),
                        TextButton(
                          onPressed: p + 1 >= totalPages || busy
                              ? null
                              : () {
                                  p++;
                                  fetch();
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
                onPressed: busy ? null : () => Navigator.pop(dc),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
    amount.dispose();
    note.dispose();
  }

  Future<void> archive(Map<String, dynamic> g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lưu trữ mục tiêu?'),
        content: const Text('Lịch sử vẫn được giữ.'),
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
        '/finance/savings/${g['id']}?version=${g['version']}',
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mục tiêu tiết kiệm')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sổ tiến độ riêng, KHÔNG khóa tiền, KHÔNG trừ ví và KHÔNG tạo giao dịch thu/chi.',
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Đã lưu trữ'),
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
            label: const Text('Tạo mục tiêu'),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error.toString(), style: const TextStyle(color: Colors.red)),
          ...goals.map(
            (g) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g['title'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${g['progress']} / ${g['target']} ${g['currencyCode']}',
                    ),
                    LinearProgressIndicator(
                      value: ((g['progress'] as num) / (g['target'] as num))
                          .clamp(0.0, 1.0),
                    ),
                    Text(
                      '${g['targetDate'] ?? 'Chưa đặt ngày'} · ${g['note'] ?? ''}',
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () => edit(g),
                          child: const Text('Sửa'),
                        ),
                        TextButton(
                          onPressed: () => operations(g),
                          child: const Text('Ghi nhận / lịch sử'),
                        ),
                        if (!archived)
                          TextButton(
                            onPressed: () => archive(g),
                            child: const Text('Lưu trữ'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
              Text('${page + 1}/${max(1, pages)}'),
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
