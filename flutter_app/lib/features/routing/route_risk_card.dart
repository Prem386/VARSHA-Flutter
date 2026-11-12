import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hazard.dart';
import '../../models/risk_assessment.dart';

/// Renders explainable route risk score and contributing hazards.
class RouteRiskCard extends StatefulWidget {
  final RouteRiskAssessment? assessment;

  const RouteRiskCard({super.key, this.assessment});

  @override
  State<RouteRiskCard> createState() => _RouteRiskCardState();
}

class _RouteRiskCardState extends State<RouteRiskCard> {
  bool _isDetailsExpanded = false;

  Color _getCategoryColor(RouteRiskCategory category) {
    switch (category) {
      case RouteRiskCategory.none:
        return AppColors.riskNone;
      case RouteRiskCategory.low:
        return AppColors.riskLow;
      case RouteRiskCategory.moderate:
        return AppColors.riskModerate;
      case RouteRiskCategory.high:
      case RouteRiskCategory.veryHigh:
        return AppColors.riskHigh;
    }
  }

  IconData _getCategoryIcon(RouteRiskCategory category) {
    switch (category) {
      case RouteRiskCategory.none:
        return Icons.verified_user_outlined;
      case RouteRiskCategory.low:
        return Icons.shield_outlined;
      case RouteRiskCategory.moderate:
      case RouteRiskCategory.high:
      case RouteRiskCategory.veryHigh:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getSeverityColor(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.high:
        return AppColors.riskHigh;
      case HazardSeverity.medium:
        return AppColors.riskModerate;
      case HazardSeverity.low:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessment = widget.assessment;
    if (assessment == null) return const SizedBox.shrink();

    if (!assessment.isSuccess || assessment.result == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                assessment.error ?? 'Risk assessment unavailable.',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final result = assessment.result!;
    final catColor = _getCategoryColor(result.riskCategory);
    final catIcon = _getCategoryIcon(result.riskCategory);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: catColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Score and Category Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prototype Risk Score',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        result.score.toStringAsFixed(result.score.truncateToDouble() == result.score ? 0 : 1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: catColor,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: catColor.withAlpha(77)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catIcon, size: 14, color: catColor),
                        const SizedBox(width: 4),
                        Text(
                          result.riskCategory.displayName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Simulated Prototype',
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.score / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(catColor),
            ),
          ),

          const SizedBox(height: 8),

          // Explanation Text
          Text(
            result.includedHazardCount == 0
                ? 'No simulated hazards detected within ${result.thresholdMeters.round()}m proximity threshold.'
                : '${result.includedHazardCount} simulated hazard${result.includedHazardCount > 1 ? "s" : ""} detected within ${result.thresholdMeters.round()}m threshold contributing to score.',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
          ),

          // Contributing Hazards Expandable List
          if (result.contributions.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Contributing Hazards (${result.contributions.length})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberText),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isDetailsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.amberText,
                    ),
                  ],
                ),
              ),
            ),
            if (_isDetailsExpanded) ...[
              const SizedBox(height: 8),
              ...result.contributions.map((c) {
                final sevColor = _getSeverityColor(c.severity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c.hazardName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.severity.displayName.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: sevColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${c.distanceMeters.toStringAsFixed(1)}m from route',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                          Text(
                            '+${c.scoreContribution.toStringAsFixed(1)} pts',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.explanation,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
