import 'package:dio/dio.dart';

/// Normalized API error, built from the backend's error envelope:
/// `{ success: false, statusCode, code, message, errors?, requestId? }`.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
    this.requestId,
  });

  static const _networkErrorTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  factory ApiException.fromDioException(DioException error) {
    if (_networkErrorTypes.contains(error.type)) {
      return const ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'সার্ভারের সাথে সংযোগ করা যাচ্ছে না। ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      );
    }
    if (error.type == DioExceptionType.cancel) {
      return const ApiException(statusCode: 0, code: 'CANCELLED', message: 'অনুরোধ বাতিল হয়েছে।');
    }

    final status = error.response?.statusCode ?? 0;
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      return ApiException(
        statusCode: (body['statusCode'] as int?) ?? status,
        code: (body['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (body['message'] as String?) ?? 'অপ্রত্যাশিত একটি সমস্যা হয়েছে।',
        fieldErrors: _parseFieldErrors(body['errors']),
        requestId: body['requestId'] as String?,
      );
    }
    return ApiException(
      statusCode: status,
      code: 'UNKNOWN_ERROR',
      message: 'অপ্রত্যাশিত একটি সমস্যা হয়েছে।',
    );
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    return raw.map(
      (field, messages) => MapEntry(
        field,
        messages is List ? messages.map((message) => message.toString()).toList() : <String>[],
      ),
    );
  }

  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> fieldErrors;
  final String? requestId;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => code == 'NETWORK_ERROR';

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
