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

  const StaffPaymentSession({
    required this.provider,
    required this.bankBin,
    required this.bankName,
    required this.qrCode,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.transferContent,
  });

  factory StaffPaymentSession.fromJson(Map<String, dynamic> json) {
    return StaffPaymentSession(
      provider: json['provider']?.toString() ?? 'BANK_QR',
      bankBin: json['bankBin']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      transferContent: json['transferContent']?.toString() ?? '',
    );
  }
}

class StaffPaymentResponse {
  final BillingModel billing;
  final StaffPaymentSession? payment;

  const StaffPaymentResponse({required this.billing, this.payment});

  bool get isPaid => billing.status.toUpperCase() == 'PAID';

  factory StaffPaymentResponse.fromJson(Map<String, dynamic> json) {
    final billingJson = json['billing'];
    final paymentJson = json['payment'];

    return StaffPaymentResponse(
      billing: BillingModel.fromJson(Map<String, dynamic>.from(billingJson as Map)),
      payment: paymentJson is Map
          ? StaffPaymentSession.fromJson(Map<String, dynamic>.from(paymentJson))
          : null,
    );
  }
}
