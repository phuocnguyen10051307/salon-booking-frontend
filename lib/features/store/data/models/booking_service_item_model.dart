class BookingServiceItemModel {
  final String serviceId;
  final String serviceName;

  const BookingServiceItemModel({
    required this.serviceId,
    required this.serviceName,
  });

  factory BookingServiceItemModel.fromJson(Map<String, dynamic> json) {
    final service = json['services'];
    return BookingServiceItemModel(
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: service is Map ? service['service_name']?.toString() ?? '' : '',
    );
  }
}
