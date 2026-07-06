import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../store/presentation/store_list_screen.dart';

class MostSearchInterest extends StatelessWidget {
  const MostSearchInterest({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTeal = const Color(0xFFE0F2F1);
    final darkTeal = const Color(0xFF00695C);
    final items = [
      'Haircut',
      'Facial',
      'Nails',
      'Coloring',
      'Hair Care',
      'Makeup',
      'Massage',
    ];
    final icons = [
      Icons.content_cut,
      Icons.spa,
      Icons.brush,
      Icons.color_lens,
      Icons.hot_tub,
      Icons.face,
      Icons.self_improvement,
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Material(
          color: lightTeal,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreListScreen(categoryName: items[index]),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icons[index], color: darkTeal, size: 18),
                  const SizedBox(width: 8),
                  Text(items[index], style: GoogleFonts.poppins(color: darkTeal)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
