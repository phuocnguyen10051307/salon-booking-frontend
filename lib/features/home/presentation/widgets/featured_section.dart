import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedSection extends StatelessWidget {
  const FeaturedSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Salon',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _FeaturedCard(index: index),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final int index;
  const _FeaturedCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final names = [
      'Salon de Elegance',
      'Plush Beauty Lounge',
      'Chic Cuts',
      'Glam Hub',
    ];
    final cats = [
      'Hair, Nails, Facial',
      'Spa, Makeup',
      'Hair, Color',
      'Nails, Waxing',
    ];

    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.network(
                    'https://picsum.photos/seed/feat$index/500/300',
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border, color: Colors.red),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cats[index % cats.length],
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    names[index % names.length],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '123 Main Street, City',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '4.8',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text('(3.1k)', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
