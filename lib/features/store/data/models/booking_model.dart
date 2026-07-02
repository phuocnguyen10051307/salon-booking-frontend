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
    this.billingId,
    this.billingStatus,
    this.paymentMethod,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    final stylist = json['stylists'];
    final items = json['booking_items'];
    final billing = json['billings'];
    return BookingModel(
      id: json['booking_id']?.toString() ?? '',
      code: json['booking_code']?.toString() ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
      bookingDate: json['booking_date']?.toString(),
      bookingTime: json['booking_time']?.toString(),
      customerName: user is Map ? user['full_name']?.toString() : null,
      stylistName: stylist is Map ? stylist['full_name']?.toString() : null,
      serviceNames: items is List
          ? items
              .map((item) => item is Map ? item['services'] : null)
              .whereType<Map>()
              .map((service) => service['service_name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList()
          : const [],
      billingId: billing is Map ? billing['billing_id']?.toString() : null,
      billingStatus: billing is Map ? billing['status']?.toString() : null,
      paymentMethod: billing is Map ? billing['payment_method']?.toString() : null,
    );
  }
}
