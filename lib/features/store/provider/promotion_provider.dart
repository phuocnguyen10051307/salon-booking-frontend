import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/promotion_model.dart';
import '../data/promotion_api.dart';

class PromotionProvider extends ChangeNotifier {
  final PromotionApi _promotionApi;

  PromotionProvider({PromotionApi? promotionApi})
    : _promotionApi = promotionApi ?? PromotionApi();

  List<PromotionModel> _promotions = const [];
  bool _isLoading = false;
  String? _error;

  List<PromotionModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchActivePromotions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _promotions = await _promotionApi.getActivePromotions();
      return true;
    } catch (error) {
      _error = _readErrorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _readErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message != null) return message.toString();
      }
      return error.message ?? 'Could not load promotions';
    }
    return error.toString();
  }
}
