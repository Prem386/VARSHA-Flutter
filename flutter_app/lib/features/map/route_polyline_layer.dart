import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/app_colors.dart';
import '../../models/route.dart';

/// Layer rendering active and alternative route polylines on the map.
class RoutePolylineLayer extends StatelessWidget {
  final List<RoadRoute> routes;
  final String? selectedRouteId;

  const RoutePolylineLayer({
    super.key,
    required this.routes,
    required this.selectedRouteId,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    final activeRoute =
        routes.firstWhere((r) => r.id == selectedRouteId, orElse: () => routes.first);
    final altRoutes = routes.where((r) => r.id != activeRoute.id).toList();

    final polylines = <Polyline>[];

    // 1. Unselected Alternative Routes (rendered first, below active)
    for (final alt in altRoutes) {
      polylines.add(
        Polyline(
          points: alt.coordinates,
          color: AppColors.routeAlternative.withAlpha(153),
          strokeWidth: 4.5,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
          pattern: StrokePattern.dashed(segments: const [10, 8]),
        ),
      );
    }

    // 2. Active Selected Route (rendered on top)
    polylines.add(
      Polyline(
        points: activeRoute.coordinates,
        color: AppColors.routePrimary,
        strokeWidth: 6.0,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    );

    return PolylineLayer(polylines: polylines);
  }
}
