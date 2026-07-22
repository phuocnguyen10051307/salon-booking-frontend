import '../../store/data/models/billing_model.dart';

class StaffPaymentSession {
  final String provider;
  final String bankBin;
  final String bankName;
  final String qrCode;
  final String accountName;
  final String accountNumber;
  final double amount;
  final String transferContent;
  final String checkoutUrl;
  final String orderCode;
  final String paymentLinkId;
  final String status;
  final List<String> missingFields;
  final String diagnosticMessage;

  const StaffPaymentSession({
    required this.provider,
    required this.bankBin,
    required this.bankName,
    required this.qrCode,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.transferContent,
    required this.checkoutUrl,
    required this.orderCode,
    required this.paymentLinkId,
    required this.status,
    this.missingFields = const [],
    this.diagnosticMessage = '',
  });

  factory StaffPaymentSession.fromJson(Map<String, dynamic> json) {
    return StaffPaymentSession(
      provider: json['provider']?.toString() ?? 'PAYOS',
      bankBin: json['bankBin']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      transferContent: json['transferContent']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      paymentLinkId: json['paymentLinkId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      missingFields: json['missingFields'] is List
          ? (json['missingFields'] as List).map((item) => item.toString()).toList()
          : const [],
      diagnosticMessage: json['diagnosticMessage']?.toString() ?? '',
    );
  }

  bool get hasQrCode => qrCode.trim().isNotEmpty;
  bool get hasCheckoutUrl => checkoutUrl.trim().isNotEmpty;
  bool get isUsable => hasQrCode || hasCheckoutUrl;
}

class StaffPaymentResponse {
  final BillingModel billing;
  final StaffPaymentSession? payment;

  const StaffPaymentResponse({required this.billing, this.payment});

  bool get isPaid => billing.status.toUpperCase() == 'PAID';

  factory StaffPaymentResponse.fromJson(Map<String, dynamic> json) {
    final billingJson = json['billing'];
    final paymentJson = json['payment'];
    final billingSource = billingJson is Map ? billingJson : json;

    return StaffPaymentResponse(
      billing: BillingModel.fromJson(Map<String, dynamic>.from(billingSource as Map)),
      payment: paymentJson is Map
          ? StaffPaymentSession.fromJson(Map<String, dynamic>.from(paymentJson))
          : null,
    );
  }
}
