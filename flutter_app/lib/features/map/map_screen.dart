import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/pilot_constants.dart';
import '../../models/alert.dart';
import '../../models/hazard.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import '../../models/scenario.dart';
import '../../models/weather.dart';
import '../../services/routing/osrm_service.dart';
import '../../services/routing/route_risk_scoring.dart';
import '../../services/weather/weather_service.dart';
import '../routing/polyline_hit_tester.dart';
import '../routing/route_planner_sheet.dart';
import '../settings/settings_sheet.dart';
import '../shell/about_sheet.dart';
import '../shell/persistent_disclaimer.dart';
import '../weather/weather_alerts_sheet.dart';
import 'endpoint_markers_layer.dart';
import 'floating_search_panel.dart';
import 'hazard_context_card.dart';
import 'hazard_markers_layer.dart';
import 'map_interaction_state.dart';
import 'map_legend.dart';
import 'route_bubbles_bar.dart';
import 'route_callout_badges_layer.dart';
import 'route_polyline_layer.dart';

class MapScreen extends StatefulWidget {
  final WeatherService? weatherService;
  final OsrmService? osrmService;
  final bool showBottomDisclaimer;
  final bool autoFetch;
  final void Function(int initialTab)? onNavigateToWeather;
  final RainfallResponse? initialRainfall;
  final AlertListResponse? initialAlerts;
  final void Function(RainfallResponse rain, AlertListResponse alerts)?
  onDataRefreshed;

  const MapScreen({
    super.key,
    this.weatherService,
    this.osrmService,
    this.showBottomDisclaimer = true,
    this.autoFetch = true,
    this.onNavigateToWeather,
    this.initialRainfall,
    this.initialAlerts,
    this.onDataRefreshed,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late final OsrmService _osrmService;
  late final WeatherService _weatherService;

  // Endpoint & Selection State
  SelectedLocation? _origin;
  SelectedLocation? _destination;
  RouteEndpointType _activeTarget = RouteEndpointType.origin;
  bool _isPickOnMapActive = false;
  bool _isSearchingDestination = false;
  HazardLocation? _inspectedHazard;

  MapInteractionState get interactionState {
    if (_isPickOnMapActive) return MapInteractionState.pickingOnMap;
    if (_inspectedHazard != null) return MapInteractionState.hazardInspection;
    if (_routeStatus == RouteStatus.loading) {
      return MapInteractionState.routesLoading;
    }
    if (_routes.isNotEmpty) {
      return _isPlannerExpanded
          ? MapInteractionState.expandedDetails
          : MapInteractionState.routesCalculated;
    }
    if (_origin != null && _destination != null) {
      return MapInteractionState.endpointsReady;
    }
    if (_destination != null && _origin == null) {
      return MapInteractionState.searchingOrigin;
    }
    if (_isSearchingDestination) {
      return MapInteractionState.searchingDestination;
    }
    return MapInteractionState.initial;
  }

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
  RainfallResponse? _rainfallData;
  AlertListResponse? _alertsData;

  int get _effectiveAlertCount {
    if (_alertsData != null && _alertsData!.provider.status == 'unavailable') {
      return 0;
    }
    return _alertCount;
  }

  // Bottom Planner Expansion State
  bool _isPlannerExpanded = false;
  final double _collapsedFraction = 0.12;
  final double _expandedFraction = 0.65;

  @override
  void initState() {
    super.initState();
    _osrmService = widget.osrmService ?? OsrmService();
    _weatherService = widget.weatherService ?? WeatherService();
    _sheetController.addListener(_onSheetSizeChanged);

    if (widget.initialRainfall != null || widget.initialAlerts != null) {
      if (widget.initialRainfall != null) {
        _rainfallData = widget.initialRainfall;
        _updateRainSummary(widget.initialRainfall!);
      }
      if (widget.initialAlerts != null) {
        _alertsData = widget.initialAlerts;
        _alertCount = widget.initialAlerts!.total;
      }
    } else if (widget.autoFetch) {
      _loadStatusData();
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRainfall != oldWidget.initialRainfall &&
        widget.initialRainfall != null) {
      _rainfallData = widget.initialRainfall;
      _updateRainSummary(widget.initialRainfall!);
    }
    if (widget.initialAlerts != oldWidget.initialAlerts &&
        widget.initialAlerts != null) {
      _alertsData = widget.initialAlerts;
      _alertCount = widget.initialAlerts!.total;
    }
  }

  void _updateRainSummary(RainfallResponse rain) {
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

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  bool _isAnimatingSheet = false;

  void _onSheetSizeChanged() {
    if (!mounted || !_sheetController.isAttached || _isAnimatingSheet) return;
    final isExpanded = _sheetController.size > (_collapsedFraction + 0.05);
    if (isExpanded != _isPlannerExpanded) {
      setState(() => _isPlannerExpanded = isExpanded);
    }
  }

  void _expandPlanner() {
    setState(() => _isPlannerExpanded = true);
    if (_sheetController.isAttached) {
      _isAnimatingSheet = true;
      _sheetController.animateTo(
        _expandedFraction,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).whenComplete(() {
        _isAnimatingSheet = false;
      });
    }
  }

  void _collapsePlanner() {
    if (_sheetController.isAttached) {
      _isAnimatingSheet = true;
      _sheetController.animateTo(
        _collapsedFraction,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).whenComplete(() {
        _isAnimatingSheet = false;
        if (mounted) {
          setState(() => _isPlannerExpanded = false);
        }
      });
    } else {
      setState(() => _isPlannerExpanded = false);
    }
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
        if (_rainfallData != null && _alertsData != null) {
          widget.onDataRefreshed?.call(_rainfallData!, _alertsData!);
        }
      }
    } finally {}
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
    FocusManager.instance.primaryFocus?.unfocus();

    // 1. If hazard context card is displayed, tapping map dismisses it
    if (_inspectedHazard != null) {
      setState(() => _inspectedHazard = null);
      return;
    }

    // 2. If actively picking on map, assign point to active endpoint
    if (_isPickOnMapActive) {
      final formattedLat = double.parse(latLng.latitude.toStringAsFixed(6));
      final formattedLng = double.parse(latLng.longitude.toStringAsFixed(6));
      final loc = SelectedLocation(
        label:
            'Pinned location (${formattedLat.toStringAsFixed(4)}, ${formattedLng.toStringAsFixed(4)})',
        coordinates: LatLng(formattedLat, formattedLng),
        source: 'map',
      );

      _clearExistingRoute();

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
        _isPickOnMapActive = false;
        _collapsePlanner();
      });
      return;
    }

