import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/api/auth_api.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds auth/session state: current [user], JWT persistence, and
/// register/login/logout actions against [AuthApi].
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthApi authApi, required SecureStorageService secureStorage})
      : _authApi = authApi,
        _secureStorage = secureStorage;

  final AuthApi _authApi;
  final SecureStorageService _secureStorage;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool isLoading = false;
  String? errorMessage;

  Future<void> restoreSession() async {
    final token = await _secureStorage.readToken();
    final userJson = await _secureStorage.readUserJson();
    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        status = AuthStatus.authenticated;
      } catch (_) {
        status = AuthStatus.unauthenticated;
      }
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _runAuthAction(() => _authApi.register(
          email: email,
          password: password,
          fullName: fullName,
        ));
  }

  Future<bool> login({required String email, required String password}) {
    return _runAuthAction(() => _authApi.login(email: email, password: password));
  }

  Future<bool> _runAuthAction(Future<AuthResponse> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await action();
      await _secureStorage.writeToken(response.token);
      await _secureStorage.writeUserJson(jsonEncode(response.user.toJson()));
      user = response.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _secureStorage.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
