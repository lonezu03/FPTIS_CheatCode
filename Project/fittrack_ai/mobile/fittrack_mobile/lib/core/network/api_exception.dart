import 'dart:convert';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.requestId});

  final String message;
  final int? statusCode;
  final String? requestId;

  factory ApiException.fromDio(DioException error) {
    final cause = error.error;
    if (cause is ApiException) return cause;

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    var message = _messageFromPayload(data, statusCode: statusCode);
    if (message == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        message = 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối máy chủ. Hãy kiểm tra mạng rồi thử lại.';
      } else if (error.type == DioExceptionType.cancel) {
        message = 'Yêu cầu đã được hủy.';
      } else {
        message = _fallbackForStatus(statusCode);
      }
    }

    final payloadRequestId = data is Map
        ? (data['requestId'] ?? data['request_id'])?.toString()
        : null;
    final requestId =
        error.response?.headers.value('x-request-id') ?? payloadRequestId;
    return ApiException(message, statusCode: statusCode, requestId: requestId);
  }

  @override
  String toString() {
    final id = requestId;
    return id == null || id.isEmpty ? message : '$message\nMã yêu cầu: $id';
  }
}

/// Converts all errors shown by the app into a concise user-facing message.
/// Never expose a Dio response dump, request headers or an exception stack.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) return error.toString();
  if (error is DioException) return ApiException.fromDio(error).toString();

  final payloadMessage = _messageFromPayload(error);
  if (payloadMessage != null) return payloadMessage;

  if (error is FormatException) {
    final message = error.message.toString().trim();
    return message.isEmpty ? 'Dữ liệu nhận được không hợp lệ.' : message;
  }
  if (error is StateError) {
    final message = error.message.toString().trim();
    return message.isEmpty ? 'Không thể thực hiện thao tác này.' : message;
  }

  final raw = error
      .toString()
      .replaceFirst(RegExp(r'^(Exception|Error):\s*'), '')
      .trim();
  if (raw.isEmpty ||
      raw.startsWith('DioException') ||
      raw.startsWith('Response<dynamic>')) {
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
  return _normalizeServerMessage(raw);
}

String? _messageFromPayload(Object? payload, {int? statusCode}) {
  if (payload == null) return null;
  if (payload is String) {
    final value = payload.trim();
    if (value.isEmpty) return null;
    if ((value.startsWith('{') && value.endsWith('}')) ||
        (value.startsWith('[') && value.endsWith(']'))) {
      try {
        return _messageFromPayload(jsonDecode(value), statusCode: statusCode);
      } catch (_) {
        // Treat a non-JSON response as plain text below.
      }
    }
    return _normalizeServerMessage(value, statusCode: statusCode);
  }
  if (payload is Map) {
    final payloadStatus = payload['status'];
    final effectiveStatus =
        statusCode ??
        (payloadStatus is num
            ? payloadStatus.toInt()
            : int.tryParse(payloadStatus?.toString() ?? ''));
    for (final key in const ['message', 'detail', 'reason', 'title']) {
      final value = payload[key];
      final message = _messageFromPayload(value, statusCode: effectiveStatus);
      if (message != null && message.isNotEmpty) return message;
    }
    for (final key in const ['errors', 'violations']) {
      final validation = _validationMessages(payload[key]);
      if (validation.isNotEmpty) return validation.join('\n');
    }
    final errorValue = payload['error'];
    if (errorValue != null) {
      final message = _messageFromPayload(
        errorValue,
        statusCode: effectiveStatus,
      );
      if (message != null && !_isGenericHttpLabel(message)) return message;
    }
    return effectiveStatus == null ? null : _fallbackForStatus(effectiveStatus);
  }
  if (payload is Iterable) {
    final messages = payload
        .map((item) => _messageFromPayload(item, statusCode: statusCode))
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList();
    return messages.isEmpty ? null : messages.join('\n');
  }
  return null;
}

List<String> _validationMessages(Object? value) {
  if (value is Map) {
    return value.values
        .expand(_validationMessages)
        .where((message) => message.isNotEmpty)
        .toSet()
        .toList();
  }
  if (value is Iterable) {
    return value
        .expand(_validationMessages)
        .where((message) => message.isNotEmpty)
        .toSet()
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}

bool _isGenericHttpLabel(String message) {
  final value = message.trim().toLowerCase();
  return const {
    'bad request',
    'unauthorized',
    'forbidden',
    'not found',
    'conflict',
    'internal server error',
    'bad gateway',
    'service unavailable',
  }.contains(value);
}

String _normalizeServerMessage(String message, {int? statusCode}) {
  final value = message.trim();
  if (_isGenericHttpLabel(value)) return _fallbackForStatus(statusCode);
  return value;
}

String _fallbackForStatus(int? statusCode) => switch (statusCode) {
  400 => 'Dữ liệu gửi lên chưa hợp lệ. Vui lòng kiểm tra lại.',
  401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  403 => 'Bạn không có quyền thực hiện thao tác này.',
  404 => 'Không tìm thấy dữ liệu yêu cầu.',
  409 => 'Dữ liệu đã thay đổi hoặc đang được sử dụng. Hãy tải lại và thử lại.',
  413 => 'Tệp tải lên vượt quá dung lượng cho phép.',
  422 => 'Một số thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
  429 => 'Bạn thao tác quá nhanh. Vui lòng chờ một lúc rồi thử lại.',
  500 => 'Máy chủ gặp sự cố. Vui lòng thử lại sau.',
  502 || 503 || 504 => 'Dịch vụ đang tạm gián đoạn. Vui lòng thử lại sau.',
  _ => 'Không thể xử lý yêu cầu. Vui lòng thử lại.',
};
