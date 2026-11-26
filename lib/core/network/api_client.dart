import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_response.dart';

/// Thin typed wrapper over Dio. Every call returns the parsed `data` of the backend
/// envelope or throws [ApiException] — repositories never see Dio types.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    required T Function(Object? data) parse,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) => _send(
    () => _dio.get<Object?>(
      path,
      queryParameters: query,
      options: _options(skipAuth).copyWith(headers: headers),
    ),
    parse,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
    bool skipAuth = false,
  }) => _send(() => _dio.post<Object?>(path, data: body, options: _options(skipAuth)), parse);

  Future<ApiResponse<T>> patch<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
  }) => _send(() => _dio.patch<Object?>(path, data: body), parse);

  Future<ApiResponse<T>> put<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
  }) => _send(() => _dio.put<Object?>(path, data: body), parse);

  /// For endpoints that answer 204 No Content (logout, delete).
  Future<void> sendNoContent(String method, String path, {Object? body}) async {
    try {
      await _dio.request<Object?>(path, data: body, options: Options(method: method));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Options _options(bool skipAuth) => Options(extra: {'skipAuth': skipAuth});

  Future<ApiResponse<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? data) parse,
  ) async {
    try {
      final response = await request();
      return ApiResponse<T>.fromJson(response.data, parse);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
