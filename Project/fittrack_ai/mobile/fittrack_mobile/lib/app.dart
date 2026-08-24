import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    api = ApiClient();
    session = AuthSession(api)..restore();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: api),
      ChangeNotifierProvider.value(value: session),
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
