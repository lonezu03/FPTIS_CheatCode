import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              title: 'Quản trị hệ thống',
              subtitle:
                  'Quản lý quyền người dùng, menu trưa và thông báo công ty.',
            ),
            const SizedBox(height: 14),
            TabBar(
              controller: tabs,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Tài khoản'),
                Tab(text: 'Quản lý menu'),
                Tab(text: 'Thông báo'),
                Tab(text: 'Quỹ'),
                Tab(text: 'Kịch bản'),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: tabs,
          children: const [_UsersAdminTab(), _MenuImportTab(), _BroadcastTab(), _FundAdminTab(), _PlaybooksAdminTab()],
        ),
      ),
    ],
  );
}

class _UsersAdminTab extends StatefulWidget {
  const _UsersAdminTab();
  @override
  State<_UsersAdminTab> createState() => _UsersAdminTabState();
}

class _UsersAdminTabState extends State<_UsersAdminTab> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await context.read<ApiClient>().get('/admin/users');
      if (mounted) {
        setState(
          () => users = raw is List
              ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [],
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggle(
    Map<String, dynamic> user,
    String key,
    bool value,
  ) async {
    try {
      final updated = await context.read<ApiClient>().patch(
        '/admin/users/${user['id']}',
        data: {key: value},
      );
      final index = users.indexOf(user);
      if (mounted) {
        setState(
          () => users[index] = Map<String, dynamic>.from(updated as Map),
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _deleteLocked(Map<String, dynamic> user) async {
    if (user['active'] == true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text('Xóa vĩnh viễn ${user['email'] ?? 'tài khoản này'}? Dữ liệu liên quan không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<ApiClient>().delete('/admin/users/${user['id']}');
      if (mounted) {
        setState(() => users.remove(user));
        showMessage(context, 'Đã xóa tài khoản bị khóa.');
      }
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'App mobile quản lý 5 quyền nghiệp vụ: Đặt cơm, Fitness, Sức khỏe, Todo và Schedule. Quyền chatbot được để lại cho giai đoạn sau.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ...users.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    child: Text(
                      _shortName(user['fullName']?.toString() ?? 'U'),
                    ),
                  ),
                  title: Text(
                    user['fullName']?.toString() ?? 'Người dùng',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${user['email']} • ${user['active'] == true ? 'Đang hoạt động' : 'Đã khóa'}',
                  ),
                  children: [
                    SwitchListTile(
                      title: const Text('Tài khoản hoạt động'),
                      value: user['active'] == true,
                      onChanged: (v) => _toggle(user, 'active', v),
                    ),
                    SwitchListTile(
                      title: const Text('Đặt cơm'),
                      value: user['lunchEnabled'] == true,
                      onChanged: (v) => _toggle(user, 'lunchEnabled', v),
                    ),
                    SwitchListTile(
                      title: const Text('Fitness'),
                      value: user['fitnessEnabled'] == true,
                      onChanged: (v) => _toggle(user, 'fitnessEnabled', v),
                    ),
                    SwitchListTile(
                      title: const Text('Chăm sóc sức khỏe'),
                      value: user['healthEnabled'] == true,
                      onChanged: (v) => _toggle(user, 'healthEnabled', v),
                    ),
                    SwitchListTile(
                      title: const Text('Todo'),
                      value: user['todoEnabled'] == true,
                      onChanged: (v) => _toggle(user, 'todoEnabled', v),
                    ),
                    SwitchListTile(
                      title: const Text('Schedule'),
                      value: user['scheduleEnabled'] == true,
                      onChanged: (v) => _toggle(user, 'scheduleEnabled', v),
                    ),
                    if (user['active'] != true)
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                        title: const Text('Xóa tài khoản đã khóa', style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteLocked(user),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybooksAdminTab extends StatefulWidget {
  const _PlaybooksAdminTab();
  @override
  State<_PlaybooksAdminTab> createState() => _PlaybooksAdminTabState();
}

class _PlaybooksAdminTabState extends State<_PlaybooksAdminTab> {
  final name = TextEditingController();
  final triggerTime = TextEditingController(text: '21:30');
  final threshold = TextEditingController();
  final messages = TextEditingController(text: 'Chúc bạn ngủ ngon và phục hồi thật tốt.');
  List<Map<String, dynamic>> playbooks = [];
  List<Map<String, dynamic>> users = [];
  String category = 'WELLNESS';
  String mode = 'RANDOM';
  String conditionType = 'ANY';
  String recipientMode = 'ALL_ACTIVE';
  final days = <String>{'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'};
  final selectedUsers = <String>{};
  String? editingId;
  bool loading = true;
  bool busy = false;
  Object? playbookError;
  Object? usersError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    name.dispose();
    triggerTime.dispose();
    threshold.dispose();
    messages.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; playbookError = null; usersError = null; });
    final api = context.read<ApiClient>();
    try {
      final value = await api.get('/admin/notification-playbooks');
      playbooks = value is List ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
    } catch (e) {
      playbookError = e;
    }
    try {
      final value = await api.get('/admin/users');
      users = value is List ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
    } catch (e) {
      usersError = e;
    }
    if (mounted) setState(() => loading = false);
  }

  void _reset() {
    setState(() {
      editingId = null;
      name.clear();
      triggerTime.text = '21:30';
      threshold.clear();
      messages.text = 'Chúc bạn ngủ ngon và phục hồi thật tốt.';
      category = 'WELLNESS';
      mode = 'RANDOM';
      conditionType = 'ANY';
      recipientMode = 'ALL_ACTIVE';
      selectedUsers.clear();
      days
        ..clear()
        ..addAll({'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'});
    });
  }

  void _edit(Map<String, dynamic> item) {
    setState(() {
      editingId = item['id']?.toString();
      name.text = item['name']?.toString() ?? '';
      triggerTime.text = _shortTime(item['triggerTime']);
      threshold.text = item['threshold']?.toString() ?? '';
      messages.text = item['messages']?.toString() ?? '';
      category = item['category']?.toString() ?? 'WELLNESS';
      mode = item['mode']?.toString() ?? 'RANDOM';
      conditionType = item['conditionType']?.toString() ?? 'ANY';
      recipientMode = item['recipientMode']?.toString() ?? 'ALL_ACTIVE';
      days
        ..clear()
        ..addAll((item['daysOfWeek']?.toString() ?? '').split(',').where((value) => value.isNotEmpty));
      selectedUsers
        ..clear()
        ..addAll((item['recipientUserIds'] is List ? item['recipientUserIds'] as List : const []).map((id) => id.toString()));
    });
  }

  Map<String, dynamic> _payload({bool? enabled}) => {
    'name': name.text.trim(),
    'category': category,
    'mode': mode,
    'triggerTime': triggerTime.text.trim(),
    'daysOfWeek': days.join(','),
    'messages': messages.text.trim(),
    'conditionType': conditionType,
    'threshold': threshold.text.trim().isEmpty ? null : num.tryParse(threshold.text.trim()),
    'recipientMode': recipientMode,
    'recipientUserIds': selectedUsers.toList(),
    'enabled': enabled ?? true,
  };

  Future<void> _save() async {
    if (name.text.trim().isEmpty || messages.text.trim().isEmpty || days.isEmpty || (recipientMode == 'SELECTED' && selectedUsers.isEmpty)) {
      showMessage(context, 'Vui lòng điền tên, câu thông báo, ngày gửi và người nhận.', error: true);
      return;
    }
    if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(triggerTime.text.trim())) {
      showMessage(context, 'Giờ gửi phải theo định dạng HH:mm, ví dụ 21:30.', error: true);
      return;
    }
    if (recipientMode == 'SELECTED' && usersError != null) {
      showMessage(context, 'Chưa tải được danh sách tài khoản. Vui lòng thử lại trước khi chọn người nhận.', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      final api = context.read<ApiClient>();
      if (editingId == null) {
        await api.post('/admin/notification-playbooks', data: _payload());
      } else {
        final current = playbooks.firstWhere((item) => item['id'].toString() == editingId, orElse: () => {'enabled': true});
        await api.patch('/admin/notification-playbooks/$editingId', data: _payload(enabled: current['enabled'] == true));
      }
      _reset();
      await _load();
      if (mounted) showMessage(context, 'Đã lưu kịch bản notification.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    try {
      await context.read<ApiClient>().patch('/admin/notification-playbooks/${item['id']}', data: {
        'name': item['name'],
        'category': item['category'],
        'mode': item['mode'],
        'triggerTime': item['triggerTime'],
        'daysOfWeek': item['daysOfWeek'],
        'messages': item['messages'],
        'conditionType': item['conditionType'],
        'threshold': item['threshold'],
        'recipientMode': item['recipientMode'],
        'recipientUserIds': item['recipientUserIds'] ?? [],
        'enabled': item['enabled'] != true,
      });
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa kịch bản?'),
      content: Text('Xóa “${item['name'] ?? 'kịch bản'}” khỏi lịch gửi?'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa'))],
    ));
    if (confirmed != true) return;
    try {
      await context.read<ApiClient>().delete('/admin/notification-playbooks/${item['id']}');
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (playbookError != null) return ErrorView(message: displayError(playbookError!), onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(editingId == null ? 'Tạo kịch bản' : 'Chỉnh sửa kịch bản', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên kịch bản', hintText: 'Ví dụ: Chúc ngủ ngon')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: category, isExpanded: true, decoration: const InputDecoration(labelText: 'Nhóm'), items: const [DropdownMenuItem(value: 'WELLNESS', child: Text('Sức khỏe')), DropdownMenuItem(value: 'MEAL', child: Text('Ăn uống')), DropdownMenuItem(value: 'SLEEP', child: Text('Giấc ngủ')), DropdownMenuItem(value: 'PRODUCTIVITY', child: Text('Hiệu suất'))], onChanged: (value) { if (value != null) setState(() => category = value); })),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<String>(value: mode, isExpanded: true, decoration: const InputDecoration(labelText: 'Cách chọn câu'), items: const [DropdownMenuItem(value: 'RANDOM', child: Text('Ngẫu nhiên')), DropdownMenuItem(value: 'FIXED', child: Text('Câu đầu tiên'))], onChanged: (value) { if (value != null) setState(() => mode = value); })),
                ]),
                const SizedBox(height: 10),
                TextField(controller: triggerTime, keyboardType: TextInputType.datetime, decoration: const InputDecoration(labelText: 'Giờ gửi', hintText: '21:30')),
                const SizedBox(height: 10),
                const Text('Ngày gửi', style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(spacing: 6, children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].asMap().entries.map((entry) {
                  final day = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'][entry.key];
                  return FilterChip(label: Text(entry.value), selected: days.contains(day), onSelected: (value) => setState(() { value ? days.add(day) : days.remove(day); }));
                }).toList()),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: conditionType, decoration: const InputDecoration(labelText: 'Điều kiện'), items: const [DropdownMenuItem(value: 'ANY', child: Text('Luôn gửi')), DropdownMenuItem(value: 'NO_MEAL', child: Text('Chưa ghi bữa')), DropdownMenuItem(value: 'MEALS_LT', child: Text('Số bữa dưới ngưỡng')), DropdownMenuItem(value: 'PROTEIN_GT', child: Text('Đạm vượt ngưỡng'))], onChanged: (value) { if (value != null) setState(() => conditionType = value); }),
                if (conditionType == 'MEALS_LT' || conditionType == 'PROTEIN_GT') ...[const SizedBox(height: 10), TextField(controller: threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ngưỡng'))],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: recipientMode, decoration: const InputDecoration(labelText: 'Người nhận'), items: const [DropdownMenuItem(value: 'ALL_ACTIVE', child: Text('Tất cả user đang hoạt động')), DropdownMenuItem(value: 'SELECTED', child: Text('Chỉ user được chọn'))], onChanged: (value) { if (value != null) setState(() => recipientMode = value); }),
                if (recipientMode == 'SELECTED') ...[
                  const SizedBox(height: 6),
                  if (usersError != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Không tải được danh sách tài khoản. Hãy bấm làm mới.', style: TextStyle(color: Colors.red.shade700))),
                  ...users.where((user) => user['active'] == true).map((user) => CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true, value: selectedUsers.contains(user['id'].toString()), title: Text(user['fullName']?.toString() ?? user['email']?.toString() ?? 'User'), onChanged: (value) => setState(() { value == true ? selectedUsers.add(user['id'].toString()) : selectedUsers.remove(user['id'].toString()); }))),
                ],
                const SizedBox(height: 10),
                TextField(controller: messages, maxLines: 5, decoration: const InputDecoration(labelText: 'Các câu thông báo (mỗi câu một dòng)')),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: FilledButton(onPressed: busy ? null : _save, child: Text(busy ? 'Đang lưu...' : editingId == null ? 'Lưu kịch bản' : 'Lưu thay đổi'))), if (editingId != null) ...[const SizedBox(width: 8), IconButton(onPressed: busy ? null : _reset, tooltip: 'Hủy sửa', icon: const Icon(Icons.close))]]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          if (playbooks.isEmpty) const EmptyView(icon: Icons.notifications_none, title: 'Chưa có kịch bản', subtitle: 'Tạo kịch bản để nhắc đúng người, đúng lúc.'),
          ...playbooks.map((item) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(child: Icon(item['enabled'] == true ? Icons.notifications_active_outlined : Icons.notifications_off_outlined)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name']?.toString() ?? 'Kịch bản', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${_shortTime(item['triggerTime'])} • ${item['recipientMode'] == 'SELECTED' ? '${(item['recipientUserIds'] as List? ?? []).length} người' : 'Tất cả tài khoản hoạt động'}', style: const TextStyle(color: Colors.black54)),
            ])),
            PopupMenuButton<String>(tooltip: 'Thao tác', onSelected: (value) { if (value == 'edit') _edit(item); if (value == 'toggle') _toggle(item); if (value == 'delete') _delete(item); }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Chỉnh sửa'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(item['enabled'] == true ? Icons.pause_circle_outline : Icons.play_circle_outline), title: Text(item['enabled'] == true ? 'Tạm dừng' : 'Kích hoạt'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Xóa'), contentPadding: EdgeInsets.zero)),
            ]),
          ])))),
        ],
      ),
    );
  }
}

