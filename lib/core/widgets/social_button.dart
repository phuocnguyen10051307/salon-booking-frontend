import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

class SocialButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Text(
          "G",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        label: const Text(
          "Sign In with Google",
          style: TextStyle(fontSize: 18),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(40),
          ),
        ),
      ),
    );
  }
  }