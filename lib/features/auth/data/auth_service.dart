import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  Future<Response> login({
    required String identifier,
    required String password,
  }) async {
    return await ApiClient.dio.post(
      ApiConstants.login,
      data: {'identifier': identifier, 'password': password},
    );
  }

  Future<Response> signup({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    return await ApiClient.dio.post(
      ApiConstants.signup,
      data: {
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    return await ApiClient.dio.post(
      ApiConstants.verifySignupOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<Response> resendSignupOtp({required String email}) async {
    return await ApiClient.dio.post(
      ApiConstants.resendSignupOtp,
      data: {'email': email},
    );
  }

  Future<Response> getCurrentUser({required String token}) async {
    return await ApiClient.dio.get(
      ApiConstants.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> logout() async {
    return await ApiClient.dio.post(ApiConstants.signout);
  }

  Future<Response> getProfile() async {
    return await ApiClient.dio.get(ApiConstants.userProfile);
  }

  Future<Response> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
  }) async {
    return await ApiClient.dio.put(
      ApiConstants.userProfile,
      data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
      },
    );
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiClient.dio.put(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}
