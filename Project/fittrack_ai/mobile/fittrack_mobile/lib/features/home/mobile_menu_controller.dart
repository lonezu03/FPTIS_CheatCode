import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_session.dart';

const mobileModuleLabels = <String, String>{
  'dashboard': 'Tổng quan',
  'lunch': 'Đặt cơm',
  'fitness': 'Luyện tập',
  'health': 'Sức khỏe',
  'planner': 'Lịch & việc',
  'quotes': 'Câu nói',
  'finance': 'Tài chính',
  'journal': 'Nhật ký',
  'assistant': 'AnCai PT',
  'workoutPlans': 'Giáo án',
  'exercises': 'Kho bài tập',
  'foods': 'Kho thực phẩm',
  'nutrition': 'Nhật ký ăn uống',
};

const mobileMenuCacheKey = 'fittrack_mobile_menu';

class MobileMenuController extends ChangeNotifier {
  MobileMenuController(
    this.api, {
    this.readCache,
    this.writeCache,
    this.retryDelays = const [Duration(seconds: 2), Duration(seconds: 5)],
  });
  final ApiClient api;

  /// Đọc/ghi cấu hình menu tải thành công gần nhất. Khi máy chủ chưa phản hồi
  /// (khởi động lại, mất mạng) app vẫn hiện menu cũ thay vì thanh điều hướng
  /// trống.
  final Future<String?> Function()? readCache;
  final Future<void> Function(String value)? writeCache;
  final List<Duration> retryDelays;
  List<Map<String, dynamic>> modules = [];
  int version = 0;
  bool loading = false, loaded = false;
  Object? error;
  bool _disposed = false;
  Future<void>? _pending;

  Future<void> load() {
    if (_disposed) return Future.value();
    return _pending ??= _load().whenComplete(() => _pending = null);
  }

  void accept(dynamic raw) {
    final parsed = parseMenu(raw);
    final nextVersion = (raw['version'] as num).toInt();
    if (_disposed || (loaded && nextVersion < version)) return;
    modules = parsed;
    version = nextVersion;
    loaded = true;
    error = null;
    notifyListeners();
    final write = writeCache;
    if (write != null) {
      write(
        jsonEncode({'version': nextVersion, 'modules': parsed}),
      ).catchError((Object _) {});
    }
  }

  Future<void> _restoreCached() async {
    final read = readCache;
    if (read == null || loaded) return;
    try {
      final raw = await read();
      if (raw == null || raw.isEmpty || loaded || _disposed) return;
      final cached = jsonDecode(raw);
      modules = parseMenu(cached);
      version = (cached['version'] as num).toInt();
      // `loaded` vẫn là false để bản mới từ máy chủ luôn được nhận.
    } catch (_) {
      // Bộ nhớ đệm hỏng hoặc không đọc được: bỏ qua, chờ máy chủ.
    }
  }

  static bool _isTransient(Object error) {
    if (error is! ApiException) return false;
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _restoreCached();
      if (!_disposed && modules.isNotEmpty) notifyListeners();
      for (var attempt = 0; ; attempt++) {
        try {
          accept(await api.get('/mobile-menu'));
          break;
        } catch (e) {
          if (_disposed) return;
          if (attempt >= retryDelays.length || !_isTransient(e)) {
            error = e;
            break;
          }
          await Future<void>.delayed(retryDelays[attempt]);
          if (_disposed) return;
        }
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  static List<Map<String, dynamic>> parseMenu(dynamic raw) {
    if (raw is! Map || raw['version'] is! num || raw['modules'] is! List) {
      throw const FormatException('Cấu hình menu không hợp lệ.');
    }
    final rows = (raw['modules'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final keys = rows.map((e) => e['key']).toSet();
    if (rows.length != mobileModuleLabels.length ||
        keys.length != rows.length ||
        !keys.containsAll(mobileModuleLabels.keys) ||
        rows.any((e) => e['visible'] is! bool)) {
      throw const FormatException('Danh sách module không hợp lệ.');
    }
    return rows;
  }

  bool allows(String key, AuthUser user) =>
      modules.any((e) => e['key'] == key && e['visible'] == true) &&
      permitted(key, user);
  static bool permitted(String key, AuthUser user) {
    if (user.isAdmin) return mobileModuleLabels.containsKey(key);
    return switch (key) {
      'dashboard' => true,
      'lunch' => user.lunchEnabled,
      'fitness' || 'workoutPlans' || 'exercises' => user.fitnessEnabled,
      'health' || 'foods' || 'nutrition' => user.healthEnabled,
      'planner' => user.todoEnabled || user.scheduleEnabled,
      'quotes' => user.quoteEnabled,
      'finance' => user.financeEnabled,
      'journal' => user.journalEnabled,
      'assistant' => user.chatbotEnabled,
      _ => false,
    };
  }

  int order(String key) => modules.indexWhere((e) => e['key'] == key);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
