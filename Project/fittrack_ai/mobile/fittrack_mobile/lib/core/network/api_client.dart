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
            if (error.response?.statusCode == 401) {
              onUnauthorized?.call();
            }
            handler.next(error);
            return;
          }

          final refreshed = await _refreshAfterUnauthorized();
          if (!refreshed) {
            _finishTracking(error.requestOptions);
            onUnauthorized?.call();
            handler.next(error);
            return;
          }

          try {
            final request = error.requestOptions;
            request.headers['Authorization'] = 'Bearer $accessToken';
            request.extra[_retriedKey] = true;
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
  void Function()? onUnauthorized;
  Future<void> Function(Map<String, dynamic> session)? onSessionRefreshed;
  Future<bool>? _refreshing;

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

  Future<bool> _refreshAfterUnauthorized() {
    final running = _refreshing;
    if (running != null) return running;
    final future = _performRefresh().whenComplete(() => _refreshing = null);
    _refreshing = future;
    return future;
  }

  Future<bool> _performRefresh() async {
    try {
      await refreshSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> refreshSession() async {
    final currentRefreshToken = refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw const ApiException('Phiên đăng nhập không tồn tại.');
    }
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
        options: Options(extra: {_skipRefreshKey: true}),
      );
      final session = Map<String, dynamic>.from(response.data as Map);
      final nextAccessToken = session['token']?.toString();
      final nextRefreshToken = session['refreshToken']?.toString();
      if (nextAccessToken == null || nextAccessToken.isEmpty) {
        throw const ApiException('Backend không trả access token mới.');
      }
      accessToken = nextAccessToken;
      if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
        refreshToken = nextRefreshToken;
      }
      await onSessionRefreshed?.call(session);
      return session;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return (await dio.get(path, queryParameters: queryParameters)).data;
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
