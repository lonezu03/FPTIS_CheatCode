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
import '../fitness/workout_plans_screen.dart';
import '../fitness/nutrition_diary_tab.dart';
import '../catalog/catalog_screen.dart';
import '../admin/mobile_menu_settings_screen.dart';
import 'dashboard_screen.dart';
import 'mobile_menu_controller.dart';
import '../health/health_screen.dart';
import '../lunch/lunch_screen.dart';
import '../planner/planner_screen.dart';
import '../nutrition_planning/meal_planning_screen.dart';
import '../personal_tracking/personal_tracking_screen.dart';
import '../finance/savings_goals_screen.dart';
import '../sharing/template_sharing_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.user, required this.menu});

  final AuthUser user;
  final MobileMenuController menu;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: menu,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final user = context.watch<AuthSession>().user ?? this.user;
    final notifications = context.watch<NotificationCenter>();
    final permissionGranted = notifications.permissionGranted == true;
    return RefreshIndicator(
      onRefresh: menu.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const PageIntro(
            title: 'Thêm',
            subtitle: 'Thông báo, quản trị, hồ sơ và quyền của ứng dụng.',
          ),
          const SizedBox(height: 16),
          if (menu.loading) const LinearProgressIndicator(),
          if (menu.error != null)
            Card(
              child: ListTile(
                title: const Text('Chưa làm mới được menu app'),
                subtitle: Text(displayError(menu.error!)),
                trailing: IconButton(
                  tooltip: 'Thử lại',
                  onPressed: menu.load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
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
                ..._moduleTiles(context, user),
                ..._extensionTiles(context, user),
                if (user.isAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.dashboard_customize_outlined),
                    ),
                    title: const Text('Sắp xếp menu app'),
                    subtitle: const Text(
                      'Ẩn/hiện và sắp xếp cho mọi người, kể cả admin',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MobileMenuSettingsScreen(menu: menu),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    title: const Text('Quản trị'),
                    subtitle: const Text(
                      'Tài khoản, menu và thông báo công ty',
                    ),
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
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
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
                          final granted = await notifications
                              .requestPermission();
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
      ),
    );
  }

  List<Widget> _moduleTiles(BuildContext context, AuthUser user) {
    final pages = <String, (IconData, Widget)>{
      'dashboard': (Icons.dashboard_outlined, const DashboardScreen()),
      'lunch': (Icons.lunch_dining_outlined, const LunchScreen()),
      'fitness': (
        Icons.fitness_center_outlined,
        FitnessScreen(showNutrition: menu.allows('nutrition', user)),
      ),
      'nutrition': (Icons.restaurant_menu_outlined, const NutritionDiaryTab()),
      'health': (Icons.favorite_outline, const HealthScreen()),
      'planner': (Icons.event_note_outlined, PlannerScreen(user: user)),
      'quotes': (Icons.format_quote_outlined, const QuoteScreen()),
      'finance': (Icons.account_balance_wallet_outlined, const FinanceScreen()),
      'journal': (Icons.menu_book_outlined, const JournalScreen()),
      'assistant': (Icons.smart_toy_outlined, const AssistantScreen()),
      'workoutPlans': (
        Icons.calendar_month_outlined,
        const WorkoutPlansScreen(),
      ),
      'exercises': (
        Icons.list_alt_outlined,
        const CatalogScreen(kind: 'EXERCISE'),
      ),
      'foods': (Icons.restaurant_outlined, const CatalogScreen(kind: 'FOOD')),
    };
    return [
      for (final entry in menu.modules)
        if (menu.allows(entry['key'] as String, user)) ...[
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(child: Icon(pages[entry['key']]!.$1)),
            title: Text(mobileModuleLabels[entry['key']]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final key = entry['key'] as String;
              final page = pages[key]!.$2;
              if (const ['exercises', 'foods'].contains(key)) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: menu,
                      child: AnimatedBuilder(
                        animation: menu,
                        builder: (c, _) =>
                            menu.allows(
                              key,
                              c.watch<AuthSession>().user ?? user,
                            )
                            ? page
                            : Scaffold(
                                appBar: AppBar(
                                  title: const Text('Module đã ẩn'),
                                ),
                                body: const Center(
                                  child: Text(
                                    'Admin đã ẩn module này khỏi app.',
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              } else {
                _open(
                  context,
                  title: mobileModuleLabels[key]!,
                  page: page,
                  moduleKey: key,
                );
              }
            },
          ),
        ],
    ];
  }

  List<Widget> _extensionTiles(BuildContext context, AuthUser user) {
    final entries = <(String, String, IconData, Widget)>[
      if (menu.allows('fitness', user))
        (
          'fitness',
          'Mục tiêu luyện tập',
          Icons.flag_outlined,
          const PersonalTrackingScreen(kind: 'WORKOUT'),
        ),
      if (menu.allows('nutrition', user))
        (
          'nutrition',
          'Thực đơn & danh sách mua',
          Icons.shopping_basket_outlined,
          const MealPlanningScreen(),
        ),
      if (menu.allows('health', user)) ...[
        (
          'health',
          'Mục tiêu sức khỏe',
          Icons.flag_outlined,
          const PersonalTrackingScreen(),
        ),
        (
          'health',
          'Giấc ngủ & phục hồi',
          Icons.bedtime_outlined,
          const PersonalTrackingScreen(section: 'recovery'),
        ),
      ],
      if (menu.allows('planner', user) && (user.isAdmin || user.todoEnabled))
        (
          'planner',
          'Thói quen',
          Icons.checklist,
          const PersonalTrackingScreen(section: 'habits'),
        ),
      if (menu.allows('finance', user))
        (
          'finance',
          'Mục tiêu tiết kiệm',
          Icons.savings_outlined,
          const SavingsGoalsScreen(),
        ),
      if (menu.allows('workoutPlans', user) || menu.allows('nutrition', user))
        (
          menu.allows('workoutPlans', user) ? 'workoutPlans' : 'nutrition',
          'Chia sẻ bản mẫu',
          Icons.share_outlined,
          const TemplateSharingScreen(),
        ),
    ];
    return [
      for (final entry in entries) ...[
        const Divider(height: 1),
        ListTile(
          leading: CircleAvatar(child: Icon(entry.$3)),
          title: Text(entry.$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(
            context,
            title: entry.$2,
            page: entry.$4,
            moduleKey: entry.$1,
          ),
        ),
      ],
    ];
  }

  void _open(
    BuildContext context, {
    required String title,
    required Widget page,
    String? moduleKey,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: menu,
          child: AnimatedBuilder(
            animation: menu,
            builder: (c, _) {
              final current = c.watch<AuthSession>().user ?? user;
              final visible =
                  moduleKey == null || menu.allows(moduleKey, current);
              return Scaffold(
                appBar: AppBar(title: Text(title)),
                body: !visible
                    ? const Center(
                        child: Text('Admin đã ẩn module này khỏi app.'),
                      )
                    : page is FitnessScreen
                    ? FitnessScreen(
                        showNutrition: menu.allows('nutrition', current),
                      )
                    : page,
              );
            },
          ),
        ),
      ),
    );
  }
}
