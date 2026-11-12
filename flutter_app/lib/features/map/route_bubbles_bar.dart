import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';

/// Horizontally scrollable row of compact alternative route bubbles.
/// Inspired by Google Maps Android navigation selector.
class RouteBubblesBar extends StatelessWidget {
  final List<RoadRoute> routes;
  final String? selectedRouteId;
  final ValueChanged<String> onSelectRoute;
  final Map<String, RouteRiskAssessment>? riskAssessments;

  const RouteBubblesBar({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
    this.riskAssessments,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    final activeRouteId = selectedRouteId ?? routes.first.id;

    // Calculate trade-off markers
    final minDuration = routes
        .map((r) => r.durationSeconds)
        .reduce((a, b) => a < b ? a : b);

    final validScores = routes
        .map((r) => riskAssessments?[r.id]?.result?.score)
        .whereType<double>()
        .toList();
    final minRiskScore = validScores.isNotEmpty
        ? validScores.reduce((a, b) => a < b ? a : b)
        : null;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: routes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final r = routes[index];
          final isSelected = r.id == activeRouteId;
          final durationStr = formatDuration(r.durationSeconds);
          final distanceStr = formatDistance(r.distanceMeters);

          final assessment = riskAssessments?[r.id];
          final category = assessment?.result?.riskCategory;
          final score = assessment?.result?.score;

          final isFastest = r.durationSeconds == minDuration;
          final isSafer = minRiskScore != null && score == minRiskScore;

          Color categoryColor = AppColors.routePrimary;
          if (category == RouteRiskCategory.none) {
            categoryColor = AppColors.riskNone;
          }
          if (category == RouteRiskCategory.low) {
            categoryColor = AppColors.riskLow;
          }
          if (category == RouteRiskCategory.moderate) {
            categoryColor = AppColors.riskModerate;
          }
          if (category == RouteRiskCategory.high ||
              category == RouteRiskCategory.veryHigh) {
            categoryColor = AppColors.riskHigh;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectRoute(r.id),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surface
                      : AppColors.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.routePrimary
                        : AppColors.borderSubtle,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? AppColors.shadowDark : Colors.black12,
                      blurRadius: isSelected ? 6 : 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.routePrimary,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      durationStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '· $distanceStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category == RouteRiskCategory.none
                              ? 'Clear'
                              : category.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ],
                    if (isFastest && !isSafer) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⚡ Fastest',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amberText,
                          ),
                        ),
                      ),
                    ],
                    if (isSafer) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.riskLow.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🛡️ Safer',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.riskLow,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
