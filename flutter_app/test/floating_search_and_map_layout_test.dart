import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:varsha_flutter/core/config/app_config.dart';
import 'package:varsha_flutter/core/theme/app_theme.dart';
import 'package:varsha_flutter/features/map/floating_search_panel.dart';
import 'package:varsha_flutter/features/map/map_screen.dart';
import 'package:varsha_flutter/features/routing/place_search_field.dart';
import 'package:varsha_flutter/features/routing/route_planner_sheet.dart';
import 'package:varsha_flutter/features/shell/main_navigation_shell.dart';
import 'package:varsha_flutter/features/shell/top_status_strip.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/risk_assessment.dart';
import 'package:varsha_flutter/models/route.dart';
import 'package:varsha_flutter/models/scenario.dart';
import 'package:varsha_flutter/models/weather.dart';
import 'package:varsha_flutter/services/weather/weather_service.dart';

class _FakeWeatherService extends WeatherService {
  @override
  Future<RainfallResponse> fetchRainfallForecast({
    double latitude = 19.0330,
    double longitude = 73.0297,
    int forecastHours = 24,
    String? customBaseUrl,
  }) async {
    return const RainfallResponse(
      provider: RainfallProviderStatus(
        provider: 'open_meteo',
        status: 'ok',
        isCached: false,
        isStale: false,
        endpointUrl: '',
      ),
      requestedCoordinate: {'latitude': 19.033, 'longitude': 73.0297},
      dataType: 'numerical_weather_prediction_precipitation',
      isModelDerived: true,
      isPhysicalObservation: false,
      current: CurrentRainfall(
        timestamp: '2026-11-12T07:00:00Z',
        intervalSeconds: 900,
        precipitationMm: 0.0,
        unit: 'mm',
        isModelDerived: true,
        isPhysicalObservation: false,
        intervalDescription: '15m window',
      ),
      hourly: [],
      caveats: [],
    );
  }

  @override
  Future<AlertListResponse> fetchOfficialAlerts({
    bool activeOnly = true,
    String? customBaseUrl,
  }) async {
    return const AlertListResponse(
      provider: AlertProviderStatus(
        provider: 'sachet',
        status: 'ok',
        isCached: false,
        isStale: false,
        feedUrl: '',
      ),
      total: 0,
      alerts: [],
      spatialFilterApplied: false,
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppConfig.initialize();
  });