    // 3. If routes are visible on map, hit-test for route selection (non-destructive)
    if (_routes.isNotEmpty) {
      final tapOffset = tapPosition.relative ?? tapPosition.global;
      final tappedRouteId = PolylineHitTester.findTappedRouteId(
        tapPoint: tapOffset,
        routes: _routes,
        selectedRouteId: _selectedRouteId,
        camera: _mapController.camera,
      );
      if (tappedRouteId != null && tappedRouteId != _selectedRouteId) {
        setState(() => _selectedRouteId = tappedRouteId);
      }
      return; // Non-destructive tap: NEVER clear existing routes on accidental map taps!
    }

    // 4. If destination search overlay is open, tapping map dismisses search mode
    if (_isSearchingDestination) {
      setState(() => _isSearchingDestination = false);
    }

    // Random map taps do NOT set origin or destination.
    // Endpoints can only be selected via search or explicitly choosing "Pick on Map".
  }

  void _handleSelectTarget(RouteEndpointType target) {
    setState(() {
      _activeTarget = target;
      _isPickOnMapActive = true;
      _isSearchingDestination = false;
    });
    _collapsePlanner();
  }

  void _handleCancelPickOnMap() {
    setState(() => _isPickOnMapActive = false);
    _collapsePlanner();
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
        _isSearchingDestination = false;
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
              padding: const EdgeInsets.only(
                top: 130,
                bottom: 110,
                left: 40,
                right: 40,
              ),
            ),
          );
        }

        // Collapse to show compact route summary card over map
        _collapsePlanner();
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

  void _showWeatherSheet() {
    WeatherAlertsSheet.show(
      context,
      weatherService: _weatherService,
      initialRainfall: _rainfallData,
      initialAlerts: _alertsData,
      onDataRefreshed: (rain, alerts) {
        setState(() {
          _rainfallData = rain;
          _alertsData = alerts;
          _updateRainSummary(rain);
          _alertCount = alerts.total;
        });
        widget.onDataRefreshed?.call(rain, alerts);
      },
    );
  }

  Widget _buildPickOnMapBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: Offset(0, 2),
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeScenario = getDemoScenario(_selectedScenarioId);
    final currentHazards = activeScenario.hazards;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Base Map Layer (fills full physical display)
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

              // Route Duration Callout Badges (on-map pills)
              if (_routes.length > 1)
                RouteCalloutBadgesLayer(
                  routes: _routes,
                  selectedRouteId: _selectedRouteId,
                  onSelectRoute: (id) => setState(() => _selectedRouteId = id),
                  riskAssessments: _riskAssessments,
                ),

              // Simulated Hazards
              HazardMarkersLayer(
                hazards: currentHazards,
                onSelectHazard: (h) => setState(() => _inspectedHazard = h),
              ),

              // Origin & Destination Pins
              EndpointMarkersLayer(origin: _origin, destination: _destination),
            ],
          ),

          // 2. Coordinated Top Interface (Search, Bubbles, and Map-Picking)
          Positioned(
            top: topInset > 0 ? topInset + 6.0 : 10.0,
            left: 12,
            right: 12,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FloatingSearchPanel(
                      origin: _origin,
                      destination: _destination,
                      activeTarget: _activeTarget,
                      isPickOnMapActive: _isPickOnMapActive,
                      isIdentical: _isIdentical,
                      isSearchingDestination: _isSearchingDestination,
                      routes: _routes,
                      rainSummary: _rainSummary,
                      alertCount: _effectiveAlertCount,
                      onOpenWeather: () {
                        if (widget.onNavigateToWeather != null) {
                          widget.onNavigateToWeather!(0);
                        } else {
                          _showWeatherSheet();
                        }
                      },
                      onOpenAlerts: () {
                        if (widget.onNavigateToWeather != null) {
                          widget.onNavigateToWeather!(1);
                        } else {
                          _showWeatherSheet();
                        }
                      },
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
                      onStartSearchDestination: () {
                        setState(() {
                          _isSearchingDestination = true;
                          _activeTarget = RouteEndpointType.destination;
                        });
                      },
                      onCancelSearch: () {
                        setState(() {
                          _isSearchingDestination = false;
                        });
                      },
                      onSelectTarget: _handleSelectTarget,
                      onSelectOrigin: (loc) {
                        _clearExistingRoute();
                        setState(() {
                          _origin = loc;
                        });
                      },
                      onSelectDestination: (loc) {
                        _clearExistingRoute();
                        setState(() {
                          _destination = loc;
                          _isSearchingDestination = false;
                          if (_origin == null) {
                            _activeTarget = RouteEndpointType.origin;
                          }
                        });
                      },
                      onSwap: _handleSwap,
                      onClear: _handleClear,
                      onPlanRoute: _handlePlanRoute,
                      onClearRoute: _clearExistingRoute,
                    ),

                    // Coordinated Route Bubbles (only when routes exist!)
                    if (_routes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      RouteBubblesBar(
                        routes: _routes,
                        selectedRouteId: _selectedRouteId,
                        onSelectRoute: (id) =>
                            setState(() => _selectedRouteId = id),
                        riskAssessments: _riskAssessments,
                      ),
                    ],

                    // Coordinated Map-picking banner
                    if (_isPickOnMapActive) ...[
                      const SizedBox(height: 6),
                      _buildPickOnMapBanner(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Map Legend (Bottom-Right, non-colliding)
          Positioned(
            right: 12,
            bottom: _routes.isNotEmpty ? 100 : 16,
            child: MapLegend(hasAlternativeRoutes: _routes.length > 1),
          ),

          // 4. Contextual Hazard Details Card (Non-destructive overlay)
          if (_inspectedHazard != null)
            Positioned(
              bottom: _routes.isNotEmpty ? 100 : 20,
              left: 12,
              right: 12,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: HazardContextCard(
                    hazard: _inspectedHazard!,
                    onClose: () => setState(() => _inspectedHazard = null),
                  ),
                ),
              ),
            ),

          // 5. Draggable Route Information Bottom Sheet (ONLY when routes exist!)
          if (_routes.isNotEmpty)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _collapsedFraction,
              minChildSize: _collapsedFraction,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.12, 0.40, 0.65, 0.85],
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

                      // Scrollable Route Summary / Details
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: RoutePlannerSheet(
                            scrollController: scrollController,
                            isExpanded: _isPlannerExpanded,
                            onToggleExpand: () {
                              if (_isPlannerExpanded) {
                                _collapsePlanner();
                              } else {
                                _expandPlanner();
                              }
                            },
                            origin: _origin,
                            destination: _destination,
                            isIdentical: _isIdentical,
                            routes: _routes,
                            selectedRouteId: _selectedRouteId,
                            onSelectRoute: (id) =>
                                setState(() => _selectedRouteId = id),
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
                            onSelectOrigin: (loc) {
                              _clearExistingRoute();
                              setState(() => _origin = loc);
                            },
                            onSelectDestination: (loc) {
                              _clearExistingRoute();
                              setState(() => _destination = loc);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: widget.showBottomDisclaimer
          ? PersistentDisclaimer(onLearnMore: () => AboutSheet.show(context))
          : null,
    );
  }
}
