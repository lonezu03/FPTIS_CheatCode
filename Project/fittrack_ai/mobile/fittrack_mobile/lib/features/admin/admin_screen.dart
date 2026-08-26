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
                Tab(text: 'Quản lý menu'),
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
    final lines = <String>[...regular];
    if (special.isNotEmpty) lines.add('+');
    lines.addAll(special);
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
              '$menuDateLabel • ${menu['vendorName'] ?? 'Chưa có tên quán'} • chốt $cutoffLabel',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '${regularItems.length} món cơm (chọn 2) • ${specialItems.length} món đơn • '
              '$totalOrders phần đã đặt',
              style: const TextStyle(color: Colors.black54),
            ),
            if (regularItems.isNotEmpty || specialItems.isNotEmpty) ...[
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
                    'Dán nguyên nội dung quán gửi hoặc chọn tệp TXT/CSV. Món phía trên dấu + là nhóm cơm chọn 2 món; phía dưới là món đơn.',
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
                    helperText: 'Dùng dấu + để ngăn món cơm và món đơn.',
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
