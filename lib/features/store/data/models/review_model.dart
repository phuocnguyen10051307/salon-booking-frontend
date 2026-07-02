class ReviewModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final int rating;
  final String? comment;

  const ReviewModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.rating,
    this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final service = json['services'];
    return ReviewModel(
      id: json['review_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: service is Map ? service['service_name']?.toString() ?? '' : '',
      rating: int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString(),
    );
  }
}
