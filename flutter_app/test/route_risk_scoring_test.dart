import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:varsha_flutter/models/hazard.dart';
import 'package:varsha_flutter/models/risk_assessment.dart';
import 'package:varsha_flutter/services/routing/hazard_proximity.dart';
import 'package:varsha_flutter/services/routing/route_risk_scoring.dart';

HazardProximityResult _createTestProximityResult(
  String hazardId,
  HazardSeverity severity,
  double distanceMeters, {
  bool isNearby = true,
  String? hazardName,
}) {
  final hazard = HazardLocation(
    id: hazardId,
    name: hazardName ?? 'Hazard $hazardId',
    area: 'Navi Mumbai Test Sector',
    coordinates: const LatLng(19.0500, 73.0000),
    hazardType: HazardType.waterlogging,
    severity: severity,
    description: 'Simulated waterlogging test site',
    isSimulated: true,
  );

  return HazardProximityResult(
    hazardId: hazardId,
    hazardName: hazardName ?? 'Hazard $hazardId',
    hazardType: HazardType.waterlogging,
    severity: severity,
    distanceMeters: distanceMeters,
    isNearby: isNearby,
    hazard: hazard,
  );
}

RouteHazardProximitySummary _createTestSummary(
  List<HazardProximityResult> hazards, {
  double thresholdMeters = defaultProximityThresholdMeters,
}) {
  return RouteHazardProximitySummary(
    thresholdMeters: thresholdMeters,
    evaluatedHazardCount: hazards.length,
    nearbyHazards: hazards.where((h) => h.isNearby && h.distanceMeters <= thresholdMeters).toList(),
    allHazards: hazards,
  );
}

