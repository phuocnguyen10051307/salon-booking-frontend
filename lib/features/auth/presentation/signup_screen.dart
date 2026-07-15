import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/auth_validators.dart';
import '../provider/auth_provider.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Tạo tài khoản',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng điền đầy đủ thông tin để tiếp tục.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: fullNameController,
                  hint: 'Họ và tên',
                  icon: Icons.person,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.fullName,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: phoneController,
                  hint: 'Số điện thoại',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.phone,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: emailController,
                  hint: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: passwordController,
                  hint: 'Mật khẩu',
                  icon: Icons.lock,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: confirmPasswordController,
                  hint: 'Nhập lại mật khẩu',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => AuthValidators.confirmPassword(
                    value,
                    passwordController.text,
                  ),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Đăng ký',
                  onPressed: () async {
                    final isValid = _formKey.currentState?.validate() ?? false;
                    if (!isValid) return;

                    final fullName = fullNameController.text.trim();
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    final success = await authProvider.signup(
                      fullName: fullName,
                      phone: phone,
                      email: email,
                      password: password,
                    );

                    if (!mounted) return;

                    if (success) {
                      _showMessage('Đăng ký thành công. Vui lòng kiểm tra email.');
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmailVerificationScreen(
                            email: email,
                            isSignupVerification: true,
                          ),
                        ),
                      );
                    } else {
                      _showMessage(
                        authProvider.errorMessage ??
                            'Đăng ký thất bại. Vui lòng thử lại.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
