import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MostSearchInterest extends StatelessWidget {
  const MostSearchInterest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lightTeal = const Color(0xFFE0F2F1);
    final darkTeal = const Color(0xFF00695C);
    final items = [
      'Haircut',
      'Facial',
      'Nails',
      'Coloring',
      'Spa',
      'Makeup',
      'Massage',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: lightTeal,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: darkTeal, size: 18),
              const SizedBox(width: 8),
              Text(items[index], style: GoogleFonts.poppins(color: darkTeal)),
            ],
          ),
        ),
      ),
    );
  }
}
