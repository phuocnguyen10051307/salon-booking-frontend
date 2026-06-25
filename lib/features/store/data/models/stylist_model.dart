class StylistModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final int? experienceYears;
  final bool isActive;
  final List<String> serviceIds;

  const StylistModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.phone,
    this.email,
    this.avatarUrl,
    this.bio,
    this.experienceYears,
    this.serviceIds = const [],
  });

  factory StylistModel.fromJson(Map<String, dynamic> json) {
    final rawServices = json['stylist_services'];
    final serviceIds = rawServices is List
        ? rawServices
            .whereType<Map>()
            .map((item) => item['service_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList()
        : const <String>[];

    return StylistModel(
      id: json['stylist_id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      experienceYears: int.tryParse(json['experience_years']?.toString() ?? ''),
      isActive: json['is_active'] as bool? ?? true,
      serviceIds: serviceIds,
    );
  }
}
