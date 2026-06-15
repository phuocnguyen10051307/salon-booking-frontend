import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNav({Key? key, this.selectedIndex = 0, this.onTap})
    : super(key: key);

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
          Stack(
            children: [
              _navItem(Icons.mail_outline, 3),
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
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
