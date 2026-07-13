import 'booking_service_item_model.dart';
import 'review_model.dart';

class BookingModel {
  final String id;
  final String code;
  final double totalAmount;
  final String? status;
  final String? bookingDate;
  final String? bookingTime;
  final String? customerName;
  final String? stylistName;
  final List<String> serviceNames;
  final List<BookingServiceItemModel> serviceItems;
  final List<ReviewModel> reviews;
  final String? billingId;
  final String? billingStatus;
  final String? paymentMethod;

  const BookingModel({
    required this.id,
    required this.code,
    required this.totalAmount,
    this.status,
    this.bookingDate,
    this.bookingTime,
    this.customerName,
    this.stylistName,
    this.serviceNames = const [],
    this.serviceItems = const [],
    this.reviews = const [],
    this.billingId,
    this.billingStatus,
    this.paymentMethod,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    final stylist = json['stylists'];
    final items = json['booking_items'];
    final billing = json['billings'];
    final serviceItems = items is List
        ? items
            .whereType<Map>()
            .map((item) => BookingServiceItemModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.serviceId.isNotEmpty)
            .toList()
        : const <BookingServiceItemModel>[];
    final reviewsRaw = json['service_reviews'];
    final reviews = reviewsRaw is List
        ? reviewsRaw
            .whereType<Map>()
            .map((item) => ReviewModel.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : const <ReviewModel>[];

    return BookingModel(
      id: json['booking_id']?.toString() ?? '',
      code: json['booking_code']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
      bookingDate: json['booking_date']?.toString(),
      bookingTime: json['booking_time']?.toString(),
      customerName: user is Map ? user['full_name']?.toString() : null,
      stylistName: stylist is Map ? stylist['full_name']?.toString() : null,
      serviceNames: serviceItems.map((item) => item.serviceName).where((name) => name.isNotEmpty).toList(),
      serviceItems: serviceItems,
      reviews: reviews,
      billingId: billing is Map ? billing['billing_id']?.toString() : null,
      billingStatus: billing is Map ? billing['status']?.toString() : null,
      paymentMethod: billing is Map ? billing['payment_method']?.toString() : null,
    );
  }
}
