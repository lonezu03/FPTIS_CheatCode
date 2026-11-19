import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_activity_controller.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio, ApiActivityController? activity})
    : activity = activity ?? ApiActivityController(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              headers: const {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
                'X-FitTrack-Client': 'mobile',
              },
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (options.path.contains('/journal') &&
              !options.path.endsWith('/journal/lock/status') &&
              !options.path.endsWith('/journal/lock/unlock') &&
              journalUnlockToken?.isNotEmpty == true) {
            options.headers['X-Journal-Unlock'] = journalUnlockToken;
          }
          final duplicateError = _startTracking(options);
          if (duplicateError != null) {
            handler.reject(duplicateError);
            return;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _finishTracking(response.requestOptions);
          handler.next(response);
        },
        onError: (error, handler) async {
          if (!_shouldRefresh(error)) {
            _finishTracking(error.requestOptions);
            // Lỗi của chính request gia hạn do refreshSession() tự phân loại.
            if (error.response?.statusCode == 401 &&
                error.requestOptions.extra[_skipRefreshKey] != true) {
              onUnauthorized?.call();
            }
            handler.next(error);
            return;
          }

          final cancellation = error.requestOptions.cancelToken;
          final outcome = await Future.any<Object?>([
            _refreshAfterUnauthorized(_bearerOf(error.requestOptions)),
            if (cancellation != null) cancellation.whenCancel.then((_) => null),
          ]);
          if (outcome == null || cancellation?.isCancelled == true) {
            _finishTracking(error.requestOptions);
            handler.next(cancellation!.cancelError!);
            return;
          }
          if (outcome is SessionRefreshException) {
            _finishTracking(error.requestOptions);
            if (outcome.sessionInvalid) {
              onUnauthorized?.call();
              handler.next(error);
            } else {
              // Máy chủ tạm không gia hạn được phiên (khởi động lại, 5xx, 429,
              // mất mạng): giữ đăng nhập, chỉ báo lỗi cho thao tác hiện tại.
              handler.next(
                error.copyWith(error: outcome, message: outcome.message),
              );
            }
            return;
          }

          try {
            final request = error.requestOptions;
            request.headers['Authorization'] = 'Bearer $accessToken';
            request.extra[_retriedKey] = true;
            // Multipart bodies were finalized by the failed send. Recreate the
            // stream while retaining this same tracked operation/mutation guard.
            if (request.data is FormData) {
              request.data = (request.data as FormData).clone();
            }
            handler.resolve(await this.dio.fetch(request));
          } on DioException {
            _finishTracking(error.requestOptions);
            handler.next(error);
          }
        },
      ),
    );
  }

  static const _skipRefreshKey = 'skipAuthRefresh';
  static const _retriedKey = 'authRetried';
  static const _trackingKey = 'fitTrackRequestTracking';

  final Dio dio;
  final ApiActivityController activity;
  final ApiMutationGuard _mutationGuard = ApiMutationGuard();
  String? accessToken;
  String? refreshToken;
  String? journalUnlockToken;
  void Function()? onUnauthorized;
  Future<void> Function(Map<String, dynamic> session)? onSessionRefreshed;

  /// Đọc refresh token đang lưu trong máy. Tác vụ nền đồng bộ thông báo chạy ở
  /// isolate khác và có thể đã xoay vòng token; dùng lại token cũ sẽ bị 401.
  Future<String?> Function()? readStoredRefreshToken;

  /// Thời gian chờ giữa các lần thử lại khi gia hạn phiên gặp lỗi tạm thời.
  List<Duration> refreshRetryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  Future<void> Function(Duration delay) sleep = Future<void>.delayed;
  Future<Map<String, dynamic>>? _refreshing;

  DioException? _startTracking(RequestOptions options) {
    if (options.extra[_trackingKey] is _ApiRequestTracking) return null;

    final isMutation = _isMutation(options.method);
    final releaseMutation = isMutation
        ? _mutationGuard.acquire(_mutationKey(options))
        : null;
    if (isMutation && releaseMutation == null) {
      return DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        message: duplicateMutationMessage,
        error: const ApiException(duplicateMutationMessage),
      );
    }

    final finishActivity = activity.begin(isMutation: isMutation);
    options.extra[_trackingKey] = _ApiRequestTracking(() {
      releaseMutation?.call();
      finishActivity();
    });
    return null;
  }

  void _finishTracking(RequestOptions options) {
    final tracking = options.extra[_trackingKey];
    if (tracking is _ApiRequestTracking) tracking.finish();
  }

  bool _isMutation(String method) => const <String>{
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  }.contains(method.toUpperCase());

  String _mutationKey(RequestOptions options) => <String>[
    options.method.toUpperCase(),
    options.baseUrl,
    options.path,
    _stableEncode(options.queryParameters),
    _stableEncode(options.data),
  ].join(':');

  String _stableEncode(Object? value) {
    try {
      if (value is FormData) {
        final fields =
            value.fields
                .map((entry) => <String>[entry.key, entry.value])
                .toList()
              ..sort((left, right) => left.first.compareTo(right.first));
        final files =
            value.files
                .map(
                  (entry) => <Object?>[
                    entry.key,
                    entry.value.filename,
                    entry.value.length,
                    entry.value.contentType?.toString(),
                  ],
                )
                .toList()
              ..sort(
                (left, right) => '${left.first}'.compareTo('${right.first}'),
              );
        return jsonEncode(<String, Object?>{'fields': fields, 'files': files});
      }
      return jsonEncode(_canonicalize(value));
    } catch (_) {
      return value?.toString() ?? '';
    }
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is Iterable) return value.map(_canonicalize).toList();
    return value;
  }

  bool _shouldRefresh(DioException error) {
    final request = error.requestOptions;
    return error.response?.statusCode == 401 &&
        refreshToken?.isNotEmpty == true &&
        request.extra[_skipRefreshKey] != true &&
        request.extra[_retriedKey] != true &&
        !request.path.endsWith('/auth/refresh') &&
        !request.path.endsWith('/auth/login');
  }

  String? _bearerOf(RequestOptions request) {
    final header = request.headers['Authorization']?.toString();
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }

  /// `true` khi đã có access token dùng được, hoặc lỗi gia hạn phiên.
  Future<Object> _refreshAfterUnauthorized(String? failedToken) async {
    final current = accessToken;
    // Một request khác đã gia hạn xong trong lúc request này đang chạy.
    if (current != null && current.isNotEmpty && current != failedToken) {
      return true;
    }
    try {
      await refreshSession();
      return true;
    } on SessionRefreshException catch (error) {
      return error;
    } catch (error) {
      return SessionRefreshException(
        friendlyErrorMessage(error),
        sessionInvalid: false,
      );
    }
  }

  /// Gia hạn phiên. Các lời gọi đồng thời dùng chung một request; lỗi tạm
  /// thời được thử lại, chỉ 400/401/403 mới coi là phiên không còn hợp lệ.
  Future<Map<String, dynamic>> refreshSession() => _refreshing ??=
      _refreshWithRetry().whenComplete(() => _refreshing = null);

  Future<Map<String, dynamic>> _refreshWithRetry() async {
    var adoptedRotation = false;
    for (var attempt = 0; ; attempt++) {
      await _adoptStoredRefreshToken();
      final sent = refreshToken;
      if (sent == null || sent.isEmpty) {
        throw const SessionRefreshException(
          'Phiên đăng nhập không tồn tại.',
          sessionInvalid: true,
        );
      }
      try {
        return await _postRefresh(sent);
      } on DioException catch (error) {
        final failure = ApiException.fromDio(error);
        if (isInvalidSessionStatus(error.response?.statusCode)) {
          // Tác vụ nền có thể vừa xoay token trong lúc request này đang chạy.
          if (!adoptedRotation &&
              await _adoptStoredRefreshToken(different: sent)) {
            adoptedRotation = true;
            continue;
          }
          throw SessionRefreshException(
            failure.message,
            statusCode: failure.statusCode,
            requestId: failure.requestId,
            sessionInvalid: true,
          );
        }
        if (error.type == DioExceptionType.cancel ||
            attempt >= refreshRetryDelays.length) {
          throw SessionRefreshException(
            'Chưa kết nối được máy chủ để gia hạn phiên. ${failure.message}',
            statusCode: failure.statusCode,
            requestId: failure.requestId,
            sessionInvalid: false,
          );
        }
        await sleep(_retryDelay(error, attempt));
      }
    }
  }

  Duration _retryDelay(DioException error, int attempt) {
    final retryAfter = int.tryParse(
      error.response?.headers.value('retry-after') ?? '',
    );
    if (error.response?.statusCode == 429 && retryAfter != null) {
      return Duration(seconds: retryAfter.clamp(1, 10));
    }
    return refreshRetryDelays[attempt];
  }

  /// Nhận refresh token đang lưu trong máy nếu nó khác [different] (mặc định
  /// là token đang dùng). Trả về `true` khi đã đổi sang token đó.
  Future<bool> _adoptStoredRefreshToken({String? different}) async {
    final reader = readStoredRefreshToken;
    if (reader == null) return false;
    String? stored;
    try {
      stored = await reader();
    } catch (_) {
      return false;
    }
    if (stored == null ||
        stored.isEmpty ||
        stored == (different ?? refreshToken)) {
      return false;
    }
    refreshToken = stored;
    return true;
  }

  Future<Map<String, dynamic>> _postRefresh(String token) async {
    final response = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': token},
      options: Options(extra: {_skipRefreshKey: true}),
    );
    final session = Map<String, dynamic>.from(response.data as Map);
    final nextAccessToken = session['token']?.toString();
    final nextRefreshToken = session['refreshToken']?.toString();
    if (nextAccessToken == null || nextAccessToken.isEmpty) {
      throw const SessionRefreshException(
        'Backend không trả access token mới.',
        sessionInvalid: false,
      );
    }
    accessToken = nextAccessToken;
    if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
      refreshToken = nextRefreshToken;
    }
    await onSessionRefreshed?.call(session);
    return session;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return (await dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      )).data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      return (await dio.post(path, data: data ?? <String, dynamic>{})).data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<dynamic> put(String path, {Object? data}) async {
    try {
      return (await dio.put(path, data: data)).data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    try {
      return (await dio.patch(path, data: data)).data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String path, {Object? data}) async {
    try {
      await dio.delete(path, data: data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

class _ApiRequestTracking {
  _ApiRequestTracking(this._onFinish);

  final void Function() _onFinish;
  bool _finished = false;

  void finish() {
    if (_finished) return;
    _finished = true;
    _onFinish();
  }
}
