import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

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
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  @override
  String toString() => message;
}
