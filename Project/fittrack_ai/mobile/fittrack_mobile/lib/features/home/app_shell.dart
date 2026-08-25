import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_center.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_session.dart';
import '../fitness/fitness_screen.dart';
import '../health/health_screen.dart';
import '../lunch/lunch_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _Destination {
  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.page, {
    this.notification = false,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final bool notification;
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerNotifications());
  }

  List<_Destination> _destinations(AuthUser user) => [
    const _Destination(
      'Tổng quan',
      Icons.dashboard_outlined,
      Icons.dashboard,
      DashboardScreen(),
    ),
    if (user.lunchEnabled || user.isAdmin)
      const _Destination(
        'Đặt cơm',
        Icons.lunch_dining_outlined,
        Icons.lunch_dining,
        LunchScreen(),
      ),
    if (user.fitnessEnabled || user.isAdmin)
      const _Destination(
        'Luyện tập',
        Icons.fitness_center_outlined,
        Icons.fitness_center,
        FitnessScreen(),
      ),
    if (user.healthEnabled || user.isAdmin)
      const _Destination(
        'Sức khỏe',
        Icons.favorite_outline,
        Icons.favorite,
        HealthScreen(),
      ),
    const _Destination(
      'Thông báo',
      Icons.notifications_outlined,
      Icons.notifications,
      NotificationsScreen(),
      notification: true,
    ),
    if (user.isAdmin)
      const _Destination(
        'Quản trị',
        Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings,
        AdminScreen(),
      ),
    const _Destination(
      'Cá nhân',
      Icons.person_outline,
      Icons.person,
      ProfileScreen(),
    ),
  ];

  List<_Destination> _phoneDestinations(AuthUser user) => [
    const _Destination(
      'Tổng quan',
      Icons.dashboard_outlined,
      Icons.dashboard,
      DashboardScreen(),
    ),
    if (user.lunchEnabled || user.isAdmin)
      const _Destination(
        'Đặt cơm',
        Icons.lunch_dining_outlined,
        Icons.lunch_dining,
        LunchScreen(),
      ),
    if (user.fitnessEnabled || user.isAdmin)
      const _Destination(
        'Luyện tập',
        Icons.fitness_center_outlined,
        Icons.fitness_center,
        FitnessScreen(),
      ),
    if (user.healthEnabled || user.isAdmin)
      const _Destination(
        'Sức khỏe',
        Icons.favorite_outline,
        Icons.favorite,
        HealthScreen(),
      ),
    _Destination(
      'Thêm',
      Icons.apps_outlined,
      Icons.apps,
      MoreScreen(user: user),
      notification: true,
    ),
  ];

  Future<void> _offerNotifications() async {
    final notifications = context.read<NotificationCenter>();
    final enabled = await notifications.refreshPermissionStatus();
    if (enabled || !mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined, size: 42),
        title: const Text('Bật thông báo FitTrack?'),
        content: const Text(
          'Nhận menu cơm mới, thông báo chốt đơn, thanh toán và lời nhắc sức khỏe ngay trên điện thoại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final granted = await notifications.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Quyền thông báo đang bị tắt. Bạn có thể bật trong Cài đặt.',
          ),
          action: SnackBarAction(
            label: 'Mở cài đặt',
            onPressed: notifications.openPermissionSettings,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSession>().user!;
    final unreadCount = context.watch<NotificationCenter>().unreadCount;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final destinations = wide ? _destinations(user) : _phoneDestinations(user);
    if (index >= destinations.length) index = 0;
    final content = IndexedStack(
      index: index,
      children: destinations.map((item) => item.page).toList(),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.health_and_safety_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FitTrack',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  'Sống khỏe mỗi ngày',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: user.fullName,
              child: CircleAvatar(
                radius: 17,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      setState(() => index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: _destinationIcon(item, false, unreadCount),
                          selectedIcon: _destinationIcon(
                            item,
                            true,
                            unreadCount,
                          ),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: _destinationIcon(item, false, unreadCount),
                      selectedIcon: _destinationIcon(item, true, unreadCount),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _destinationIcon(
    _Destination destination,
    bool selected,
    int unreadCount,
  ) {
    final icon = Icon(selected ? destination.selectedIcon : destination.icon);
    if (!destination.notification || unreadCount <= 0) return icon;
    return Badge(
      label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
      child: icon,
    );
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