class _FundAdminTab extends StatefulWidget {
  const _FundAdminTab();

  @override
  State<_FundAdminTab> createState() => _FundAdminTabState();
}

class _FundAdminTabState extends State<_FundAdminTab> {
  final amount = TextEditingController(text: '100000');
  final note = TextEditingController();
  List<Map<String, dynamic>> members = [];
  String? selectedUserId;
  String action = 'ADD_FUND';
  bool loading = true;
  bool busy = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final raw = await context.read<ApiClient>().get('/lunch/admin/members');
      if (!mounted) return;
      setState(() {
        members = raw is List ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
        selectedUserId ??= members.isNotEmpty ? members.first['id']?.toString() : null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _adjust() async {
    final userId = selectedUserId;
    final value = int.tryParse(amount.text.replaceAll(',', '').trim());
    if (userId == null || value == null || value <= 0) {
      showMessage(context, 'Chọn thành viên và nhập số tiền hợp lệ.', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      await context.read<ApiClient>().post('/lunch/admin/funds/adjust', data: {
        'userId': userId,
        'amount': value,
        'action': action,
        'note': note.text.trim(),
      });
      if (!mounted) return;
      note.clear();
      await _load();
      if (mounted) showMessage(context, 'Đã ghi nhận điều chỉnh quỹ.');
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error != null) return ErrorView(message: displayError(error!), onRetry: _load);
    final matchingMembers = members.where((member) => member['id']?.toString() == selectedUserId).toList();
    final selected = matchingMembers.isEmpty ? null : matchingMembers.first;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const PageIntro(
            title: 'Quỹ & công nợ',
            subtitle: 'Cộng, trừ quỹ hoặc điều chỉnh công nợ với lý do rõ ràng.',
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Thành viên'),
                    items: members.map((member) => DropdownMenuItem<String>(
                      value: member['id']?.toString(),
                      child: Text(member['fullName']?.toString() ?? 'Người dùng'),
                    )).toList(),
                    onChanged: busy ? null : (value) => setState(() => selectedUserId = value),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 10),
                    Text('Số dư ròng: ${_formatMoney(selected['walletBalance'])} • Công nợ: ${_formatMoney(selected['outstandingDebt'])}', style: const TextStyle(color: Colors.black54)),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: action,
                    decoration: const InputDecoration(labelText: 'Thao tác'),
                    items: const [
                      DropdownMenuItem(value: 'ADD_FUND', child: Text('Cộng tiền vào quỹ')),
                      DropdownMenuItem(value: 'REMOVE_FUND', child: Text('Trừ tiền khỏi quỹ')),
                      DropdownMenuItem(value: 'ADD_DEBT', child: Text('Ghi tăng công nợ')),
                      DropdownMenuItem(value: 'REMOVE_DEBT', child: Text('Ghi giảm công nợ')),
                    ],
                    onChanged: busy ? null : (value) => setState(() => action = value ?? 'ADD_FUND'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: amount, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số tiền', suffixText: 'đ')),
                  const SizedBox(height: 10),
                  TextField(controller: note, enabled: !busy, maxLength: 500, decoration: const InputDecoration(labelText: 'Ghi chú đối soát', hintText: 'Ví dụ: điều chỉnh theo biên bản tháng này')),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: busy ? null : _adjust, icon: const Icon(Icons.account_balance_wallet_outlined), label: Text(busy ? 'Đang ghi nhận...' : 'Xác nhận điều chỉnh')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...members.map((member) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(_shortName(member['fullName']?.toString() ?? 'U'))),
              title: Text(member['fullName']?.toString() ?? 'Người dùng'),
              subtitle: Text('Quỹ: ${_formatMoney(member['walletBalance'])} • Nợ: ${_formatMoney(member['outstandingDebt'])}'),
              onTap: () => setState(() => selectedUserId = member['id']?.toString()),
            ),
          )),
        ],
      ),
    );
  }

  String _formatMoney(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
    return '${NumberFormat('#,##0', 'vi_VN').format(number)}đ';
  }
}