  group('Phase 5B: Mobile-First Map Layout and Floating Search', () {
    testWidgets('1. TopStatusStrip is compact with 48px height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: TopStatusStrip(
              rainSummary: '2.5 mm · Light rain',
              alertCount: 1,
              isRefreshing: false,
              onRefresh: () {},
              onOpenWeather: () {},
              onOpenAbout: () {},
              onOpenSettings: () {},
            ),
            body: const SizedBox(),
          ),
        ),
      );

      final strip = tester.widget<TopStatusStrip>(find.byType(TopStatusStrip));
      expect(strip.preferredSize.height, 48.0);
      expect(find.text('VARSHA'), findsOneWidget);
      expect(find.text('Pilot: Navi Mumbai'), findsOneWidget);
      expect(find.text('2.5 mm · Light rain'), findsOneWidget);
      expect(find.text('1 active'), findsOneWidget);
    });

    testWidgets('2. FloatingSearchPanel renders Origin (A) and Destination (B) distinctly', (WidgetTester tester) async {
      SelectedLocation? origin;
      SelectedLocation? destination;
      RouteEndpointType target = RouteEndpointType.origin;
      bool pickActive = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingSearchPanel(
                  origin: origin,
                  destination: destination,
                  activeTarget: target,
                  isPickOnMapActive: pickActive,
                  onSelectTarget: (t) => setState(() {
                    target = t;
                    pickActive = true;
                  }),
                  onSelectOrigin: (loc) => setState(() => origin = loc),
                  onSelectDestination: (loc) => setState(() => destination = loc),
                  onSwap: () {
                    setState(() {
                      final tmp = origin;
                      origin = destination;
                      destination = tmp;
                    });
                  },
                  onClear: (t) {
                    setState(() {
                      if (t == RouteEndpointType.origin) origin = null;
                      if (t == RouteEndpointType.destination) destination = null;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify Origin and Destination fields and badges
      expect(find.text('Origin'), findsOneWidget);
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Swap'), findsOneWidget);

      // Tap Pick on Map for Origin
      await tester.tap(find.byTooltip('Pick on Map').first);
      await tester.pump();
      expect(target, RouteEndpointType.origin);
      expect(pickActive, true);
    });

    testWidgets('3. FloatingSearchPanel swap and clear actions function correctly', (WidgetTester tester) async {
      SelectedLocation? origin = const SelectedLocation(
        label: 'Vashi Station',
        coordinates: LatLng(19.0645, 72.9983),
        source: 'curated',
      );
      SelectedLocation? destination = const SelectedLocation(
        label: 'CBD Belapur Station',
        coordinates: LatLng(19.0185, 73.0385),
        source: 'curated',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingSearchPanel(
                  origin: origin,
                  destination: destination,
                  activeTarget: RouteEndpointType.origin,
                  isPickOnMapActive: false,
                  onSelectTarget: (_) {},
                  onSelectOrigin: (loc) => setState(() => origin = loc),
                  onSelectDestination: (loc) => setState(() => destination = loc),
                  onSwap: () {
                    setState(() {
                      final tmp = origin;
                      origin = destination;
                      destination = tmp;
                    });
                  },
                  onClear: (t) {
                    setState(() {
                      if (t == RouteEndpointType.origin) origin = null;
                      if (t == RouteEndpointType.destination) destination = null;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Check initial text
      expect(find.text('Vashi Station'), findsOneWidget);
      expect(find.text('CBD Belapur Station'), findsOneWidget);

      // Tap Swap
      await tester.tap(find.text('Swap'));
      await tester.pump();

      // Swapped locations
      expect(origin?.label, 'CBD Belapur Station');
      expect(destination?.label, 'Vashi Station');

      // Tap clear for Origin
      await tester.tap(find.byTooltip('Clear origin'));
      await tester.pump();
      expect(origin, isNull);
    });

    testWidgets('4. FloatingSearchPanel shows warning when origin and destination are identical', (WidgetTester tester) async {
      const sameLoc = SelectedLocation(
        label: 'Vashi Station',
        coordinates: LatLng(19.0645, 72.9983),
        source: 'curated',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: FloatingSearchPanel(
              origin: sameLoc,
              destination: sameLoc,
              isIdentical: true,
              activeTarget: RouteEndpointType.origin,
              isPickOnMapActive: false,
              onSelectTarget: (_) {},
              onSelectOrigin: (_) {},
              onSelectDestination: (_) {},
              onSwap: () {},
              onClear: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Origin and destination cannot be the same location.'), findsOneWidget);
    });

    testWidgets('5. MapScreen integrates FloatingSearchPanel and Pick on Map banner', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MapScreen(
            weatherService: _FakeWeatherService(),
            autoFetch: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify floating search panel exists with single Where to? search surface
      expect(find.byType(FloatingSearchPanel), findsOneWidget);
      expect(find.text('Where to?'), findsOneWidget);

      // Tap Where to? to enter destination search mode
      await tester.tap(find.text('Where to?'));
      await tester.pumpAndSettle();

      expect(find.text('Destination'), findsOneWidget);

      // Tap Pick on Map for Destination
      await tester.tap(find.byTooltip('Pick on Map').first);
      await tester.pumpAndSettle();

      // Pick on Map banner appears
      expect(find.textContaining('Tap map to set Destination (B)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Banner dismissed
      expect(find.textContaining('Tap map to set Destination (B)'), findsNothing);
    });

    testWidgets('6. RoutePlannerSheet is simplified without duplicated search inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RoutePlannerSheet(
              origin: null,
              destination: null,
              isIdentical: false,
              routes: const [],
              selectedRouteId: null,
              onSelectRoute: (_) {},
              routeStatus: RouteStatus.idle,
              routeError: null,
              onPlanRoute: () {},
              onClearRoute: () {},
              selectedScenarioId: DemoScenarioId.baseline,
              onSelectScenario: (_) {},
              onSelectOrigin: (_) {},
              onSelectDestination: (_) {},
            ),
          ),
        ),
      );

      // Heading and preset options present
      expect(find.text('Plan your route'), findsOneWidget);
      expect(find.text('Popular routes in Navi Mumbai:'), findsOneWidget);
      expect(find.text('Vashi → Belapur'), findsOneWidget);
      expect(find.text('Airoli → Kharghar'), findsOneWidget);
      expect(find.text('Nerul → Seawoods'), findsOneWidget);

      // Route planning CTA button present
      expect(find.text('Plan Driving Routes'), findsOneWidget);
      expect(find.text('Demo mode'), findsOneWidget);

      // Search fields are NOT duplicated inside the sheet
      expect(find.byType(PlaceSearchField), findsNothing);
    });

    testWidgets('7. Initial launch shows single destination-search surface without empty route-planning bottom panel', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MapScreen(
            weatherService: _FakeWeatherService(),
            autoFetch: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clean map screen: Single floating search surface "Where to?" visible
      expect(find.byType(FloatingSearchPanel), findsOneWidget);
      expect(find.text('Where to?'), findsOneWidget);

      // Empty route planning bottom panel is NOT visible
      expect(find.text('Plan your route'), findsNothing);
      expect(find.text('Choose your start and destination above'), findsNothing);
      expect(find.byTooltip('Expand planner'), findsNothing);
    });

    testWidgets('8. Route planner expands on tap and collapses via down chevron', (WidgetTester tester) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RoutePlannerSheet(
                  isExpanded: isExpanded,
                  onToggleExpand: () => setState(() => isExpanded = !isExpanded),
                  origin: null,
                  destination: null,
                  isIdentical: false,
                  routes: const [],
                  selectedRouteId: null,
                  onSelectRoute: (_) {},
                  routeStatus: RouteStatus.idle,
                  routeError: null,
                  onPlanRoute: () {},
                  onClearRoute: () {},
                  selectedScenarioId: DemoScenarioId.baseline,
                  onSelectScenario: (_) {},
                  onSelectOrigin: (_) {},
                  onSelectDestination: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byTooltip('Expand planner'), findsOneWidget);
      expect(find.text('Popular routes in Navi Mumbai:'), findsNothing);

      // Tap to expand
      await tester.tap(find.byTooltip('Expand planner'));
      await tester.pumpAndSettle();

      // Expanded content now visible
      expect(find.text('Popular routes in Navi Mumbai:'), findsOneWidget);
      expect(find.text('Vashi → Belapur'), findsOneWidget);
      expect(find.byTooltip('Collapse planner'), findsOneWidget);

      // Tap collapse button
      await tester.tap(find.byTooltip('Collapse planner'));
      await tester.pumpAndSettle();

      // Presets hidden again, collapsed helper visible
      expect(find.text('Popular routes in Navi Mumbai:'), findsNothing);
      expect(find.byTooltip('Expand planner'), findsOneWidget);
    });

    testWidgets('9. Collapsed card displays ready state and Plan Route CTA when endpoints selected', (WidgetTester tester) async {
      bool planCalled = false;
      const originLoc = SelectedLocation(
        label: 'Vashi Station',
        coordinates: LatLng(19.0645, 72.9983),
        source: 'curated',
      );
      const destLoc = SelectedLocation(
        label: 'CBD Belapur Station',
        coordinates: LatLng(19.0185, 73.0385),
        source: 'curated',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RoutePlannerSheet(
              isExpanded: false,
              origin: originLoc,
              destination: destLoc,
              isIdentical: false,
              routes: const [],
              selectedRouteId: null,
              onSelectRoute: (_) {},
              routeStatus: RouteStatus.idle,
              routeError: null,
              onPlanRoute: () => planCalled = true,
              onClearRoute: () {},
              selectedScenarioId: DemoScenarioId.baseline,
              onSelectScenario: (_) {},
              onSelectOrigin: (_) {},
              onSelectDestination: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Endpoints ready'), findsOneWidget);
      expect(find.text('Vashi Station → CBD Belapur Station'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Plan Route'), findsOneWidget);

      // Tap Plan Route
      await tester.tap(find.widgetWithText(ElevatedButton, 'Plan Route'));
      await tester.pump();
      expect(planCalled, isTrue);
    });

    testWidgets('10. Collapsed card displays route metrics and risk score summary when route calculated', (WidgetTester tester) async {
      final sampleRoute = RoadRoute(
        id: 'route-1',
        label: 'Palm Beach Road',
        coordinates: const [
          LatLng(19.0645, 72.9983),
          LatLng(19.0185, 73.0385),
        ],
        distanceMeters: 14200,
        durationSeconds: 1440, // 24 min
        engineEstimateNotice: 'OSRM driving route',
      );

      const sampleAssessment = RouteRiskAssessment(
        routeId: 'route-1',
        status: 'success',
        result: RouteRiskScoreResult(
          score: 18.0,
          riskCategory: RouteRiskCategory.low,
          evaluatedHazardCount: 1,
          includedHazardCount: 1,
          thresholdMeters: 500,
          contributions: [],
          summaryExplanation: 'Low risk due to minor water accumulation',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RoutePlannerSheet(
              isExpanded: false,
              origin: const SelectedLocation(
                label: 'Vashi Station',
                coordinates: LatLng(19.0645, 72.9983),
              ),
              destination: const SelectedLocation(
                label: 'CBD Belapur Station',
                coordinates: LatLng(19.0185, 73.0385),
              ),
              isIdentical: false,
              routes: [sampleRoute],
              selectedRouteId: 'route-1',
              onSelectRoute: (_) {},
              routeStatus: RouteStatus.success,
              routeError: null,
              onPlanRoute: () {},
              onClearRoute: () {},
              riskAssessments: {'route-1': sampleAssessment},
              selectedScenarioId: DemoScenarioId.baseline,
              onSelectScenario: (_) {},
              onSelectOrigin: (_) {},
              onSelectDestination: (_) {},
            ),
          ),
        ),
      );

      // Route metrics displayed in collapsed card
      expect(find.text('24 mins'), findsOneWidget);
      expect(find.text('(14.2 km)'), findsOneWidget);
      expect(find.text('Low (18)'), findsOneWidget);
      expect(find.byTooltip('Expand route details'), findsOneWidget);
    });

    testWidgets('11. Small-screen mobile layout renders without overflow', (WidgetTester tester) async {
      // 360 x 640 logical pixels (standard budget Android viewport)
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MapScreen(
            weatherService: _FakeWeatherService(),
            autoFetch: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingSearchPanel), findsOneWidget);
      expect(find.text('Where to?'), findsOneWidget);
      expect(find.text('Plan your route'), findsNothing);
    });

    testWidgets('12. Autocomplete suggestions appear upon typing and selection updates endpoint', (WidgetTester tester) async {
      SelectedLocation? selectedOrigin;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingSearchPanel(
                  origin: selectedOrigin,
                  destination: null,
                  activeTarget: RouteEndpointType.origin,
                  isPickOnMapActive: false,
                  onSelectTarget: (_) {},
                  onSelectOrigin: (loc) => setState(() => selectedOrigin = loc),
                  onSelectDestination: (_) {},
                  onSwap: () {},
                  onClear: (_) {},
                );
              },
            ),
          ),
        ),
      );

      // Focus and enter text in Origin search field
      final originField = find.byType(TextField).first;
      await tester.tap(originField);
      await tester.pump();

      // Initially on empty focus, curated hubs appear
      expect(find.text('Popular Navi Mumbai Transit Hubs'), findsOneWidget);

      // Enter query
      await tester.enterText(originField, 'Vashi');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Suggestions rendered
      expect(find.text('Vashi Railway Station'), findsOneWidget);

      // Tap suggestion
      await tester.tap(find.text('Vashi Railway Station'));
      await tester.pumpAndSettle();

      // Selection callback triggered and dropdown closed
      expect(selectedOrigin?.label, 'Vashi Railway Station');
      expect(find.text('Popular Navi Mumbai Transit Hubs'), findsNothing);
    });

    testWidgets('13. Accessing expanded route details shows route comparisons and risk assessment', (WidgetTester tester) async {
      final sampleRoute = RoadRoute(
        id: 'route-1',
        label: 'Palm Beach Road',
        coordinates: const [
          LatLng(19.0645, 72.9983),
          LatLng(19.0185, 73.0385),
        ],
        distanceMeters: 14200,
        durationSeconds: 1440,
        engineEstimateNotice: 'OSRM driving route',
      );

      const sampleAssessment = RouteRiskAssessment(
        routeId: 'route-1',
        status: 'success',
        result: RouteRiskScoreResult(
          score: 18.0,
          riskCategory: RouteRiskCategory.low,
          evaluatedHazardCount: 1,
          includedHazardCount: 1,
          thresholdMeters: 500,
          contributions: [],
          summaryExplanation: 'Low risk due to minor water accumulation',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RoutePlannerSheet(
              isExpanded: true,
              origin: const SelectedLocation(
                label: 'Vashi Station',
                coordinates: LatLng(19.0645, 72.9983),
              ),
              destination: const SelectedLocation(
                label: 'CBD Belapur Station',
                coordinates: LatLng(19.0185, 73.0385),
              ),
              isIdentical: false,
              routes: [sampleRoute],
              selectedRouteId: 'route-1',
              onSelectRoute: (_) {},
              routeStatus: RouteStatus.success,
              routeError: null,
              onPlanRoute: () {},
              onClearRoute: () {},
              riskAssessments: {'route-1': sampleAssessment},
              selectedScenarioId: DemoScenarioId.baseline,
              onSelectScenario: (_) {},
              onSelectOrigin: (_) {},
              onSelectDestination: (_) {},
            ),
          ),
        ),
      );

      // Verify route comparison heading and clear action
      expect(find.text('OSRM Road Route'), findsOneWidget);
      expect(find.text('Clear Line'), findsOneWidget);

      // Verify risk score display in expanded view
      expect(find.text('Low'), findsWidgets);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('14. MainNavigationShell IndexedStack preserves MapScreen state across tab switches', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(
            weatherService: _FakeWeatherService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check on Map screen initially
      expect(find.byType(FloatingSearchPanel), findsOneWidget);
      expect(find.text('Where to?'), findsOneWidget);

      // Switch to Weather tab
      await tester.tap(find.text('Weather & Alerts'));
      await tester.pumpAndSettle();

      // Navigation bar indicates tab 1
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);

      // Switch back to Map
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();

      // Map screen preserved with search panel
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
      expect(find.byType(FloatingSearchPanel), findsOneWidget);
      expect(find.text('Where to?'), findsOneWidget);
    });
  });
}
