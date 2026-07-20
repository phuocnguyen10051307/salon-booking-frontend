import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../store/data/models/booking_model.dart';
import '../data/staff_api.dart';
import '../data/staff_payment_response.dart';

class StaffScheduleTab extends StatefulWidget {
  const StaffScheduleTab({super.key});

  @override
  State<StaffScheduleTab> createState() => _StaffScheduleTabState();
}

class _StaffScheduleTabState extends State<StaffScheduleTab> {
  final StaffApi _api = StaffApi();
  late Future<List<BookingModel>> _future;
  late DateTime _selectedDate;
  String? _collectingBookingId;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _future = _loadBookings();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month && left.day == right.day;

  Future<List<BookingModel>> _loadBookings() {
    return _api.getBookingsForDate(date: _selectedDate);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadBookings();
    });
    await _future;
  }

  Future<void> _showToday() async {
    final today = _today;
    if (_isSameDate(_selectedDate, today)) return _refresh();

    setState(() {
      _selectedDate = today;
      _future = _loadBookings();
    });
    await _future;
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      selectableDayPredicate: (date) => !date.isAfter(today),
    );

    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _selectedDate = normalized;
      _future = _loadBookings();
    });
    await _future;
  }

  Future<void> _openBookingDetails(BookingModel booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BookingDetailsSheet(
        booking: booking,
        isCollecting: _collectingBookingId == booking.id,
        onCollectPayment: (paymentMethod) {
          Navigator.of(context).pop();
          _collectPayment(booking, paymentMethod);
        },
      ),
    );
  }

  Future<void> _collectPayment(BookingModel booking, String paymentMethod) async {
    setState(() => _collectingBookingId = booking.id);
    try {
      final response = await _api.collectBookingPayment(
        bookingId: booking.id,
        paymentMethod: paymentMethod,
      );
      if (!mounted) return;

      if (paymentMethod == 'BANK_TRANSFER' && response.payment != null && !response.isPaid) {
        await _showTransferPaymentDialog(booking, response.payment!);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da ghi nhan thanh toan tien mat.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong ghi nhan duoc thanh toan: ${_readErrorMessage(error)}')),
      );
    } finally {
      if (mounted) setState(() => _collectingBookingId = null);
    }
  }

  Future<void> _showTransferPaymentDialog(BookingModel booking, StaffPaymentSession payment) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _TransferPaymentDialog(
        booking: booking,
        payment: payment,
        api: _api,
        onPaymentConfirmed: () async {
          if (!mounted) return;
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Da xac nhan da nhan tien chuyen khoan.')),
          );
          await _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDate(_selectedDate, _today);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00695C),
      child: FutureBuilder<List<BookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            children: [
              Text(
                'Lich lam viec',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                style: GoogleFonts.openSans(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _showToday,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.today),
                    label: Text(isToday ? 'Hom nay' : 'Ve hom nay'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Chon ngay'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.hasError)
                const _StateBox(message: 'Khong tai duoc lich lam viec.')
              else if (bookings.isEmpty)
                _StateBox(
                  message: isToday ? 'Hom nay chua co lich hen.' : 'Ngay nay chua co lich hen.',
                )
              else
                ...bookings.map(
                  (booking) => _BookingTile(
                    booking: booking,
                    isCollecting: _collectingBookingId == booking.id,
                    onTap: () => _openBookingDetails(booking),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  final bool isCollecting;
  final VoidCallback onTap;

  const _BookingTile({required this.booking, required this.isCollecting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final services = booking.serviceNames.isEmpty ? 'No services' : booking.serviceNames.join(', ');
    final time = _formatTime(booking.bookingTime);
    final billingStatus = booking.billingStatus ?? 'UNPAID';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                time,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00695C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName ?? 'Customer',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    services,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusPill(label: booking.status ?? 'PENDING', isPaid: false),
                      _StatusPill(label: billingStatus, isPaid: billingStatus == 'PAID'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isCollecting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailsSheet extends StatelessWidget {
  final BookingModel booking;
  final bool isCollecting;
  final ValueChanged<String> onCollectPayment;

  const _BookingDetailsSheet({
    required this.booking,
    required this.isCollecting,
    required this.onCollectPayment,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');
    final isPaid = booking.billingStatus == 'PAID';
    final services = booking.serviceNames.isEmpty ? ['No services'] : booking.serviceNames;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.customerName ?? 'Customer',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(label: booking.billingStatus ?? 'UNPAID', isPaid: isPaid),
              ],
            ),
            const SizedBox(height: 14),
            _DetailRow(icon: Icons.schedule, label: 'Time', value: _formatTime(booking.bookingTime)),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.confirmation_number_outlined, label: 'Booking', value: booking.code),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Total',
              value: currencyFormatter.format(booking.totalAmount),
            ),
            const SizedBox(height: 18),
            Text('Services', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF00695C)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service, style: GoogleFonts.openSans(color: Colors.grey.shade800))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (isPaid)
              _PaidNotice(paymentMethod: booking.paymentMethod ?? 'CASH')
            else
              _PaymentMethodButtons(isCollecting: isCollecting, onSelected: onCollectPayment),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodButtons extends StatelessWidget {
  final bool isCollecting;
  final ValueChanged<String> onSelected;

  const _PaymentMethodButtons({required this.isCollecting, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final methods = const [
      ('CASH', 'Tien mat', Icons.payments_outlined),
      ('BANK_TRANSFER', 'Chuyen khoan QR', Icons.account_balance_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thu tien sau khi xong dich vu', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods
              .map(
                (method) => OutlinedButton.icon(
                  onPressed: isCollecting ? null : () => onSelected(method.$1),
                  icon: Icon(method.$3, size: 18),
                  label: Text(method.$2),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TransferPaymentDialog extends StatefulWidget {
  final BookingModel booking;
  final StaffPaymentSession payment;
  final StaffApi api;
  final Future<void> Function() onPaymentConfirmed;

  const _TransferPaymentDialog({
    required this.booking,
    required this.payment,
    required this.api,
    required this.onPaymentConfirmed,
  });

  @override
  State<_TransferPaymentDialog> createState() => _TransferPaymentDialogState();
}

class _TransferPaymentDialogState extends State<_TransferPaymentDialog> {
  bool _isConfirming = false;

  Future<void> _confirmPayment() async {
    setState(() => _isConfirming = true);
    try {
      await widget.api.confirmBookingTransferPayment(bookingId: widget.booking.id);
      if (!mounted) return;
      await widget.onPaymentConfirmed();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong xac nhan duoc thanh toan: $error')),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

    return AlertDialog(
      title: Text('Xac nhan nhan tien chuyen khoan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dua ma QR nay cho khach quet bang app ngan hang. Sau khi da kiem tra tien da vao tai khoan, staff bam xac nhan da nhan tien.',
                style: GoogleFonts.openSans(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              if (payment.qrCode.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      payment.qrCode,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 220,
                        height: 220,
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const Text('Khong tai duoc QR'),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'So tien',
                value: currencyFormatter.format(payment.amount),
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.account_balance_outlined,
                label: 'Ngan hang',
                value: payment.bankName.isEmpty ? payment.bankBin : payment.bankName,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Chu TK',
                value: payment.accountName.isEmpty ? '--' : payment.accountName,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.credit_card_outlined,
                label: 'So TK',
                value: payment.accountNumber.isEmpty ? '--' : payment.accountNumber,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.receipt_long_outlined,
                label: 'Noi dung',
                value: payment.transferContent.isEmpty ? '--' : payment.transferContent,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
          child: const Text('Dong'),
        ),
        FilledButton.icon(
          onPressed: _isConfirming ? null : _confirmPayment,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
          icon: _isConfirming
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.verified_outlined),
          label: Text(_isConfirming ? 'Dang xac nhan' : 'Xac nhan da nhan tien'),
        ),
      ],
    );
  }
}

class _PaidNotice extends StatelessWidget {
  final String paymentMethod;

  const _PaidNotice({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Da thanh toan bang $paymentMethod',
        style: GoogleFonts.poppins(color: const Color(0xFF00695C), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: const Color(0xFF00695C)),
        ),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.openSans(color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isPaid;

  const _StatusPill({required this.label, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE3F6EE) : const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: isPaid ? const Color(0xFF00695C) : const Color(0xFF9A6500),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final String message;

  const _StateBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.openSans(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

String _readErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return error.message ?? 'Request failed';
  }
  return error.toString();
}

String _formatTime(String? raw) {
  if (raw == null || raw.isEmpty) return '--:--';
  final match = RegExp(r'(\d{2}:\d{2})').firstMatch(raw);
  return match?.group(1) ?? raw;
}





