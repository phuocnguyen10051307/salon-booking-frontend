import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_colors.dart';
import '../provider/auth_provider.dart';
import 'new_password_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool isSignupVerification;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isSignupVerification = false,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int signupOtpLength = 6;
  static const int defaultOtpLength = 4;

  late final int otpLength;
  late final List<TextEditingController> controllers;
  late final List<FocusNode> focusNodes;
  Timer? timer;
  int secondsLeft = 159;

  @override
  void initState() {
    super.initState();
    otpLength = widget.isSignupVerification ? signupOtpLength : defaultOtpLength;
    controllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft == 0) return;
      setState(() {
        secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get timerText {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _verify() async {
    final otp = controllers.map((controller) => controller.text).join();
    if (otp.length < otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code.')),
      );
      return;
    }

    if (widget.isSignupVerification) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifySignupOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kích hoạt tài khoản thành công.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP không hợp lệ hoặc đã hết hạn.')),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
    );
  }

  Future<void> _resend() async {
    if (widget.isSignupVerification) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resendSignupOtp(email: widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã gửi lại OTP kích hoạt tài khoản.'
                : 'Không thể gửi lại OTP. Vui lòng thử lại.',
          ),
        ),
      );

      if (!success) return;
    }

    setState(() {
      secondsLeft = 159;
      for (final controller in controllers) {
        controller.clear();
      }
    });
    focusNodes.first.requestFocus();
  }

  Widget _otpBox(int index) {
    final boxWidth = widget.isSignupVerification ? 44.0 : 68.0;
    return SizedBox(
      width: boxWidth,
      height: 48,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF151515),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF0F3F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < focusNodes.length - 1) {
            focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),
              const Text(
                'Email verification,',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF151515),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please type OTP code that we give you',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 104),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(otpLength, _otpBox),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: secondsLeft == 0 ? _resend : null,
                  child: Text(
                    secondsLeft == 0 ? 'Resend' : 'Resend on $timerText',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verify Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
