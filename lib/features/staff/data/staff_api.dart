import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../store/data/models/booking_model.dart';
import 'staff_payment_response.dart';

class StaffApi {
  Future<List<BookingModel>> getBookingsForDate({DateTime? date}) async {
    final response = await ApiClient.dio.get(
      ApiConstants.staffTodayBookings,
      queryParameters: date == null
          ? null
          : {
              'date': DateFormat('yyyy-MM-dd').format(date),
            },
    );

    final bookings = response.data['data']?['bookings'] ?? response.data['bookings'];
    if (bookings is! List) return [];
    return bookings
        .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<StaffPaymentResponse> collectBookingPayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    final response = await ApiClient.dio.patch(
      '${ApiConstants.billing}/booking/$bookingId/pay',
      data: {'payment_method': paymentMethod},
    );
    final payload = response.data['data'] ?? response.data;
    return StaffPaymentResponse.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<StaffPaymentResponse> confirmBookingTransferPayment({required String bookingId}) async {
    final response = await ApiClient.dio.patch(
      '${ApiConstants.billing}/booking/$bookingId/pay/confirm',
      data: {'payment_method': 'BANK_TRANSFER'},
    );
    final payload = response.data['data'] ?? response.data;
    return StaffPaymentResponse.fromJson(Map<String, dynamic>.from(payload as Map));
  }
}
