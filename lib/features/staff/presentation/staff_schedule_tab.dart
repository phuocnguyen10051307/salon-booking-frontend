import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../store/data/models/booking_model.dart';
import '../data/staff_api.dart';

class StaffScheduleTab extends StatefulWidget {
  const StaffScheduleTab({super.key});

  @override
  State<StaffScheduleTab> createState() => _StaffScheduleTabState();
}

class _StaffScheduleTabState extends State<StaffScheduleTab> {
  final StaffApi _api = StaffApi();
  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getTodayBookings();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.getTodayBookings();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
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
                'Today schedule',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd/MM/yyyy').format(DateTime.now()),
                style: GoogleFonts.openSans(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              if (snapshot.hasError)
                _StateBox(message: 'Can not load today schedule.')
              else if (bookings.isEmpty)
                _StateBox(message: 'No appointments for today.')
              else
                ...bookings.map((booking) => _BookingTile(booking: booking)),
            ],
          );
        },
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;

  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final services = booking.serviceNames.isEmpty ? 'No services' : booking.serviceNames.join(', ');
    final time = _formatTime(booking.bookingTime);

    return Container(
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
                Text(
                  booking.status ?? 'PENDING',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF00695C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    final match = RegExp(r'(\d{2}:\d{2})').firstMatch(raw);
    return match?.group(1) ?? raw;
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
