import 'package:flutter/material.dart';

import '../data/cart_api.dart';
import '../data/models/billing_model.dart';
import '../data/models/booking_model.dart';
import '../data/models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final CartApi _cartApi = CartApi();

  CartModel _cart = CartModel.empty();
  BookingModel? _latestBooking;
  BillingModel? _latestBilling;
  bool _isLoading = false;
  String? _error;

  CartModel get cart => _cart;
  BookingModel? get latestBooking => _latestBooking;
  BillingModel? get latestBilling => _latestBilling;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart.itemCount;

  Future<void> fetchCart() async {
    await _run(() async {
      _cart = await _cartApi.getCart();
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
    required String paymentMethod,
    String? note,
  }) async {
    final success = await _run(() async {
      _latestBooking = await _cartApi.createBooking(
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        note: note,
      );
      _latestBilling = await _cartApi.createBilling(
        bookingId: _latestBooking!.id,
        paymentMethod: paymentMethod,
      );
      _cart = CartModel.empty();
    });
    return success ? _latestBilling : null;
  }

  Future<BillingModel?> payLatestBilling(String paymentMethod) async {
    final billingId = _latestBilling?.id;
    if (billingId == null || billingId.isEmpty) return null;

    final success = await _run(() async {
      _latestBilling = await _cartApi.payBilling(
        billingId: billingId,
        paymentMethod: paymentMethod,
      );
    });
    return success ? _latestBilling : null;
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
