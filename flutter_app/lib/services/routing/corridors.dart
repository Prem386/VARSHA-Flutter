import 'package:latlong2/latlong.dart';
import '../../models/route.dart';
import 'hazard_proximity.dart';

class CorridorConfig {
  final String id;
  final String name;
  final String primaryLabel;
  final String alternativeLabel;
  final String viaName;
  final LatLng viaWaypoint;
  final bool Function(LatLng origin, LatLng destination) matches;

  const CorridorConfig({
    required this.id,
    required this.name,
    required this.primaryLabel,
    required this.alternativeLabel,
    required this.viaName,
    required this.viaWaypoint,
    required this.matches,
  });
}

/// Known Navi Mumbai parallel corridors for route alternative generation.
final List<CorridorConfig> naviMumbaiCorridors = [
  CorridorConfig(
    id: 'vashi-belapur-palm-beach',
    name: 'Vashi – Belapur Arterial Corridor',
    primaryLabel: 'via Sion-Panvel Hwy',
    alternativeLabel: 'via Palm Beach Rd',
    viaName: 'Palm Beach Road Central',
    viaWaypoint: const LatLng(19.0410, 73.0135),
    matches: (origin, destination) {
      final origLat = origin.latitude;
      final origLng = origin.longitude;
      final destLat = destination.latitude;
      final destLng = destination.longitude;

      final isOriginNorth = origLat >= 19.055 && origLat <= 19.090 && origLng >= 72.980 && origLng <= 73.030;
      final isDestSouth = destLat >= 19.005 && destLat <= 19.045 && destLng >= 73.005 && destLng <= 73.075;

      final isOriginSouth = origLat >= 19.005 && origLat <= 19.045 && origLng >= 73.005 && origLng <= 73.075;
      final isDestNorth = destLat >= 19.055 && destLat <= 19.090 && destLng >= 72.980 && destLng <= 73.030;

      return (isOriginNorth && isDestSouth) || (isOriginSouth && isDestNorth);
    },
  ),
  CorridorConfig(
    id: 'airoli-vashi-west-bypass',
    name: 'Airoli – Vashi Trans-Harbour Corridor',
    primaryLabel: 'via Thane-Belapur Rd',
    alternativeLabel: 'via West Bypass',
    viaName: 'Kopar Khairane West Bypass',
    viaWaypoint: const LatLng(19.1025, 73.0035),
    matches: (origin, destination) {
      final origLat = origin.latitude;
      final origLng = origin.longitude;
      final destLat = destination.latitude;
      final destLng = destination.longitude;

      final isOriginUpperNorth = origLat >= 19.120 && origLat <= 19.170 && origLng >= 72.985 && origLng <= 73.015;
      final isDestLower = destLat >= 19.055 && destLat <= 19.085 && destLng >= 72.990 && destLng <= 73.030;

      final isOriginLower = origLat >= 19.055 && origLat <= 19.085 && origLng >= 72.990 && origLng <= 73.030;
      final isDestUpperNorth = destLat >= 19.120 && destLat <= 19.170 && destLng >= 72.985 && destLng <= 73.015;

      return (isOriginUpperNorth && isDestLower) || (isOriginLower && isDestUpperNorth);
    },
  ),
];

CorridorConfig? findMatchingCorridor(LatLng origin, LatLng destination) {
  try {
    return naviMumbaiCorridors.firstWhere((c) => c.matches(origin, destination));
  } catch (_) {
    return null;
  }
}

/// Verifies that route start and end are within tolerance of requested endpoints.
bool validateRouteEndpoints(
  RoadRoute route,
  LatLng origin,
  LatLng destination, {
  double toleranceMeters = 500,
}) {
  if (route.coordinates.length < 2) return false;

  final first = route.coordinates.first;
  final last = route.coordinates.last;

  final startDist = calculatePointToPointDistanceMeters(first, origin);
  final endDist = calculatePointToPointDistanceMeters(last, destination);

  return startDist <= toleranceMeters && endDist <= toleranceMeters;
}

/// Checks whether two routes represent distinct physical paths.
bool isRouteDistinct(RoadRoute routeA, RoadRoute routeB) {
  if (routeA.coordinates.length < 2 || routeB.coordinates.length < 2) return false;

  final distDiff = (routeA.distanceMeters - routeB.distanceMeters).abs();
  final durDiff = (routeA.durationSeconds - routeB.durationSeconds).abs();

  if (distDiff > 250 || durDiff > 45) {
    if (routeA.coordinates.length == routeB.coordinates.length) {
      bool coordsMatch = true;
      for (int i = 0; i < routeA.coordinates.length; i++) {
        final pA = routeA.coordinates[i];
        final pB = routeB.coordinates[i];
        if ((pA.latitude - pB.latitude).abs() >= 0.00001 ||
            (pA.longitude - pB.longitude).abs() >= 0.00001) {
          coordsMatch = false;
          break;
        }
      }
      if (coordsMatch) return false;
    }
    return true;
  }

  // Midpoint divergence check
  final midA = routeA.coordinates[routeA.coordinates.length ~/ 2];
  final midB = routeB.coordinates[routeB.coordinates.length ~/ 2];
  final midDist = calculatePointToPointDistanceMeters(midA, midB);

  return midDist > 75;
}
