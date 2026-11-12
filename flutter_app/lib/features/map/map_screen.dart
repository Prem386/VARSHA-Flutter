import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/pilot_constants.dart';
import '../../models/alert.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import '../../models/scenario.dart';
import '../../models/weather.dart';
import '../../services/routing/osrm_service.dart';
import '../../services/routing/route_risk_scoring.dart';
import '../../services/weather/weather_service.dart';
import '../routing/route_planner_sheet.dart';
import '../settings/settings_sheet.dart';
import '../shell/about_sheet.dart';
import '../shell/persistent_disclaimer.dart';
import '../shell/top_status_strip.dart';
import '../weather/weather_alerts_sheet.dart';
import 'endpoint_markers_layer.dart';
import 'hazard_markers_layer.dart';
import 'map_legend.dart';
import 'route_polyline_layer.dart';

class MapScreen extends StatefulWidget {
  final WeatherService? weatherService;
  final OsrmService? osrmService;

  const MapScreen({super.key, this.weatherService, this.osrmService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  late final OsrmService _osrmService;
  late final WeatherService _weatherService;

  // Endpoint & Selection State
  SelectedLocation? _origin;
  SelectedLocation? _destination;
  RouteEndpointType _activeTarget = RouteEndpointType.origin;
  bool _isPickOnMapActive = false;

  // Scenario State
  DemoScenarioId _selectedScenarioId = DemoScenarioId.baseline;

  // Routing State
  List<RoadRoute> _routes = [];
  String? _selectedRouteId;
  RouteStatus _routeStatus = RouteStatus.idle;
  String? _routeError;
  Map<String, RouteRiskAssessment> _riskAssessments = {};

  // Status Strip Data
  String _rainSummary = '0.0 mm · Clear';
  int _alertCount = 0;
  bool _isRefreshing = false;
  RainfallResponse? _rainfallData;
  AlertListResponse? _alertsData;

  @override
  void initState() {
    super.initState();
    _osrmService = widget.osrmService ?? OsrmService();
    _weatherService = widget.weatherService ?? WeatherService();
    _loadStatusData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  bool get _isIdentical {
    if (_origin == null || _destination == null) return false;
    final o = _origin!.coordinates;
    final d = _destination!.coordinates;
    return (o.latitude - d.latitude).abs() < 0.0001 &&
        (o.longitude - d.longitude).abs() < 0.0001;
  }

  void _clearExistingRoute() {
    setState(() {
      _routes = [];
      _selectedRouteId = null;
      _routeStatus = RouteStatus.idle;
      _routeError = null;
      _riskAssessments = {};
    });
  }

  void _updateRiskAssessments() {
    final activeScenario = getDemoScenario(_selectedScenarioId);
    setState(() {
      _riskAssessments = assessRoutesRisk(_routes, activeScenario.hazards);
    });
  }

  Future<void> _loadStatusData() async {
    setState(() => _isRefreshing = true);
    try {
      final rain = await _safeFetchRainfall();
      final alerts = await _safeFetchAlerts();

      if (mounted) {
        setState(() {
          if (rain != null) {
            _rainfallData = rain;
            final mm = rain.current?.precipitationMm ?? 0.0;
            final desc = mm > 15
                ? 'Heavy rain'
                : mm > 5
                    ? 'Moderate rain'
                    : mm > 0.5
                        ? 'Light rain'
                        : 'Clear';
            _rainSummary = '${mm.toStringAsFixed(1)} mm (15m) · $desc';
          }
          if (alerts != null) {
            _alertsData = alerts;
            _alertCount = alerts.total;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<RainfallResponse?> _safeFetchRainfall() async {
    try {
      return await _weatherService.fetchRainfallForecast();
    } catch (_) {
      return null;
    }
  }

  Future<AlertListResponse?> _safeFetchAlerts() async {
    try {
      return await _weatherService.fetchOfficialAlerts();
    } catch (_) {
      return null;
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    _clearExistingRoute();

    final formattedLat = double.parse(latLng.latitude.toStringAsFixed(6));
    final formattedLng = double.parse(latLng.longitude.toStringAsFixed(6));
    final loc = SelectedLocation(
      label: 'Pinned location (${formattedLat.toStringAsFixed(4)}, ${formattedLng.toStringAsFixed(4)})',
      coordinates: LatLng(formattedLat, formattedLng),
      source: 'map',
    );

    setState(() {
      if (_activeTarget == RouteEndpointType.origin) {
        _origin = loc;
        if (_destination == null) {
          _activeTarget = RouteEndpointType.destination;
        }
      } else {
        _destination = loc;
        if (_origin == null) {
          _activeTarget = RouteEndpointType.origin;
        }
      }

      if (_isPickOnMapActive) {
        _isPickOnMapActive = false;
        try {
          _sheetController.animateTo(
            0.45,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  void _handleSelectTarget(RouteEndpointType target) {
    setState(() {
      _activeTarget = target;
      _isPickOnMapActive = true;
    });
    try {
      _sheetController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  void _handleCancelPickOnMap() {
    setState(() => _isPickOnMapActive = false);
    try {
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  void _handleSwap() {
    _clearExistingRoute();
    setState(() {
      final prevO = _origin;
      _origin = _destination;
      _destination = prevO;
    });
  }

  void _handleClear(RouteEndpointType target) {
    _clearExistingRoute();
    setState(() {
      if (target == RouteEndpointType.origin) {
        _origin = null;
        _activeTarget = RouteEndpointType.origin;
      } else {
        _destination = null;
        _activeTarget = RouteEndpointType.destination;
      }
    });
  }

  Future<void> _handlePlanRoute() async {
    if (_origin == null || _destination == null || _isIdentical) return;

    setState(() {
      _routeStatus = RouteStatus.loading;
      _routeError = null;
    });

    try {
      final results = await _osrmService.fetchRoadRoutes(
        _origin!.coordinates,
        _destination!.coordinates,
      );

      if (mounted) {
        setState(() {
          _routes = results;
          _selectedRouteId = results.first.id;
          _routeStatus = RouteStatus.success;
        });
        _updateRiskAssessments();

        // Fit map bounds to encompass the new route coordinates
        if (results.first.coordinates.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(results.first.coordinates);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(top: 80, bottom: 260, left: 40, right: 40),
            ),
          );
        }

        // Expand sheet to half
        try {
          _sheetController.animateTo(
            0.55,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _routes = [];
          _selectedRouteId = null;
          _routeStatus = RouteStatus.error;
          _routeError = err.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeScenario = getDemoScenario(_selectedScenarioId);
    final currentHazards = activeScenario.hazards;

    return Scaffold(
      appBar: TopStatusStrip(
        rainSummary: _rainSummary,
        alertCount: _alertCount,
        isRefreshing: _isRefreshing,
        onRefresh: _loadStatusData,
        onOpenWeather: () {
          WeatherAlertsSheet.show(
            context,
            weatherService: _weatherService,
            initialRainfall: _rainfallData,
            initialAlerts: _alertsData,
            onDataRefreshed: (rain, alerts) {
              setState(() {
                _rainfallData = rain;
                _alertsData = alerts;
                final mm = rain.current?.precipitationMm ?? 0.0;
                final desc = mm > 15
                    ? 'Heavy rain'
                    : mm > 5
                        ? 'Moderate rain'
                        : mm > 0.5
                            ? 'Light rain'
                            : 'Clear';
                _rainSummary = '${mm.toStringAsFixed(1)} mm (15m) · $desc';
                _alertCount = alerts.total;
              });
            },
          );
        },
        onOpenAbout: () => AboutSheet.show(context),
        onOpenSettings: () {
          SettingsSheet.show(
            context,
            onConfigChanged: () {
              _loadStatusData();
              if (_origin != null && _destination != null) {
                _handlePlanRoute();
              }
            },
          );
        },
      ),
      body: Stack(
        children: [
          // 1. Base Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: PilotConstants.naviMumbaiCenter,
              initialZoom: PilotConstants.defaultZoom,
              minZoom: 9.0,
              maxZoom: 18.0,
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: PilotConstants.osmTileUrl,
                userAgentPackageName: PilotConstants.osmUserAgent,
              ),

              // Route Polylines
              RoutePolylineLayer(
                routes: _routes,
                selectedRouteId: _selectedRouteId,
              ),

              // Simulated Hazards
              HazardMarkersLayer(hazards: currentHazards),

              // Origin & Destination Pins
              EndpointMarkersLayer(
                origin: _origin,
                destination: _destination,
              ),
            ],
          ),

          // 2. Floating Pick on Map Banner (when active)
          if (_isPickOnMapActive)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowDark,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.amber),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap map to set ${_activeTarget == RouteEndpointType.origin ? "Origin (A)" : "Destination (B)"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleCancelPickOnMap,
                        child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Map Legend (top right)
          Positioned(
            top: _isPickOnMapActive ? 68 : 12,
            right: 12,
            child: SafeArea(
              child: MapLegend(hasAlternativeRoutes: _routes.length > 1),
            ),
          ),

          // 4. Draggable Route Planner Bottom Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.32,
            minChildSize: 0.12,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.12, 0.32, 0.55, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Sheet Handle Area
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withAlpha(80),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Scrollable Route Planner Content
                    Expanded(
                      child: RoutePlannerSheet(
                        scrollController: scrollController,
                        origin: _origin,
                        destination: _destination,
                        activeTarget: _activeTarget,
                        onSelectTarget: _handleSelectTarget,
                        onSelectOrigin: (loc) {
                          _clearExistingRoute();
                          setState(() {
                            _origin = loc;
                            if (_destination == null) {
                              _activeTarget = RouteEndpointType.destination;
                            }
                          });
                        },
                        onSelectDestination: (loc) {
                          _clearExistingRoute();
                          setState(() {
                            _destination = loc;
                            if (_origin == null) {
                              _activeTarget = RouteEndpointType.origin;
                            }
                          });
                        },
                        onSwap: _handleSwap,
                        onClear: _handleClear,
                        isIdentical: _isIdentical,
                        routes: _routes,
                        selectedRouteId: _selectedRouteId,
                        onSelectRoute: (id) => setState(() => _selectedRouteId = id),
                        routeStatus: _routeStatus,
                        routeError: _routeError,
                        onPlanRoute: _handlePlanRoute,
                        onClearRoute: _clearExistingRoute,
                        riskAssessments: _riskAssessments,
                        selectedScenarioId: _selectedScenarioId,
                        onSelectScenario: (scenarioId) {
                          setState(() => _selectedScenarioId = scenarioId);
                          _updateRiskAssessments();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: PersistentDisclaimer(
        onLearnMore: () => AboutSheet.show(context),
      ),
    );
  }
}
