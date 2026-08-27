import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  Object? error;
  bool updatingEmailPreference = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final raw = await context.read<ApiClient>().get('/users/me');
      if (mounted) {
        setState(() => profile = Map<String, dynamic>.from(raw as Map));
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> _setEmailNotifications(bool enabled) async {
    final previous = profile?['emailNotificationsEnabled'];
    setState(() {
      updatingEmailPreference = true;
      profile = {...?profile, 'emailNotificationsEnabled': enabled};
    });
    try {
      final updated = await context.read<ApiClient>().put(
        '/users/me',
        data: {'emailNotificationsEnabled': enabled},
      );
      if (mounted && updated is Map) {
        setState(() => profile = Map<String, dynamic>.from(updated));
      }
      if (mounted) showMessage(context, enabled ? 'Đã bật email notification.' : 'Đã tắt email notification.');
    } catch (e) {
      if (mounted) {
        setState(() {
          updatingEmailPreference = false;
          profile = {...?profile, 'emailNotificationsEnabled': previous ?? false};
        });
        showMessage(context, displayError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => updatingEmailPreference = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession>().user;
    if (auth == null) return const SizedBox.shrink();
    if (error != null) {
      return ErrorView(message: displayError(error!), onRetry: _load);
    }
    if (profile == null) return const LoadingView();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageIntro(
          title: 'Hồ sơ cá nhân',
          subtitle: 'Thông tin tài khoản và quyền truy cập hiện tại.',
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    _initials(auth.fullName),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.fullName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(auth.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (auth.lunchEnabled || auth.isAdmin)
                      const Chip(
                        avatar: Icon(Icons.lunch_dining, size: 18),
                        label: Text('Đặt cơm'),
                      ),
                    if (auth.fitnessEnabled || auth.isAdmin)
                      const Chip(
                        avatar: Icon(Icons.fitness_center, size: 18),
                        label: Text('Fitness'),
                      ),
                    if (auth.healthEnabled || auth.isAdmin)
                      const Chip(
                        avatar: Icon(Icons.favorite, size: 18),
                        label: Text('Sức khỏe'),
                      ),
                    if (auth.isAdmin)
                      const Chip(
                        avatar: Icon(Icons.admin_panel_settings, size: 18),
                        label: Text('Quản trị viên'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              _ProfileRow(
                label: 'Chiều cao',
                value: '${profile!['height'] ?? '-'} cm',
              ),
              const Divider(height: 1),
              _ProfileRow(
                label: 'Cân nặng',
                value: '${profile!['weight'] ?? '-'} kg',
              ),
              const Divider(height: 1),
              _ProfileRow(
                label: 'Mục tiêu',
                value: profile!['goal']?.toString() ?? 'Chưa thiết lập',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: SwitchListTile.adaptive(
            value: profile!['emailNotificationsEnabled'] == true,
            onChanged: updatingEmailPreference ? null : _setEmailNotifications,
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Nhận email notification'),
            subtitle: const Text('Cho phép FitTrack gửi email menu, broadcast và kịch bản nhắc nhở. OTP đặt lại mật khẩu vẫn hoạt động độc lập.'),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AuthSession>().logout();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .take(2)
      .map((e) => e[0].toUpperCase())
      .join();
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
