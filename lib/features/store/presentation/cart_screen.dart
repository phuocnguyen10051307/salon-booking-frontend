import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/billing_model.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/stylist_model.dart';
import '../provider/cart_provider.dart';
import 'billing_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6FBFA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: CartContent(embedded: false),
        ),
      ),
    );
  }
}

class CartContent extends StatefulWidget {
  final bool embedded;

  const CartContent({super.key, this.embedded = true});

  @override
  State<CartContent> createState() => _CartContentState();
}

class _CartContentState extends State<CartContent> {
  final Set<String> _selectedItemIds = <String>{};
  String _selectionSignature = '';
  String _billingFilter = 'UNPAID';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CartProvider>();
      await provider.fetchCart();
      await provider.fetchBillings();
    });
  }

  Future<void> _refreshAll() async {
    final provider = context.read<CartProvider>();
    await provider.fetchCart();
    await provider.fetchBillings();
  }

  void _syncSelection(List<CartItemModel> items) {
    final nextIds = items.map((item) => item.id).toList()..sort();
    final nextSignature = nextIds.join('|');

    if (_selectionSignature == nextSignature) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectionSignature = nextSignature;
        _selectedItemIds
          ..clear()
          ..addAll(nextIds);
      });
    });
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  List<CartItemModel> _selectedItems(List<CartItemModel> items) {
    return items.where((item) => _selectedItemIds.contains(item.id)).toList();
  }

  void _openCheckout(List<CartItemModel> items) {
    if (items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutSelectionScreen(items: items)),
    );
  }

  void _openBilling(BillingModel billing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillingScreen(billing: billing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

    return Consumer<CartProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.cart.items.isEmpty && provider.billings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.cart.items.isEmpty && provider.billings.isEmpty) {
          return Center(
            child: _RequestErrorCard(
              message: provider.error!,
              onRetry: _refreshAll,
            ),
          );
        }

        final items = provider.cart.items;
        _syncSelection(items);
        final selectedItems = _selectedItems(items);
        final selectedCount = selectedItems.fold<int>(0, (sum, item) => sum + item.quantity);
        final selectedSubtotal = selectedItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
        final unpaidBillings = provider.billings.where((item) => item.status == 'UNPAID').toList();
        final paidBillings = provider.billings.where((item) => item.status == 'PAID').toList();
        final visibleBillings = _billingFilter == 'PAID' ? paidBillings : unpaidBillings;

        return RefreshIndicator(
          onRefresh: _refreshAll,
          color: const Color(0xFF00695C),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 12, 0, widget.embedded ? 100 : 24),
            children: [
              _CartHero(
                itemCount: provider.cart.itemCount,
                subtotal: currencyFormatter.format(provider.cart.subtotal),
                isEmbedded: widget.embedded,
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const _EmptyCart()
              else ...[
                Text(
                  'Choose services to checkout',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap one service to book it now, or tick several services then continue to checkout.',
                  style: GoogleFonts.openSans(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => _CartItemTile(
                    item: item,
                    currencyFormatter: currencyFormatter,
                    isSelected: _selectedItemIds.contains(item.id),
                    onTap: () => _openCheckout([item]),
                    onSelected: () => _toggleSelection(item.id),
                    onMinus: () => provider.updateQuantity(item.id, item.quantity - 1),
                    onPlus: () => provider.updateQuantity(item.id, item.quantity + 1),
                    onRemove: () => provider.removeItem(item.id),
                  ),
                ),
                const SizedBox(height: 8),
                _SelectionSummary(
                  selectedServices: selectedItems.length,
                  selectedCount: selectedCount,
                  subtotal: currencyFormatter.format(selectedSubtotal),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _TotalRow(label: 'Cart subtotal', value: currencyFormatter.format(provider.cart.subtotal)),
                      const SizedBox(height: 10),
                      _TotalRow(label: 'Selected subtotal', value: currencyFormatter.format(selectedSubtotal)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      final success = await provider.clearCart();
                                      if (!context.mounted || success) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(provider.error ?? 'Can not clear cart.')),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                minimumSize: const Size.fromHeight(50),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text('Clear cart', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.isLoading || selectedItems.isEmpty ? null : () => _openCheckout(selectedItems),
                              icon: const Icon(Icons.receipt_long),
                              label: Text(
                                'Checkout (${selectedItems.length})',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00695C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _BillingSection(
                unpaidCount: unpaidBillings.length,
                paidCount: paidBillings.length,
                selectedFilter: _billingFilter,
                billings: visibleBillings,
                currencyFormatter: currencyFormatter,
                onFilterChanged: (value) => setState(() => _billingFilter = value),
                onOpenBilling: _openBilling,
              ),
            ],
          ),
        );
      },
    );
  }
}

class CheckoutSelectionScreen extends StatefulWidget {
  final List<CartItemModel> items;

  const CheckoutSelectionScreen({super.key, required this.items});

  @override
  State<CheckoutSelectionScreen> createState() => _CheckoutSelectionScreenState();
}

class _CheckoutSelectionScreenState extends State<CheckoutSelectionScreen> {
  final TextEditingController _noteController = TextEditingController();
  DateTime _bookingDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _bookingTime = const TimeOfDay(hour: 9, minute: 0);
  String? _selectedStylistId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serviceIds = widget.items
          .map((item) => item.serviceId ?? item.service?.id ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      context.read<CartProvider>().fetchStylistsForServices(serviceIds);
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
    final picked = await showTimePicker(context: context, initialTime: _bookingTime);
    if (picked != null) setState(() => _bookingTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _checkout() async {
    final provider = context.read<CartProvider>();
    if (provider.stylists.isNotEmpty && (_selectedStylistId == null || _selectedStylistId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a stylist before checkout.')),
      );
      return;
    }

    final billing = await provider.checkout(
      bookingDate: _bookingDate,
      bookingTime: _formatTime(_bookingTime),
      stylistId: _selectedStylistId,
      selectedItemIds: widget.items.map((item) => item.id).toList(),
      note: _noteController.text,
    );

    if (!mounted) return;
    if (billing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Can not checkout. Please try again.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BillingScreen(billing: billing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final subtotal = widget.items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final totalQuantity = widget.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FBFA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Checkout details',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SelectionSummary(
                selectedServices: widget.items.length,
                selectedCount: totalQuantity,
                subtotal: currencyFormatter.format(subtotal),
              ),
              const SizedBox(height: 12),
              ...widget.items.map(
                (item) => _CheckoutItemTile(item: item, currencyFormatter: currencyFormatter),
              ),
              const SizedBox(height: 12),
              _StylistSection(
                stylists: provider.stylists,
                selectedStylistId: _selectedStylistId,
                isLoading: provider.isLoading && provider.stylists.isEmpty,
                onChanged: (value) => setState(() => _selectedStylistId = value),
              ),
              const SizedBox(height: 12),
              _CheckoutSection(
                dateLabel: dateFormatter.format(_bookingDate),
                timeLabel: _bookingTime.format(context),
                          noteController: _noteController,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _checkout,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.event_available_outlined),
                label: Text('Confirm checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartHero extends StatelessWidget {
  final int itemCount;
  final String subtotal;
  final bool isEmbedded;

  const _CartHero({required this.itemCount, required this.subtotal, required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEmbedded)
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12)),
                ),
                const SizedBox(width: 12),
                Text(
                  'My cart',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            Text(
              'My cart',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          Text(
            'Pick a service for quick checkout, or combine several services before confirming your booking.',
            style: GoogleFonts.openSans(color: Colors.white.withOpacity(0.9), height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Items', value: '$itemCount')),
              const SizedBox(width: 12),
              Expanded(child: _HeroStat(label: 'Subtotal', value: subtotal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.openSans(color: Colors.white.withOpacity(0.86), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final NumberFormat currencyFormatter;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelected;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.currencyFormatter,
    required this.isSelected,
    required this.onTap,
    required this.onSelected,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? const Color(0xFF26A69A) : Colors.transparent, width: 1.4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onSelected,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00695C) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00695C)),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(borderRadius: BorderRadius.circular(18), child: _Thumb(imageUrl: service?.imageUrl)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service?.name ?? 'Service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service?.durationMinutes ?? 0} mins',
                    style: GoogleFonts.openSans(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(service?.price ?? 0),
                    style: GoogleFonts.poppins(color: const Color(0xFF00695C), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SmallIconButton(icon: Icons.remove, onPressed: onMinus),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(item.quantity.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      _SmallIconButton(icon: Icons.add, onPressed: onPlus),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                Text(
                  currencyFormatter.format(item.lineTotal),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'Book now',
                  style: GoogleFonts.openSans(color: const Color(0xFF00695C), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  final CartItemModel item;
  final NumberFormat currencyFormatter;

  const _CheckoutItemTile({required this.item, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(18), child: _Thumb(imageUrl: service?.imageUrl)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service?.name ?? 'Service',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${currencyFormatter.format(service?.price ?? 0)}',
                  style: GoogleFonts.openSans(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(item.lineTotal),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF00695C)),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final int selectedServices;
  final int selectedCount;
  final String subtotal;

  const _SelectionSummary({required this.selectedServices, required this.selectedCount, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected cart information',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _SummaryStat(label: 'Services', value: '$selectedServices')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryStat(label: 'Quantity', value: '$selectedCount')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryStat(label: 'Subtotal', value: subtotal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF7FAFA), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.openSans(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF00695C)),
          ),
        ],
      ),
    );
  }
}

class _BillingSection extends StatelessWidget {
  final int unpaidCount;
  final int paidCount;
  final String selectedFilter;
  final List<BillingModel> billings;
  final NumberFormat currencyFormatter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<BillingModel> onOpenBilling;

  const _BillingSection({
    required this.unpaidCount,
    required this.paidCount,
    required this.selectedFilter,
    required this.billings,
    required this.currencyFormatter,
    required this.onFilterChanged,
    required this.onOpenBilling,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Billing status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Switch between unpaid and paid bills, then tap a bill to view its details.',
            style: GoogleFonts.openSans(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChip(
                label: 'Unpaid ($unpaidCount)',
                isSelected: selectedFilter == 'UNPAID',
                onTap: () => onFilterChanged('UNPAID'),
              ),
              _FilterChip(
                label: 'Paid ($paidCount)',
                isSelected: selectedFilter == 'PAID',
                onTap: () => onFilterChanged('PAID'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (billings.isEmpty)
            Text(
              selectedFilter == 'UNPAID' ? 'No unpaid bills yet.' : 'No paid bills yet.',
              style: GoogleFonts.openSans(color: Colors.grey.shade600),
            )
          else
            ...billings.map(
              (billing) => _BillingTile(
                billing: billing,
                currencyFormatter: currencyFormatter,
                onTap: () => onOpenBilling(billing),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF00695C),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFF1F6F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _BillingTile extends StatelessWidget {
  final BillingModel billing;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  const _BillingTile({required this.billing, required this.currencyFormatter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = billing.status == 'PAID';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPaid ? const Color(0xFFCBEBDD) : const Color(0xFFF3DCA4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPaid ? const Color(0xFFE3F6EE) : const Color(0xFFFFF3D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.pending_actions,
                color: isPaid ? const Color(0xFF00695C) : const Color(0xFF9A6500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(billing.code, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    billing.status == 'PAID' ? 'Method: ${billing.paymentMethod}' : 'Payment: Staff will collect after service',
                    style: GoogleFonts.openSans(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(billing.totalAmount),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00695C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: billing.status),
                const SizedBox(height: 10),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

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

class _StylistSection extends StatelessWidget {
  final List<StylistModel> stylists;
  final String? selectedStylistId;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const _StylistSection({
    required this.stylists,
    required this.selectedStylistId,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose stylist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Choose the person who will handle this booking. You can set the date and time right below.',
            style: GoogleFonts.openSans(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (stylists.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF2D7A1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline, color: Color(0xFF9A6500)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No active stylist is available right now. Please try another service or come back later.',
                      style: GoogleFonts.openSans(color: const Color(0xFF9A6500), height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFF00695C), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stylists.length} stylist available for this booking.',
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF00695C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedStylistId,
              decoration: InputDecoration(
                labelText: 'Stylist',
                hintText: 'Select a stylist',
                filled: true,
                fillColor: const Color(0xFFF7FAFA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: stylists
                  .map(
                    (stylist) => DropdownMenuItem<String>(
                      value: stylist.id,
                      child: Text(stylist.name),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final String dateLabel;
  final String timeLabel;
  final TextEditingController noteController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _CheckoutSection({
    required this.dateLabel,
    required this.timeLabel,
    required this.noteController,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Choose date, time, stylist, and any note before creating the booking.',
            style: GoogleFonts.openSans(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _PickerButton(icon: Icons.calendar_today, label: dateLabel, onPressed: onPickDate)),
              const SizedBox(width: 10),
              Expanded(child: _PickerButton(icon: Icons.schedule, label: timeLabel, onPressed: onPickTime)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Note for the salon',
              filled: true,
              fillColor: const Color(0xFFF7FAFA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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

  const _PickerButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700))),
        Text(
          value,
          style: GoogleFonts.poppins(color: const Color(0xFF00695C), fontSize: 18, fontWeight: FontWeight.w800),
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
      width: 34,
      height: 34,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFE6F4F1),
          foregroundColor: const Color(0xFF00695C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      width: 76,
      height: 76,
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
      width: 76,
      height: 76,
      color: const Color(0xFFE7F3F0),
      child: const Icon(Icons.spa, color: Color(0xFF00695C)),
    );
  }
}

class _RequestErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _RequestErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Can not load cart',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
            icon: const Icon(Icons.refresh),
            label: Text('Try again', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE6F4F1), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF00695C), size: 36),
          ),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Add a service from the home catalog to start building your booking.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}




