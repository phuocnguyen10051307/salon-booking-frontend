import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../home/presentation/home_screen.dart';
import '../data/models/service_model.dart';
import '../data/service_api.dart';
import '../provider/cart_provider.dart';
import 'cart_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const StoreDetailScreen({super.key, required this.service});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final ServiceApi _serviceApi = ServiceApi();

  late ServiceModel _service;
  int _quantity = 1;
  bool _isRefreshing = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _refreshServiceDetail();
  }

  Future<void> _refreshServiceDetail() async {
    setState(() {
      _isRefreshing = true;
      _detailError = null;
    });

    try {
      final latest = await _serviceApi.getServiceById(widget.service.id);
      if (!mounted) return;
      setState(() => _service = latest);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detailError = 'Can not refresh service details right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _addToCart() async {
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addService(
      _service.id,
      quantity: _quantity,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cartProvider.error ?? 'Session expired. Please log in again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
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
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Consumer<CartProvider>(
              builder: (context, provider, child) {
                return Badge(
                  isLabelVisible: provider.itemCount > 0,
                  label: Text(provider.itemCount.toString()),
                  child: const Icon(Icons.shopping_bag_outlined),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ServiceImage(imageUrl: service.imageUrl),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.categoryName ?? 'Salon service',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(service.price),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00695C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: '${service.durationMinutes} mins',
                  ),
                  _InfoChip(
                    icon: Icons.spa_outlined,
                    label: service.categoryName ?? 'Service',
                  ),
                ],
              ),
              if (_detailError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _detailError!,
                  style: GoogleFonts.openSans(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (service.description ?? '').isNotEmpty
                    ? service.description!
                    : 'Relax and enjoy this service with our salon team.',
                style: GoogleFonts.poppins(
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Text(
                        _quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onPressed: () => setState(() => _quantity++),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: cartProvider.isLoading ? null : _addToCart,
                      icon: cartProvider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(
                        'Add to cart',
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
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;

  const _ServiceImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    if (url.isEmpty) return const _ImageFallback();

    return Image.network(
      url,
      height: 230,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      color: const Color(0xFFE7F3F0),
      child: const Icon(Icons.spa, color: Color(0xFF00695C), size: 64),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00695C)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}





