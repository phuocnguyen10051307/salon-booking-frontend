import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _token = prefs.getString('token');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập thành công')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Đăng nhập thành công',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_token != null && _token!.isNotEmpty)
                Text('Token: $_token', textAlign: TextAlign.center)
              else
                const Text(
                  'Không tìm thấy token trong SharedPreferences.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
