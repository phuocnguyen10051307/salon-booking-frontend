import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    final hasPendingTransfer =
        booking.billingStatus != 'PAID' && booking.paymentMethod == 'BANK_TRANSFER';
    if (hasPendingTransfer) {
      await _openTransferPaymentScreen(booking, null);
      return;
    }

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

      if (paymentMethod == 'BANK_TRANSFER') {
        final payment = response.payment;
        if (payment == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PayOS chua tra ve phien thanh toan. Vui long thu lai.')),
          );
          await _refresh();
          return;
        }


        await _openTransferPaymentScreen(booking, payment);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isPaid
                ? 'Da ghi nhan thanh toan thanh cong.'
                : 'Da tao phien thanh toan PayOS.',
          ),
        ),
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

  Future<void> _openTransferPaymentScreen(BookingModel booking, StaffPaymentSession? payment) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TransferPaymentScreen(
          booking: booking,
          payment: payment,
          api: _api,
          onPaymentConfirmed: () async {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Da xac nhan thanh toan thanh cong.')),
            );
            await _refresh();
          },
          onPaymentCancelled: () async {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Da huy phien thanh toan PayOS.')),
            );
            await _refresh();
          },
        ),
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
              value: currencyFormatter.format(
                booking.billedTotalAmount > 0 ? booking.billedTotalAmount : booking.totalAmount,
              ),
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
      ('BANK_TRANSFER', 'Thanh toan PayOS', Icons.qr_code_2_outlined),
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

class _TransferPaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final StaffPaymentSession? payment;
  final StaffApi api;
  final Future<void> Function() onPaymentConfirmed;
  final Future<void> Function() onPaymentCancelled;

  const _TransferPaymentScreen({
    required this.booking,
    required this.payment,
    required this.api,
    required this.onPaymentConfirmed,
    required this.onPaymentCancelled,
  });

  @override
  State<_TransferPaymentScreen> createState() => _TransferPaymentScreenState();
}

class _TransferPaymentScreenState extends State<_TransferPaymentScreen> {
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  StaffPaymentSession? _payment;
  bool _isCancelling = false;
  bool _isCheckingStatus = false;
  bool _isOpeningCheckout = false;
  bool _hasHandledPaid = false;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
    _startPolling();
    unawaited(_loadInitialPayment());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialPayment() async {
    if (_payment != null) return;
    try {
      final response = await widget.api.getBookingPaymentStatus(bookingId: widget.booking.id);
      if (!mounted) return;
      if (response.payment != null) {
        setState(() {
          _payment = _payment == null
              ? response.payment!
              : _mergePaymentSession(_payment!, response.payment!);
        });
      }
    } catch (_) {
      // keep fallback view
    }
  }

