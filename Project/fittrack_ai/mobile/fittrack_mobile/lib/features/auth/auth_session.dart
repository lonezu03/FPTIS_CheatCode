import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'auth_storage_keys.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.lunchEnabled,
    required this.fitnessEnabled,
    required this.healthEnabled,
    required this.todoEnabled,
    required this.scheduleEnabled,
    required this.passwordChangeRequired,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool lunchEnabled;
  final bool fitnessEnabled;
  final bool healthEnabled;
  final bool todoEnabled;
  final bool scheduleEnabled;
  final bool passwordChangeRequired;

  bool get isAdmin => role == 'ADMIN';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['userId']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? 'Người dùng',
    role: json['role']?.toString() ?? 'USER',
    lunchEnabled: json['lunchEnabled'] == true,
    fitnessEnabled: json['fitnessEnabled'] == true,
    healthEnabled: json['healthEnabled'] == true,
    todoEnabled: json['todoEnabled'] == true,
    scheduleEnabled: json['scheduleEnabled'] == true,
    passwordChangeRequired: json['passwordChangeRequired'] == true,
  );

  Map<String, dynamic> toJson() => {
    'userId': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'lunchEnabled': lunchEnabled,
    'fitnessEnabled': fitnessEnabled,
    'healthEnabled': healthEnabled,
    'todoEnabled': todoEnabled,
    'scheduleEnabled': scheduleEnabled,
    'passwordChangeRequired': passwordChangeRequired,
  };
}

class AuthSession extends ChangeNotifier {
  AuthSession(this.api, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    api.onUnauthorized = _handleUnauthorized;
    api.onSessionRefreshed = _persistRefreshedSession;
  }

  final ApiClient api;
  final FlutterSecureStorage _storage;
  AuthUser? user;
  bool restoring = true;
  bool submitting = false;

  bool get authenticated => user != null && api.accessToken != null;

  Future<void> restore() async {
    try {
      final token = await _storage.read(key: AuthStorageKeys.accessToken);
      final refreshToken = await _storage.read(
        key: AuthStorageKeys.refreshToken,
      );
      final rawUser = await _storage.read(key: AuthStorageKeys.user);
      if (token != null && refreshToken != null && rawUser != null) {
        api.accessToken = token;
        api.refreshToken = refreshToken;
        user = AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
        try {
          await api.refreshSession();
        } on ApiException catch (error) {
          if (error.statusCode != null &&
              error.statusCode! >= 400 &&
              error.statusCode! < 500) {
            await _clear();
          }
        }
      }
    } catch (_) {
      await _clear();
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    submitting = true;
    notifyListeners();
    try {
      final data = Map<String, dynamic>.from(
        await api.post(
          '/auth/login',
          data: {'email': email.trim(), 'password': password},
        ),
      );
      await _setSession(data);
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async =>
      Map<String, dynamic>.from(
        await api.post('/auth/register', data: payload),
      );

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final data = Map<String, dynamic>.from(
      await api.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      ),
    );
    await _setSession(data);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', data: {'refreshToken': api.refreshToken});
    } catch (_) {
      // Xóa phiên cục bộ kể cả khi backend đang ngủ hoặc mất mạng.
    }
    await _clear();
    notifyListeners();
  }

  Future<void> _setSession(Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Backend không trả access token.');
    }
    api.accessToken = token;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      api.refreshToken = refreshToken;
    }
    user = AuthUser.fromJson(data);
    await _storage.write(key: AuthStorageKeys.accessToken, value: token);
    if (api.refreshToken != null) {
      await _storage.write(
        key: AuthStorageKeys.refreshToken,
        value: api.refreshToken,
      );
    }
    await _storage.write(
      key: AuthStorageKeys.user,
      value: jsonEncode(user!.toJson()),
    );
  }

  Future<void> _persistRefreshedSession(Map<String, dynamic> data) async {
    await _setSession(data);
    notifyListeners();
  }

  Future<void> _clear() async {
    api.accessToken = null;
    api.refreshToken = null;
    user = null;
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
    await _storage.delete(key: AuthStorageKeys.user);
  }

  void _handleUnauthorized() {
    if (!authenticated) return;
    _clear().then((_) => notifyListeners());
  }
}
