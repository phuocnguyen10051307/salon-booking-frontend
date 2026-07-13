import 'package:flutter/material.dart';

import '../data/models/service_model.dart';
import '../data/service_api.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceApi _serviceApi = ServiceApi();

  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<ServiceModel> get searchedServices {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _services;
    return _services.where((service) {
      return service.name.toLowerCase().contains(query) ||
          (service.description ?? '').toLowerCase().contains(query) ||
          (service.categoryName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> fetchServices({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _serviceApi.getServices(search: search);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveService({
    ServiceModel? existing,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (existing == null) {
        await _serviceApi.createService(
          name: name,
          price: price,
          durationMinutes: durationMinutes,
          description: description,
          imageUrl: imageUrl,
          categoryId: categoryId,
          isActive: isActive,
        );
      } else {
        await _serviceApi.updateService(
          id: existing.id,
          name: name,
          price: price,
          durationMinutes: durationMinutes,
          description: description,
          imageUrl: imageUrl,
          categoryId: categoryId,
          isActive: isActive,
        );
      }
      await fetchServices();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteService(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _serviceApi.deleteService(id);
      await fetchServices();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
