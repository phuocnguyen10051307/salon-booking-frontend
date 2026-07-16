import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/promotion_model.dart';

class PromotionApi {
  Future<List<PromotionModel>> getActivePromotions() async {
    final response = await ApiClient.dio.get(ApiConstants.activePromotions);
    final rawPromotions =
        response.data['data']?['promotions'] ?? response.data['promotions'];
    if (rawPromotions is! List) return const [];

    return rawPromotions
        .whereType<Map>()
        .map(
          (value) => PromotionModel.fromJson(Map<String, dynamic>.from(value)),
        )
        .where((promotion) => promotion.id.isNotEmpty)
        .toList();
  }
}
