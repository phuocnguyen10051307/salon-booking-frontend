import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFFF7043);
    final cream = const Color(0xFFFFF8E1);

    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://picsum.photos/800/400?grayscale&blur=2',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.25),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Look more beautiful and save more discount',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Get offer now!',
                            style: TextStyle(
                              color: orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'Up to\n50%',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
