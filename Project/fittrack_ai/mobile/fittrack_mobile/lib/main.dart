import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/background_notification_worker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitTrackBootstrap());
  unawaited(_initializeBackgroundNotifications());
}

Future<void> _initializeBackgroundNotifications() async {
  try {
    await initializeNotificationBackgroundWorker();
  } catch (error, stackTrace) {
    // Background notifications are optional. A device-specific Workmanager
    // failure must never prevent the main application from opening.
    debugPrint('Unable to initialize background notifications: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
