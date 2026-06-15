import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: kIsWeb ? 'http://localhost:3000/v1' : 'http://10.0.2.2:3000/v1',
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
