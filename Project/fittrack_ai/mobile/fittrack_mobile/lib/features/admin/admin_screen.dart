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
    tabs = TabController(length: 3, vsync: this);
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
                Tab(text: 'Import menu'),
                Tab(text: 'Thông báo'),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: tabs,
          children: const [_UsersAdminTab(), _MenuImportTab(), _BroadcastTab()],
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
            'App mobile chỉ quản lý 3 quyền nghiệp vụ. Quyền chatbot được để lại cho giai đoạn sau.',
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

class _MenuImportTab extends StatefulWidget {
  const _MenuImportTab();
  @override
  State<_MenuImportTab> createState() => _MenuImportTabState();
}

class _MenuImportTabState extends State<_MenuImportTab> {
  final label = TextEditingController(text: 'Cơm trưa');
  final vendor = TextEditingController(text: 'Quán cơm');
  final price = TextEditingController(text: '35000');
  final raw = TextEditingController();
  TimeOfDay cutoff = const TimeOfDay(hour: 10, minute: 30);
  bool busy = false;

  @override
  void dispose() {
    label.dispose();
    vendor.dispose();
    price.dispose();
    raw.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (raw.text.trim().isEmpty) {
      return showMessage(
        context,
        'Dán danh sách món quán gửi vào ô menu.',
        error: true,
      );
    }
    setState(() => busy = true);
    try {
      final api = context.read<ApiClient>();
      final now = DateTime.now();
      final cutoffDate = DateTime(
        now.year,
        now.month,
        now.day,
        cutoff.hour,
        cutoff.minute,
      );
      final menu = await api.post(
        '/lunch/admin/menus/import',
        data: {
          'menuDate': DateFormat('yyyy-MM-dd').format(now),
          'orderLabel': label.text.trim(),
          'vendorName': vendor.text.trim(),
          'cutoffAt': cutoffDate.toIso8601String(),
          'price': double.tryParse(price.text) ?? 35000,
          'rawMenuText': raw.text.trim(),
        },
      );
      if (!mounted) return;
      final notify = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 42),
          title: const Text('Import thành công'),
          content: const Text(
            'Bạn có muốn gửi thông báo app và email cho toàn bộ user đang hoạt động ngay bây giờ không?',
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
      raw.clear();
    } catch (e) {
      if (mounted) showMessage(context, displayError(e), error: true);
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

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text(
        'Dán nguyên nội dung quán gửi hoặc chọn tệp TXT/CSV. Các món phía trên dấu + là nhóm cơm 2 món; phía dưới là món đơn.',
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
        decoration: const InputDecoration(labelText: 'Tên đợt đặt món'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: vendor,
        decoration: const InputDecoration(labelText: 'Tên quán'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: price,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Giá một phần (đồng)'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () async {
          final value = await showTimePicker(
            context: context,
            initialTime: cutoff,
          );
          if (value != null) setState(() => cutoff = value);
        },
        icon: const Icon(Icons.schedule),
        label: Text('Giờ chốt: ${cutoff.format(context)}'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: raw,
        minLines: 10,
        maxLines: 18,
        decoration: const InputDecoration(
          labelText: 'Danh sách món',
          hintText: 'Lòng gà roty\nTôm ram\nSườn ram\n+\nPhở bò',
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _import,
        icon: const Icon(Icons.upload_file),
        label: Text(busy ? 'Đang import...' : 'Import menu hôm nay'),
      ),
    ],
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
