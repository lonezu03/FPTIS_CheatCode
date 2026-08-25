import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/notifications/notification_center.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_session.dart';
import 'features/auth/change_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/app_shell.dart';

class FitTrackBootstrap extends StatefulWidget {
  const FitTrackBootstrap({super.key});

  @override
  State<FitTrackBootstrap> createState() => _FitTrackBootstrapState();
}

class _FitTrackBootstrapState extends State<FitTrackBootstrap> {
  late final ApiClient api;
  late final AuthSession session;
  late final NotificationCenter notifications;
  bool _notificationsRunning = false;

  @override
  void initState() {
    super.initState();
    api = ApiClient();
    notifications = NotificationCenter(api);
    session = AuthSession(api)..addListener(_syncNotificationService);
    session.restore();
  }

  void _syncNotificationService() {
    if (session.authenticated && !_notificationsRunning) {
      _notificationsRunning = true;
      unawaited(notifications.start());
    } else if (!session.authenticated && _notificationsRunning) {
      _notificationsRunning = false;
      unawaited(notifications.stop(cancelBackground: true));
    }
  }

  @override
  void dispose() {
    session.removeListener(_syncNotificationService);
    unawaited(notifications.stop());
    session.dispose();
    notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: api),
      ChangeNotifierProvider.value(value: session),
      ChangeNotifierProvider.value(value: notifications),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitTrack',
      theme: AppTheme.light,
      home: const _AuthGate(),
    ),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    if (session.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.authenticated) return const LoginScreen();
    if (session.user!.passwordChangeRequired) {
      return const ChangePasswordScreen();
    }
    return const AppShell();
  }
}
