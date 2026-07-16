import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../store/data/models/promotion_model.dart';

class PromoBanner extends StatelessWidget {
  final List<PromotionModel> promotions;
  final VoidCallback onExplore;

  const PromoBanner({
    super.key,
    required this.promotions,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 170,
      child: PageView.builder(
        itemCount: promotions.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == promotions.length - 1 ? 0 : 10,
            ),
            child: _PromotionCard(promotion: promotion, onExplore: onExplore),
          );
        },
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onExplore;

  const _PromotionCard({required this.promotion, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7043);
    const cream = Color(0xFFFFF8E1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  promotion.description ?? 'Save on your next salon booking.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 11),
                InkWell(
                  onTap: onExplore,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Explore services',
                      style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: orange,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${promotion.discountPercent}%\nOFF',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
