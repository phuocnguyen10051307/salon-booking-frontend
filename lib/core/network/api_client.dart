import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000/v1',
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
