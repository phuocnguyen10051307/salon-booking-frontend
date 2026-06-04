import 'package:flutter/material.dart';

class SalonYouFollow extends StatelessWidget {
  const SalonYouFollow({super.key});

  @override
  Widget build(BuildContext context) {
    final avatars = List.generate(
      8,
      (i) => 'https://picsum.photos/seed/salon$i/200/200',
    );

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: avatars.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.shade100, width: 2),
            ),
            child: ClipOval(
              child: Image.network(avatars[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
