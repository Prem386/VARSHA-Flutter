import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/constants/app_colors.dart';
import '../../models/route.dart';

/// Layer rendering active and alternative route polylines on the map with clear visual contrast.
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

    final activeRoute = routes.firstWhere(
      (r) => r.id == selectedRouteId,
      orElse: () => routes.first,
    );
    final altRoutes = routes.where((r) => r.id != activeRoute.id).toList();

    final polylines = <Polyline>[];

    // 1. Unselected Alternative Routes (solid slate line, clear contrast against OSM tiles)
    for (final alt in altRoutes) {
      polylines.add(
        Polyline(
          points: alt.coordinates,
          color: const Color(0xFF64748B),
          strokeWidth: 5.0,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    // 2. Active Selected Route (prominent primary amber stroke on top)
    polylines.add(
      Polyline(
        points: activeRoute.coordinates,
        color: AppColors.routePrimary,
        strokeWidth: 6.5,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    );

    return PolylineLayer(polylines: polylines);
  }
}
