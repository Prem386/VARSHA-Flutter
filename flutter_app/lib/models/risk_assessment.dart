import 'hazard.dart';

enum RouteRiskCategory {
  none('No nearby simulated hazards'),
  low('Low'),
  moderate('Moderate'),
  high('High'),
  veryHigh('Very High');

  final String displayName;
  const RouteRiskCategory(this.displayName);

  static RouteRiskCategory fromScore(double score) {
    if (score <= 0 || !score.isFinite) {
      return RouteRiskCategory.none;
    }
    if (score < 25) {
      return RouteRiskCategory.low;
    }
    if (score < 50) {
      return RouteRiskCategory.moderate;
    }
    if (score < 75) {
      return RouteRiskCategory.high;
    }
    return RouteRiskCategory.veryHigh;
  }
}

/// Proximity calculation result for a single hazard against route geometry.
class HazardProximityResult {
  final String hazardId;
  final String hazardName;
  final HazardType hazardType;
  final HazardSeverity severity;
  final double distanceMeters;
  final bool isNearby;
  final HazardLocation hazard;

  const HazardProximityResult({
    required this.hazardId,
    required this.hazardName,
    required this.hazardType,
    required this.severity,
    required this.distanceMeters,
    required this.isNearby,
    required this.hazard,
  });
}

/// Summary of evaluated hazards for a route.
class RouteHazardProximitySummary {
  final double thresholdMeters;
  final int evaluatedHazardCount;
  final List<HazardProximityResult> nearbyHazards;
  final List<HazardProximityResult> allHazards;

  const RouteHazardProximitySummary({
    required this.thresholdMeters,
    required this.evaluatedHazardCount,
    required this.nearbyHazards,
    required this.allHazards,
  });
}

/// Individual hazard contribution to route risk score.
class HazardRiskContribution {
  final String hazardId;
  final String hazardName;
  final HazardSeverity severity;
  final double distanceMeters;
  final double baseWeight;
  final double proximityMultiplier;
  final double scoreContribution;
  final String explanation;

  const HazardRiskContribution({
    required this.hazardId,
    required this.hazardName,
    required this.severity,
    required this.distanceMeters,
    required this.baseWeight,
    required this.proximityMultiplier,
    required this.scoreContribution,
    required this.explanation,
  });
}

/// Full explainable risk score calculation output.
class RouteRiskScoreResult {
  final double score;
  final RouteRiskCategory riskCategory;
  final int evaluatedHazardCount;
  final int includedHazardCount;
  final double thresholdMeters;
  final List<HazardRiskContribution> contributions;
  final String summaryExplanation;

  const RouteRiskScoreResult({
    required this.score,
    required this.riskCategory,
    required this.evaluatedHazardCount,
    required this.includedHazardCount,
    required this.thresholdMeters,
    required this.contributions,
    required this.summaryExplanation,
  });
}

/// Container for route risk assessment status and result.
class RouteRiskAssessment {
  final String routeId;
  final String status; // 'success' | 'error'
  final RouteRiskScoreResult? result;
  final String? error;

  const RouteRiskAssessment({
    required this.routeId,
    required this.status,
    this.result,
    this.error,
  });

  bool get isSuccess => status == 'success' && result != null;
}
