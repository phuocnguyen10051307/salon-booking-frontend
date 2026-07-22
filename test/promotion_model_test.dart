import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_frontend/features/store/data/cart_api.dart';
import 'package:salon_booking_frontend/features/store/data/models/billing_model.dart';
import 'package:salon_booking_frontend/features/store/data/models/booking_model.dart';
import 'package:salon_booking_frontend/features/store/data/models/cart_item_model.dart';
import 'package:salon_booking_frontend/features/store/data/models/promotion_model.dart';
import 'package:salon_booking_frontend/features/store/data/models/service_model.dart';
import 'package:salon_booking_frontend/features/staff/data/staff_payment_response.dart';

void main() {
  group('PromotionModel parsing', () {
    test('parses snake_case response and nullable dates', () {
      final promotion = PromotionModel.fromJson({
        'promotion_id': 'promotion-1',
        'title': 'Summer deal',
        'description': null,
        'discount_percent': 20,
        'start_date': null,
        'end_date': '2026-08-31T00:00:00.000Z',
        'is_active': true,
        'scope': 'SELECTED_SERVICES',
        'service_ids': ['service-1'],
        'services': [],
      });

      expect(promotion.id, 'promotion-1');
      expect(promotion.discountPercent, 20);
      expect(promotion.startDate, isNull);
      expect(promotion.endDate, DateTime.parse('2026-08-31T00:00:00.000Z'));
      expect(promotion.scope, PromotionModel.selectedServicesScope);
      expect(promotion.serviceIds, ['service-1']);
    });

    test('parses camelCase response and all-services scope', () {
      final promotion = PromotionModel.fromJson({
        'promotionId': 'promotion-2',
        'discountPercent': '15',
        'isActive': true,
        'scope': 'all_services',
        'serviceIds': [],
      });

      expect(promotion.id, 'promotion-2');
      expect(promotion.discountPercent, 15);
      expect(promotion.scope, PromotionModel.allServicesScope);
    });
  });

  group('Promotion calculations', () {
    final items = [
      _cartItem(id: 'item-1', serviceId: 'service-1', price: 100, quantity: 2),
      _cartItem(id: 'item-2', serviceId: 'service-2', price: 50, quantity: 1),
    ];

    test('discounts the complete subtotal for all-services promotion', () {
      final promotion = _promotion(
        scope: PromotionModel.allServicesScope,
        percent: 20,
      );

      expect(promotion.eligibleSubtotal(items), 250);
      expect(promotion.discountAmount(items), 50);
      expect(promotion.estimatedTotal(items), 200);
    });

    test('discounts only matching services and respects quantity', () {
      final promotion = _promotion(
        scope: PromotionModel.selectedServicesScope,
        percent: 20,
        serviceIds: ['service-1'],
      );

      expect(promotion.appliesToAny(['service-1', 'service-2']), isTrue);
      expect(promotion.eligibleSubtotal(items), 200);
      expect(promotion.discountAmount(items), 40);
      expect(promotion.estimatedTotal(items), 210);
    });

    test('returns no eligible value when services do not match', () {
      final promotion = _promotion(
        scope: PromotionModel.selectedServicesScope,
        percent: 20,
        serviceIds: ['service-3'],
      );

      expect(promotion.appliesToAny(['service-1', 'service-2']), isFalse);
      expect(promotion.eligibleSubtotal(items), 0);
      expect(promotion.discountAmount(items), 0);
    });
  });

  group('Checkout promotion payload', () {
    test('includes promotion_id when selected', () {
      final payload = buildCheckoutPayload(
        bookingDate: DateTime(2026, 7, 20),
        bookingTime: '09:30',
        selectedItemIds: ['item-1'],
        promotionId: 'promotion-1',
      );

      expect(payload['promotion_id'], 'promotion-1');
      expect(payload['booking_date'], '2026-07-20');
    });

    test('omits promotion_id when no promotion is selected', () {
      final payload = buildCheckoutPayload(
        bookingDate: DateTime(2026, 7, 20),
        bookingTime: '09:30',
      );

      expect(payload.containsKey('promotion_id'), isFalse);
    });
  });

  test('BookingModel parses the billed total from nested billing data', () {
    final booking = BookingModel.fromJson({
      'booking_id': 'booking-1',
      'booking_code': 'BK001',
      'total_amount': '250',
      'billings': {
        'billing_id': 'billing-1',
        'status': 'UNPAID',
        'payment_method': 'BANK_TRANSFER',
        'total_amount': '200',
      },
    });

    expect(booking.totalAmount, 250);
    expect(booking.billedTotalAmount, 200);
    expect(booking.billingStatus, 'UNPAID');
  });

  test('StaffPaymentSession parses diagnostics for incomplete PayOS payloads', () {
    final session = StaffPaymentSession.fromJson({
      'status': 'PENDING',
      'amount': 0,
      'missingFields': ['checkoutUrl', 'qrCode'],
      'diagnosticMessage': 'PayOS response is missing required fields: checkoutUrl, qrCode',
    });

    expect(session.isUsable, isFalse);
    expect(session.missingFields, ['checkoutUrl', 'qrCode']);
    expect(session.diagnosticMessage, contains('checkoutUrl'));
  });

  test('BillingModel parses the applied promotion', () {
    final billing = BillingModel.fromJson({
      'billing_id': 'billing-1',
      'billing_code': 'BL001',
      'booking_id': 'booking-1',
      'subtotal': '250',
      'discount_amount': '50',
      'total_amount': '200',
      'status': 'UNPAID',
      'promotions': {
        'promotion_id': 'promotion-1',
        'title': 'Summer deal',
        'discount_percent': 20,
        'scope': 'ALL_SERVICES',
      },
    });

    expect(billing.promotion?.title, 'Summer deal');
    expect(billing.promotion?.discountPercent, 20);
    expect(billing.discountAmount, 50);
  });
}

CartItemModel _cartItem({
  required String id,
  required String serviceId,
  required double price,
  required int quantity,
}) {
  return CartItemModel(
    id: id,
    serviceId: serviceId,
    quantity: quantity,
    service: ServiceModel(
      id: serviceId,
      name: serviceId,
      price: price,
      durationMinutes: 30,
      isActive: true,
    ),
  );
}

PromotionModel _promotion({
  required String scope,
  required int percent,
  List<String> serviceIds = const [],
}) {
  return PromotionModel(
    id: 'promotion',
    title: 'Promotion',
    discountPercent: percent,
    isActive: true,
    scope: scope,
    serviceIds: serviceIds,
    services: const [],
  );
}