void main() {
  group('Route Risk Scoring Engine', () {
    test('Test A — No nearby hazards: empty summary returns score 0, designated category', () {
      final emptySummary = _createTestSummary([]);
      final result = calculateRouteRiskScore(emptySummary);

      expect(result.score, 0.0);
      expect(result.riskCategory, RouteRiskCategory.none);
      expect(result.includedHazardCount, 0);
      expect(result.evaluatedHazardCount, 0);
      expect(result.thresholdMeters, 100.0);
      expect(result.contributions.isEmpty, true);
      expect(result.summaryExplanation.contains('No simulated hazards were detected'), true);

      final nullResult = calculateRouteRiskScore(null);
      expect(nullResult.score, 0.0);
      expect(nullResult.riskCategory, RouteRiskCategory.none);
    });

    test('Test B — One low-severity hazard: verifies weight, multiplier, score, explanation', () {
      final lowHazard = _createTestProximityResult('haz-low-1', HazardSeverity.low, 15.0, hazardName: 'Vashi Low Point');
      final summary = _createTestSummary([lowHazard]);

      final result = calculateRouteRiskScore(summary);

      expect(result.score, 10.0);
      expect(result.riskCategory, RouteRiskCategory.low);
      expect(result.includedHazardCount, 1);
      expect(result.evaluatedHazardCount, 1);
      expect(result.contributions.length, 1);

      final c = result.contributions[0];
      expect(c.hazardId, 'haz-low-1');
      expect(c.hazardName, 'Vashi Low Point');
      expect(c.severity, HazardSeverity.low);
      expect(c.distanceMeters, 15.0);
      expect(c.baseWeight, 10.0);
      expect(c.proximityMultiplier, 1.0);
      expect(c.scoreContribution, 10.0);
      expect(c.explanation.contains('Low severity (base weight 10) at 15m'), true);
      expect(c.explanation.contains('within 25m band, multiplier 1'), true);
    });

    test('Test C — Medium and high severity mapping', () {
      final medHazard = _createTestProximityResult('haz-med-1', HazardSeverity.medium, 20.0);
      final medResult = calculateRouteRiskScore(_createTestSummary([medHazard]));

      expect(medResult.score, 20.0);
      expect(medResult.contributions[0].baseWeight, 20.0);
      expect(medResult.contributions[0].proximityMultiplier, 1.0);
      expect(medResult.contributions[0].scoreContribution, 20.0);
      expect(medResult.riskCategory, RouteRiskCategory.low);

      final highHazard = _createTestProximityResult('haz-high-1', HazardSeverity.high, 20.0);
      final highResult = calculateRouteRiskScore(_createTestSummary([highHazard]));

      expect(highResult.score, 35.0);
      expect(highResult.contributions[0].baseWeight, 35.0);
      expect(highResult.contributions[0].proximityMultiplier, 1.0);
      expect(highResult.contributions[0].scoreContribution, 35.0);
      expect(highResult.riskCategory, RouteRiskCategory.moderate);
    });

    test('Test D — Proximity multiplier bands: <=25m (1.0), 25-50m (0.75), 50-100m (0.5)', () {
      expect(calculateProximityMultiplier(0, 100), 1.0);
      expect(calculateProximityMultiplier(12.5, 100), 1.0);
      expect(calculateProximityMultiplier(25.0, 100), 1.0);

      expect(calculateProximityMultiplier(25.1, 100), 0.75);
      expect(calculateProximityMultiplier(35.0, 100), 0.75);
      expect(calculateProximityMultiplier(50.0, 100), 0.75);

      expect(calculateProximityMultiplier(50.1, 100), 0.5);
      expect(calculateProximityMultiplier(75.0, 100), 0.5);
      expect(calculateProximityMultiplier(100.0, 100), 0.5);

      final at25 = _createTestProximityResult('h25', HazardSeverity.medium, 25.0);
      final at50 = _createTestProximityResult('h50', HazardSeverity.medium, 50.0);
      final at100 = _createTestProximityResult('h100', HazardSeverity.medium, 100.0);

      expect(calculateRouteRiskScore(_createTestSummary([at25])).contributions[0].scoreContribution, 20.0);
      expect(calculateRouteRiskScore(_createTestSummary([at50])).contributions[0].scoreContribution, 15.0);
      expect(calculateRouteRiskScore(_createTestSummary([at100])).contributions[0].scoreContribution, 10.0);
    });

    test('Test E — Threshold boundary: exact 100m distance has multiplier 0.5', () {
      final boundaryHazard = _createTestProximityResult('h-boundary', HazardSeverity.high, 100.0);
      final result = calculateRouteRiskScore(_createTestSummary([boundaryHazard], thresholdMeters: 100));

      expect(result.includedHazardCount, 1);
      expect(result.contributions[0].hazardId, 'h-boundary');
      expect(result.contributions[0].proximityMultiplier, 0.5);
      expect(result.contributions[0].scoreContribution, 17.5);
      expect(result.score, 17.5);
    });

    test('Test F — Outside threshold: hazard beyond threshold excluded from score', () {
      final farHazard = _createTestProximityResult('h-far', HazardSeverity.high, 120.0, isNearby: true);
      final result = calculateRouteRiskScore(_createTestSummary([farHazard], thresholdMeters: 100));

      expect(result.includedHazardCount, 0);
      expect(result.score, 0.0);
      expect(result.riskCategory, RouteRiskCategory.none);
    });

    test('Test G — Multiple hazards: aggregation and nearest-first ordering', () {
      final h1 = _createTestProximityResult('h-far', HazardSeverity.low, 80.0); // 10 * 0.5 = 5
      final h2 = _createTestProximityResult('h-mid', HazardSeverity.medium, 40.0); // 20 * 0.75 = 15
      final h3 = _createTestProximityResult('h-near', HazardSeverity.high, 10.0); // 35 * 1.0 = 35

      final summary = _createTestSummary([h1, h3, h2], thresholdMeters: 100);
      final result = calculateRouteRiskScore(summary);

      expect(result.evaluatedHazardCount, 3);
      expect(result.includedHazardCount, 3);
      expect(result.score, 55.0);
      expect(result.riskCategory, RouteRiskCategory.high);

      expect(result.contributions[0].hazardId, 'h-near');
      expect(result.contributions[1].hazardId, 'h-mid');
      expect(result.contributions[2].hazardId, 'h-far');
    });

    test('Test H — Category boundaries: 0, 1, 24, 25, 49, 50, 74, 75, 100', () {
      expect(RouteRiskCategory.fromScore(0), RouteRiskCategory.none);
      expect(RouteRiskCategory.fromScore(1), RouteRiskCategory.low);
      expect(RouteRiskCategory.fromScore(24.9), RouteRiskCategory.low);
      expect(RouteRiskCategory.fromScore(25), RouteRiskCategory.moderate);
      expect(RouteRiskCategory.fromScore(49.9), RouteRiskCategory.moderate);
      expect(RouteRiskCategory.fromScore(50), RouteRiskCategory.high);
      expect(RouteRiskCategory.fromScore(74.9), RouteRiskCategory.high);
      expect(RouteRiskCategory.fromScore(75), RouteRiskCategory.veryHigh);
      expect(RouteRiskCategory.fromScore(100), RouteRiskCategory.veryHigh);
    });

    test('Test I — Score cap: aggregate contributions clamped to 100', () {
      final h1 = _createTestProximityResult('h1', HazardSeverity.high, 10.0);
      final h2 = _createTestProximityResult('h2', HazardSeverity.high, 15.0);
      final h3 = _createTestProximityResult('h3', HazardSeverity.high, 20.0);
      final h4 = _createTestProximityResult('h4', HazardSeverity.high, 22.0);

      final result = calculateRouteRiskScore(_createTestSummary([h1, h2, h3, h4]));

      expect(result.includedHazardCount, 4);
      expect(result.score, 100.0);
      expect(result.riskCategory, RouteRiskCategory.veryHigh);
    });

    test('Test K — Invalid threshold rejected with RangeError', () {
      final h1 = _createTestProximityResult('h1', HazardSeverity.low, 10.0);
      final summary = _createTestSummary([h1]);

      expect(() => calculateRouteRiskScore(summary, thresholdMeters: -10), throwsA(isA<RangeError>()));
      expect(() => calculateRouteRiskScore(summary, thresholdMeters: double.nan), throwsA(isA<RangeError>()));
      expect(() => calculateRouteRiskScore(summary, thresholdMeters: double.infinity), throwsA(isA<RangeError>()));
    });

    test('Test P — Direct HazardProximityResult list input accepted', () {
      final h1 = _createTestProximityResult('h-arr-1', HazardSeverity.high, 10.0);
      final h2 = _createTestProximityResult('h-arr-2', HazardSeverity.low, 80.0);
      final result = calculateRouteRiskScore([h1, h2]);

      expect(result.score, 40.0); // 35 * 1.0 + 10 * 0.5 = 40
      expect(result.includedHazardCount, 2);
      expect(result.riskCategory, RouteRiskCategory.moderate);
    });

    test('Test Q — fromScore handles invalid values', () {
      expect(RouteRiskCategory.fromScore(-1), RouteRiskCategory.none);
      expect(RouteRiskCategory.fromScore(double.nan), RouteRiskCategory.none);
      expect(RouteRiskCategory.fromScore(double.infinity), RouteRiskCategory.none);
    });
  });
}
