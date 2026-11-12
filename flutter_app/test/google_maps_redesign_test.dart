import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:varsha_flutter/core/config/app_config.dart';
import 'package:varsha_flutter/core/theme/app_theme.dart';
import 'package:varsha_flutter/features/map/floating_search_panel.dart';
import 'package:varsha_flutter/features/map/hazard_context_card.dart';
import 'package:varsha_flutter/features/map/hazard_markers_layer.dart';
import 'package:varsha_flutter/features/map/map_screen.dart';
import 'package:varsha_flutter/features/map/route_bubbles_bar.dart';
import 'package:varsha_flutter/features/map/route_callout_badges_layer.dart';
import 'package:varsha_flutter/features/routing/polyline_hit_tester.dart';
import 'package:varsha_flutter/features/routing/route_planner_sheet.dart';
import 'package:varsha_flutter/features/shell/main_navigation_shell.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/hazard.dart';
import 'package:varsha_flutter/models/risk_assessment.dart';
import 'package:varsha_flutter/models/route.dart';
import 'package:varsha_flutter/models/weather.dart';
import 'package:varsha_flutter/services/routing/osrm_service.dart';
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
        precipitationMm: 12.5,
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

class _FakeOsrmService extends OsrmService {
  final List<RoadRoute> mockRoutes;
  _FakeOsrmService({this.mockRoutes = const []});

