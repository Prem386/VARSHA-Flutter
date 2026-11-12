import 'package:latlong2/latlong.dart';

enum RouteEndpointType {
  origin,
  destination;

  String get label => this == RouteEndpointType.origin ? 'Origin' : 'Destination';
  String get tagLetter => this == RouteEndpointType.origin ? 'A' : 'B';
}

enum RouteStatus { idle, loading, success, error }

/// Represents a pinned or searched point for origin/destination.
class SelectedLocation {
  final String label;
  final LatLng coordinates;
  final String? landmarkId;
  final String? placeId;
  final String? formattedAddress;
  final String? source; // 'geoapify' | 'curated' | 'map'
  final String? category;
  final String? locality;

  const SelectedLocation({
    required this.label,
    required this.coordinates,
    this.landmarkId,
    this.placeId,
    this.formattedAddress,
    this.source,
    this.category,
    this.locality,
  });

  SelectedLocation copyWith({
    String? label,
    LatLng? coordinates,
    String? landmarkId,
    String? placeId,
    String? formattedAddress,
    String? source,
    String? category,
    String? locality,
  }) {
    return SelectedLocation(
      label: label ?? this.label,
      coordinates: coordinates ?? this.coordinates,
      landmarkId: landmarkId ?? this.landmarkId,
      placeId: placeId ?? this.placeId,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      source: source ?? this.source,
      category: category ?? this.category,
      locality: locality ?? this.locality,
    );
  }
}

/// Validated road route from OSRM driving service.
class RoadRoute {
  final String id;
  String? label;
  final List<LatLng> coordinates;
  final double distanceMeters;
  final double durationSeconds;
  String engineEstimateNotice;
  String? corridorName;
  bool isCorridorAlternative;

  RoadRoute({
    required this.id,
    this.label,
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.engineEstimateNotice,
    this.corridorName,
    this.isCorridorAlternative = false,
  });

  double get distanceKm => distanceMeters / 1000.0;
  double get durationMinutes => durationSeconds / 60.0;
}

/// Distance formatting helper matching React osrmService.ts.
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Duration formatting helper matching React osrmService.ts.
String formatDuration(double seconds) {
  final totalMinutes = (seconds / 60).round();
  if (totalMinutes < 60) {
    final m = totalMinutes < 1 ? 1 : totalMinutes;
    return '$m min${m == 1 ? '' : 's'}';
  }
  final hours = totalMinutes ~/ 60;
  final remainingMins = totalMinutes % 60;
  if (remainingMins == 0) {
    return '$hours hr${hours == 1 ? '' : 's'}';
  }
  return '$hours hr $remainingMins min';
}
