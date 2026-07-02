import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/location_api.dart';
import '../data/models/route_summary_model.dart';
import '../data/models/salon_location_model.dart';

class HomeProvider extends ChangeNotifier {
  final LocationApi _locationApi = LocationApi();

  bool isLoading = false;
  bool isRouteLoading = false;
  String? error;
  String? routeError;
  SalonLocationModel? location;
  LatLng? currentPosition;
  List<LatLng> routePoints = const [];
  double? routeDistanceMeters;
  double? routeDurationSeconds;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> fetchLocation() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final primaryLocation = await _locationApi.getLocation();
      location = primaryLocation;

      try {
        final mapLocation = await _locationApi.getMapLocation();
        location = SalonLocationModel(
          id: primaryLocation.id,
          salonName: primaryLocation.salonName,
          address: primaryLocation.address,
          hotline: primaryLocation.hotline,
          openingHours: primaryLocation.openingHours,
          latitude: mapLocation.latitude ?? primaryLocation.latitude,
          longitude: mapLocation.longitude ?? primaryLocation.longitude,
        );
      } catch (_) {
        location = primaryLocation;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }

    if (location?.latitude != null && location?.longitude != null) {
      await fetchRouteToSalon();
    }
  }

  Future<void> fetchRouteToSalon() async {
    final salon = location;
    final lat = salon?.latitude;
    final lng = salon?.longitude;
    if (salon == null || lat == null || lng == null) {
      routeError = 'Salon coordinates are not available';
      routePoints = const [];
      routeDistanceMeters = null;
      routeDurationSeconds = null;
      notifyListeners();
      return;
    }

    isRouteLoading = true;
    routeError = null;
    notifyListeners();

    try {
      final origin = await _locationApi.getCurrentLocation();
      currentPosition = origin;
      final route = await _locationApi.getRoute(
        origin: origin,
        destination: LatLng(lat, lng),
      );
      _applyRoute(route);
    } catch (e) {
      routeError = e.toString();
      routePoints = const [];
      routeDistanceMeters = null;
      routeDurationSeconds = null;
    } finally {
      isRouteLoading = false;
      notifyListeners();
    }
  }

  void _applyRoute(RouteSummaryModel route) {
    routePoints = route.points;
    routeDistanceMeters = route.distanceMeters;
    routeDurationSeconds = route.durationSeconds;
  }
}
