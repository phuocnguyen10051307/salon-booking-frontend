import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lightTeal = const Color(0xFFE0F2F1);
    final darkTeal = const Color(0xFF00695C);
    final items = [
      'Haircut',
      'Nails',
      'Facial',
      'Coloring',
      'Spa',
      'Waxing',
      'Makeup',
      'Massage',
    ];
    final icons = [
      Icons.content_cut,
      Icons.brush,
      Icons.spa,
      Icons.color_lens,
      Icons.hot_tub,
      Icons.remove,
      Icons.face,
      Icons.self_improvement,
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: List.generate(items.length, (index) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: lightTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(icons[index], color: darkTeal, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              items[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}
