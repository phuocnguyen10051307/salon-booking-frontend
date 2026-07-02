import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/home/provider/home_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/store/provider/cart_provider.dart';
import 'features/store/provider/service_provider.dart';

Future<void> testConnection() async {
  print('=== START TEST ===');

  final dio = Dio(
    BaseOptions(
      baseUrl: kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  print('=== BEFORE REQUEST ===');

  try {
    final response = await dio.get('/v1/status');

    print('=== SUCCESS ===');
    print(response.data);
  } on DioException catch (e) {
    print('=== DIO ERROR ===');
    print(e.type);
    print(e.message);
  } catch (e) {
    print('=== OTHER ERROR ===');
    print(e);
  }

  print('=== END TEST ===');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: const SplashScreen());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasToken = await authProvider.restoreSession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasToken ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
