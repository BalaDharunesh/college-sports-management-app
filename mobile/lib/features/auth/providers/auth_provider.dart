import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user_model.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Fetch user profile from /auth/me
      final response = await _apiClient.get(ApiConfig.me);
      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = UserModel.fromJson(response.data['user']);
        _status = AuthStatus.authenticated;
      } else {
        await _storageService.clearAll();
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      await _storageService.clearAll();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        _user = UserModel.fromJson(response.data['user']);

        await _storageService.saveToken(token);
        await _storageService.saveUserJson(jsonEncode(_user!.toJson()));

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Login failed.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please check backend server at ${ApiConfig.baseUrl}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
