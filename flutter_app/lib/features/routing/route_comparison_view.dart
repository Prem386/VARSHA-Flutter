import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import 'route_risk_card.dart';

class RouteComparisonView extends StatelessWidget {
  final List<RoadRoute> routes;
  final String? selectedRouteId;
  final ValueChanged<String> onSelectRoute;
  final VoidCallback onClearRoute;
  final Map<String, RouteRiskAssessment>? riskAssessments;

  const RouteComparisonView({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
    required this.onClearRoute,
    this.riskAssessments,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    final activeRoute =
        routes.firstWhere((r) => r.id == selectedRouteId, orElse: () => routes.first);

    // Calculate comparative trade-offs
    final minDuration = routes.map((r) => r.durationSeconds).reduce((a, b) => a < b ? a : b);
    final minDistance = routes.map((r) => r.distanceMeters).reduce((a, b) => a < b ? a : b);

    final validScores = routes
        .map((r) => riskAssessments?[r.id]?.result?.score)
        .whereType<double>()
        .toList();
    final minRiskScore = validScores.isNotEmpty
        ? validScores.reduce((a, b) => a < b ? a : b)
        : null;

    // Sort routes: lowest risk score first, then duration
    final sortedRoutes = List<RoadRoute>.from(routes)..sort((a, b) {
      final scoreA = riskAssessments?[a.id]?.result?.score ?? 999.0;
      final scoreB = riskAssessments?[b.id]?.result?.score ?? 999.0;
      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }
      return a.durationSeconds.compareTo(b.durationSeconds);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.routePrimary.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      routes.length > 1
                          ? 'OSRM Alternatives • ${routes.length} Found'
                          : 'Route Retrieved',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.routePrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routes.length > 1 ? 'Alternative Route Comparison' : 'OSRM Road Route',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onClearRoute,
              child: Text(
                routes.length > 1 ? 'Clear Routes' : 'Clear Line',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Route Cards List
        ...sortedRoutes.asMap().entries.map((entry) {
          final index = entry.key;
          final r = entry.value;
          final isSelected = r.id == activeRoute.id;
          final label = r.label ?? 'Route ${index + 1}';

          final isFastest = r.durationSeconds == minDuration;
          final isShortest = r.distanceMeters == minDistance;
          final isSafer = minRiskScore != null &&
              riskAssessments?[r.id]?.result?.score == minRiskScore;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.routePrimary
                    : isSafer
                        ? AppColors.riskLow.withAlpha(128)
                        : AppColors.borderSubtle,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Number, Name, Corridor Tag, Status
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.routePrimary : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.routePrimary.withAlpha(26)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSelected ? '✓ Highlighted' : 'Alternative',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.routePrimary : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                if (r.corridorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.corridorName!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],

                // Trade-off Badges
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isSafer)
                      _buildTradeoffBadge('🛡️ Recommended / Safer', AppColors.riskNone),
                    if (isFastest)
                      _buildTradeoffBadge('⚡ Fastest Estimate', AppColors.amberText),
                    if (isShortest)
                      _buildTradeoffBadge('📏 Shortest Distance', AppColors.routePrimary),
                  ],
                ),

                const SizedBox(height: 10),

                // Metrics Row
                Row(
                  children: [
                    _buildMetricBox('Distance', formatDistance(r.distanceMeters)),
                    const SizedBox(width: 8),
                    _buildMetricBox('Est. Duration', formatDuration(r.durationSeconds)),
                    const SizedBox(width: 8),
                    _buildMetricBox('Points', '${r.coordinates.length} pts'),
                  ],
                ),

                // Risk Assessment Display
                RouteRiskCard(assessment: riskAssessments?[r.id]),

                // Select Button
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.routePrimary : AppColors.surface,
                      foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                      elevation: 0,
                      side: BorderSide(
                        color: isSelected ? AppColors.routePrimary : AppColors.borderInteractive,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: isSelected ? null : () => onSelectRoute(r.id),
                    child: Text(
                      isSelected ? 'Highlighted on Map' : 'Select This Route',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Single route notice if only 1
        if (routes.length == 1)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Single driving route returned by routing service. No distinct alternative corridor found for these endpoints.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prototype risk estimate based on simulated hazards. This is not a validated flood prediction or guarantee of route safety.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                activeRoute.engineEstimateNotice,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeoffBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
