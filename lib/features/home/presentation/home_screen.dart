import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/login_screen.dart';
import '../../auth/provider/auth_provider.dart';
import 'widgets/header.dart';
import 'widgets/promo_banner.dart';
import 'widgets/categories_grid.dart';
import 'widgets/featured_section.dart';
import 'widgets/most_search_interest.dart';
import 'widgets/nearby_offers.dart';
import 'widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.loadCurrentUser();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          HomeHeader(displayName: authProvider.currentUser?.displayName),
          const SizedBox(height: 18),
          const PromoBanner(),
          const SizedBox(height: 20),
          const Text(
            'What do you want to do?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const CategoriesGrid(),
          const SizedBox(height: 18),
          const FeaturedSection(),
          const SizedBox(height: 18),
          const Text(
            'Most Search Interest',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const MostSearchInterest(),
          const SizedBox(height: 18),
          const NearbyOffers(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileContent(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Thông tin cá nhân',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tên: ${user?.displayName ?? 'Không có dữ liệu'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Số điện thoại: ${user?.phone ?? 'Không có'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Vai trò: ${user?.role ?? 'Customer'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Trạng thái: ${user?.isActive == true ? 'Hoạt động' : 'Không hoạt động'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Đăng xuất'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _selectedIndex == 4
              ? _buildProfileContent(authProvider)
              : _buildHomeContent(authProvider),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
