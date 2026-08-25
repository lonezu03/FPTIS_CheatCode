import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.requestId});

  final String message;
  final int? statusCode;
  final String? requestId;

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    var message = 'Không thể kết nối máy chủ. Vui lòng thử lại.';
    if (data is Map && data['message']?.toString().trim().isNotEmpty == true) {
      message = data['message'].toString();
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Không kết nối được backend tại ${error.requestOptions.baseUrl}.';
    }
    final requestId = error.response?.headers.value('x-request-id');
    return ApiException(
      message,
      statusCode: error.response?.statusCode,
      requestId: requestId,
    );
  }

  @override
  String toString() {
    final id = requestId;
    return id == null || id.isEmpty ? message : '$message\nMã yêu cầu: $id';
  }
}
