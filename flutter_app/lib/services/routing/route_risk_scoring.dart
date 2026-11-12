import 'dart:math' as math;
import '../../models/hazard.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import 'hazard_proximity.dart';

const Map<HazardSeverity, double> defaultSeverityBaseWeights = {
  HazardSeverity.low: 10.0,
  HazardSeverity.medium: 20.0,
  HazardSeverity.high: 35.0,
};

/// Returns stepped proximity multiplier based on distance to route.
double calculateProximityMultiplier(double distanceMeters, double thresholdMeters) {
  if (!distanceMeters.isFinite || distanceMeters < 0) {
    return 0.0;
  }
  if (distanceMeters > (thresholdMeters + 1e-6)) {
    return 0.0;
  }
  if (distanceMeters <= (25.0 + 1e-6)) {
    return 1.0;
  }
  if (distanceMeters <= (50.0 + 1e-6)) {
    return 0.75;
  }
  return 0.5;
}

String _getBandDescription(double distanceMeters, double thresholdMeters) {
  if (distanceMeters <= (25.0 + 1e-6)) {
    return 'within 25m band';
  }
  if (distanceMeters <= (50.0 + 1e-6)) {
    return '25m–50m band';
  }
  return '50m–${thresholdMeters.round()}m band';
}

/// Pure deterministic risk scoring engine for routes against evaluated hazards.
RouteRiskScoreResult calculateRouteRiskScore(
  dynamic summaryOrHazards, {
  double? thresholdMeters,
  Map<HazardSeverity, double>? severityWeights,
}) {
  double? summaryThreshold;
  int evaluatedCount = 0;
  List<HazardProximityResult> rawCandidates = [];

  if (summaryOrHazards is RouteHazardProximitySummary) {
    summaryThreshold = summaryOrHazards.thresholdMeters;
    evaluatedCount = summaryOrHazards.evaluatedHazardCount;
    if (summaryOrHazards.allHazards.isNotEmpty) {
      rawCandidates = summaryOrHazards.allHazards;
    } else {
      rawCandidates = summaryOrHazards.nearbyHazards;
    }
  } else if (summaryOrHazards is List<HazardProximityResult>) {
    rawCandidates = summaryOrHazards;
    evaluatedCount = summaryOrHazards.length;
  }

  final effectiveThreshold =
      thresholdMeters ?? summaryThreshold ?? defaultProximityThresholdMeters;

  if (!effectiveThreshold.isFinite || effectiveThreshold < 0) {
    throw RangeError('Proximity threshold must be a non-negative finite number of meters. Received: $effectiveThreshold');
  }

  final weights = {
    HazardSeverity.low: severityWeights?[HazardSeverity.low] ??
        defaultSeverityBaseWeights[HazardSeverity.low]!,
    HazardSeverity.medium: severityWeights?[HazardSeverity.medium] ??
        defaultSeverityBaseWeights[HazardSeverity.medium]!,
    HazardSeverity.high: severityWeights?[HazardSeverity.high] ??
        defaultSeverityBaseWeights[HazardSeverity.high]!,
  };

  for (final entry in weights.entries) {
    if (!entry.value.isFinite || entry.value < 0) {
      throw RangeError('Severity base weight for "${entry.key.name}" must be non-negative finite. Received: ${entry.value}');
    }
  }

  // Deduplicate by hazardId, keeping minimum distance
  final candidateMap = <String, HazardProximityResult>{};
  for (final item in rawCandidates) {
    if (candidateMap.containsKey(item.hazardId)) {
      final existing = candidateMap[item.hazardId]!;
      if (item.distanceMeters < existing.distanceMeters) {
        candidateMap[item.hazardId] = item;
      }
    } else {
      candidateMap[item.hazardId] = item;
    }
  }

  final contributions = <HazardRiskContribution>[];

  for (final item in candidateMap.values) {
    if (!item.distanceMeters.isFinite || item.distanceMeters < 0) continue;

    final multiplier = calculateProximityMultiplier(item.distanceMeters, effectiveThreshold);
    if (multiplier <= 0.0) continue;

    final baseWeight = weights[item.severity]!;
    final scoreContrib = ((baseWeight * multiplier) * 100).round() / 100.0;
    final bandDesc = _getBandDescription(item.distanceMeters, effectiveThreshold);
    final sevName = item.severity.displayName;

    final multStr = multiplier == 1.0 ? '1' : multiplier.toString();

    contributions.add(
      HazardRiskContribution(
        hazardId: item.hazardId,
        hazardName: item.hazardName,
        severity: item.severity,
        distanceMeters: item.distanceMeters,
        baseWeight: baseWeight,
        proximityMultiplier: multiplier,
        scoreContribution: scoreContrib,
        explanation:
            '$sevName severity (base weight ${baseWeight.round()}) at ${item.distanceMeters.toStringAsFixed(item.distanceMeters.truncateToDouble() == item.distanceMeters ? 0 : 1)}m '
            '($bandDesc, multiplier $multStr) contributes ${scoreContrib.toStringAsFixed(scoreContrib.truncateToDouble() == scoreContrib ? 0 : 1)} to risk score.',
      ),
    );
  }

  // Sort nearest-first, then by hazardId
  contributions.sort((a, b) {
    final cmp = a.distanceMeters.compareTo(b.distanceMeters);
    if (cmp != 0) return cmp;
    return a.hazardId.compareTo(b.hazardId);
  });

  final rawScore = contributions.fold<double>(0.0, (acc, c) => acc + c.scoreContribution);
  final score = math.min(100.0, math.max(0.0, (rawScore * 100).round() / 100.0));
  final category = RouteRiskCategory.fromScore(score);
  final includedCount = contributions.length;

  final summaryExplanation = includedCount == 0
      ? 'No simulated hazards were detected within the ${effectiveThreshold.round()}m proximity threshold. '
          'Note: this prototype score reflects only simulated hazards and does not guarantee hazard-free conditions.'
      : 'Evaluated $evaluatedCount simulated hazard(s); $includedCount within ${effectiveThreshold.round()}m threshold '
          'contributed to an aggregate risk score of ${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)}/100 (${category.displayName}). '
          'Note: prototype model based solely on simulated hazard proximity.';

  return RouteRiskScoreResult(
    score: score,
    riskCategory: category,
    evaluatedHazardCount: evaluatedCount,
    includedHazardCount: includedCount,
    thresholdMeters: effectiveThreshold,
    contributions: contributions,
    summaryExplanation: summaryExplanation,
  );
}

