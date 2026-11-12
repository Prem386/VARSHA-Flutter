import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/constants/app_colors.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';

/// Renders interactive on-map duration callout pills at route midpoints.
/// Inspired by Google Maps Android route badge markers.
class RouteCalloutBadgesLayer extends StatelessWidget {
  final List<RoadRoute> routes;
  final String? selectedRouteId;
  final ValueChanged<String> onSelectRoute;
  final Map<String, RouteRiskAssessment>? riskAssessments;

  const RouteCalloutBadgesLayer({
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
    final activeRoute = routes.firstWhere(
      (r) => r.id == activeRouteId,
      orElse: () => routes.first,
    );
    final activeDuration = activeRoute.durationSeconds;

    final markers = <Marker>[];

    for (int i = 0; i < routes.length; i++) {
      final r = routes[i];
      if (r.coordinates.isEmpty) continue;

      // Select midpoint along coordinates
      final midIndex = (r.coordinates.length * 0.45).toInt().clamp(
        0,
        r.coordinates.length - 1,
      );
      final point = r.coordinates[midIndex];
      final isSelected = r.id == activeRouteId;

      final durationMinutes = (r.durationSeconds / 60).round();
      final diffSeconds = r.durationSeconds - activeDuration;
      final diffMinutes = (diffSeconds / 60).round();

      final label = isSelected
          ? '$durationMinutes min'
          : (diffMinutes > 0 ? '+$diffMinutes min' : '$diffMinutes min');

      markers.add(
        Marker(
          point: point,
          width: 108,
          height: 34,
          child: GestureDetector(
            onTap: () => onSelectRoute(r.id),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.routePrimary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.navigation_rounded
                          : Icons.directions_outlined,
                      size: 11,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }
}
