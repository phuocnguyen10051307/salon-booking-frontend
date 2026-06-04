import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  State<CustomTextField> createState() =>
      _CustomTextFieldState();
}

class _CustomTextFieldState
    extends State<CustomTextField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText:
      widget.isPassword ? obscure : false,
      decoration: InputDecoration(
        hintText: widget.hint,

        prefixIcon: Icon(
          widget.icon,
          color: widget.isPassword
              ? Colors.grey
              : AppColors.primary,
        ),

        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              obscure = !obscure;
            });
          },
        )
            : null,

        filled: widget.isPassword,
        fillColor: Colors.grey.shade100,

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(40),
          borderSide: BorderSide(
            color: widget.isPassword
                ? Colors.transparent
                : AppColors.primary,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(40),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}