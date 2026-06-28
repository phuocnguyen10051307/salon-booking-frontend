import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../admin/presentation/admin_services_tab.dart';
import '../../auth/provider/auth_provider.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../staff/presentation/staff_schedule_tab.dart';
import '../../store/data/models/service_model.dart';
import '../../store/provider/cart_provider.dart';
import '../../store/provider/service_provider.dart';
import '../../store/presentation/cart_screen.dart';
import '../../store/presentation/store_detail_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/categories_grid.dart';
import 'widgets/featured_section.dart';
import 'widgets/header.dart';
import 'widgets/most_search_interest.dart';
import 'widgets/nearby_offers.dart';
import 'widgets/profile_tab.dart';
import 'widgets/promo_banner.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _lastRole;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = _normalizedRole(context.read<AuthProvider>().currentUser?.role);
      if (role == 'CUSTOMER') {
        context.read<ServiceProvider>().fetchServices();
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<HomeNavItem> _itemsForRole(String role) {
    if (role == 'STAFF') {
      return const [
        HomeNavItem(icon: Icons.today_outlined, label: 'Hom nay'),
        HomeNavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
        HomeNavItem(icon: Icons.person_outline, label: 'Profile'),
      ];
    }
    if (role == 'ADMIN') {
      return const [
        HomeNavItem(icon: Icons.spa_outlined, label: 'Services'),
        HomeNavItem(icon: Icons.person_outline, label: 'Profile'),
      ];
    }
    return const [
      HomeNavItem(icon: Icons.home, label: 'Home'),
      HomeNavItem(icon: Icons.explore, label: 'Explore'),
      HomeNavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
      HomeNavItem(icon: Icons.shopping_bag_outlined, label: 'Cart'),
      HomeNavItem(icon: Icons.person_outline, label: 'Profile'),
    ];
  }

  Widget _bodyForRole(String role, AuthProvider authProvider) {
    if (_lastRole != role) {
      _lastRole = role;
      _selectedIndex = 0;
    }

    if (role == 'STAFF') {
      return switch (_selectedIndex) {
        1 => const ChatTab(),
        2 => const ProfileTab(),
        _ => const StaffScheduleTab(),
      };
    }

    if (role == 'ADMIN') {
      return switch (_selectedIndex) {
        1 => const ProfileTab(),
        _ => const AdminServicesTab(),
      };
    }

    return switch (_selectedIndex) {
      1 => const _EmptyCustomerTab(title: 'Explore'),
      2 => const ChatTab(),
      3 => const CartContent(),
      4 => const ProfileTab(),
      _ => _buildCustomerHome(authProvider),
    };
  }

  String _normalizedRole(String? role) {
    final normalized = role?.trim().toUpperCase();
    return normalized == null || normalized.isEmpty ? 'CUSTOMER' : normalized;
  }

  Widget _buildCustomerHome(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          HomeHeader(displayName: authProvider.currentUser?.displayName),
          const SizedBox(height: 14),
          _CustomerSearch(),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = _normalizedRole(authProvider.currentUser?.role);
    final items = _itemsForRole(role);
    final selectedIndex = _selectedIndex >= items.length ? 0 : _selectedIndex;
    if (selectedIndex != _selectedIndex) _selectedIndex = selectedIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
              child: _bodyForRole(role, authProvider),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: HomeBottomNav(
                selectedIndex: _selectedIndex,
                onTap: _onNavTap,
                items: items,
                cartIndex: role == 'CUSTOMER' ? 3 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyCustomerTab extends StatelessWidget {
  final String title;

  const _EmptyCustomerTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _CustomerSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        final results = provider.searchQuery.trim().isEmpty ? <ServiceModel>[] : provider.searchedServices;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search services',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...results.take(4).map((service) => _SearchResultTile(service: service)),
            ],
          ],
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ServiceModel service;

  const _SearchResultTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreDetailScreen(service: service)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.spa_outlined, color: Color(0xFF00695C)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    service.categoryName ?? '${service.durationMinutes} mins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              formatter.format(service.price),
              style: GoogleFonts.poppins(color: const Color(0xFF00695C), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}



