import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/billing_model.dart';
import '../data/models/booking_service_item_model.dart';
import '../data/models/review_model.dart';
import '../provider/cart_provider.dart';

class BillingScreen extends StatelessWidget {
  final BillingModel billing;

  const BillingScreen({super.key, required this.billing});

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
                    if (currentBilling.booking != null) ...[
                      const Divider(height: 28),
                      _AmountRow(
                        label: 'Booking time',
                        value: _bookingTimeLabel(currentBilling.booking),
                      ),
                      const SizedBox(height: 10),
                      _AmountRow(
                        label: 'Services',
                        value: currentBilling.booking!.serviceNames.isEmpty
                            ? 'No services'
                            : currentBilling.booking!.serviceNames.join(', '),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _AmountRow(
                      label: 'Payment',
                      value: isPaid ? currentBilling.paymentMethod : 'Pay at salon after service',
                    ),
                  ],
                ),
              ),
              if (isPaid && currentBilling.booking != null) ...[
                const SizedBox(height: 16),
                _ReviewSection(billing: currentBilling),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _bookingTimeLabel(dynamic booking) {
  final rawDate = booking.bookingDate?.toString() ?? '';
  final rawTime = booking.bookingTime?.toString() ?? '';
  final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
  final match = RegExp(r'(\d{2}:\d{2})').firstMatch(rawTime);
  final time = match?.group(1) ?? rawTime;
  return [date, time].where((item) => item.isNotEmpty).join(' ');
}

class _ReviewSection extends StatelessWidget {
  final BillingModel billing;

  const _ReviewSection({required this.billing});

  @override
  Widget build(BuildContext context) {
    final booking = billing.booking!;
    final reviewsByServiceId = {for (final review in booking.reviews) review.serviceId: review};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review services',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thanh toan xong roi, ban co the danh gia tung dich vu ngay ben duoi.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          if (booking.serviceItems.isEmpty)
            Text(
              'No services available for review.',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ...booking.serviceItems.map((item) {
            final review = reviewsByServiceId[item.serviceId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(
                billingId: billing.id,
                serviceItem: item,
                review: review,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String billingId;
  final BookingServiceItemModel serviceItem;
  final ReviewModel? review;

  const _ReviewCard({
    required this.billingId,
    required this.serviceItem,
    this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceItem.serviceName.isEmpty ? 'Service' : serviceItem.serviceName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final filled = index < (review?.rating ?? 0);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? Colors.amber : Colors.grey.shade400,
                  size: 20,
                ),
              );
            }),
          ),
          if (review?.comment != null && review!.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review!.comment!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showReviewDialog(context),
              icon: Icon(review == null ? Icons.rate_review_outlined : Icons.edit_outlined),
              label: Text(review == null ? 'Rate now' : 'Edit review'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ReviewDialog(
        billingId: billingId,
        serviceItem: serviceItem,
        initialReview: review,
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final String billingId;
  final BookingServiceItemModel serviceItem;
  final ReviewModel? initialReview;

  const _ReviewDialog({
    required this.billingId,
    required this.serviceItem,
    this.initialReview,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final TextEditingController _commentController;
  late int _rating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialReview?.rating ?? 5;
    _commentController = TextEditingController(text: widget.initialReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.serviceItem.serviceName.isEmpty ? 'Review service' : widget.serviceItem.serviceName,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ban danh gia trai nghiem nhu the nao?',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: _submitting ? null : () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            TextField(
              controller: _commentController,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Chia se cam nhan cua ban',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Saving...' : 'Save review'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<CartProvider>();
    final success = await provider.submitReview(
      billingId: widget.billingId,
      serviceId: widget.serviceItem.serviceId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved successfully')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Unable to save review')),
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
