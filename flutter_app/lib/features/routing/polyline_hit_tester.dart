import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/route.dart';

/// Screen-space hit-testing utility for interactive polyline route selection.
/// Calculates Euclidean distance from a screen tap to route line segments.
class PolylineHitTester {
  /// Finds the route whose polyline passes within [thresholdPixels] of [tapPoint].
  /// Uses [camera.latLngToScreenOffset] for viewport-accurate screen distances.
  static String? findTappedRouteId({
    required Offset tapPoint,
    required List<RoadRoute> routes,
    required String? selectedRouteId,
    required MapCamera camera,
    double thresholdPixels = 28.0,
  }) {
    if (routes.isEmpty) return null;

    String? bestRouteId;
    double bestDistance = double.infinity;

    for (final route in routes) {
      if (route.coordinates.length < 2) continue;

      for (int i = 0; i < route.coordinates.length - 1; i++) {
        final p1 = camera.latLngToScreenOffset(route.coordinates[i]);
        final p2 = camera.latLngToScreenOffset(route.coordinates[i + 1]);

        final dist = distanceToSegment(tapPoint, p1, p2);
        if (dist <= thresholdPixels && dist < bestDistance) {
          bestDistance = dist;
          bestRouteId = route.id;
        }
      }
    }

    return bestRouteId;
  }

  /// Calculates perpendicular distance from point P to line segment AB in screen coordinates.
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b.dx - a.dx) * (b.dx - a.dx) + (b.dy - a.dy) * (b.dy - a.dy);
    if (l2 == 0) {
      return math.sqrt(
        (p.dx - a.dx) * (p.dx - a.dx) + (p.dy - a.dy) * (p.dy - a.dy),
      );
    }

    var t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = math.max(0.0, math.min(1.0, t));

    final projX = a.dx + t * (b.dx - a.dx);
    final projY = a.dy + t * (b.dy - a.dy);

    final dx = p.dx - projX;
    final dy = p.dy - projY;
    return math.sqrt(dx * dx + dy * dy);
  }
}
