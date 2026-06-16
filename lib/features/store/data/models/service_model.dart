class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'];
    return ServiceModel(
      id: json['service_id']?.toString() ?? '',
      name: json['service_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 0,
      description: json['description'],
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      categoryName: category is Map<String, dynamic> ? category['category_name'] : null,
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
    'category_name': categoryName,
  };
}
