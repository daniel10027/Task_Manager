import 'package:dio/dio.dart';

import '../../models/user.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password, 'fullName': fullName},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}
