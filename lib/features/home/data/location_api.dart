import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/route_summary_model.dart';
import 'models/salon_location_model.dart';

class LocationApi {
  final Dio _routingDio = Dio(
    BaseOptions(
      baseUrl: 'https://router.project-osrm.org',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<SalonLocationModel> getLocation() async {
    final response = await ApiClient.dio.get(ApiConstants.locations);
    final location = response.data['data']?['location'] ?? response.data['location'];
    return SalonLocationModel.fromJson(Map<String, dynamic>.from(location as Map));
  }

  Future<SalonLocationModel> getMapLocation() async {
    final response = await ApiClient.dio.get(ApiConstants.locationsMap);
    final location = response.data['data']?['location'] ?? response.data['location'];
    return SalonLocationModel.fromJson(Map<String, dynamic>.from(location as Map));
  }

  Future<LatLng> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<RouteSummaryModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await _routingDio.get(
      '/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
      },
    );

    return RouteSummaryModel.fromOsrmJson(Map<String, dynamic>.from(response.data as Map));
  }
}
