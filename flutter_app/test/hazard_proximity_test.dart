import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:varsha_flutter/models/hazard.dart';
import 'package:varsha_flutter/models/route.dart';
import 'package:varsha_flutter/services/routing/hazard_proximity.dart';
import 'package:varsha_flutter/services/routing/route_risk_scoring.dart';

HazardLocation _createTestHazard(
  String id,
  LatLng coordinates, {
  String? name,
  HazardSeverity severity = HazardSeverity.medium,
}) {
  return HazardLocation(
    id: id,
    name: name ?? 'Hazard $id',
    area: 'Navi Mumbai Test Area',
    coordinates: coordinates,
    hazardType: HazardType.waterlogging,
    severity: severity,
    description: 'Test hazard description',
    isSimulated: true,
  );
}

void main() {
  group('Hazard Proximity Calculations', () {
    test('Test A — Hazard on the route: minimum distance ~0m and considered nearby', () {
      final routeCoords = [
        const LatLng(19.0650, 72.9900),
        const LatLng(19.0650, 73.0100),
      ];
      final onRouteHazard = _createTestHazard('haz-a', const LatLng(19.0650, 73.0000));

      final summary = evaluateRouteHazardProximity(routeCoords, [onRouteHazard]);

      expect(summary.evaluatedHazardCount, 1);
      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].hazardId, 'haz-a');
      expect(summary.nearbyHazards[0].isNearby, true);
      expect(summary.nearbyHazards[0].distanceMeters <= 0.1, true);
    });

    test('Test B — Hazard near a segment, not a vertex: detected when far from endpoints', () {
      final start = const LatLng(19.0700, 72.9900);
      final end = const LatLng(19.0700, 73.0000);
      final routeCoords = [start, end];

      // Midpoint is [19.0700, 72.9950]. Place hazard ~33.4m north
      final midpointHazard = _createTestHazard('haz-b', const LatLng(19.0703, 72.9950));

      final distToStart = calculatePointToPointDistanceMeters(midpointHazard.coordinates, start);
      final distToEnd = calculatePointToPointDistanceMeters(midpointHazard.coordinates, end);
      expect(distToStart > 500, true);
      expect(distToEnd > 500, true);

      final summary = evaluateRouteHazardProximity(routeCoords, [midpointHazard]);

      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].isNearby, true);
      expect(summary.nearbyHazards[0].distanceMeters >= 30, true);
      expect(summary.nearbyHazards[0].distanceMeters <= 36, true);
    });

    test('Test C — Hazard outside the threshold: excluded from nearby-hazard results', () {
      final routeCoords = [
        const LatLng(19.0600, 73.0000),
        const LatLng(19.0600, 73.0100),
      ];
      // ~166.8m away (> 100m threshold)
      final farHazard = _createTestHazard('haz-c', const LatLng(19.0615, 73.0050));

      final summary = evaluateRouteHazardProximity(
        routeCoords,
        [farHazard],
        thresholdMeters: 100,
      );

      expect(summary.evaluatedHazardCount, 1);
      expect(summary.nearbyHazards.length, 0);
      expect(summary.allHazards[0].isNearby, false);
      expect(summary.allHazards[0].distanceMeters > 150, true);
    });

    test('Test D — Threshold boundary: inclusive boundary behavior at exact threshold', () {
      final routeCoords = [
        const LatLng(19.0000, 73.0000),
        const LatLng(19.0100, 73.0000),
      ];

      const latMid = 19.0050;
      const degToRadConst = math.pi / 180.0;
      final cosLat = math.cos(latMid * degToRadConst);
      final deltaLon = 100.0 / (6371000.0 * cosLat * degToRadConst);
      final boundaryHazard = _createTestHazard('haz-d', LatLng(latMid, 73.0000 + deltaLon));

      final dist = calculatePointToSegmentDistanceMeters(
        boundaryHazard.coordinates,
        routeCoords[0],
        routeCoords[1],
      );
      expect((dist - 100.0).abs() < 0.05, true);

      final summary = evaluateRouteHazardProximity(
        routeCoords,
        [boundaryHazard],
        thresholdMeters: 100,
      );

      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].isNearby, true);
      expect(summary.nearbyHazards[0].distanceMeters.round(), 100);
    });

    test('Test E — Multiple hazards: correct identification and nearest-first sorting', () {
      final routeCoords = [
        const LatLng(19.0500, 73.0000),
        const LatLng(19.0500, 73.0200),
      ];

      final hazNear = _createTestHazard('haz-near', const LatLng(19.0502, 73.0050)); // ~22.2m
      final hazMid = _createTestHazard('haz-mid', const LatLng(19.0506, 73.0100)); // ~66.7m
      final hazFar = _createTestHazard('haz-far', const LatLng(19.0515, 73.0150)); // ~166.8m

      final summary = evaluateRouteHazardProximity(
        routeCoords,
        [hazFar, hazMid, hazNear],
        thresholdMeters: 100,
      );

      expect(summary.evaluatedHazardCount, 3);
      expect(summary.nearbyHazards.length, 2);
      expect(summary.nearbyHazards[0].hazardId, 'haz-near');
      expect(summary.nearbyHazards[1].hazardId, 'haz-mid');
      expect(summary.nearbyHazards[0].distanceMeters < summary.nearbyHazards[1].distanceMeters, true);
    });

    test('Test F — Multiple route segments: minimum distance evaluated across all segments', () {
      final routeCoords = [
        const LatLng(19.0000, 73.0000),
        const LatLng(19.0000, 73.0100),
        const LatLng(19.0100, 73.0100),
        const LatLng(19.0100, 73.0200),
      ];

      final hazardNearS2 = _createTestHazard('haz-s2', const LatLng(19.0050, 73.01024));

      final distToS1 = calculatePointToSegmentDistanceMeters(
        hazardNearS2.coordinates,
        routeCoords[0],
        routeCoords[1],
      );
      final distToS2 = calculatePointToSegmentDistanceMeters(
        hazardNearS2.coordinates,
        routeCoords[1],
        routeCoords[2],
      );
      final distToS3 = calculatePointToSegmentDistanceMeters(
        hazardNearS2.coordinates,
        routeCoords[2],
        routeCoords[3],
      );

      expect(distToS1 > 500, true);
      expect(distToS2 < 30, true);
      expect(distToS3 > 500, true);

      final totalMinDist = calculateHazardRouteDistanceMeters(
        hazardNearS2.coordinates,
        routeCoords,
      );
      expect((totalMinDist * 10).round() / 10, (distToS2 * 10).round() / 10);

      final summary = evaluateRouteHazardProximity(routeCoords, [hazardNearS2]);
      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].hazardId, 'haz-s2');
    });

    test('Test G — Single-point route: evaluates distance to vertex', () {
      final singlePointRoute = [const LatLng(19.0700, 73.0000)];
      final hazard = _createTestHazard('haz-g', const LatLng(19.0705, 73.0000));

      final summary = evaluateRouteHazardProximity(singlePointRoute, [hazard]);

      expect(summary.evaluatedHazardCount, 1);
      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].hazardId, 'haz-g');
      expect(summary.nearbyHazards[0].distanceMeters >= 50, true);
      expect(summary.nearbyHazards[0].distanceMeters <= 60, true);
    });

    test('Test H — Empty route geometry returns empty summary safely', () {
      final hazards = [_createTestHazard('haz-h', const LatLng(19.0700, 73.0000))];

      final summaryEmpty = evaluateRouteHazardProximity(<LatLng>[], hazards);
      expect(summaryEmpty.evaluatedHazardCount, 0);
      expect(summaryEmpty.nearbyHazards.length, 0);

      final roadRouteEmpty = RoadRoute(
        id: 'r-empty',
        coordinates: [],
        distanceMeters: 0,
        durationSeconds: 0,
        engineEstimateNotice: 'Test',
      );
      final summaryRoadRoute = evaluateRouteHazardProximity(roadRouteEmpty, hazards);
      expect(summaryRoadRoute.evaluatedHazardCount, 0);
      expect(summaryRoadRoute.nearbyHazards.length, 0);
    });

    test('Test I — Repeated route points do not divide by zero', () {
      final degenerateRoute = [
        const LatLng(19.0700, 73.0000),
        const LatLng(19.0700, 73.0000),
        const LatLng(19.0750, 73.0000),
      ];
      final hazard = _createTestHazard('haz-i', const LatLng(19.0700, 73.0002));

      final summary = evaluateRouteHazardProximity(degenerateRoute, [hazard]);

      expect(summary.evaluatedHazardCount, 1);
      expect(summary.nearbyHazards.length, 1);
      expect(summary.nearbyHazards[0].distanceMeters.isFinite, true);
      expect(summary.nearbyHazards[0].distanceMeters > 0, true);
    });

    test('Test L — Threshold validation: rejects negative or non-finite threshold', () {
      final validRoute = [
        const LatLng(19.0700, 73.0000),
        const LatLng(19.0800, 73.0000),
      ];
      final hazards = [_createTestHazard('haz-l', const LatLng(19.0750, 73.0000))];

      expect(
        () => evaluateRouteHazardProximity(validRoute, hazards, thresholdMeters: -5),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => evaluateRouteHazardProximity(validRoute, hazards, thresholdMeters: double.nan),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => evaluateRouteHazardProximity(validRoute, hazards, thresholdMeters: double.infinity),
        throwsA(isA<RangeError>()),
      );
    });

    test('Test SIMULATED_HAZARDS integration: actual project hazards evaluate with RoadRoute', () {
      final testRoute = RoadRoute(
        id: 'test-osrm-route-1',
        label: 'Route 1',
        coordinates: const [
          LatLng(19.0700, 72.9985),
          LatLng(19.0758, 72.9985), // within ~22m of sim-haz-01
          LatLng(19.0800, 72.9985),
        ],
        distanceMeters: 1110,
        durationSeconds: 120,
        engineEstimateNotice: 'Test notice',
      );

      final summary = evaluateRouteHazardProximity(testRoute, simulatedHazards);

      expect(summary.thresholdMeters, 100);
      expect(summary.evaluatedHazardCount, simulatedHazards.length);

      final nearby = detectNearbyHazards(testRoute, simulatedHazards);
      expect(nearby.isNotEmpty, true);
      expect(nearby[0].hazardId, 'sim-haz-01');
      expect(nearby[0].hazardName, 'Illustrative Waterlogging Point A');
      expect(nearby[0].distanceMeters <= 25, true);
      expect(nearby[0].isNearby, true);
    });

    test('Test P — Duplicate hazard IDs deduplicated to nearest during scoring', () {
      final routeCoords = [
        const LatLng(19.0700, 73.0000),
        const LatLng(19.0700, 73.0100),
      ];
      final haz1 = _createTestHazard('dup-haz', const LatLng(19.0701, 73.0050)); // ~11m
      final haz2 = _createTestHazard('dup-haz', const LatLng(19.0705, 73.0050)); // ~55m

      final summary = evaluateRouteHazardProximity(routeCoords, [haz1, haz2]);
      expect(summary.evaluatedHazardCount, 2);
      expect(summary.allHazards.length, 2);
      expect(summary.nearbyHazards.length, 2);

      final result = calculateRouteRiskScore(summary);
      expect(result.includedHazardCount, 1);
      expect(result.contributions[0].distanceMeters <= 15, true);
    });
  });
}
