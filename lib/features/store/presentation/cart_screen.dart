import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/cart_item_model.dart';
import '../provider/cart_provider.dart';
import 'billing_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _noteController = TextEditingController();
  DateTime _bookingDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _bookingTime = const TimeOfDay(hour: 9, minute: 0);
  String _paymentMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _bookingDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bookingTime,
    );
    if (picked != null) setState(() => _bookingTime = picked);
  }

  Future<void> _checkout() async {
    final provider = context.read<CartProvider>();
    final billing = await provider.checkout(
      bookingDate: _bookingDate,
      bookingTime: _formatTime(_bookingTime),
      paymentMethod: _paymentMethod,
      note: _noteController.text,
    );

    if (!mounted) return;
    if (billing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Can not checkout. Please try again.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BillingScreen(billing: billing)),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'd',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Cart',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.cart.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cart.items.isEmpty) {
            return const _EmptyCart();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ...provider.cart.items.map(
                (item) => _CartItemTile(
                  item: item,
                  currencyFormatter: currencyFormatter,
                  onMinus: () =>
                      provider.updateQuantity(item.id, item.quantity - 1),
                  onPlus: () =>
                      provider.updateQuantity(item.id, item.quantity + 1),
                  onRemove: () => provider.removeItem(item.id),
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSection(
                dateLabel: dateFormatter.format(_bookingDate),
                timeLabel: _bookingTime.format(context),
                paymentMethod: _paymentMethod,
                noteController: _noteController,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
                onPaymentChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 18),
              _TotalRow(
                label: 'Subtotal',
                value: currencyFormatter.format(provider.cart.subtotal),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _checkout,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(
                  'Checkout',
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

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final NumberFormat currencyFormatter;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.currencyFormatter,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _Thumb(imageUrl: service?.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service?.name ?? 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(service?.price ?? 0),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00695C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallIconButton(icon: Icons.remove, onPressed: onMinus),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          item.quantity.toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    _SmallIconButton(icon: Icons.add, onPressed: onPlus),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final String dateLabel;
  final String timeLabel;
  final String paymentMethod;
  final TextEditingController noteController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<String?> onPaymentChanged;

  const _CheckoutSection({
    required this.dateLabel,
    required this.timeLabel,
    required this.paymentMethod,
    required this.noteController,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking info',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.calendar_today,
                  label: dateLabel,
                  onPressed: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerButton(
                  icon: Icons.schedule,
                  label: timeLabel,
                  onPressed: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment method',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'CASH', child: Text('Cash')),
              DropdownMenuItem(value: 'CARD', child: Text('Card')),
              DropdownMenuItem(
                value: 'BANK_TRANSFER',
                child: Text('Bank transfer'),
              ),
              DropdownMenuItem(value: 'E_WALLET', child: Text('E-wallet')),
            ],
            onChanged: onPaymentChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: const Color(0xFF00695C),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SmallIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;

  const _Thumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    if (url.isEmpty) return const _ThumbFallback();
    return Image.network(
      url,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ThumbFallback(),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE7F3F0),
      child: const Icon(Icons.spa, color: Color(0xFF00695C)),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF00695C),
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a service to start booking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
