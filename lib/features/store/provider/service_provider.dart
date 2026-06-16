import 'package:flutter/material.dart';
import '../data/models/service_model.dart';
import '../data/service_api.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceApi _serviceApi = ServiceApi();
  
  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _serviceApi.getServices();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
