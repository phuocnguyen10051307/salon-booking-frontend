import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppUrlConfig {
  static String resolve({
    required String key,
    required String dartDefine,
    required Map<String, String> environment,
    required bool isRelease,
    required bool isAndroid,
    required bool isSocket,
  }) {
    final definedValue = dartDefine.trim();
    if (definedValue.isNotEmpty) {
      return validate(
        definedValue,
        key: key,
        isRelease: isRelease,
        isSocket: isSocket,
      );
    }

    if (isRelease) {
      throw StateError(
        '$key must be supplied with --dart-define for release builds',
      );
    }

    final platformKey = '${key}_${isAndroid ? 'ANDROID' : 'WEB'}';
    final platformValue = environment[platformKey]?.trim() ?? '';
    final value = platformValue.isNotEmpty
        ? platformValue
        : environment[key]?.trim() ?? '';
    if (value.isEmpty) {
      throw StateError('$key must be configured in .env or --dart-define');
    }
    return validate(value, key: key, isRelease: false, isSocket: isSocket);
  }

  static String validate(
    String value, {
    required String key,
    required bool isRelease,
    required bool isSocket,
  }) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError('$key is not a valid HTTP(S) URL');
    }
    if (isRelease && uri.scheme.toLowerCase() != 'https') {
      throw StateError('$key must use HTTPS in release builds');
    }
    if (isRelease && _isLocalHost(uri.host)) {
      throw StateError('$key cannot use a local address in release builds');
    }
    if (isSocket && uri.path.isNotEmpty && uri.path != '/') {
      throw StateError(
        '$key must contain only the server origin; do not include API paths, '
        '/socket.io, or a namespace',
      );
    }
    return normalized;
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    if (const {
      'localhost',
      '0.0.0.0',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    }.contains(normalized)) {
      return true;
    }
    if (normalized.startsWith('127.') ||
        normalized.startsWith('fc') ||
        normalized.startsWith('fd') ||
        normalized.startsWith('fe80:')) {
      return true;
    }

    final parts = normalized.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 169 && second == 254) ||
        (first == 100 && second >= 64 && second <= 127);
  }
}

class ApiConstants {
  static const _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _definedSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
  );

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String get baseUrl => AppUrlConfig.resolve(
    key: 'API_BASE_URL',
    dartDefine: _definedApiBaseUrl,
    environment: dotenv.env,
    isRelease: kReleaseMode,
    isAndroid: _isAndroid,
    isSocket: false,
  );

  static String get socketBaseUrl => AppUrlConfig.resolve(
    key: 'SOCKET_BASE_URL',
    dartDefine: _definedSocketBaseUrl,
    environment: dotenv.env,
    isRelease: kReleaseMode,
    isAndroid: _isAndroid,
    isSocket: true,
  );

  static void validateAndLog() {
    final resolvedApiUrl = baseUrl;
    final resolvedSocketUrl = socketBaseUrl;
    final mode = kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug';
    debugPrint('[Config] buildMode=$mode');
    debugPrint('[Config] API_BASE_URL=$resolvedApiUrl');
    debugPrint('[Config] SOCKET_BASE_URL=$resolvedSocketUrl');
    debugPrint('[Config] SOCKET_PATH=/socket.io namespace=/');
  }

  static const String login = '/auth/signin';
  static const String signup = '/auth/signup';
  static const String verifySignupOtp = '/auth/verify-signup-otp';
  static const String resendSignupOtp = '/auth/resend-signup-otp';
  static const String me = '/auth/me';
  static const String signout = '/auth/signout';
  static const String userProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static const String services = '/services';
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String bookings = '/bookings';
  static const String bookingsCheckout = '/bookings/checkout';
  static const String billing = '/billing';
  static const String reviews = '/reviews';
  static const String promotions = '/promotions';
  static const String activePromotions = '$promotions/active';
  static const String stylists = '/stylists';
  static const String staffTodayBookings = '/bookings/staff/today';
  static const String chatConversations = '/chat/conversations';
  static const String locations = '/locations';
  static const String locationsMap = '/locations/map';
}
