import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:varsha_flutter/core/theme/app_theme.dart';
import 'package:varsha_flutter/features/map/map_screen.dart';
import 'package:varsha_flutter/features/routing/route_comparison_view.dart';
import 'package:varsha_flutter/features/routing/route_planner_sheet.dart';
import 'package:varsha_flutter/features/routing/route_risk_card.dart';
import 'package:varsha_flutter/models/alert.dart';
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
  _FakeOsrmService({required this.mockRoutes});

  @override
  Future<List<RoadRoute>> fetchRoadRoutes(
    LatLng origin,
    LatLng destination, {
    String? customBaseUrl,
  }) async {
    return mockRoutes;
  }
}

void main() {
  final sampleRoutes = [
    RoadRoute(
      id: 'route-1',
      coordinates: const [LatLng(19.0185, 73.0385), LatLng(19.0645, 72.9983)],
      distanceMeters: 12000,
      durationSeconds: 1200,
      label: 'Sion-Panvel Highway',
      corridorName: 'Sion-Panvel Expressway',
      engineEstimateNotice: 'OSRM driving route',
    ),
    RoadRoute(
      id: 'route-2',
      coordinates: const [LatLng(19.0185, 73.0385), LatLng(19.04, 73.01), LatLng(19.0645, 72.9983)],
      distanceMeters: 14500,
      durationSeconds: 1440,
      label: 'Palm Beach Road',
      corridorName: 'Palm Beach Corridor',
      engineEstimateNotice: 'OSRM driving route',
    ),
  ];

  group('Route Details Bottom Sheet Expansion Tests', () {
    testWidgets(
      '1 & 7. Route summary bottom sheet does NOT appear before calculation, but appears after calculation',
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

        // 7. Panel does not appear before route calculation
        expect(find.byType(RoutePlannerSheet), findsNothing);

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

        // 1. Route summary appears after calculation
        expect(find.byType(RoutePlannerSheet), findsOneWidget);
        expect(find.byTooltip('Expand route details'), findsOneWidget);
        expect(find.text('20 mins'), findsWidgets);
        expect(find.textContaining('12.0 km'), findsWidgets);
      },
    );

    testWidgets(
      '2, 3, 4, 5. Tapping expand control expands panel displaying details, collapse control returns to compact state, repeated operations work',
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

        // Initial compact state height
        final compactRect = tester.getRect(find.byType(RoutePlannerSheet));

        // 2. Tapping expand expands the panel smoothly
        await tester.tap(find.byTooltip('Expand route details'));
        await tester.pumpAndSettle();

        final expandedRect = tester.getRect(find.byType(RoutePlannerSheet));
        expect(expandedRect.height > compactRect.height * 2, isTrue);

        // 3. Displays detailed route information
        expect(find.byTooltip('Collapse planner'), findsOneWidget);
        expect(find.text('Route options'), findsOneWidget);
        expect(find.byType(RouteComparisonView), findsOneWidget);
        expect(find.byType(RouteRiskCard), findsWidgets);
        expect(find.text('Sion-Panvel Highway'), findsWidgets);
        expect(find.text('Palm Beach Road'), findsWidgets);

        // 4. Tapping collapse returns it to its compact state
        await tester.tap(find.byTooltip('Collapse planner'));
        await tester.pumpAndSettle();

        final collapsedRect = tester.getRect(find.byType(RoutePlannerSheet));
        expect(collapsedRect.height, closeTo(compactRect.height, 5.0));
        expect(find.byTooltip('Expand route details'), findsOneWidget);
        expect(find.text('Route options'), findsNothing);

        // 5. Repeated expand and collapse operations work repeatedly without getting stuck
        await tester.tap(find.byTooltip('Expand route details'));
        await tester.pumpAndSettle();

        expect(tester.getRect(find.byType(RoutePlannerSheet)).height, closeTo(expandedRect.height, 5.0));
        expect(find.byTooltip('Collapse planner'), findsOneWidget);
        expect(find.text('Route options'), findsOneWidget);

        await tester.tap(find.byTooltip('Collapse planner'));
        await tester.pumpAndSettle();

        expect(tester.getRect(find.byType(RoutePlannerSheet)).height, closeTo(compactRect.height, 5.0));
        expect(find.byTooltip('Expand route details'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Swiping upwards expands panel and swiping downwards collapses it',
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

        final compactRect = tester.getRect(find.byType(RoutePlannerSheet));

        // 6a. Swiping upwards on the panel expands it
        await tester.drag(find.byTooltip('Expand route details'), const Offset(0, -350));
        await tester.pumpAndSettle();

        final expandedRect = tester.getRect(find.byType(RoutePlannerSheet));
        expect(expandedRect.height > compactRect.height * 2, isTrue);
        expect(find.byTooltip('Collapse planner'), findsOneWidget);
        expect(find.byType(RouteComparisonView), findsOneWidget);

        // 6b. Swiping downwards collapses it
        await tester.drag(find.byType(ListView).last, const Offset(0, 350));
        await tester.pumpAndSettle();

        final collapsedRect = tester.getRect(find.byType(RoutePlannerSheet));
        expect(collapsedRect.height, closeTo(compactRect.height, 5.0));
        expect(find.byTooltip('Expand route details'), findsOneWidget);
      },
    );
  });
}
