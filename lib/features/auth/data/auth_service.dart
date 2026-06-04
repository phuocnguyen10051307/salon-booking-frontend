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

  Future<Response> getCurrentUser({required String token}) async {
    return await ApiClient.dio.get(
      ApiConstants.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> logout() async {
    return await ApiClient.dio.post(ApiConstants.signout);
  }
}