  StaffPaymentSession _mergePaymentSession(
    StaffPaymentSession current,
    StaffPaymentSession incoming,
  ) {
    String pick(String next, String previous) => next.trim().isNotEmpty ? next : previous;

    return StaffPaymentSession(
      provider: pick(incoming.provider, current.provider),
      bankBin: pick(incoming.bankBin, current.bankBin),
      bankName: pick(incoming.bankName, current.bankName),
      qrCode: pick(incoming.qrCode, current.qrCode),
      accountName: pick(incoming.accountName, current.accountName),
      accountNumber: pick(incoming.accountNumber, current.accountNumber),
      amount: incoming.amount > 0 ? incoming.amount : current.amount,
      transferContent: pick(incoming.transferContent, current.transferContent),
      checkoutUrl: pick(incoming.checkoutUrl, current.checkoutUrl),
      orderCode: pick(incoming.orderCode, current.orderCode),
      paymentLinkId: pick(incoming.paymentLinkId, current.paymentLinkId),
      status: pick(incoming.status, current.status),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    unawaited(_checkPaymentStatus());
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_checkPaymentStatus());
    });
  }

  Future<void> _handlePaid() async {
    if (_hasHandledPaid) return;
    _hasHandledPaid = true;
    _pollTimer?.cancel();
    await widget.onPaymentConfirmed();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _checkPaymentStatus({bool showFeedback = false}) async {
    if (_isCheckingStatus || _hasHandledPaid) return;
    setState(() => _isCheckingStatus = true);
    try {
      final response = await widget.api.getBookingPaymentStatus(bookingId: widget.booking.id);
      if (!mounted) return;

      if (response.payment != null) {
        setState(() {
          _payment = _payment == null
              ? response.payment!
              : _mergePaymentSession(_payment!, response.payment!);
        });
      }

      if (response.isPaid) {
        await _handlePaid();
        return;
      }

      if (showFeedback) {
        final payment = _payment;
        final reason = payment != null && !payment.isUsable
            ? (payment.diagnosticMessage.trim().isNotEmpty
                ? payment.diagnosticMessage
                : 'PayOS tra ve phien thanh toan thieu du lieu can thiet.')
            : 'Chua thay thanh toan thanh cong. Trang thai hien tai: ${_payment?.status ?? 'PENDING'}.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Khong kiem tra duoc trang thai: ${_readErrorMessage(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _cancelPayment() async {
    if (_isCancelling || _hasHandledPaid) return;
    setState(() => _isCancelling = true);
    try {
      await widget.api.cancelBookingTransferPayment(bookingId: widget.booking.id);
      if (!mounted) return;
      _pollTimer?.cancel();
      await widget.onPaymentCancelled();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong huy duoc thanh toan: ')),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _openCheckout() async {
    final payment = _payment;
    if (payment == null || !payment.isUsable) {
      final reason = payment?.diagnosticMessage.trim().isNotEmpty == true
          ? payment!.diagnosticMessage
          : 'Phien thanh toan PayOS chua du du lieu de mo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
      return;
    }

    final checkoutUrl = payment.checkoutUrl.trim();
    if (checkoutUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong co duong dan thanh toan PayOS.')),
      );
      return;
    }

    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duong dan thanh toan khong hop le.')),
      );
      return;
    }

    setState(() => _isOpeningCheckout = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _PayosCheckoutWebViewScreen(url: uri.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');
    final isBusy = _isCancelling || _hasHandledPaid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Thanh toan PayOS'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF16312B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isOpeningCheckout ? null : _openCheckout,
            icon: _isOpeningCheckout
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2E27),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.customerName ?? 'Customer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TopChip(
                        icon: Icons.payments_outlined,
                        label: currencyFormatter.format(payment?.amount ?? 0),
                      ),
                      _TopChip(
                        icon: Icons.verified_outlined,
                        label: _payment?.status ?? 'PENDING',
                      ),
                      _TopChip(
                        icon: Icons.qr_code_2_outlined,
                        label: (_payment?.orderCode ?? '').isEmpty ? '--' : _payment!.orderCode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _FallbackQrView(
                    payment: payment,
                    isOpeningCheckout: _isOpeningCheckout,
                    onOpenCheckout: _openCheckout,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : _cancelPayment,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded),
                  label: const Text('Huy thanh toan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackQrView extends StatelessWidget {
  final StaffPaymentSession? payment;
  final bool isOpeningCheckout;
  final Future<void> Function() onOpenCheckout;

  const _FallbackQrView({
    required this.payment,
    required this.isOpeningCheckout,
    required this.onOpenCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            'Mo PayOS bang trinh duyet de thanh toan tren dien thoai, hoac dung QR du phong ben duoi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(color: Colors.grey.shade700),
          ),
          if ((payment?.diagnosticMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD8A8)),
              ),
              child: Text(
                payment!.diagnosticMessage,
                style: GoogleFonts.openSans(
                  color: const Color(0xFF8A4B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isOpeningCheckout ? null : onOpenCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: isOpeningCheckout
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.open_in_new),
              label: Text(isOpeningCheckout ? 'Dang mo PayOS' : 'Mo PayOS de thanh toan'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _buildPaymentQrView(payment),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.account_balance_outlined,
            label: 'Ngan hang',
            value: (payment?.bankName ?? '').isEmpty ? (payment?.bankBin ?? '--') : payment!.bankName,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Chu TK',
            value: (payment?.accountName ?? '').isEmpty ? '--' : payment!.accountName,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.credit_card_outlined,
            label: 'So TK',
            value: (payment?.accountNumber ?? '').isEmpty ? '--' : payment!.accountNumber,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.receipt_long_outlined,
            label: 'Noi dung',
            value: (payment?.transferContent ?? '').isEmpty ? '--' : payment!.transferContent,
          ),
        ],
      ),
    );
  }
}

Widget _buildPaymentQrView(StaffPaymentSession? payment) {
  final qrCode = payment?.qrCode.trim() ?? '';
  final checkoutUrl = payment?.checkoutUrl.trim() ?? '';
  final qrData = qrCode.isNotEmpty ? qrCode : checkoutUrl;

  if (qrData.isNotEmpty) {
    return QrImageView(
      data: qrData,
      size: 240,
      backgroundColor: Colors.white,
    );
  }

  return SizedBox(
    width: 240,
    height: 240,
    child: Center(
      child: Text(
        (payment?.diagnosticMessage ?? '').trim().isNotEmpty
            ? payment!.diagnosticMessage
            : 'Khong co ma QR PayOS',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _PayosCheckoutWebViewScreen extends StatefulWidget {
  final String url;

  const _PayosCheckoutWebViewScreen({required this.url});

  @override
  State<_PayosCheckoutWebViewScreen> createState() => _PayosCheckoutWebViewScreenState();
}

class _PayosCheckoutWebViewScreenState extends State<_PayosCheckoutWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayOS'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF16312B),
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
class _TopChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
    return error.message ?? 'Khong the thuc hien yeu cau';
  }
  return error.toString();
}

String _formatTime(String? raw) {
  if (raw == null || raw.isEmpty) return '--:--';
  final match = RegExp(r'(\d{2}:\d{2})').firstMatch(raw);
  return match?.group(1) ?? raw;
}




