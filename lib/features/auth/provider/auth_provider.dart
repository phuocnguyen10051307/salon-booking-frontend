import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_service.dart';
import '../data/model/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  UserModel? currentUser;

  Future<bool> login(String identifier, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data is Map<String, dynamic>
            ? data['accessToken']?.toString()
            : null;

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          return await loadCurrentUser();
        }
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final response = await _authService.getCurrentUser(token: token);
      if (response.statusCode == 200) {
        final data = response.data;
        final userJson = data is Map<String, dynamic>
            ? (data['user'] ?? data)
            : null;

        if (userJson is Map<String, dynamic>) {
          currentUser = UserModel.fromJson(userJson);
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Ignored, cleanup locally regardless
    }

    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<bool> signup({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authService.signup(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );

      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
