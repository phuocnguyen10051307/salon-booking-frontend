import 'package:latlong2/latlong.dart';

class RouteSummaryModel {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteSummaryModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteSummaryModel.fromOsrmJson(Map<String, dynamic> json) {
    final routes = json['routes'];
    if (routes is! List || routes.isEmpty) {
      throw Exception('Route not found');
    }

    final firstRoute = Map<String, dynamic>.from(routes.first as Map);
    final geometry = firstRoute['geometry'];
    final coordinates = geometry is Map<String, dynamic> ? geometry['coordinates'] : null;

    if (coordinates is! List) {
      throw Exception('Route geometry not available');
    }

    return RouteSummaryModel(
      points: coordinates
          .whereType<List>()
          .where((coordinate) => coordinate.length >= 2)
          .map(
            (coordinate) => LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            ),
          )
          .toList(growable: false),
      distanceMeters: (firstRoute['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (firstRoute['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}