class _MenuImportTab extends StatefulWidget {
  const _MenuImportTab();
  @override
  State<_MenuImportTab> createState() => _MenuImportTabState();
}

class _MenuImportTabState extends State<_MenuImportTab> {
  static const _defaultLabel = 'Cơm trưa';
  static const _defaultVendor = 'Quán cơm';

  final label = TextEditingController(text: _defaultLabel);
  final vendor = TextEditingController(text: _defaultVendor);
  final price = TextEditingController(text: '35000');
  final raw = TextEditingController();
  final scrollController = ScrollController();

  DateTime menuDate = DateTime.now();
  TimeOfDay cutoff = const TimeOfDay(hour: 10, minute: 30);
  List<Map<String, dynamic>> menus = [];
  String? editingMenuId;
  bool loadingMenus = true;
  Object? menusError;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenus());
  }

  @override
  void dispose() {
    label.dispose();
    vendor.dispose();
    price.dispose();
    raw.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    if (mounted) {
      setState(() {
        loadingMenus = true;
        menusError = null;
      });
    }
    try {
      final response = await context.read<ApiClient>().get(
        '/lunch/admin/menus',
      );
      final fetched = response is List
          ? response
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => menus = fetched);
    } catch (error) {
      if (mounted) setState(() => menusError = error);
    } finally {
      if (mounted) setState(() => loadingMenus = false);
    }
  }

  Future<void> _saveMenu() async {
    if (raw.text.trim().isEmpty) {
      return showMessage(
        context,
        'Dán danh sách món quán gửi vào ô menu.',
        error: true,
      );
    }
    final portionPrice = _readPrice();
    if (portionPrice == null || portionPrice <= 0) {
      return showMessage(
        context,
        'Giá một phần phải là số tiền lớn hơn 0.',
        error: true,
      );
    }

    final isEditing = editingMenuId != null;
    setState(() => busy = true);
    try {
      final api = context.read<ApiClient>();
      final cutoffDate = DateTime(
        menuDate.year,
        menuDate.month,
        menuDate.day,
        cutoff.hour,
        cutoff.minute,
      );
      final payload = {
        'menuDate': DateFormat('yyyy-MM-dd').format(menuDate),
        'orderLabel': label.text.trim().isEmpty
            ? _defaultLabel
            : label.text.trim(),
        'vendorName': vendor.text.trim().isEmpty
            ? _defaultVendor
            : vendor.text.trim(),
        // Spring receives LocalDateTime, so send an offset-free local value.
        'cutoffAt': DateFormat('yyyy-MM-ddTHH:mm:ss').format(cutoffDate),
        'price': portionPrice,
        'rawMenuText': raw.text.trim(),
      };
      final menu = isEditing
          ? await api.put('/lunch/admin/menus/$editingMenuId', data: payload)
          : await api.post('/lunch/admin/menus/import', data: payload);
      if (!mounted) return;
      final notify = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 42),
          title: Text(isEditing ? 'Cập nhật thành công' : 'Import thành công'),
          content: Text(
            isEditing
                ? 'Bạn có muốn thông báo thực đơn đã thay đổi cho toàn bộ người dùng đang hoạt động không?'
                : 'Bạn có muốn gửi thông báo app và email cho toàn bộ người dùng đang hoạt động ngay bây giờ không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi thông báo'),
            ),
          ],
        ),
      );
      if (notify == true && menu is Map && menu['id'] != null) {
        await api.post('/lunch/admin/menus/${menu['id']}/notify');
        if (mounted) {
          showMessage(context, 'Đã gửi thông báo menu đến người dùng.');
        }
      }
      if (!isEditing) raw.clear();
      await _loadMenus();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int? _readPrice() {
    final digitsOnly = price.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly);
  }

  List<Map<String, dynamic>> _itemsFor(Map<String, dynamic> menu, String key) {
    final value = menu[key];
    if (value is! List) return const [];
    final items = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    items.sort(
      (left, right) => ((left['sortOrder'] as num?)?.toInt() ?? 0).compareTo(
        (right['sortOrder'] as num?)?.toInt() ?? 0,
      ),
    );
    return items;
  }

  String _rawMenuText(Map<String, dynamic> menu) {
    final regular = _itemsFor(menu, 'regularItems')
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty);
    final special = _itemsFor(menu, 'specialItems')
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty);
    final extras = _itemsFor(menu, 'extraItems').map((item) {
      final name = item['name']?.toString().trim() ?? '';
      final itemPrice = item['unitPrice'];
      return itemPrice == null ? name : '$name | ${itemPrice.toString()}';
    }).where((name) => name.isNotEmpty);
    final lines = <String>[...regular];
    if (special.isNotEmpty) lines.add('+');
    lines.addAll(special);
    if (extras.isNotEmpty) {
      lines.add('@DRINKS');
      lines.addAll(extras);
    }
    return lines.join('\n');
  }

  DateTime _readDate(dynamic value, DateTime fallback) =>
      DateTime.tryParse(value?.toString() ?? '') ?? fallback;

  TimeOfDay _readTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return const TimeOfDay(hour: 10, minute: 30);
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    return TimeOfDay(hour: local.hour, minute: local.minute);
  }

  void _editMenu(Map<String, dynamic> menu) {
    if (menu['canReplace'] != true) return;
    final nextDate = _readDate(menu['menuDate'], DateTime.now());
    setState(() {
      editingMenuId = menu['id']?.toString();
      menuDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
      cutoff = _readTime(menu['cutoffAt']);
      label.text = menu['orderLabel']?.toString() ?? _defaultLabel;
      vendor.text = menu['vendorName']?.toString() ?? _defaultVendor;
      price.text = menu['price']?.toString() ?? '35000';
      raw.text = _rawMenuText(menu);
    });
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _newMenu({bool keepDraft = false}) {
    setState(() {
      editingMenuId = null;
      menuDate = DateTime.now();
      cutoff = const TimeOfDay(hour: 10, minute: 30);
      label.text = _defaultLabel;
      vendor.text = _defaultVendor;
      price.text = '35000';
      if (!keepDraft) raw.clear();
    });
  }

  Future<void> _deleteMenu(Map<String, dynamic> menu) async {
    if (menu['canReplace'] != true) return;
    final menuId = menu['id']?.toString();
    if (menuId == null || menuId.isEmpty) return;
    final date = menu['menuDate']?.toString() ?? 'đã chọn';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        title: const Text('Xóa thực đơn?'),
        content: Text(
          'Thực đơn ngày $date chỉ xóa được khi chưa từng phát sinh đơn nào. '
          'Nếu đã có đơn hoặc đã chốt, hệ thống sẽ từ chối để bảo vệ lịch sử. '
          'Sau khi xóa, bạn có thể dùng nội dung trong form để import lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa thực đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => busy = true);
    try {
      await context.read<ApiClient>().delete('/lunch/admin/menus/$menuId');
      if (!mounted) return;
      if (editingMenuId == menuId) _newMenu(keepDraft: true);
      await _loadMenus();
      if (mounted) {
        showMessage(
          context,
          'Đã xóa thực đơn. Bạn có thể kiểm tra nội dung trong form và import lại.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickMenuFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true).trim();
      if (content.isEmpty) {
        if (mounted) {
          showMessage(context, 'Tệp không có nội dung menu.', error: true);
        }
        return;
      }
      raw.text = content;
      if (mounted) {
        showMessage(context, 'Đã đọc menu từ ${file.name}.');
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: menuDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (value != null && mounted) setState(() => menuDate = value);
  }

  Future<void> _pickCutoff() async {
    final value = await showTimePicker(context: context, initialTime: cutoff);
    if (value != null && mounted) setState(() => cutoff = value);
  }

  Widget _menuCard(Map<String, dynamic> menu) {
    final regularItems = _itemsFor(menu, 'regularItems');
    final specialItems = _itemsFor(menu, 'specialItems');
    final extraItems = _itemsFor(menu, 'extraItems');
    final menuId = menu['id']?.toString();
    final isSelected = editingMenuId == menuId;
    final canReplace = menu['canReplace'] == true;
    final menuDateLabel = menu['menuDate']?.toString() ?? 'Không rõ ngày';
    final cutoffLabel = _readTime(menu['cutoffAt']).format(context);
    final totalOrders = (menu['totalOrders'] as num?)?.toInt() ?? 0;

    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu['orderLabel']?.toString() ?? 'Thực đơn trưa',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isSelected) const Chip(label: Text('Đang sửa')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$menuDateLabel • ${menu['vendorName'] ?? 'Chưa có tên quán'} • ${menu['coordinator'] is Map ? (menu['coordinator']['fullName'] ?? 'Điều phối viên') : 'Điều phối viên'} • chốt $cutoffLabel',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '${regularItems.length} món cơm (chọn 2) • ${specialItems.length} món đơn • ${extraItems.length} món thêm • '
              '$totalOrders phần đã đặt',
              style: const TextStyle(color: Colors.black54),
            ),
            if (regularItems.isNotEmpty || specialItems.isNotEmpty || extraItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...regularItems
                      .take(4)
                      .map(
                        (item) =>
                            Chip(label: Text(item['name']?.toString() ?? '')),
                      ),
                  if (regularItems.length > 4)
                    Chip(label: Text('+${regularItems.length - 4} món')),
                  ...extraItems.take(3).map((item) => Chip(avatar: const Icon(Icons.local_drink_outlined, size: 16), label: Text('${item['name'] ?? ''} ${item['unitPrice'] == null ? '' : '${item['unitPrice']}đ'}'))),
                  ...specialItems
                      .take(2)
                      .map(
                        (item) => Chip(
                          avatar: const Icon(Icons.star_outline, size: 16),
                          label: Text(item['name']?.toString() ?? ''),
                        ),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (!canReplace) ...[
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.black54),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đã có lịch sử đơn hoặc đã chốt; không thể sửa/xóa để bảo toàn dữ liệu.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy || !canReplace ? null : () => _editMenu(menu),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa menu'),
                ),
                OutlinedButton.icon(
                  onPressed: busy || !canReplace
                      ? null
                      : () => _deleteMenu(menu),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa / import lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _loadMenus,
    child: ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editingMenuId == null
                            ? 'Import thực đơn mới'
                            : 'Chỉnh sửa thực đơn đã import',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (editingMenuId != null)
                      TextButton.icon(
                        onPressed: busy ? null : _newMenu,
                        icon: const Icon(Icons.add),
                        label: const Text('Menu mới'),
                      ),
                  ],
                ),
                if (editingMenuId != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Chỉ có thể thay danh sách món khi thực đơn chưa phát sinh đơn nào. '
                    'Nếu đã có đơn, hãy giữ menu để bảo toàn lịch sử đặt cơm.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ] else
                  const Text(
                    'Dán nội dung quán gửi hoặc chọn TXT/CSV. Món trước dấu + là nhóm cơm chọn 2 món; sau dấu + là món đơn. Thêm @DRINKS rồi nhập Trà đào | 45000 hoặc Trà vải 50000 để lưu món có giá riêng.',
                    style: TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickMenuFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Chọn tệp menu từ thiết bị'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: label,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên đợt đặt món',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vendor,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Tên quán'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá một phần (đồng)',
                    helperText: 'Ví dụ: 35000',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Ngày menu: ${DateFormat('dd/MM/yyyy').format(menuDate)}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickCutoff,
                      icon: const Icon(Icons.schedule),
                      label: Text('Giờ chốt: ${cutoff.format(context)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: raw,
                  minLines: 10,
                  maxLines: 18,
                  decoration: const InputDecoration(
                    labelText: 'Danh sách món',
                    helperText: 'Dùng dấu + để ngăn món cơm/món đơn; dùng @DRINKS hoặc @EXTRAS cho đồ uống có giá riêng.',
                    hintText: 'Lòng gà roty\nTôm ram\nSườn ram\n+\nPhở bò',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy ? null : _saveMenu,
                  icon: Icon(
                    editingMenuId == null
                        ? Icons.upload_file
                        : Icons.save_outlined,
                  ),
                  label: Text(
                    busy
                        ? 'Đang lưu...'
                        : editingMenuId == null
                        ? 'Import thực đơn'
                        : 'Lưu thay đổi thực đơn',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Thực đơn đã import',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Tải lại danh sách',
              onPressed: loadingMenus ? null : _loadMenus,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn một thực đơn để nạp lại dữ liệu vào form bên trên. Kéo xuống để làm mới danh sách.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 8),
        if (loadingMenus)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (menusError != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayError(menusError!),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loadMenus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          )
        else if (menus.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Chưa có thực đơn nào được import.'),
            ),
          )
        else
          ...menus.map(_menuCard),
      ],
    ),
  );
}

class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();
  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final title = TextEditingController();
  final message = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (title.text.trim().isEmpty || message.text.trim().isEmpty) {
      return showMessage(
        context,
        'Nhập tiêu đề và nội dung thông báo.',
        error: true,
      );
    }
    setState(() => busy = true);
    try {
      final result = await context.read<ApiClient>().post(
        '/admin/notifications/broadcast',
        data: {
          'title': title.text.trim(),
          'message': message.text.trim(),
          'sendToAll': true,
          'recipientUserIds': <String>[],
        },
      );
      if (mounted) {
        showMessage(
          context,
          result is Map
              ? (result['message']?.toString() ?? 'Đã gửi thông báo.')
              : 'Đã gửi thông báo.',
        );
      }
      title.clear();
      message.clear();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text(
        'Thông báo được lưu trong app và gửi email tới toàn bộ tài khoản đang hoạt động.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: title,
        maxLength: 150,
        decoration: const InputDecoration(labelText: 'Tiêu đề'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: message,
        minLines: 5,
        maxLines: 10,
        maxLength: 2000,
        decoration: const InputDecoration(labelText: 'Nội dung'),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _send,
        icon: const Icon(Icons.send_outlined),
        label: Text(busy ? 'Đang gửi...' : 'Gửi tới toàn bộ người dùng'),
      ),
    ],
  );
}

String _shortName(String value) =>
    value.trim().isEmpty ? 'U' : value.trim()[0].toUpperCase();

String _shortTime(dynamic value) {
  final text = value?.toString().trim() ?? '';
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
  if (match == null) return '--:--';
  return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
}
