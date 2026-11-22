import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Called by the auth interceptor on 401. Overridden in main.dart's ProviderScope to sign
/// the user out, so core/ never imports features/.
final unauthorizedHandlerProvider = Provider<void Function()>((ref) => () {});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      onUnauthorized: () => ref.read(unauthorizedHandlerProvider)(),
    ),
  );

  if (kDebugMode) {
    // Never logs headers, so the Authorization token stays out of logs.
    dio.interceptors.add(
      LogInterceptor(requestHeader: false, responseHeader: false, requestBody: false),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
