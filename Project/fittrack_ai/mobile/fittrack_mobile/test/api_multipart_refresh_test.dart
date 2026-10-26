import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';

class _MultipartAdapter implements HttpClientAdapter {
  int previews = 0;
  final bodies = <List<int>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (stream != null) {
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
    }
    if (options.path.endsWith('/auth/refresh')) {
      return ResponseBody.fromString(
        jsonEncode({'token': 'new', 'refreshToken': 'refresh-new'}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    bodies.add(bytes);
    previews++;
    return ResponseBody.fromString(
      previews == 1 ? '{}' : '{"id":"batch"}',
      previews == 1 ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'multipart import survives auth refresh and releases tracked activity',
    () async {
      final adapter = _MultipartAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(dio: dio)
        ..accessToken = 'old'
        ..refreshToken = 'refresh';
      final response = await api.post(
        '/catalog-imports/EXERCISE/preview',
        data: FormData.fromMap({
          'mapping': '{}',
          'file': MultipartFile.fromBytes(
            utf8.encode('name\nSmith Squat'),
            filename: 'test.csv',
          ),
        }),
      );
      expect(response['id'], 'batch');
      expect(adapter.previews, 2);
      for (final bytes in adapter.bodies) {
        expect(utf8.decode(bytes), contains('Smith Squat'));
      }
      expect(api.activity.pendingRequests, 0);
      expect(api.activity.pendingMutations, 0);
      api.activity.dispose();
      dio.close();
    },
  );
}
