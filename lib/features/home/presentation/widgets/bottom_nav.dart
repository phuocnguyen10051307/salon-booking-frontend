import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../store/provider/cart_provider.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNav({super.key, this.selectedIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.home, 0),
          _navItem(Icons.explore, 1),
          _navItem(Icons.calendar_today, 2),
          Consumer<CartProvider>(
            builder: (context, provider, child) {
              return Badge(
                isLabelVisible: provider.itemCount > 0,
                label: Text(provider.itemCount.toString()),
                child: _navItem(Icons.shopping_bag_outlined, 3),
              );
            },
          ),
          _navItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int idx) {
    final active = idx == selectedIndex;
    final darkTeal = const Color(0xFF00695C);
    return GestureDetector(
      onTap: () => onTap?.call(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? darkTeal : Colors.grey[500]),
          const SizedBox(height: 4),
          if (active)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: darkTeal,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
