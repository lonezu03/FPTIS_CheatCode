import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';
import '../home/mobile_menu_controller.dart';

class MobileMenuSettingsScreen extends StatefulWidget {
  const MobileMenuSettingsScreen({super.key, required this.menu});
  final MobileMenuController menu;
  @override
  State<MobileMenuSettingsScreen> createState() =>
      _MobileMenuSettingsScreenState();
}

class _MobileMenuSettingsScreenState extends State<MobileMenuSettingsScreen> {
  List<Map<String, dynamic>> rows = [];
  int version = 0;
  bool busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    setState(() {
      busy = true;
      error = null;
    });
    await widget.menu.load();
    if (!mounted) return;
    setState(() {
      error = widget.menu.error;
      version = widget.menu.version;
      rows = widget.menu.modules
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      busy = false;
    });
  }

  Future<void> save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Áp dụng menu cho toàn bộ app?'),
        content: const Text(
          'Áp dụng cho mọi tài khoản, kể cả admin. Ẩn menu không thu hồi quyền truy cập API. Mỗi người chỉ thấy các module được phân quyền.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final result = await context.read<ApiClient>().put(
        '/admin/mobile-menu',
        data: {'version': version, 'modules': rows},
      );
      widget.menu.accept(result);
      if (!mounted) return;
      if (widget.menu.error != null) throw widget.menu.error!;
      version = widget.menu.version;
      showMessage(
        context,
        'Đã cập nhật menu app. Các máy khác nhận cấu hình khi mở lại hoặc làm mới app.',
      );
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          '${displayError(e)}\nNếu cấu hình đã đổi, nhấn Tải lại rồi kiểm tra trước khi lưu.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthSession>().user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Chỉ quản trị viên được chỉnh menu.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sắp xếp menu app'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: busy ? null : reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Kéo để sắp xếp; tắt để ẩn với tất cả tài khoản, kể cả admin. Không thay đổi phân quyền. Thêm, Thông báo, Cá nhân và Quản trị luôn có lối vào.',
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(displayError(error!)),
            ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: rows.length,
              onReorderItem: (oldIndex, newIndex) {
                if (busy) return;
                setState(() {
                  rows.insert(newIndex, rows.removeAt(oldIndex));
                });
              },
              itemBuilder: (context, index) => ListTile(
                key: ValueKey(rows[index]['key']),
                leading: ReorderableDragStartListener(
                  index: index,
                  enabled: !busy,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(mobileModuleLabels[rows[index]['key']] ?? ''),
                trailing: Switch(
                  key: ValueKey('menu-visible-${rows[index]['key']}'),
                  value: rows[index]['visible'] == true,
                  onChanged: busy
                      ? null
                      : (value) =>
                            setState(() => rows[index]['visible'] = value),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy || error != null || rows.isEmpty
                      ? null
                      : save,
                  child: const Text('Lưu cấu hình toàn bộ app'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
