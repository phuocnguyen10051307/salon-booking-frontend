import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../admin/presentation/admin_services_tab.dart';
import '../../auth/provider/auth_provider.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../staff/presentation/staff_schedule_tab.dart';
import '../../store/data/models/service_model.dart';
import '../../store/presentation/cart_screen.dart';
import '../../store/presentation/store_detail_screen.dart';
import '../../store/provider/cart_provider.dart';
import '../../store/provider/service_provider.dart';
import '../../store/provider/promotion_provider.dart';
import '../data/models/salon_location_model.dart';
import '../provider/home_provider.dart';
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
      final role = _normalizedRole(
        context.read<AuthProvider>().currentUser?.role,
      );
      if (role == 'CUSTOMER') {
        context.read<HomeProvider>().fetchLocation();
        context.read<ServiceProvider>().fetchServices();
        context.read<CartProvider>().fetchCart();
        context.read<PromotionProvider>().fetchActivePromotions();
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
      1 => const _CustomerExploreTab(),
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
          Consumer<PromotionProvider>(
            builder: (context, provider, child) {
              if (provider.promotions.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  PromoBanner(
                    promotions: provider.promotions,
                    onExplore: () => _onNavTap(1),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
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

class _CustomerExploreTab extends StatelessWidget {
  const _CustomerExploreTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final location = provider.location;

        return RefreshIndicator(
          onRefresh: provider.fetchLocation,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 16),
              Text(
                'Explore',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See the salon, check your ETA, and start navigation when you are ready.',
                style: GoogleFonts.openSans(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (provider.isLoading && location == null)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.error != null && location == null)
                const _ExploreMessageCard(
                  title: 'Could not load location',
                  description: 'Please pull down to try again.',
                  icon: Icons.location_off_outlined,
                )
              else if (location == null)
                const _ExploreMessageCard(
                  title: 'Location not available',
                  description: 'Salon address has not been set yet.',
                  icon: Icons.place_outlined,
                )
              else ...[
                _ExploreHeroCard(location: location),
                const SizedBox(height: 16),
                if (location.latitude != null &&
                    location.longitude != null) ...[
                  _ExploreEtaCard(provider: provider),
                  const SizedBox(height: 16),
                  _ExploreMapCard(location: location),
                  const SizedBox(height: 16),
                ],
                if (provider.routeError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ExploreMessageCard(
                      title: 'Unable to estimate route',
                      description: provider.routeError!,
                      icon: Icons.route_outlined,
                    ),
                  ),
                _ExploreInfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Hotline',
                  value: location.hotline ?? 'Updating',
                ),
                const SizedBox(height: 12),
                _ExploreInfoTile(
                  icon: Icons.access_time_outlined,
                  title: 'Opening hours',
                  value: location.openingHours ?? 'Updating',
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}

class _ExploreHeroCard extends StatelessWidget {
  final SalonLocationModel location;

  const _ExploreHeroCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Main salon',
              style: GoogleFonts.openSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            location.salonName.isEmpty ? 'Salon Location' : location.salonName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreEtaCard extends StatelessWidget {
  final HomeProvider provider;

  const _ExploreEtaCard({required this.provider});

  Future<void> _startNavigation(BuildContext context) async {
    final location = provider.location;
    final lat = location?.latitude;
    final lng = location?.longitude;
    if (lat == null || lng == null) return;

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    final opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication) ||
        await launchUrl(uri, mode: LaunchMode.platformDefault) ||
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot open navigation right now.')),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '--';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return remainMinutes == 0 ? '$hours h' : '$hours h $remainMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final hasEta =
        provider.routeDurationSeconds != null &&
        provider.routeDistanceMeters != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trip estimate',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: provider.isRouteLoading
                    ? null
                    : provider.fetchRouteToSalon,
                icon: provider.isRouteLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined, size: 18),
                label: Text(
                  provider.isRouteLoading ? 'Updating' : 'Refresh ETA',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EtaMetric(
                  label: 'Drive time',
                  value: _formatDuration(provider.routeDurationSeconds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EtaMetric(
                  label: 'Distance',
                  value: _formatDistance(provider.routeDistanceMeters),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasEta ? () => _startNavigation(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined),
              label: Text(
                hasEta ? 'Start' : 'Waiting for route',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaMetric extends StatelessWidget {
  final String label;
  final String value;

  const _EtaMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreMapCard extends StatelessWidget {
  final SalonLocationModel location;

  const _ExploreMapCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final lat = location.latitude;
    final lng = location.longitude;
    if (lat == null || lng == null) return const SizedBox.shrink();

    final salonPoint = LatLng(lat, lng);
    final currentPoint = provider.currentPosition;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salon and your route',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 380,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: currentPoint ?? salonPoint,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.salon_booking_',
                    ),
                    if (provider.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: provider.routePoints,
                            strokeWidth: 5,
                            color: const Color(0xFF0F766E),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (currentPoint != null)
                          Marker(
                            point: currentPoint,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        Marker(
                          point: salonPoint,
                          width: 52,
                          height: 52,
                          child: const Icon(
                            Icons.location_on,
                            size: 44,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'OpenStreetMap',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ExploreInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7ECE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreMessageCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _ExploreMessageCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7ECE8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF0F766E)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.openSans(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CustomerSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        final results = provider.searchQuery.trim().isEmpty
            ? <ServiceModel>[]
            : provider.searchedServices;
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
              ...results
                  .take(4)
                  .map((service) => _SearchResultTile(service: service)),
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
                    style: GoogleFonts.openSans(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatter.format(service.price),
              style: GoogleFonts.poppins(
                color: const Color(0xFF00695C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
