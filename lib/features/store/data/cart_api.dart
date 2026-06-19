import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/billing_model.dart';
import 'models/booking_model.dart';
import 'models/cart_item_model.dart';

class CartApi {
  Future<CartModel> getCart() async {
    final response = await ApiClient.dio.get(ApiConstants.cart);
    final cart = response.data['data']?['cart'] ?? response.data['cart'];
    if (cart is Map) return CartModel.fromJson(Map<String, dynamic>.from(cart));
    return CartModel.empty();
  }

  Future<CartItemModel> addCartItem({
    required String serviceId,
    int quantity = 1,
  }) async {
    final response = await ApiClient.dio.post(
      ApiConstants.cartItems,
      data: {'service_id': serviceId, 'quantity': quantity},
    );
    final item = response.data['data']?['item'] ?? response.data['item'];
    return CartItemModel.fromJson(Map<String, dynamic>.from(item as Map));
  }

  Future<CartItemModel> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await ApiClient.dio.put(
      '${ApiConstants.cartItems}/$itemId',
      data: {'quantity': quantity},
    );
    final item = response.data['data']?['item'] ?? response.data['item'];
    return CartItemModel.fromJson(Map<String, dynamic>.from(item as Map));
  }

  Future<void> deleteCartItem(String itemId) async {
    await ApiClient.dio.delete('${ApiConstants.cartItems}/$itemId');
  }

  Future<void> clearCart() async {
    await ApiClient.dio.delete(ApiConstants.cart);
  }

  Future<BookingModel> createBooking({
    required DateTime bookingDate,
    required String bookingTime,
    String? note,
  }) async {
    final response = await ApiClient.dio.post(
      ApiConstants.bookings,
      data: {
        'booking_date': _formatDate(bookingDate),
        'booking_time': bookingTime,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final booking =
        response.data['data']?['booking'] ?? response.data['booking'];
    return BookingModel.fromJson(Map<String, dynamic>.from(booking as Map));
  }

  Future<BillingModel> createBilling({
    required String bookingId,
    String paymentMethod = 'CASH',
  }) async {
    final response = await ApiClient.dio.post(
      ApiConstants.billing,
      data: {'booking_id': bookingId, 'payment_method': paymentMethod},
    );
    final billing =
        response.data['data']?['billing'] ?? response.data['billing'];
    return BillingModel.fromJson(Map<String, dynamic>.from(billing as Map));
  }

  Future<BillingModel> payBilling({
    required String billingId,
    required String paymentMethod,
  }) async {
    final response = await ApiClient.dio.patch(
      '${ApiConstants.billing}/$billingId/pay',
      data: {'payment_method': paymentMethod},
    );
    final billing =
        response.data['data']?['billing'] ?? response.data['billing'];
    return BillingModel.fromJson(Map<String, dynamic>.from(billing as Map));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
