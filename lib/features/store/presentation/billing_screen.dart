import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/billing_model.dart';
import '../provider/cart_provider.dart';

class BillingScreen extends StatelessWidget {
  final BillingModel billing;

  const BillingScreen({super.key, required this.billing});

  Future<void> _pay(BuildContext context, BillingModel currentBilling) async {
    final provider = context.read<CartProvider>();
    final paidBilling = await provider.payBilling(
      billingId: currentBilling.id,
      paymentMethod: currentBilling.paymentMethod,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paidBilling != null ? 'Payment completed' : (provider.error ?? 'Can not pay billing'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'd',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Billing',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          final latestBilling = provider.latestBilling;
          final currentBilling = latestBilling != null && latestBilling.id == billing.id ? latestBilling : billing;
          final isPaid = currentBilling.status == 'PAID';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF00695C),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentBilling.code,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusPill(status: currentBilling.status),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _AmountRow(
                      label: 'Subtotal',
                      value: currencyFormatter.format(currentBilling.subtotal),
                    ),
                    const SizedBox(height: 10),
                    _AmountRow(
                      label: 'Discount',
                      value: currencyFormatter.format(
                        currentBilling.discountAmount,
                      ),
                    ),
                    const Divider(height: 28),
                    _AmountRow(
                      label: 'Total',
                      value: currencyFormatter.format(
                        currentBilling.totalAmount,
                      ),
                      isStrong: true,
                    ),
                    const SizedBox(height: 14),
                    _AmountRow(
                      label: 'Payment',
                      value: currentBilling.paymentMethod,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: provider.isLoading || isPaid
                    ? null
                    : () => _pay(context, currentBilling),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isPaid ? Icons.check_circle : Icons.payments),
                label: Text(
                  isPaid ? 'Paid' : 'Mark as paid',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _AmountRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isStrong ? const Color(0xFF00695C) : Colors.black87,
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
            fontSize: isStrong ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE3F6EE) : const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: isPaid ? const Color(0xFF00695C) : const Color(0xFF9A6500),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

