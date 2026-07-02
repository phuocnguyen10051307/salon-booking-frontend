class SalonLocationModel {
  final String id;
  final String salonName;
  final String address;
  final String? hotline;
  final String? openingHours;
  final double? latitude;
  final double? longitude;

  const SalonLocationModel({
    required this.id,
    required this.salonName,
    required this.address,
    this.hotline,
    this.openingHours,
    this.latitude,
    this.longitude,
  });

  factory SalonLocationModel.fromJson(Map<String, dynamic> json) {
    return SalonLocationModel(
      id: json['location_id']?.toString() ?? '',
      salonName: json['salon_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      hotline: json['hotline']?.toString(),
      openingHours: json['opening_hours']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
