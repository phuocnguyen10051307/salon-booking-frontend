import 'service_model.dart';

class CartItemModel {
  final String id;
  final String? cartId;
  final String? serviceId;
  final int quantity;
  final ServiceModel? service;

  const CartItemModel({
    required this.id,
    this.cartId,
    this.serviceId,
    required this.quantity,
    this.service,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['services'];
    return CartItemModel(
      id: json['cart_item_id']?.toString() ?? '',
      cartId: json['cart_id']?.toString(),
      serviceId: json['service_id']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      service: serviceJson is Map
          ? ServiceModel.fromJson(Map<String, dynamic>.from(serviceJson))
          : null,
    );
  }

  double get lineTotal => (service?.price ?? 0) * quantity;
}

class CartModel {
  final String id;
  final List<CartItemModel> items;

  const CartModel({required this.id, required this.items});

  factory CartModel.empty() => const CartModel(id: '', items: []);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['booking_cart_items'];
    return CartModel(
      id: json['cart_id']?.toString() ?? '',
      items: rawItems is List
          ? rawItems.whereType<Map>().map((item) {
              return CartItemModel.fromJson(Map<String, dynamic>.from(item));
            }).toList()
          : [],
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
}
