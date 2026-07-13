import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../store/provider/cart_provider.dart';

class HomeNavItem {
  final IconData icon;
  final String label;

  const HomeNavItem({required this.icon, required this.label});
}

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final List<HomeNavItem> items;
  final int? cartIndex;

  const HomeBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onTap,
    required this.items,
    this.cartIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final nav = _navItem(item.icon, item.label, index);
          if (cartIndex != index) return nav;
          return Consumer<CartProvider>(
            builder: (context, provider, child) {
              return Badge(
                isLabelVisible: provider.itemCount > 0,
                label: Text(provider.itemCount.toString()),
                child: nav,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final active = idx == selectedIndex;
    const darkTeal = Color(0xFF00695C);
    return GestureDetector(
      onTap: () => onTap?.call(idx),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? darkTeal : Colors.grey[500]),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? darkTeal : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
