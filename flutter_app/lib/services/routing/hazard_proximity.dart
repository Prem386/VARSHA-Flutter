import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../models/hazard.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';

const double defaultProximityThresholdMeters = 100.0;
const double earthRadiusMeters = 6371000.0;
const double degToRad = math.pi / 180.0;

/// Checks if LatLng is within valid geographic boundaries and is finite.
bool isValidCoordinate(LatLng? coord) {
  if (coord == null) return false;
  return coord.latitude.isFinite &&
      coord.longitude.isFinite &&
      coord.latitude >= -90.0 &&
      coord.latitude <= 90.0 &&
      coord.longitude >= -180.0 &&
      coord.longitude <= 180.0;
}

/// Point-to-point distance in meters using equirectangular projection centered at segment midpoint.
double calculatePointToPointDistanceMeters(LatLng pointA, LatLng pointB) {
  final midLat = ((pointA.latitude + pointB.latitude) / 2.0) * degToRad;
  final dx = (pointB.longitude - pointA.longitude) *
      degToRad *
      earthRadiusMeters *
      math.cos(midLat);
  final dy = (pointB.latitude - pointA.latitude) * degToRad * earthRadiusMeters;
  return math.sqrt(dx * dx + dy * dy);
}

/// Point-to-segment distance in meters on local Cartesian projection.
double calculatePointToSegmentDistanceMeters(
  LatLng point,
  LatLng segmentStart,
  LatLng segmentEnd,
) {
  final midLat = ((segmentStart.latitude + segmentEnd.latitude) / 2.0) * degToRad;
  final cosMidLat = math.cos(midLat);

  final segDx = (segmentEnd.longitude - segmentStart.longitude) *
      degToRad *
      earthRadiusMeters *
      cosMidLat;
  final segDy = (segmentEnd.latitude - segmentStart.latitude) * degToRad * earthRadiusMeters;

  final ptDx = (point.longitude - segmentStart.longitude) *
      degToRad *
      earthRadiusMeters *
      cosMidLat;
  final ptDy = (point.latitude - segmentStart.latitude) * degToRad * earthRadiusMeters;

  final segLengthSq = segDx * segDx + segDy * segDy;
  if (segLengthSq == 0.0) {
    return math.sqrt(ptDx * ptDx + ptDy * ptDy);
  }

  final t = (ptDx * segDx + ptDy * segDy) / segLengthSq;
  final tClamped = math.max(0.0, math.min(1.0, t));

  final projX = tClamped * segDx;
  final projY = tClamped * segDy;

  final diffX = ptDx - projX;
  final diffY = ptDy - projY;

  return math.sqrt(diffX * diffX + diffY * diffY);
}

/// Minimum distance in meters from a hazard coordinate to all segments in route coordinates.
double calculateHazardRouteDistanceMeters(
  LatLng hazardCoord,
  List<LatLng> routeCoords,
) {
  if (routeCoords.isEmpty) return double.infinity;
  if (routeCoords.length == 1) {
    return calculatePointToPointDistanceMeters(hazardCoord, routeCoords[0]);
  }

  double minDistance = double.infinity;
  for (int i = 0; i < routeCoords.length - 1; i++) {
    final dist = calculatePointToSegmentDistanceMeters(
      hazardCoord,
      routeCoords[i],
      routeCoords[i + 1],
    );
    if (dist < minDistance) {
      minDistance = dist;
    }
  }
  return minDistance;
}

/// Evaluates proximity between a route and simulated hazards.
///
/// Throws [RangeError] if thresholdMeters is negative or non-finite.
RouteHazardProximitySummary evaluateRouteHazardProximity(
  dynamic routeOrCoords,
  List<HazardLocation>? hazards, {
  double thresholdMeters = defaultProximityThresholdMeters,
}) {
  if (!thresholdMeters.isFinite || thresholdMeters < 0) {
    throw RangeError('Proximity threshold must be a non-negative finite number of meters. Received: $thresholdMeters');
  }

  if (hazards == null || hazards.isEmpty) {
    return RouteHazardProximitySummary(
      thresholdMeters: thresholdMeters,
      evaluatedHazardCount: 0,
      nearbyHazards: [],
      allHazards: [],
    );
  }

  List<LatLng> coords = [];
  if (routeOrCoords is RoadRoute) {
    coords = routeOrCoords.coordinates;
  } else if (routeOrCoords is List<LatLng>) {
    coords = routeOrCoords;
  }

  if (coords.isEmpty) {
    return RouteHazardProximitySummary(
      thresholdMeters: thresholdMeters,
      evaluatedHazardCount: 0,
      nearbyHazards: [],
      allHazards: [],
    );
  }

  // Validate all coordinates in route (reject whole route if corrupt coordinate found)
  for (final pt in coords) {
    if (!isValidCoordinate(pt)) {
      return RouteHazardProximitySummary(
        thresholdMeters: thresholdMeters,
        evaluatedHazardCount: 0,
        nearbyHazards: [],
        allHazards: [],
      );
    }
  }

  final allHazards = <HazardProximityResult>[];

  for (final hazard in hazards) {
    if (!isValidCoordinate(hazard.coordinates)) continue;

    final rawDist = calculateHazardRouteDistanceMeters(hazard.coordinates, coords);
    if (!rawDist.isFinite) continue;

    final isNearby = rawDist <= (thresholdMeters + 1e-6);
    final roundedDist = (rawDist * 10).round() / 10.0;

    allHazards.add(
      HazardProximityResult(
        hazardId: hazard.id,
        hazardName: hazard.name,
        hazardType: hazard.hazardType,
        severity: hazard.severity,
        distanceMeters: roundedDist,
        isNearby: isNearby,
        hazard: hazard,
      ),
    );
  }

  // Filter nearby and sort nearest-first
  final nearbyHazards = allHazards.where((h) => h.isNearby).toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

  return RouteHazardProximitySummary(
    thresholdMeters: thresholdMeters,
    evaluatedHazardCount: allHazards.length,
    nearbyHazards: nearbyHazards,
    allHazards: allHazards,
  );
}

/// Convenience helper to detect nearby hazards directly.
List<HazardProximityResult> detectNearbyHazards(
  dynamic routeOrCoords,
  List<HazardLocation>? hazards, {
  double thresholdMeters = defaultProximityThresholdMeters,
}) {
  return evaluateRouteHazardProximity(
    routeOrCoords,
    hazards,
    thresholdMeters: thresholdMeters,
  ).nearbyHazards;
}
