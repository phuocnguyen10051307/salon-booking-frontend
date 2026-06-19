class BookingModel {
  final String id;
  final String code;
  final double totalAmount;
  final String? status;

  const BookingModel({
    required this.id,
    required this.code,
    required this.totalAmount,
    this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['booking_id']?.toString() ?? '',
      code: json['booking_code']?.toString() ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
    );
  }
}
