import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/auth/auth_storage_keys.dart';
import '../network/api_client.dart';
import 'native_notification_service.dart';
import 'notification_sync_service.dart';

const notificationTaskUniqueName = 'fittrack.notification.sync';
const notificationTaskName = 'syncBackendNotifications';

bool get _supportsBackgroundWork =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void>? _initialization;

Future<void> initializeNotificationBackgroundWorker() async {
  if (!_supportsBackgroundWork) return;
  _initialization ??= Workmanager().initialize(notificationCallbackDispatcher);
  try {
    await _initialization;
  } catch (_) {
    _initialization = null;
    rethrow;
  }
}

Future<void> registerNotificationBackgroundTask() async {
  if (!_supportsBackgroundWork) return;
  await initializeNotificationBackgroundWorker();
  await Workmanager().registerPeriodicTask(
    notificationTaskUniqueName,
    notificationTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

Future<void> cancelNotificationBackgroundTask() async {
  if (!_supportsBackgroundWork) return;
  await Workmanager().cancelByUniqueName(notificationTaskUniqueName);
}

@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != notificationTaskName && task != notificationTaskUniqueName) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    const storage = FlutterSecureStorage();
    final refreshToken = await storage.read(key: AuthStorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return true;

    final api = ApiClient();
    api.accessToken = await storage.read(key: AuthStorageKeys.accessToken);
    api.refreshToken = refreshToken;
    api.onSessionRefreshed = (session) async {
      await storage.write(
        key: AuthStorageKeys.accessToken,
        value: session['token']?.toString(),
      );
      final rotated = session['refreshToken']?.toString();
      if (rotated != null && rotated.isNotEmpty) {
        await storage.write(key: AuthStorageKeys.refreshToken, value: rotated);
      }
      await storage.write(
        key: AuthStorageKeys.user,
        value: jsonEncode(session),
      );
    };

    try {
      await NativeNotificationService.initialize();
      await NotificationSyncService(api, storage: storage).sync();
      return true;
    } catch (_) {
      return false;
    }
  });
}
