import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
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
        final responseData = data is Map<String, dynamic> ? data['data'] : null;
        final token = responseData is Map<String, dynamic>
            ? responseData['accessToken']?.toString()
            : null;

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          ApiClient.dio.options.headers['Authorization'] = 'Bearer $token';
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
      isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      ApiClient.dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _authService.getCurrentUser(token: token);
      if (response.statusCode == 200) {
        final data = response.data;
        final responseData = data is Map<String, dynamic> ? data['data'] : null;
        final userJson = responseData is Map<String, dynamic>
            ? responseData['user']
            : data is Map<String, dynamic>
                ? data['user']
                : null;

        if (userJson is Map<String, dynamic>) {
          currentUser = UserModel.fromJson(userJson);
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      ApiClient.dio.options.headers.remove('Authorization');
      currentUser = null;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
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
    ApiClient.dio.options.headers.remove('Authorization');
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

  Future<bool> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authService.verifySignupOtp(
        email: email,
        otp: otp,
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

  Future<bool> resendSignupOtp({required String email}) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authService.resendSignupOtp(email: email);
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
