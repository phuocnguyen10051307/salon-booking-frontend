import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => _requiredUrl('API_BASE_URL');
  static String get socketBaseUrl => _requiredUrl('SOCKET_BASE_URL');

  static String _requiredUrl(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('$key must be configured in .env');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
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
  static const String stylists = '/stylists';
  static const String staffTodayBookings = '/bookings/staff/today';
  static const String chatMessages = '/chat/messages';
  static const String chatConversations = '/chat/conversations';
  static const String locations = '/locations';
  static const String locationsMap = '/locations/map';
}
