class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final String? imageUrl;
  final String? categoryId;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.imageUrl,
    this.categoryId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['service_id']?.toString() ?? '',
      name: json['service_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 0,
      description: json['description'],
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'service_id': id,
    'service_name': name,
    'price': price,
    'duration_minutes': durationMinutes,
    'description': description,
    'image_url': imageUrl,
    'category_id': categoryId,
  };
}
