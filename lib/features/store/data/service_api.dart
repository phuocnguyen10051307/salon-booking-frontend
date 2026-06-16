import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/service_model.dart';

class ServiceApi {
  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await ApiClient.dio.get(ApiConstants.services);
      final services = response.data['data']?['services'] ?? response.data['services'];
      if (services != null) {
        final List<dynamic> servicesData = services;
        return servicesData.map((json) => ServiceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
