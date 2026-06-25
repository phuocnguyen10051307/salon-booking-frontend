import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/v1'
      : 'http://10.0.2.2:3000/v1';

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
  static const String stylists = '/stylists';
  static const String staffTodayBookings = '/bookings/staff/today';
  static const String chatMessages = '/chat/messages';
}

