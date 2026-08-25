import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_center.dart';
import '../../core/widgets/common_widgets.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_session.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationCenter>();
    final permissionGranted = notifications.permissionGranted == true;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageIntro(
          title: 'Thêm',
          subtitle: 'Thông báo, quản trị, hồ sơ và quyền của ứng dụng.',
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.notifications_outlined),
                ),
                title: const Text('Thông báo'),
                subtitle: Text(
                  notifications.unreadCount == 0
                      ? 'Không có thông báo chưa đọc'
                      : '${notifications.unreadCount} thông báo chưa đọc',
                ),
                trailing: notifications.unreadCount > 0
                    ? Badge(
                        label: Text(
                          notifications.unreadCount > 99
                              ? '99+'
                              : notifications.unreadCount.toString(),
                        ),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  title: 'Thông báo',
                  page: const NotificationsScreen(),
                ),
              ),
              if (user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  title: const Text('Quản trị'),
                  subtitle: const Text('Tài khoản, menu và thông báo công ty'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Quản trị',
                    page: const AdminScreen(),
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: const Text('Cá nhân'),
                subtitle: const Text('Hồ sơ, quyền truy cập và đăng xuất'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  title: 'Cá nhân',
                  page: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quyền ứng dụng',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    permissionGranted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: permissionGranted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Thông báo'),
                  subtitle: Text(
                    permissionGranted
                        ? 'Đã được phép gửi thông báo và phát âm thanh.'
                        : 'Chưa được cấp quyền thông báo.',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      if (permissionGranted) {
                        await notifications.openPermissionSettings();
                      } else {
                        final granted = await notifications.requestPermission();
                        if (!granted && context.mounted) {
                          await notifications.openPermissionSettings();
                        }
                      }
                    },
                    child: Text(permissionGranted ? 'Cài đặt' : 'Cho phép'),
                  ),
                ),
                const Divider(height: 20),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.folder_open_outlined),
                  title: Text('Tệp trên thiết bị'),
                  subtitle: Text(
                    'FitTrack chỉ đọc tệp bạn chủ động chọn bằng trình chọn tệp của hệ thống, không xem toàn bộ bộ nhớ.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _open(
    BuildContext context, {
    required String title,
    required Widget page,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: page,
        ),
      ),
    );
  }
}
