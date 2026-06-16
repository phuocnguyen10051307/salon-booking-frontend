import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = kIsWeb ? 'http://localhost:3000/v1' : 'http://10.0.2.2:3000/v1';

  static const String login = '/auth/signin';
  static const String signup = '/auth/signup';
  static const String me = '/auth/me';
  static const String signout = '/auth/signout';
  static const String services = '/services';
}
