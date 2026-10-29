import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_session.dart';

/// Independent group ledger. Server authorization and version checks remain authoritative.
class SharedExpensesScreen extends StatefulWidget {
  const SharedExpensesScreen({super.key});
  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {
  static const base = '/finance/shared';
  final operations = <String, String>{};
  List<Map<String, dynamic>> groups = [],
      invitations = [],
      members = [],
      expenses = [],
      settlements = [],
      audit = [];
  Map<String, dynamic>? group;
  String? selected;
  Object? error;
  bool loading = true, busy = false;
  int loadGeneration = 0;
  int groupPage = 0,
      invitePage = 0,
      expensePage = 0,
      settlementPage = 0,
      auditPage = 0;
  int groupPages = 0,
      invitePages = 0,
      expensePages = 0,
      settlementPages = 0,
      auditPages = 0;

  ApiClient get api => context.read<ApiClient>();
  String get userId => context.read<AuthSession>().user?.id ?? '';
  bool get owner => group?['ownerId'] == userId;
  bool get active => group?['myStatus'] == 'ACTIVE';
  bool get canWrite => active && group?['archived'] != true;
  String memberName(Object? id) =>
      members
          .where((m) => m['userId'] == id)
          .map((m) => m['name'].toString())
          .firstOrNull ??
      'Thành viên';
  String money(Object? value) =>
      '${NumberFormat.decimalPattern('vi_VN').format(value ?? 0)} đ';
  List<Map<String, dynamic>> items(dynamic page) =>
      ((page as Map)['content'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  int pages(dynamic page) => ((page as Map)['totalPages'] as num? ?? 0).toInt();

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
      final current = selected;
      final result = await Future.wait([
        api.get(
          '$base/groups',
          queryParameters: {'page': groupPage, 'size': 12},
        ),
        api.get(
          '$base/invitations',
          queryParameters: {'page': invitePage, 'size': 12},
        ),
        if (current != null) ...[
          api.get('$base/groups/$current'),
          api.get(
            '$base/groups/$current/expenses',
            queryParameters: {'page': expensePage, 'size': 15},
          ),
          api.get(
            '$base/groups/$current/settlements',
            queryParameters: {'page': settlementPage, 'size': 15},
          ),
          api.get(
            '$base/groups/$current/audit',
            queryParameters: {'page': auditPage, 'size': 15},
          ),
        ],
      ]);
      if (!mounted || generation != loadGeneration || current != selected)
        return;
      setState(() {
        groups = items(result[0]);
        groupPages = pages(result[0]);
        invitations = items(result[1]);
        invitePages = pages(result[1]);
        if (current != null) {
          final detail = Map<String, dynamic>.from(result[2] as Map);
          group = Map<String, dynamic>.from(detail['group'] as Map);
          members = (detail['members'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          expenses = items(result[3]);
          expensePages = pages(result[3]);
          settlements = items(result[4]);
          settlementPages = pages(result[4]);
          audit = items(result[5]);
          auditPages = pages(result[5]);
        }
      });
    } catch (e) {
      if (mounted && generation == loadGeneration) setState(() => error = e);
    } finally {
      if (mounted && generation == loadGeneration)
        setState(() => loading = false);
    }
  }

  String operation(String key) => operations.putIfAbsent(key, () {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  });

  Future<bool> mutate(
    String path,
    Map<String, dynamic> payload, {
    bool patch = false,
  }) async {
    if (busy) return false;
    setState(() => busy = true);
    final key = '$path:${jsonEncode(payload)}';
    try {
      final body = {...payload, 'operationId': operation(key)};
      if (patch) {
        await api.patch(path, data: body);
      } else {
        await api.post(path, data: body);
      }
      operations.remove(key);
      if (mounted) {
        await load();
      }
      return true;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
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

  Future<String?> ask(
    String title, {
    String initial = '',
    String label = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final dialog = DialogRoute<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    final result = await Navigator.of(context).push(dialog);
    await dialog.completed;
    controller.dispose();
    return result;
  }

  Future<void> groupEditor([Map<String, dynamic>? old]) async {
    final name = TextEditingController(text: old?['name']?.toString() ?? '');
    final description = TextEditingController(
      text: old?['description']?.toString() ?? '',
    );
    bool archived = old?['archived'] == true;
    final dialog = DialogRoute<Map<String, dynamic>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, change) => AlertDialog(
          title: Text(old == null ? 'Tạo nhóm' : 'Chỉnh sửa nhóm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                ),
                TextField(
                  controller: description,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                if (old != null)
                  CheckboxListTile(
                    value: archived,
                    onChanged: (v) => change(() => archived = v == true),
                    title: const Text('Lưu trữ nhóm'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty)
                  Navigator.pop(c, {
                    'name': name.text.trim(),
                    'description': description.text.trim(),
                    'archived': archived,
                    if (old != null) 'version': old['version'],
                  });
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    final result = await Navigator.of(context).push(dialog);
    await dialog.completed;
    name.dispose();
    description.dispose();
    if (result != null && mounted)
      await mutate(
        old == null ? '$base/groups' : '$base/groups/${old['id']}',
        result,
        patch: old != null,
      );
  }

  Future<void> memberAction(
    String action, {
    String? email,
    Map<String, dynamic>? invite,
  }) async {
    final id = invite?['groupId'] ?? selected;
    final version = invite?['version'] ?? group?['version'];
    if (id == null) return;
    if (action == 'ACCEPT' &&
        !await confirm(
          'Chấp nhận lời mời',
          'Thành viên được xem lịch sử và công nợ nhóm, kể cả sau khi rời nhóm để tiếp tục đối soát.',
        ))
      return;
    await mutate('$base/groups/$id/members', {
      'version': version,
      'action': action,
      if (email != null) 'email': email,
    });
  }

  Future<void> expenseEditor([Map<String, dynamic>? old]) async {
    final activeMembers = members
        .where((m) => m['status'] == 'ACTIVE')
        .toList();
    if (activeMembers.isEmpty) return;
    final title = TextEditingController(text: old?['title']?.toString() ?? '');
    final amount = TextEditingController(
      text: old?['amount']?.toString() ?? '',
    );
    final date = TextEditingController(
      text:
          old?['spentOn']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final note = TextEditingController(text: old?['note']?.toString() ?? '');
    String payer = old?['payerId']?.toString() ?? userId;
    if (!activeMembers.any((m) => m['userId'] == payer))
      payer = activeMembers.first['userId'].toString();
    String mode = old == null ? 'EQUAL' : 'CUSTOM';
    final selectedIds = old == null
        ? activeMembers.map((m) => m['userId'].toString()).toSet()
        : ((old['splits'] as List?) ?? [])
              .map((e) => (e as Map)['userId'].toString())
              .toSet();
    final amounts = <String, TextEditingController>{};
    for (final m in activeMembers) {
      final id = m['userId'].toString();
      final split = ((old?['splits'] as List?) ?? [])
          .where((e) => (e as Map)['userId'] == id)
          .firstOrNull;
      amounts[id] = TextEditingController(
        text: split == null ? '0' : (split as Map)['amount'].toString(),
      );
    }
    List<dynamic>? preview;
    Map<String, dynamic>? previewedPayload;
    int previewGeneration = 0;
    bool previewing = false;
    Map<String, dynamic>? result;
    final dialog = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, change) {
          void invalidatePreview() {
            previewGeneration++;
            preview = null;
            previewedPayload = null;
          }

          Map<String, dynamic> payload() => {
            'version': old?['version'] ?? group?['version'],
            'title': title.text.trim(),
            'amount': int.tryParse(amount.text) ?? 0,
            'spentOn': date.text.trim(),
            'note': note.text.trim(),
            'payerId': payer,
            'splitMode': mode,
            'splits': selectedIds
                .map(
                  (id) => {
                    'userId': id,
                    'amount': int.tryParse(amounts[id]?.text ?? '') ?? 0,
                  },
                )
                .toList(),
          };
          return AlertDialog(
            title: Text(old == null ? 'Thêm khoản chi' : 'Sửa khoản chi'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Nội dung'),
                      onChanged: (_) => change(invalidatePreview),
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (đồng)',
                      ),
                      onChanged: (_) => change(invalidatePreview),
                    ),
                    TextField(
                      controller: date,
                      decoration: const InputDecoration(
                        labelText: 'Ngày chi (yyyy-MM-dd)',
                      ),
                      onChanged: (_) => change(invalidatePreview),
                    ),
                    TextField(
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                      onChanged: (_) => change(invalidatePreview),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: payer,
                      decoration: const InputDecoration(labelText: 'Người trả'),
                      items: activeMembers
                          .map(
                            (m) => DropdownMenuItem(
                              value: m['userId'].toString(),
                              child: Text(m['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => change(() {
                        payer = v!;
                        invalidatePreview();
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: 'Cách chia'),
                      items: const [
                        DropdownMenuItem(
                          value: 'EQUAL',
                          child: Text('Chia đều'),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOM',
                          child: Text('Tự nhập'),
                        ),
                      ],
                      onChanged: (v) => change(() {
                        mode = v!;
                        invalidatePreview();
                      }),
                    ),
                    ...activeMembers.map((m) {
                      final id = m['userId'].toString();
                      return Column(
                        children: [
                          CheckboxListTile(
                            title: Text(m['name'].toString()),
                            value: selectedIds.contains(id),
                            onChanged: (v) => change(() {
                              if (v == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                              invalidatePreview();
                            }),
                          ),
                          if (mode == 'CUSTOM' && selectedIds.contains(id))
                            TextField(
                              controller: amounts[id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Phần chia (đồng)',
                              ),
                              onChanged: (_) => change(invalidatePreview),
                            ),
                        ],
                      );
                    }),
                    TextButton(
                      onPressed: previewing
                          ? null
                          : () async {
                              final snapshot = payload();
                              final requestGeneration = ++previewGeneration;
                              change(() {
                                previewing = true;
                                preview = null;
                                previewedPayload = null;
                              });
                              try {
                                final response = await api.post(
                                  '$base/groups/$selected/expenses/preview',
                                  data: snapshot,
                                );
                                if (c.mounted &&
                                    requestGeneration == previewGeneration) {
                                  change(() {
                                    preview = response as List;
                                    previewedPayload = snapshot;
                                  });
                                }
                              } catch (e) {
                                if (c.mounted &&
                                    requestGeneration == previewGeneration)
                                  ScaffoldMessenger.of(
                                    c,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                              } finally {
                                if (c.mounted) change(() => previewing = false);
                              }
                            },
                      child: const Text('Xem trước phần chia'),
                    ),
                    if (preview != null)
                      ...preview!.map(
                        (s) => Text(
                          '${memberName((s as Map)['userId'])}: ${money(s['amount'])}',
                        ),
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
                onPressed:
                    preview == null || previewedPayload == null || previewing
                    ? null
                    : () {
                        result = previewedPayload;
                        Navigator.pop(c);
                      },
                child: const Text('Lưu khoản chi'),
              ),
            ],
          );
        },
      ),
    );
    await Navigator.of(context).push(dialog);
    await dialog.completed;
    title.dispose();
    amount.dispose();
    date.dispose();
    note.dispose();
    for (final c in amounts.values) {
      c.dispose();
    }
    if (result != null && mounted)
      await mutate(
        '$base/groups/$selected/expenses${old == null ? '' : '/${old['id']}'}',
        result!,
        patch: old != null,
      );
  }

  Future<void> settlementEditor() async {
    final eligible = members.where((m) => m['acceptedAt'] != null).toList();
    if (eligible.length < 2) return;
    String debtor = eligible.first['userId'].toString(),
        creditor = eligible.last['userId'].toString();
    final amount = TextEditingController(), note = TextEditingController();
    Map<String, dynamic>? result;
    final dialog = DialogRoute<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, change) => AlertDialog(
          title: const Text('Đề nghị đối soát'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bên còn lại phải xác nhận. Số tiền chờ xác nhận chưa làm giảm công nợ.',
                ),
                DropdownButtonFormField<String>(
                  initialValue: debtor,
                  decoration: const InputDecoration(labelText: 'Người đã trả'),
                  items: eligible
                      .map(
                        (m) => DropdownMenuItem(
                          value: m['userId'].toString(),
                          child: Text('${m['name']} · ${money(m['balance'])}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => change(() => debtor = v!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: creditor,
                  decoration: const InputDecoration(labelText: 'Người đã nhận'),
                  items: eligible
                      .map(
                        (m) => DropdownMenuItem(
                          value: m['userId'].toString(),
                          child: Text('${m['name']} · ${money(m['balance'])}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => change(() => creditor = v!),
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền đã trả (đồng)',
                  ),
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed:
                  debtor == creditor || (debtor != userId && creditor != userId)
                  ? null
                  : () {
                      final n = int.tryParse(amount.text) ?? 0;
                      if (n <= 0) return;
                      result = {
                        'version': group?['version'],
                        'debtorId': debtor,
                        'creditorId': creditor,
                        'amount': n,
                        'note': note.text.trim(),
                      };
                      Navigator.pop(c);
                    },
              child: const Text('Gửi đề nghị'),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context).push(dialog);
    await dialog.completed;
    amount.dispose();
    note.dispose();
    if (result != null && mounted)
      await mutate('$base/groups/$selected/settlements', result!);
  }

  Widget pager(int page, int total, ValueChanged<int> onChange) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton(
        onPressed: page > 0 && !loading ? () => onChange(page - 1) : null,
        child: const Text('Trước'),
      ),
      Text('${page + 1}/${max(1, total)}'),
      TextButton(
        onPressed: page + 1 < total && !loading
            ? () => onChange(page + 1)
            : null,
        child: const Text('Sau'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiêu chung'),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sổ đối soát nhóm độc lập. Không tự chuyển tiền hay thay đổi ví cá nhân.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Khi chấp nhận lời mời, các thành viên được xem lịch sử và công nợ nhóm, kể cả sau khi rời nhóm.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            ListTile(
              title: const Text('Không tải được dữ liệu'),
              subtitle: Text('$error'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: load,
              ),
            ),
          const SizedBox(height: 12),
          Text('Lời mời', style: Theme.of(context).textTheme.titleLarge),
          if (invitations.isEmpty && !loading)
            const Text('Không có lời mời đang chờ.'),
          ...invitations.map(
            (i) => Card(
              child: ListTile(
                title: Text('${i['groupName']}'),
                subtitle: Text('Mời bởi ${i['invitedBy']}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Chấp nhận',
                      onPressed: busy
                          ? null
                          : () => memberAction('ACCEPT', invite: i),
                      icon: const Icon(Icons.check),
                    ),
                    IconButton(
                      tooltip: 'Từ chối',
                      onPressed: busy
                          ? null
                          : () => memberAction('DECLINE', invite: i),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
          pager(invitePage, invitePages, (p) {
            setState(() => invitePage = p);
            load();
          }),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nhóm của bạn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => groupEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Tạo nhóm'),
              ),
            ],
          ),
          if (groups.isEmpty && !loading) const Text('Chưa có nhóm.'),
          ...groups.map(
            (g) => Card(
              child: ListTile(
                title: Text('${g['name']}'),
                subtitle: Text(
                  g['archived'] == true
                      ? 'Đã lưu trữ'
                      : g['myStatus'] == 'REMOVED'
                      ? 'Đã rời nhóm'
                      : 'Đang tham gia',
                ),
                selected: selected == g['id'],
                onTap: () {
                  setState(() {
                    selected = g['id'].toString();
                    group = null;
                    expensePage = settlementPage = auditPage = 0;
                  });
                  load();
                },
              ),
            ),
          ),
          pager(groupPage, groupPages, (p) {
            setState(() => groupPage = p);
            load();
          }),
          if (group != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${group!['name']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (owner)
                  IconButton(
                    tooltip: 'Sửa nhóm',
                    onPressed: busy ? null : () => groupEditor(group),
                    icon: const Icon(Icons.edit),
                  ),
              ],
            ),
            Text('${group!['description'] ?? ''}'),
            const SizedBox(height: 8),
            const Text('Thành viên và số dư ròng'),
            ...members.map(
              (m) => ListTile(
                title: Text('${m['name']}'),
                subtitle: Text('${m['status']} · ${money(m['balance'])}'),
                trailing:
                    owner &&
                        group!['archived'] != true &&
                        m['userId'] != group!['ownerId'] &&
                        ['ACTIVE', 'INVITED'].contains(m['status'])
                    ? IconButton(
                        tooltip: 'Gỡ thành viên',
                        icon: const Icon(Icons.person_remove),
                        onPressed: busy
                            ? null
                            : () async {
                                if (await confirm(
                                  'Gỡ thành viên',
                                  'Lịch sử và công nợ vẫn được giữ lại.',
                                ))
                                  await memberAction(
                                    'REMOVE',
                                    email: m['userId'].toString(),
                                  );
                              },
                      )
                    : null,
              ),
            ),
            if (owner && group!['archived'] != true)
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final email = await ask(
                          'Mời thành viên',
                          label: 'Email đăng ký',
                        );
                        if (email != null && email.isNotEmpty)
                          await memberAction('INVITE', email: email);
                      },
                child: const Text('Mời thành viên'),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Khoản chi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canWrite)
                  TextButton.icon(
                    onPressed: busy ? null : () => expenseEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
              ],
            ),
            ...expenses.map(
              (e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e['title']} · ${money(e['amount'])}${e['voided'] == true ? ' · Đã hủy' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${e['spentOn']} · Người trả: ${memberName(e['payerId'])}',
                      ),
                      Text(
                        ((e['splits'] as List?) ?? [])
                            .map(
                              (s) =>
                                  '${memberName((s as Map)['userId'])}: ${money(s['amount'])}',
                            )
                            .join(' · '),
                      ),
                      Wrap(
                        children: [
                          if (canWrite &&
                              e['voided'] != true &&
                              e['creatorId'] == userId)
                            TextButton(
                              onPressed: busy ? null : () => expenseEditor(e),
                              child: const Text('Sửa'),
                            ),
                          if (active &&
                              e['voided'] != true &&
                              (owner || e['creatorId'] == userId))
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final reason = await ask(
                                        'Hủy khoản chi',
                                        label: 'Lý do hủy',
                                      );
                                      if (reason != null && reason.isNotEmpty)
                                        await mutate(
                                          '$base/groups/$selected/expenses/${e['id']}/void',
                                          {
                                            'version': e['version'],
                                            'reason': reason,
                                          },
                                        );
                                    },
                              child: const Text('Hủy khoản chi'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            pager(expensePage, expensePages, (p) {
              setState(() => expensePage = p);
              load();
            }),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đối soát',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : settlementEditor,
                  child: const Text('Đề nghị'),
                ),
              ],
            ),
            ...settlements.map(
              (s) => Card(
                child: ListTile(
                  title: Text(
                    '${memberName(s['debtorId'])} → ${memberName(s['creditorId'])}: ${money(s['amount'])}',
                  ),
                  subtitle: Text('${s['status']} · ${s['note'] ?? ''}'),
                  trailing:
                      s['status'] == 'PENDING' &&
                          s['initiatorId'] != userId &&
                          (s['debtorId'] == userId || s['creditorId'] == userId)
                      ? Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Xác nhận',
                              icon: const Icon(Icons.check),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await confirm(
                                        'Xác nhận',
                                        'Bạn xác nhận khoản tiền đã thực sự được trả hoặc nhận?',
                                      ))
                                        await mutate(
                                          '$base/groups/$selected/settlements/${s['id']}/confirm',
                                          {'version': s['version']},
                                        );
                                    },
                            ),
                            IconButton(
                              tooltip: 'Từ chối',
                              icon: const Icon(Icons.close),
                              onPressed: busy
                                  ? null
                                  : () => mutate(
                                      '$base/groups/$selected/settlements/${s['id']}/reject',
                                      {'version': s['version']},
                                    ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            pager(settlementPage, settlementPages, (p) {
              setState(() => settlementPage = p);
              load();
            }),
            Text(
              'Nhật ký kiểm toán',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...audit.map(
              (a) => ListTile(
                title: Text('${a['action']}'),
                subtitle: Text(
                  '${memberName(a['actorId'])} · ${a['createdAt']}',
                ),
              ),
            ),
            pager(auditPage, auditPages, (p) {
              setState(() => auditPage = p);
              load();
            }),
          ],
        ],
      ),
    ),
  );
}
