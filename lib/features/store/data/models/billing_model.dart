class BillingModel {
  final String id;
  final String code;
  final String bookingId;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;

  const BillingModel({
    required this.id,
    required this.code,
    required this.bookingId,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
  });

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      id: json['billing_id']?.toString() ?? '',
      code: json['billing_code']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
      status: json['status']?.toString() ?? 'UNPAID',
    );
  }
}
