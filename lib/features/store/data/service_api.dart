import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/service_model.dart';

class ServiceApi {
  Future<List<ServiceModel>> getServices({String? search}) async {
    final response = await ApiClient.dio.get(ApiConstants.services);
    final services = response.data['data']?['services'] ?? response.data['services'];
    if (services == null) return [];

    final query = search?.trim().toLowerCase() ?? '';
    final list = (services as List<dynamic>)
        .map((json) => ServiceModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .where((service) {
      if (query.isEmpty) return true;
      return service.name.toLowerCase().contains(query) ||
          (service.description ?? '').toLowerCase().contains(query) ||
          (service.categoryName ?? '').toLowerCase().contains(query);
    }).toList();

    return list;
  }

  Future<ServiceModel> getServiceById(String id) async {
    final response = await ApiClient.dio.get('${ApiConstants.services}/$id');
    final service = response.data['data']?['service'] ?? response.data['service'];
    return ServiceModel.fromJson(Map<String, dynamic>.from(service as Map));
  }

  Future<ServiceModel> createService({
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.post(
      ApiConstants.services,
      data: {
        'service_name': name,
        'price': price,
        'duration_minutes': durationMinutes,
        'description': description,
        'image_url': imageUrl,
        'category_id': categoryId,
        'is_active': isActive,
      },
    );
    final service = response.data['data']?['service'] ?? response.data['service'];
    return ServiceModel.fromJson(Map<String, dynamic>.from(service as Map));
  }

  Future<ServiceModel> updateService({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.put(
      '${ApiConstants.services}/$id',
      data: {
        'service_name': name,
        'price': price,
        'duration_minutes': durationMinutes,
        'description': description,
        'image_url': imageUrl,
        'category_id': categoryId,
        'is_active': isActive,
      },
    );
    final service = response.data['data']?['service'] ?? response.data['service'];
    return ServiceModel.fromJson(Map<String, dynamic>.from(service as Map));
  }

  Future<void> deleteService(String id) async {
    await ApiClient.dio.delete('${ApiConstants.services}/$id');
  }
}
