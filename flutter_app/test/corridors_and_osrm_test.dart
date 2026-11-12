import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:varsha_flutter/models/route.dart';
import 'package:varsha_flutter/services/routing/corridors.dart';

void main() {
  group('Corridors and Route Distinction', () {
    test('findMatchingCorridor identifies Vashi to Belapur arterial corridor', () {
      const vashi = LatLng(19.0645, 72.9983);
      const belapur = LatLng(19.0185, 73.0385);

      final corridor = findMatchingCorridor(vashi, belapur);
      expect(corridor, isNotNull);
      expect(corridor!.id, 'vashi-belapur-palm-beach');
      expect(corridor.primaryLabel, 'via Sion-Panvel Hwy');
      expect(corridor.alternativeLabel, 'via Palm Beach Rd');

      // Reverse direction: Belapur to Vashi
      final reverseCorridor = findMatchingCorridor(belapur, vashi);
      expect(reverseCorridor, isNotNull);
      expect(reverseCorridor!.id, 'vashi-belapur-palm-beach');
    });

    test('findMatchingCorridor identifies Airoli to Vashi trans-harbour corridor', () {
      const airoli = LatLng(19.1553, 72.9986);
      const vashi = LatLng(19.0645, 72.9983);

      final corridor = findMatchingCorridor(airoli, vashi);
      expect(corridor, isNotNull);
      expect(corridor!.id, 'airoli-vashi-west-bypass');
      expect(corridor.primaryLabel, 'via Thane-Belapur Rd');
      expect(corridor.alternativeLabel, 'via West Bypass');
    });

    test('validateRouteEndpoints checks start and end point tolerance', () {
      final route = RoadRoute(
        id: 'r1',
        coordinates: const [
          LatLng(19.0640, 72.9980),
          LatLng(19.0400, 73.0100),
          LatLng(19.0180, 73.0380),
        ],
        distanceMeters: 8000,
        durationSeconds: 900,
        engineEstimateNotice: 'Test',
      );

      // Close endpoints (< 500m)
      expect(
        validateRouteEndpoints(route, const LatLng(19.0645, 72.9983), const LatLng(19.0185, 73.0385)),
        true,
      );

      // Far endpoint (> 500m)
      expect(
        validateRouteEndpoints(route, const LatLng(19.1000, 72.9983), const LatLng(19.0185, 73.0385)),
        false,
      );
    });

    test('isRouteDistinct distinguishes routes with distance/duration differences', () {
      final routeA = RoadRoute(
        id: 'rA',
        coordinates: const [
          LatLng(19.06, 73.00),
          LatLng(19.04, 73.01),
          LatLng(19.02, 73.03),
        ],
        distanceMeters: 8000,
        durationSeconds: 900,
        engineEstimateNotice: 'Test',
      );

      final routeB = RoadRoute(
        id: 'rB',
        coordinates: const [
          LatLng(19.06, 73.00),
          LatLng(19.03, 73.02),
          LatLng(19.02, 73.03),
        ],
        distanceMeters: 8400, // > 250m diff
        durationSeconds: 960,
        engineEstimateNotice: 'Test',
      );

      expect(isRouteDistinct(routeA, routeB), true);
    });

    test('formatDistance and formatDuration format metrics cleanly', () {
      expect(formatDistance(450), '450 m');
      expect(formatDistance(1250), '1.3 km');
      expect(formatDistance(10000), '10.0 km');

      expect(formatDuration(45), '1 min');
      expect(formatDuration(120), '2 mins');
      expect(formatDuration(3600), '1 hr');
      expect(formatDuration(3900), '1 hr 5 min');
    });
  });
}
