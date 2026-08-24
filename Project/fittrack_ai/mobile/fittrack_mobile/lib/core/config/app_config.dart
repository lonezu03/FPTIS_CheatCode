import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _normalize(_definedBaseUrl);
    }
    if (kIsWeb) return 'http://localhost:8081/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8081/api'
        : 'http://localhost:8081/api';
  }

  static String _normalize(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }
}
