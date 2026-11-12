import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/pilot_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../models/route.dart';
import 'corridors.dart';

class OsrmService {
  final http.Client _client;

  OsrmService({http.Client? client}) : _client = client ?? http.Client();

  RoadRoute? _parseRouteItem(
    Map<String, dynamic> routeItem,
    String id,
    String label,
    LatLng origin,
    LatLng destination,
  ) {
    final distance = (routeItem['distance'] as num?)?.toDouble();
    final duration = (routeItem['duration'] as num?)?.toDouble();

    if (distance == null || !distance.isFinite || distance < 0 ||
        duration == null || !duration.isFinite || duration < 0) {
      return null;
    }

    final geometry = routeItem['geometry'] as Map<String, dynamic>?;
    final rawCoords = geometry?['coordinates'] as List<dynamic>?;
    if (rawCoords == null || rawCoords.length < 2) return null;

    final latLngs = <LatLng>[];
    for (final pt in rawCoords) {
      if (pt is List && pt.length >= 2) {
        final lon = (pt[0] as num?)?.toDouble();
        final lat = (pt[1] as num?)?.toDouble();
        if (lon == null || lat == null || !lon.isFinite || !lat.isFinite) {
          return null;
        }
        latLngs.add(LatLng(lat, lon));
      } else {
        return null;
      }
    }

    if (latLngs.length < 2) return null;

    final candidate = RoadRoute(
      id: id,
      label: label,
      coordinates: latLngs,
      distanceMeters: distance,
      durationSeconds: duration,
      engineEstimateNotice: PilotConstants.osrmEstimateNotice,
    );

    if (!validateRouteEndpoints(candidate, origin, destination)) {
      return null;
    }

    return candidate;
  }

  /// Retrieves driving routes from OSRM router with parallel corridor fallback.
  Future<List<RoadRoute>> fetchRoadRoutes(
    LatLng origin,
    LatLng destination, {
    String? customBaseUrl,
  }) async {
    final baseUrl = (customBaseUrl ?? AppConfig.osrmRouterUrl).replaceAll(RegExp(r'/+$'), '');

    final coordsParam =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    final primaryUri = Uri.parse(
      '$baseUrl/route/v1/driving/$coordsParam?overview=full&geometries=geojson&steps=false&alternatives=3',
    );

    http.Response primaryResponse;
    try {
      primaryResponse = await _client.get(primaryUri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw const RoutingException(
        'Unable to connect to routing service. Please check your internet connection and retry.',
      );
    }

    Map<String, dynamic> primaryData;
    try {
      primaryData = jsonDecode(primaryResponse.body) as Map<String, dynamic>;
    } catch (_) {
      throw const RoutingException('Received an unreadable response from the routing service.');
    }

    final code = primaryData['code'] as String?;
    if (primaryResponse.statusCode != 200 || code != 'Ok') {
      if (code == 'NoRoute') {
        throw const RoutingException(
          'No driving route found between selected points. Try choosing points on connected roads.',
        );
      }
      if (code == 'NoSegment') {
        throw const RoutingException(
          'One of the selected points is too far from a navigable road. Please adjust your pins.',
        );
      }
      final msg = primaryData['message'] as String?;
      throw RoutingException(msg ?? 'Routing service returned an error (${primaryResponse.statusCode}).');
    }

    final rawRoutes = primaryData['routes'] as List<dynamic>?;
    if (rawRoutes == null || rawRoutes.isEmpty) {
      throw const RoutingException('Routing service returned no route options.');
    }

    final validNativeRoutes = <RoadRoute>[];
    for (int i = 0; i < rawRoutes.length; i++) {
      final item = rawRoutes[i] as Map<String, dynamic>;
      final candidate = _parseRouteItem(
        item,
        'osrm-route-${i + 1}',
        'Route ${i + 1}',
        origin,
        destination,
      );
      if (candidate != null) {
        final isDuplicate = validNativeRoutes.any((r) => !isRouteDistinct(r, candidate));
        if (!isDuplicate) {
          validNativeRoutes.add(candidate);
        }
      }
    }

    if (validNativeRoutes.isEmpty) {
      throw const RoutingException(
        'Routing service returned no usable route options within expected endpoint tolerance.',
      );
    }

    // Multiple distinct routes found natively
    if (validNativeRoutes.length > 1) {
      validNativeRoutes[0].label = 'Route 1 (Primary)';
      for (int i = 1; i < validNativeRoutes.length; i++) {
        validNativeRoutes[i].label = 'Route ${i + 1} (Alternative)';
      }
      return validNativeRoutes;
    }

    // Single route found: check known parallel corridor for Navi Mumbai
    final primaryRoute = validNativeRoutes.first;
    final corridor = findMatchingCorridor(origin, destination);
    if (corridor == null) {
      primaryRoute.label = 'Primary Road Route';
      return [primaryRoute];
    }

    // Attempt corridor via-point query
    try {
      final via = corridor.viaWaypoint;
      final viaCoordsParam =
          '${origin.longitude},${origin.latitude};${via.longitude},${via.latitude};${destination.longitude},${destination.latitude}';
      final viaUri = Uri.parse(
        '$baseUrl/route/v1/driving/$viaCoordsParam?overview=full&geometries=geojson&steps=false',
      );

      final viaResponse = await _client.get(viaUri).timeout(const Duration(seconds: 10));
      if (viaResponse.statusCode == 200) {
        final viaData = jsonDecode(viaResponse.body) as Map<String, dynamic>;
        final viaRoutes = viaData['routes'] as List<dynamic>?;
        if (viaRoutes != null && viaRoutes.isNotEmpty) {
          final rawViaItem = viaRoutes.first as Map<String, dynamic>;
          final candidateVia = _parseRouteItem(
            rawViaItem,
            'osrm-route-2',
            'Route 2 (${corridor.alternativeLabel})',
            origin,
            destination,
          );

          if (candidateVia != null && isRouteDistinct(primaryRoute, candidateVia)) {
            primaryRoute.label = 'Route 1 (${corridor.primaryLabel})';
            primaryRoute.corridorName = corridor.name;

            candidateVia.corridorName = corridor.name;
            candidateVia.isCorridorAlternative = true;
            candidateVia.engineEstimateNotice =
                'Via-waypoint candidate route along ${corridor.viaName}. Duration does not reflect live traffic or monsoon hazard delays.';

            return [primaryRoute, candidateVia];
          }
        }
      }
    } catch (_) {
      // Fallback failure must not break primary route
    }

    primaryRoute.label = 'Primary Road Route';
    return [primaryRoute];
  }

  /// Single route convenience wrapper.
  Future<RoadRoute> fetchRoadRoute(
    LatLng origin,
    LatLng destination, {
    String? customBaseUrl,
  }) async {
    final routes = await fetchRoadRoutes(origin, destination, customBaseUrl: customBaseUrl);
    return routes.first;
  }
}
