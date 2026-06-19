import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/service_model.dart';
import '../provider/cart_provider.dart';
import 'cart_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const StoreDetailScreen({super.key, required this.service});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  int _quantity = 1;

  Future<void> _addToCart() async {
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addService(
      widget.service.id,
      quantity: _quantity,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Added to cart' : 'Can not add service. Please try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
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
