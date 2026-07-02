import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/cart_api.dart';
import '../data/models/billing_model.dart';
import '../data/models/booking_model.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/stylist_model.dart';

class CartProvider extends ChangeNotifier {
  final CartApi _cartApi = CartApi();

  CartModel _cart = CartModel.empty();
  BookingModel? _latestBooking;
  BillingModel? _latestBilling;
  List<BillingModel> _billings = const [];
  List<StylistModel> _stylists = const [];
  bool _isLoading = false;
  String? _error;

  CartModel get cart => _cart;
  BookingModel? get latestBooking => _latestBooking;
  BillingModel? get latestBilling => _latestBilling;
  List<BillingModel> get billings => _billings;
  List<StylistModel> get stylists => _stylists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart.itemCount;

  Future<void> fetchCart() async {
    await _run(() async {
      _cart = await _cartApi.getCart();
    });
  }

  Future<void> fetchBillings() async {
    await _run(() async {
      _billings = await _cartApi.getBillings();
    });
  }

  Future<void> fetchStylistsForServices(List<String> serviceIds) async {
    await _run(() async {
      final stylists = await _cartApi.getStylists();
      final activeStylists = stylists.where((stylist) => stylist.isActive).toList();
      final matchingStylists = activeStylists.where((stylist) {
        return serviceIds.every((serviceId) => stylist.serviceIds.contains(serviceId));
      }).toList();

      _stylists = matchingStylists.isNotEmpty ? matchingStylists : activeStylists;
    });
  }

  Future<bool> addService(String serviceId, {int quantity = 1}) async {
    return _run(() async {
      await _cartApi.addCartItem(serviceId: serviceId, quantity: quantity);
      _cart = await _cartApi.getCart();
    });
  }

  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) return removeItem(itemId);
    return _run(() async {
      await _cartApi.updateCartItem(itemId: itemId, quantity: quantity);
      _cart = await _cartApi.getCart();
    });
  }

  Future<bool> removeItem(String itemId) async {
    return _run(() async {
      await _cartApi.deleteCartItem(itemId);
      _cart = await _cartApi.getCart();
    });
  }

  Future<bool> clearCart() async {
    return _run(() async {
      await _cartApi.clearCart();
      _cart = CartModel.empty();
    });
  }

  Future<BillingModel?> checkout({
    required DateTime bookingDate,
    required String bookingTime,
    String? stylistId,
    List<String> selectedItemIds = const [],
    String? note,
  }) async {
    final success = await _run(() async {
      final result = await _cartApi.checkout(
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        stylistId: stylistId,
        selectedItemIds: selectedItemIds,
        note: note,
      );
      _latestBooking = result.booking;
      _latestBilling = result.billing;
      _cart = await _cartApi.getCart();
      _billings = await _cartApi.getBillings();
    });
    return success ? _latestBilling : null;
  }

  Future<BillingModel?> payBilling({required String billingId, required String paymentMethod}) async {
    final success = await _run(() async {
      _latestBilling = await _cartApi.payBilling(
        billingId: billingId,
        paymentMethod: paymentMethod,
      );
      _billings = await _cartApi.getBillings();
    });
    return success ? _latestBilling : null;
  }

  Future<bool> submitReview({
    required String billingId,
    required String serviceId,
    required int rating,
    String? comment,
  }) {
    return _run(() async {
      await _cartApi.submitReview(
        billingId: billingId,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
      );
      _billings = await _cartApi.getBillings();
      final matched = _billings.where((item) => item.id == billingId);
      if (matched.isNotEmpty) {
        _latestBilling = matched.first;
      }
    });
  }

  String _readErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message != null) return message.toString();
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = _readErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
