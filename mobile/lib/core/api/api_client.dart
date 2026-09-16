import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// `--dart-define=API_BASE_URL=...` overrides the platform-aware default.
const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

String resolveApiBaseUrl() {
  if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

/// Builds the shared [Dio] instance used by every API service: attaches the
/// bearer token from secure storage to every request, and maps error
/// responses into [ApiException] carrying CONTRACT.md's `message` field.
Dio createApiClient({
  required SecureStorageService secureStorage,
  String? baseUrl,
  Dio? dio,
}) {
  final client =
      dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl ?? resolveApiBaseUrl(),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  client.interceptors.addAll([
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
    InterceptorsWrapper(
      onError: (DioException err, handler) {
        handler.reject(_mapError(err));
      },
    ),
  ]);

  return client;
}

DioException _mapError(DioException err) {
  final data = err.response?.data;
  String message = 'Une erreur réseau est survenue.';
  if (data is Map && data['message'] is String) {
    message = data['message'] as String;
  } else if (err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.connectionError) {
    message = 'Impossible de contacter le serveur.';
  } else if (err.message != null) {
    message = err.message!;
  }
  final apiException = ApiException(
    message,
    statusCode: err.response?.statusCode,
    path: data is Map ? data['path'] as String? : null,
  );
  return err.copyWith(error: apiException);
}

/// Extracts the [ApiException] set by the client's error interceptor,
/// falling back to a generic network exception for anything unexpected
/// (e.g. the request never reached the interceptor at all).
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return const ApiException('Une erreur inattendue est survenue.');
}
