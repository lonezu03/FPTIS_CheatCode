import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/core/network/api_exception.dart';
import 'package:fittrack_mobile/features/home/mobile_menu_controller.dart';

ResponseBody _json(Object body, int status, {Map<String, String>? headers}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final entry in (headers ?? const {}).entries)
          entry.key: [entry.value],
      },
    );

/// `/todos` trả 401 với access token cũ; `/auth/refresh` trả theo [refresh].
class _Adapter implements HttpClientAdapter {
  _Adapter(this.refresh);

  final ResponseBody Function(String refreshToken, int call) refresh;
  final sentRefreshTokens = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/refresh')) {
      final token = (options.data as Map)['refreshToken'] as String;
      sentRefreshTokens.add(token);
      return refresh(token, sentRefreshTokens.length);
    }
    final ok = options.headers['Authorization'] == 'Bearer new';
    return ok ? _json({'ok': true}, 200) : _json({}, 401);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _session(String refreshToken) =>
    _json({'token': 'new', 'refreshToken': refreshToken}, 200);

({ApiClient api, List<Duration> sleeps, List<bool> unauthorized}) _client(
  _Adapter adapter, {
  Future<String?> Function()? stored,
}) {
  final sleeps = <Duration>[];
  final unauthorized = <bool>[];
  final api =
      ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
            ..httpClientAdapter = adapter,
        )
        ..accessToken = 'old'
        ..refreshToken = 'refresh-old'
        ..readStoredRefreshToken = stored
        ..sleep = (delay) async {
          sleeps.add(delay);
        }
        ..onUnauthorized = () => unauthorized.add(true);
  return (api: api, sleeps: sleeps, unauthorized: unauthorized);
}

void main() {
  test('transient refresh failures are retried and the request succeeds', () async {
    final adapter = _Adapter(
      (token, call) => call < 3 ? _json({}, 503) : _session('refresh-new'),
    );
    final c = _client(adapter);
    expect(await c.api.get('/todos'), {'ok': true});
    expect(adapter.sentRefreshTokens, hasLength(3));
    expect(c.sleeps, const [Duration(seconds: 1), Duration(seconds: 3)]);
    expect(c.unauthorized, isEmpty);
    expect(c.api.refreshToken, 'refresh-new');
  });

  test('server still unavailable keeps the session and reports the error', () async {
    final adapter = _Adapter((token, call) => _json({}, 503));
    final c = _client(adapter);
    final error = await c.api.get('/todos').then<Object?>((_) => null, onError: (Object e) => e);
    expect(error, isA<SessionRefreshException>());
    expect((error as SessionRefreshException).sessionInvalid, isFalse);
    expect(c.unauthorized, isEmpty);
    expect(c.api.accessToken, 'old');
    expect(c.api.refreshToken, 'refresh-old');
  });

  test('rate limit honours Retry-After capped at 10 seconds', () async {
    final adapter = _Adapter(
      (token, call) => call == 1
          ? _json({}, 429, headers: {'retry-after': '60'})
          : _session('refresh-new'),
    );
    final c = _client(adapter);
    await c.api.get('/todos');
    expect(c.sleeps, const [Duration(seconds: 10)]);
    expect(c.unauthorized, isEmpty);
  });

  test('rejected refresh token logs out once without retrying', () async {
    final adapter = _Adapter((token, call) => _json({}, 401));
    final c = _client(adapter);
    await expectLater(c.api.get('/todos'), throwsA(isA<ApiException>()));
    expect(adapter.sentRefreshTokens, ['refresh-old']);
    expect(c.unauthorized, [true]);
  });

  test('uses a token already rotated by the background worker', () async {
    final adapter = _Adapter(
      (token, call) =>
          token == 'refresh-bg' ? _session('refresh-new') : _json({}, 401),
    );
    final c = _client(adapter, stored: () async => 'refresh-bg');
    expect(await c.api.get('/todos'), {'ok': true});
    expect(adapter.sentRefreshTokens, ['refresh-bg']);
    expect(c.unauthorized, isEmpty);
  });

  test('recovers when the background worker rotates during the refresh', () async {
    var reads = 0;
    final adapter = _Adapter(
      (token, call) =>
          token == 'refresh-bg' ? _session('refresh-new') : _json({}, 401),
    );
    final c = _client(
      adapter,
      stored: () async => ++reads == 1 ? 'refresh-old' : 'refresh-bg',
    );
    expect(await c.api.get('/todos'), {'ok': true});
    expect(adapter.sentRefreshTokens, ['refresh-old', 'refresh-bg']);
    expect(c.unauthorized, isEmpty);
  });

  test('concurrent 401s share one refresh request', () async {
    final adapter = _Adapter((token, call) => _session('refresh-new'));
    final c = _client(adapter);
    final results = await Future.wait([c.api.get('/todos'), c.api.get('/todos')]);
    expect(results, [
      {'ok': true},
      {'ok': true},
    ]);
    expect(adapter.sentRefreshTokens, hasLength(1));
  });

  test('isInvalidSessionStatus only accepts 400/401/403', () {
    expect([400, 401, 403].every(isInvalidSessionStatus), isTrue);
    expect([null, 404, 408, 429, 500, 503].any(isInvalidSessionStatus), isFalse);
  });

  group('MobileMenuController', () {
    Map<String, dynamic> menu(int version) => {
      'version': version,
      'modules': mobileModuleLabels.keys
          .map((key) => {'key': key, 'visible': true})
          .toList(),
    };

    test('retries a transient failure before showing an error', () async {
      var calls = 0;
      final api = _MenuApi(() {
        if (++calls == 1) throw const ApiException('Tạm lỗi', statusCode: 503);
        return menu(4);
      });
      final controller = MobileMenuController(api, retryDelays: const [Duration.zero]);
      await controller.load();
      expect(calls, 2);
      expect(controller.error, isNull);
      expect(controller.version, 4);
    });

    test('keeps the cached menu when the server is unreachable', () async {
      String? cache = jsonEncode(menu(7));
      final api = _MenuApi(() => throw const ApiException('Mất mạng'));
      final controller = MobileMenuController(
        api,
        readCache: () async => cache,
        writeCache: (value) async => cache = value,
        retryDelays: const [Duration.zero],
      );
      await controller.load();
      expect(controller.modules, hasLength(mobileModuleLabels.length));
      expect(controller.version, 7);
      expect(controller.error, isA<ApiException>());
    });

    test('stores the latest menu for the next start', () async {
      String? cache;
      final controller = MobileMenuController(
        _MenuApi(() => menu(9)),
        readCache: () async => cache,
        writeCache: (value) async => cache = value,
      );
      await controller.load();
      await Future<void>.delayed(Duration.zero);
      expect((jsonDecode(cache!) as Map)['version'], 9);
    });
  });
}

class _MenuApi extends ApiClient {
  _MenuApi(this.handler);
  final Object Function() handler;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async => handler();
}
