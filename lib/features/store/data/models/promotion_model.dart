import 'cart_item_model.dart';
import 'service_model.dart';

class PromotionModel {
  static const String allServicesScope = 'ALL_SERVICES';
  static const String selectedServicesScope = 'SELECTED_SERVICES';

  final String id;
  final String title;
  final String? description;
  final int discountPercent;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String scope;
  final List<String> serviceIds;
  final List<ServiceModel> services;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.discountPercent,
    required this.isActive,
    required this.scope,
    required this.serviceIds,
    required this.services,
    this.description,
    this.startDate,
    this.endDate,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final rawServiceIds = json['service_ids'] ?? json['serviceIds'];
    final rawServices = json['services'];

    return PromotionModel(
      id: (json['promotion_id'] ?? json['promotionId'])?.toString() ?? '',
      title: json['title']?.toString() ?? 'Promotion',
      description: json['description']?.toString(),
      discountPercent:
          int.tryParse(
            (json['discount_percent'] ?? json['discountPercent'] ?? 0)
                .toString(),
          ) ??
          0,
      startDate: _parseDate(json['start_date'] ?? json['startDate']),
      endDate: _parseDate(json['end_date'] ?? json['endDate']),
      isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,
      scope: (json['scope']?.toString().toUpperCase() ?? allServicesScope),
      serviceIds: rawServiceIds is List
          ? rawServiceIds
                .map((value) => value.toString())
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      services: rawServices is List
          ? rawServices
                .whereType<Map>()
                .map(
                  (value) =>
                      ServiceModel.fromJson(Map<String, dynamic>.from(value)),
                )
                .toList()
          : const [],
    );
  }

  bool appliesToAny(Iterable<String> selectedServiceIds) {
    if (scope == allServicesScope) return true;
    final selected = selectedServiceIds.toSet();
    return serviceIds.any(selected.contains);
  }

  double eligibleSubtotal(Iterable<CartItemModel> items) {
    if (scope == allServicesScope) {
      return items.fold(0, (sum, item) => sum + item.lineTotal);
    }

    final allowed = serviceIds.toSet();
    return items.fold(0, (sum, item) {
      final serviceId = item.serviceId ?? item.service?.id;
      return serviceId != null && allowed.contains(serviceId)
          ? sum + item.lineTotal
          : sum;
    });
  }

  double discountAmount(Iterable<CartItemModel> items) {
    final itemList = items.toList();
    final subtotal = itemList.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final normalizedPercent = discountPercent < 0 ? 0 : discountPercent;
    final discount = eligibleSubtotal(itemList) * normalizedPercent / 100;
    return discount.clamp(0, subtotal).toDouble();
  }

  double estimatedTotal(Iterable<CartItemModel> items) {
    final itemList = items.toList();
    final subtotal = itemList.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    return (subtotal - discountAmount(itemList)).clamp(0, subtotal).toDouble();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
