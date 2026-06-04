import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  final String? displayName;

  const HomeHeader({Key? key, this.displayName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkTeal = const Color(0xFF00695C);
    final greetingName = displayName?.isNotEmpty == true
        ? displayName
        : 'there';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $greetingName',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find the service you want, and treat yourself',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(color: darkTeal, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
