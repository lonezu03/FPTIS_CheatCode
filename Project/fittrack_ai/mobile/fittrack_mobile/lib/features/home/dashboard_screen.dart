import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  Object? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthSession>().user!;
    if (!user.fitnessEnabled && !user.healthEnabled && !user.isAdmin) {
      setState(() => data = const {});
      return;
    }
    setState(() => error = null);
    try {
      final result = await context.read<ApiClient>().get('/dashboard/today');
      if (mounted) {
        setState(() => data = Map<String, dynamic>.from(result as Map));
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    if (data == null) return const LoadingView();
    final user = context.read<AuthSession>().user!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PageIntro(
            title: 'Xin chào, ${user.fullName}',
            subtitle: 'Đây là tổng quan hoạt động của bạn hôm nay.',
          ),
          const SizedBox(height: 20),
          if (!user.fitnessEnabled && !user.healthEnabled && !user.isAdmin)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lunch_dining, size: 38),
                  title: Text(
                    'Tài khoản đặt cơm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Admin có thể cấp thêm quyền Fitness và Sức khỏe trong màn hình quản trị.',
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Năng lượng',
                  value: _value(data!, [
                    'calories',
                    'caloriesToday',
                    'totalCalories',
                  ], suffix: ' kcal'),
                  icon: Icons.local_fire_department_outlined,
                ),
                _MetricCard(
                  label: 'Chất đạm',
                  value: _value(data!, [
                    'protein',
                    'proteinToday',
                    'totalProtein',
                  ], suffix: ' g'),
                  icon: Icons.egg_alt_outlined,
                ),
                _MetricCard(
                  label: 'Buổi tập',
                  value: _value(data!, [
                    'workouts',
                    'workoutCount',
                    'sessions',
                  ]),
                  icon: Icons.fitness_center,
                ),
                _MetricCard(
                  label: 'Bữa ăn',
                  value: _value(data!, ['meals', 'mealCount']),
                  icon: Icons.restaurant_outlined,
                ),
              ],
            ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gợi ý hôm nay',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.water_drop_outlined),
                    title: Text('Uống đủ nước'),
                    subtitle: Text(
                      'Chia đều lượng nước trong ngày thay vì uống nhiều một lần.',
                    ),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.directions_walk_outlined),
                    title: Text('Duy trì vận động'),
                    subtitle: Text(
                      'Một buổi đi bộ ngắn cũng giúp bạn giữ nhịp sinh hoạt.',
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

  static String _value(
    Map<String, dynamic> data,
    List<String> keys, {
    String suffix = '',
  }) {
    for (final key in keys) {
      if (data[key] != null) return '${data[key]}$suffix';
    }
    return '0$suffix';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}