  @override
  Future<List<RoadRoute>> fetchRoadRoutes(
    LatLng origin,
    LatLng destination, {
    String? customBaseUrl,
  }) async {
    if (mockRoutes.isNotEmpty) return mockRoutes;
    return [
      RoadRoute(
        id: 'route-fastest',
        label: 'Sion-Panvel Highway',
        durationSeconds: 1200, // 20m
        distanceMeters: 14500, // 14.5 km
        engineEstimateNotice: 'OSRM driving route',
        coordinates: const [
          LatLng(19.0645, 72.9983),
          LatLng(19.0400, 73.0150),
          LatLng(19.0185, 73.0385),
        ],
      ),
      RoadRoute(
        id: 'route-alternative',
        label: 'Palm Beach Road',
        durationSeconds: 1440, // 24m (+4m)
        distanceMeters: 16200, // 16.2 km
        engineEstimateNotice: 'OSRM driving route',
        coordinates: const [
          LatLng(19.0645, 72.9983),
          LatLng(19.0350, 73.0080),
          LatLng(19.0185, 73.0385),
        ],
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppConfig.initialize();
  });

  final List<RoadRoute> sampleRoutes = [
    RoadRoute(
      id: 'route-1',
      label: 'Primary Arterial',
      durationSeconds: 1200,
      distanceMeters: 12000,
      engineEstimateNotice: 'OSRM driving route',
      coordinates: const [
        LatLng(19.0645, 72.9983),
        LatLng(19.0400, 73.0150),
        LatLng(19.0185, 73.0385),
      ],
    ),
    RoadRoute(
      id: 'route-2',
      label: 'Coastal Bypass',
      durationSeconds: 1440,
      distanceMeters: 13500,
      engineEstimateNotice: 'OSRM driving route',
      coordinates: const [
        LatLng(19.0645, 72.9983),
        LatLng(19.0350, 73.0080),
        LatLng(19.0185, 73.0385),
      ],
    ),
  ];

  final sampleAssessments = {
    'route-1': const RouteRiskAssessment(
      routeId: 'route-1',
      status: 'success',
      result: RouteRiskScoreResult(
        score: 45.0,
        riskCategory: RouteRiskCategory.moderate,
        evaluatedHazardCount: 2,
        includedHazardCount: 1,
        thresholdMeters: 500,
        contributions: [],
        summaryExplanation: 'Moderate risk near flood zones',
      ),
    ),
    'route-2': const RouteRiskAssessment(
      routeId: 'route-2',
      status: 'success',
      result: RouteRiskScoreResult(
        score: 15.0,
        riskCategory: RouteRiskCategory.low,
        evaluatedHazardCount: 1,
        includedHazardCount: 0,
        thresholdMeters: 500,
        contributions: [],
        summaryExplanation: 'Low risk along bypass',
      ),
    ),
  };

  group('Google Maps-Inspired UX Redesign Tests', () {
    test('PolylineHitTester screen point-to-segment distance algorithm', () {
      final p = const Offset(5, 5);
      final a = const Offset(0, 0);
      final b = const Offset(10, 0);

      final dist = PolylineHitTester.distanceToSegment(p, a, b);
      expect((dist - 5.0).abs() < 0.001, isTrue);

      final distB = PolylineHitTester.distanceToSegment(
        const Offset(14, 3),
        a,
        b,
      );
      expect((distB - 5.0).abs() < 0.001, isTrue);
    });

    testWidgets(
      'RouteBubblesBar renders alternative options with fastest & safer badges',
      (tester) async {
        String selectedId = 'route-1';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return RouteBubblesBar(
                    routes: sampleRoutes,
                    selectedRouteId: selectedId,
                    onSelectRoute: (id) => setState(() => selectedId = id),
                    riskAssessments: sampleAssessments,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('20 mins'), findsOneWidget);
        expect(find.textContaining('Fastest'), findsOneWidget);

        expect(find.text('24 mins'), findsOneWidget);
        expect(find.textContaining('Safer'), findsOneWidget);

        await tester.tap(find.text('24 mins'));
        await tester.pumpAndSettle();

        expect(selectedId, 'route-2');
      },
    );

    testWidgets(
      'RouteCalloutBadgesLayer renders on-map duration callout pills',
      (tester) async {
        String selectedId = 'route-1';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(19.04, 73.01),
                  initialZoom: 12.0,
                ),
                children: [
                  StatefulBuilder(
                    builder: (context, setState) {
                      return RouteCalloutBadgesLayer(
                        routes: sampleRoutes,
                        selectedRouteId: selectedId,
                        onSelectRoute: (id) => setState(() => selectedId = id),
                        riskAssessments: sampleAssessments,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('20 min'), findsOneWidget);
        expect(find.text('+4 min'), findsOneWidget);

        await tester.tap(find.text('+4 min'));
        await tester.pumpAndSettle();

        expect(selectedId, 'route-2');
      },
    );

    testWidgets(
      'HazardContextCard renders severity and dismisses via close button',
      (tester) async {
        bool isClosed = false;

        const testHazard = HazardLocation(
          id: 'hz-1',
          name: 'Sector 17 Underpass Flooding',
          area: 'Vashi',
          description: 'Water depth 45cm during high tide',
          severity: HazardSeverity.high,
          hazardType: HazardType.floodedUnderpass,
          coordinates: LatLng(19.0720, 72.9980),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: HazardContextCard(
                hazard: testHazard,
                onClose: () => isClosed = true,
              ),
            ),
          ),
        );

        expect(find.text('Sector 17 Underpass Flooding'), findsOneWidget);
        expect(find.text('HIGH HAZARD'), findsOneWidget);
        expect(find.text('Water depth 45cm during high tide'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(isClosed, isTrue);
      },
    );

    testWidgets(
      '1 & 2. Initial launch shows single destination-search surface without empty route panel',
      (tester) async {
        // Test standard 360 x 800 logical viewport
        tester.view.physicalSize = const Size(720, 1600);
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

        // 1. Single floating search surface "Where to?" dominates the top
        expect(find.text('Where to?'), findsOneWidget);
        expect(find.byType(FloatingSearchPanel), findsOneWidget);

        // 2. No empty route-planning bottom panel or comparison cards
        expect(find.text('Plan your route'), findsNothing);
        expect(find.byType(RoutePlannerSheet), findsNothing);
        expect(find.byType(RouteBubblesBar), findsNothing);
      },
    );

    testWidgets(
      '3 & 4. Tapping search opens destination search and autocomplete does not resize search surface',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830); // ~412 x 915 logical pixels
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

        // 3. Tap search surface to transition to destination search
        await tester.tap(find.text('Where to?'));
        await tester.pumpAndSettle();

        // Destination search input is focused with cursor
        expect(find.text('Destination'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        final searchBoxBefore = tester.getRect(find.byType(FloatingSearchPanel));

        // Tap textfield to trigger curated landmarks dropdown
        await tester.tap(find.byType(TextField).first);
        await tester.pumpAndSettle();
        expect(find.text('Popular Navi Mumbai Transit Hubs'), findsOneWidget);

        // 4. Autocomplete dropdown is an anchored floating overlay; it does NOT resize the search panel
        final searchBoxAfter = tester.getRect(find.byType(FloatingSearchPanel));
        expect(searchBoxAfter.size.height, searchBoxBefore.size.height);
      },
    );

    testWidgets(
      '5 & 6. Selecting destination transitions to origin selection, which enables route calculation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MapScreen(
              weatherService: _FakeWeatherService(),
              osrmService: _FakeOsrmService(mockRoutes: sampleRoutes),
              autoFetch: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start search
        await tester.tap(find.text('Where to?'));
        await tester.pumpAndSettle();

        // 5. Select Destination
        await tester.enterText(find.byType(TextField).first, 'Belapur');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CBD Belapur Railway Station').first);
        await tester.pumpAndSettle();

        // Transitions to origin selection
        expect(find.text('Origin'), findsOneWidget);
        expect(find.text('CBD Belapur Railway Station'), findsWidgets);

        // 6. Select Origin
        await tester.enterText(find.byType(TextField).first, 'Vashi');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vashi Railway Station').first);
        await tester.pumpAndSettle();

        // Endpoints ready with Plan Route button
        expect(find.widgetWithText(ElevatedButton, 'Plan Route'), findsOneWidget);
      },
    );

    testWidgets(
      '7, 8, 9, 10, 11, 12, 13, 14. Route calculation, bubbles positioning, bottom panel metrics & expansion',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MapScreen(
              weatherService: _FakeWeatherService(),
              osrmService: _FakeOsrmService(mockRoutes: sampleRoutes),
              autoFetch: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select endpoints
        await tester.tap(find.text('Where to?'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Belapur');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CBD Belapur Railway Station').first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Vashi');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vashi Railway Station').first);
        await tester.pumpAndSettle();

        // 7. Calculate routes
        await tester.tap(find.widgetWithText(ElevatedButton, 'Plan Route'));
        await tester.pumpAndSettle();

        // 8 & 9. Route bubbles appear directly below directions surface without overlap
        expect(find.byType(RouteBubblesBar), findsOneWidget);
        final searchRect = tester.getRect(find.byType(FloatingSearchPanel));
        final bubblesRect = tester.getRect(find.byType(RouteBubblesBar));

        expect(bubblesRect.top >= searchRect.bottom, isTrue);
        expect(bubblesRect.overlaps(searchRect), isFalse);

        // 10. Selecting a route bubble updates selected route
        expect(find.text('20 mins'), findsWidgets);
        expect(find.text('24 mins'), findsOneWidget);
        await tester.tap(find.text('24 mins'));
        await tester.pumpAndSettle();

        // 11. Tapping alternative on-map callout badge updates route
        if (find.text('+4 min').evaluate().isNotEmpty) {
          await tester.tap(find.text('+4 min'));
          await tester.pumpAndSettle();
        }

        // 12. Bottom route panel appears ONLY after route calculation
        expect(find.byType(RoutePlannerSheet), findsOneWidget);

        // 13. Displays actual route metrics
        expect(find.textContaining('12.0 km'), findsWidgets);

        // 14. Expand and collapse bottom panel
        final rectBefore = tester.getRect(find.byType(RoutePlannerSheet));
        await tester.tap(find.byTooltip('Expand route details'));
        await tester.pumpAndSettle();
        final rectAfter = tester.getRect(find.byType(RoutePlannerSheet));
        expect(rectAfter.height > rectBefore.height * 2, isTrue);
        expect(find.byTooltip('Collapse planner'), findsOneWidget);

        await tester.tap(find.byTooltip('Collapse planner'));
        await tester.pumpAndSettle();
        final rectCollapsed = tester.getRect(find.byType(RoutePlannerSheet));
        expect(find.byTooltip('Expand route details'), findsOneWidget);
        expect(rectCollapsed.height, closeTo(rectBefore.height, 5.0));

        // Repeated tap expand works
        await tester.tap(find.byTooltip('Expand route details'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Collapse planner'), findsOneWidget);
        expect(tester.getRect(find.byType(RoutePlannerSheet)).height, closeTo(rectAfter.height, 5.0));

        await tester.tap(find.byTooltip('Collapse planner'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Expand route details'), findsOneWidget);

        // Swiping upwards expands the panel
        await tester.drag(find.byTooltip('Expand route details'), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(RoutePlannerSheet)).height > rectBefore.height * 2, isTrue);
        expect(find.byTooltip('Collapse planner'), findsOneWidget);

        // Swiping downwards collapses the panel
        await tester.drag(find.byType(ListView).last, const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Expand route details'), findsOneWidget);
      },
    );

    testWidgets(
      '15. Hazard inspection does not clear selected route or endpoints',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MapScreen(
              weatherService: _FakeWeatherService(),
              osrmService: _FakeOsrmService(mockRoutes: sampleRoutes),
              autoFetch: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Plan route
        await tester.tap(find.text('Where to?'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Belapur');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CBD Belapur Railway Station').first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Vashi');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vashi Railway Station').first);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Plan Route'));
        await tester.pumpAndSettle();

        expect(find.byType(RouteBubblesBar), findsOneWidget);

        // Inspect hazard
        final hazardGestureDetector = find.descendant(
          of: find.byType(HazardMarkersLayer),
          matching: find.byType(GestureDetector),
        );
        expect(hazardGestureDetector, findsWidgets);

        await tester.tap(hazardGestureDetector.first);
        await tester.pumpAndSettle();

        // HazardContextCard is displayed without destroying routes!
        expect(find.byType(HazardContextCard), findsOneWidget);
        expect(find.byType(RouteBubblesBar), findsOneWidget);

        // Dismiss hazard card
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();

        expect(find.byType(HazardContextCard), findsNothing);
        expect(find.byType(RouteBubblesBar), findsOneWidget);
      },
    );

    testWidgets(
      '16. Small-screen Android layouts render without overflow',
      (tester) async {
        // Budget Android: 360 x 800 logical pixels
        tester.view.physicalSize = const Size(720, 1600);
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

        expect(tester.takeException(), isNull);
        expect(find.text('Where to?'), findsOneWidget);
      },
    );

    testWidgets(
      '17. Returning from Weather & Alerts preserves map state',
      (tester) async {
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

        expect(find.text('Where to?'), findsOneWidget);

        // Navigate to Weather tab
        await tester.tap(find.text('Weather & Alerts'));
        await tester.pumpAndSettle();

        expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);

        // Return to Map
        await tester.tap(find.text('Map').last);
        await tester.pumpAndSettle();

        // Map state preserved
        expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
        expect(find.text('Where to?'), findsOneWidget);
      },
    );

    testWidgets(
      '18. Restored compact top branding and settings bar renders unified container and triggers settings',
      (tester) async {
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

        // 1. Top row identity, telemetry chips, and settings in floating container
        expect(find.text('VARSHA'), findsOneWidget);
        expect(find.byKey(const Key('status_strip_rain_chip')), findsOneWidget);
        expect(find.byKey(const Key('status_strip_alerts_chip')), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);

        // 2. Bottom row destination search directly below identity row with Google Maps height
        expect(find.text('Where to?'), findsOneWidget);

        final varshaRect = tester.getRect(find.text('VARSHA'));
        final searchRect = tester.getRect(find.text('Where to?'));
        expect(searchRect.top > varshaRect.bottom, isTrue);

        // 3. Tapping settings opens SettingsSheet modal
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();

        expect(find.text('API & Network Settings'), findsOneWidget);
      },
    );

    testWidgets(
      '19. Random map tap does NOT set destination; destination requires search or explicit Pick on Map',
      (tester) async {
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

        // 1. Initial screen: Tap somewhere in the middle of the map
        final mapFinder = find.byType(FlutterMap);
        expect(mapFinder, findsOneWidget);
        await tester.tapAt(const Offset(200, 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Destination is NOT set, still in initial state ("Where to?")
        expect(find.text('Where to?'), findsOneWidget);
        expect(find.text('Origin'), findsNothing);
        expect(find.text('Destination'), findsNothing);

        // 2. Tap search to open destination search
        await tester.tap(find.text('Where to?'));
        await tester.pumpAndSettle();
        expect(find.text('Destination'), findsOneWidget);

        // 3. Tap "Pick on Map" to enter explicit map selection mode
        await tester.tap(find.byTooltip('Pick on Map').first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Tap map to set Destination (B)'), findsOneWidget);

        // 4. Now tapping the map DOES set destination
        await tester.tapAt(const Offset(200, 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Destination was set! Banner dismissed, transitioned to Origin selection
        expect(find.textContaining('Tap map to set Destination (B)'), findsNothing);
        expect(find.text('Origin'), findsOneWidget);

        // 5. Subsequent random map tap does NOT reassign or overwrite
        await tester.tapAt(const Offset(200, 450));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Origin'), findsOneWidget);
      },
    );
  });
}
