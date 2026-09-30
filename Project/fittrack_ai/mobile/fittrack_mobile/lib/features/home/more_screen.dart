import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_center.dart';
import '../../core/widgets/common_widgets.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_session.dart';
import '../help/user_guide_sheet.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../quotes/quote_screen.dart';
import '../journal/journal_screen.dart';
import '../finance/finance_screen.dart';
import '../assistant/assistant_screen.dart';
import '../fitness/fitness_screen.dart';
import '../health/health_screen.dart';
import '../lunch/lunch_screen.dart';
import '../planner/planner_screen.dart';

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
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.help_outline_rounded),
                ),
                title: const Text('Hướng dẫn sử dụng'),
                subtitle: const Text(
                  'Xem từng bước theo các module bạn được cấp quyền',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final session = context.read<AuthSession>();
                  try {
                    await session.refreshProfile();
                  } catch (_) {
                    // Dùng quyền gần nhất đã lưu nếu đang mất mạng.
                  }
                  if (!context.mounted || session.user == null) return;
                  await showUserGuideSheet(context, session.user!);
                },
              ),
              if (user.lunchEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.lunch_dining_outlined),
                  ),
                  title: const Text('Đặt cơm'),
                  subtitle: const Text('Menu, giỏ món, quỹ và lịch sử đặt cơm'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Đặt cơm',
                    page: const LunchScreen(),
                  ),
                ),
              ],
              if (user.fitnessEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.fitness_center_outlined),
                  ),
                  title: const Text('Luyện tập'),
                  subtitle: const Text('Buổi tập và nhật ký dinh dưỡng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Luyện tập',
                    page: const FitnessScreen(),
                  ),
                ),
              ],
              if (user.healthEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.favorite_outline),
                  ),
                  title: const Text('Sức khỏe'),
                  subtitle: const Text('Tổng hợp, chỉ số cơ thể và nhắc nhở'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Sức khỏe',
                    page: const HealthScreen(),
                  ),
                ),
              ],
              if (user.todoEnabled || user.scheduleEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_note_outlined),
                  ),
                  title: const Text('Lịch & việc'),
                  subtitle: const Text(
                    'Việc cần làm và thời khóa biểu hợp nhất',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Lịch & việc',
                    page: PlannerScreen(user: user),
                  ),
                ),
              ],
              if (user.quoteEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.format_quote_outlined),
                  ),
                  title: const Text('Kho câu nói'),
                  subtitle: const Text('Lưu câu yêu thích và xem lại mỗi ngày'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Kho câu nói',
                    page: const QuoteScreen(),
                  ),
                ),
              ],
              if (user.journalEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.menu_book_outlined),
                  ),
                  title: const Text('Nhật ký'),
                  subtitle: const Text(
                    'Câu hỏi hôm nay và những trang riêng tư',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Nhật ký',
                    page: const JournalScreen(),
                  ),
                ),
              ],
              if (user.financeEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: const Text('Tài chính cá nhân'),
                  subtitle: const Text(
                    'Thu chi, tài khoản, ngân sách và khoản định kỳ',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'Tài chính cá nhân',
                    page: const FinanceScreen(),
                  ),
                ),
              ],
              if (user.chatbotEnabled || user.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.smart_toy_outlined),
                  ),
                  title: const Text('FitTrack PT'),
                  subtitle: const Text('Tư vấn và thao tác có xác nhận'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    title: 'FitTrack PT',
                    page: const AssistantScreen(),
                  ),
                ),
              ],
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
