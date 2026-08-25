import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/background_notification_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotificationBackgroundWorker();
  runApp(const FitTrackBootstrap());
}