/// Assesses prototype monsoon risk for a single route.
RouteRiskAssessment assessRouteRisk(
  RoadRoute? route,
  List<HazardLocation>? hazards, {
  double? thresholdMeters,
}) {
  final routeId = route?.id ?? 'unknown';
  if (route == null || route.coordinates.isEmpty) {
    return RouteRiskAssessment(
      routeId: routeId,
      status: 'error',
      error: 'Risk assessment unavailable: missing or empty route coordinates.',
    );
  }

  try {
    final proximity = evaluateRouteHazardProximity(
      route,
      hazards,
      thresholdMeters: thresholdMeters ?? defaultProximityThresholdMeters,
    );
    final result = calculateRouteRiskScore(proximity, thresholdMeters: thresholdMeters);
    return RouteRiskAssessment(
      routeId: routeId,
      status: 'success',
      result: result,
    );
  } catch (err) {
    return RouteRiskAssessment(
      routeId: routeId,
      status: 'error',
      error: err.toString(),
    );
  }
}

/// Assesses prototype risk for multiple routes.
Map<String, RouteRiskAssessment> assessRoutesRisk(
  List<RoadRoute>? routes,
  List<HazardLocation>? hazards, {
  double? thresholdMeters,
}) {
  final assessments = <String, RouteRiskAssessment>{};
  if (routes == null || routes.isEmpty) return assessments;

  for (final route in routes) {
    assessments[route.id] = assessRouteRisk(route, hazards, thresholdMeters: thresholdMeters);
  }
  return assessments;
}
