import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/admin_screen.dart';
import '../auth/auth_session.dart';
import '../fitness/fitness_screen.dart';
import '../health/health_screen.dart';
import '../lunch/lunch_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

class _AppShellState extends State<AppShell> {
  int index = 0;

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSession>().user!;
    final destinations = _destinations(user);
    if (index >= destinations.length) index = 0;
    final wide = MediaQuery.sizeOf(context).width >= 760;
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
            child: Center(
              child: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
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
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
