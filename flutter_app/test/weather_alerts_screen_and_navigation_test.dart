import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:varsha_flutter/core/config/app_config.dart';
import 'package:varsha_flutter/core/theme/app_theme.dart';
import 'package:varsha_flutter/features/shell/main_navigation_shell.dart';
import 'package:varsha_flutter/features/weather/disaster_alerts_view.dart';
import 'package:varsha_flutter/features/weather/weather_alerts_screen.dart';
import 'package:varsha_flutter/features/weather/weather_forecast_view.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/weather.dart';
import 'package:varsha_flutter/services/weather/weather_service.dart';

class _CountingMockHttpClient extends http.BaseClient {
  int requestCount = 0;
  final http.Response Function(http.BaseRequest request) handler;

  _CountingMockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    final response = handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

RainfallResponse _sampleRainfall({
  String status = 'ok',
  bool isStale = false,
  double mm = 12.0,
}) {
  final now = DateTime.now().toUtc();
  return RainfallResponse(
    provider: RainfallProviderStatus(
      provider: 'open-meteo',
      status: status,
      isCached: false,
      isStale: isStale,
      retrievedAt: '2026-08-15T12:00:00Z',
      endpointUrl: 'https://api.open-meteo.com/v1/forecast',
    ),
    requestedCoordinate: const {'lat': 19.033, 'lon': 73.0297},
    dataType: 'hourly',
    isModelDerived: true,
    isPhysicalObservation: false,
    current: CurrentRainfall(
      timestamp: '2026-08-15T12:00:00Z',
      intervalSeconds: 900,
      precipitationMm: mm,
      unit: 'mm',
      isModelDerived: true,
      isPhysicalObservation: false,
      intervalDescription: 'Past 15 minutes',
    ),
    hourly: [
      PrecipitationStep(
        timestamp: now.add(const Duration(hours: 1)).toIso8601String(),
        precipitationMm: 5.0,
        precipitationProbabilityPct: 70,
        intervalMinutes: 60,
        unit: 'mm',
        isModelDerived: true,
      ),
      PrecipitationStep(
        timestamp: now.add(const Duration(hours: 2)).toIso8601String(),
        precipitationMm: 10.0,
        precipitationProbabilityPct: 90,
        intervalMinutes: 60,
        unit: 'mm',
        isModelDerived: true,
      ),
    ],
    summary: const RainfallSummary(
      forecastHours: 24,
      totalPrecipitationMm: 45.0,
      maxHourlyPrecipitationMm: 15.0,
      maxProbabilityPct: 90,
      isComplete: true,
    ),
    caveats: const [],
  );
}

AlertListResponse _sampleAlerts({
  String status = 'ok',
  bool isStale = false,
  int total = 1,
}) {
  return AlertListResponse(
    provider: AlertProviderStatus(
      provider: 'sachet',
      status: status,
      isCached: false,
      isStale: isStale,
      retrievedAt: '2026-08-15T12:00:00Z',
      feedUrl: 'https://sachet.ndma.gov.in',
    ),
    total: total,
    alerts: total == 0
        ? const []
        : const [
            NormalizedAlert(
              provider: 'sachet',
              identifier: 'SACHET-NM-001',
              sender: 'NDMA',
              status: 'Actual',
              msgType: 'Alert',
              severity: 'Severe',
              urgency: 'Immediate',
              certainty: 'Observed',
              isActive: true,
              headline: 'Heavy Rain Warning for Navi Mumbai',
              description: 'Very heavy localized rainfall expected along Sion-Panvel Highway.',
              instruction: 'Avoid waterlogged areas and follow traffic diversions.',
              areaDescription: 'Navi Mumbai, Thane',
              retrievedAt: '2026-08-15T12:00:00Z',
              effective: '2026-08-15T12:00:00Z',
              expires: '2026-08-15T18:00:00Z',
              alternateLanguages: [],
              geocodes: [],
              geometryType: 'Point',
              hasSpatialGeometry: false,
              warnings: [],
            ),
          ],
    spatialFilterApplied: false,
  );
}

class _TestMockWeatherService extends WeatherService {
  final RainfallResponse? rainfall;
  final AlertListResponse? alerts;
  int rainfallFetchCount = 0;
  int alertsFetchCount = 0;

  _TestMockWeatherService({this.rainfall, this.alerts});

  @override
  Future<RainfallResponse> fetchRainfallForecast({
    double latitude = 19.0330,
    double longitude = 73.0297,
    int forecastHours = 24,
    String? customBaseUrl,
  }) async {
    rainfallFetchCount++;
    return rainfall ?? _sampleRainfall();
  }

  @override
  Future<AlertListResponse> fetchOfficialAlerts({
    bool activeOnly = true,
    String? customBaseUrl,
  }) async {
    alertsFetchCount++;
    return alerts ?? _sampleAlerts();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppConfig.initialize();
  });

  group('Phase 3: Navigation and Shell Integration', () {
    testWidgets('1 & 2. Navigates to Weather & Alerts screen with correct active state and back-navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _TestMockWeatherService(
        rainfall: _sampleRainfall(mm: 8.5),
        alerts: _sampleAlerts(total: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Map screen
      expect(find.text('Map'), findsWidgets);
      expect(find.text('Weather & Alerts'), findsWidgets);
      expect(find.text('Where to?'), findsOneWidget);

      // Verify bottom navigation bar destinations
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);

      // Tap "Weather & Alerts" on bottom navigation
      await tester.tap(find.text('Weather & Alerts').last);
      await tester.pumpAndSettle();

      // Navigation state updated
      final updatedNavBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(updatedNavBar.selectedIndex, 1);

      // Dedicated Weather & Alerts screen displayed
      expect(find.text('Weather & Alerts'), findsWidgets);
      expect(
        find.text('Provides weather conditions, rainfall forecasts and official disaster warnings for Navi Mumbai.'),
        findsOneWidget,
      );
      expect(find.text('Weather'), findsWidgets);
      expect(find.text('Disaster Alerts'), findsWidgets);

      // Back navigation via Map tab
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();

      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
      expect(find.text('Where to?'), findsOneWidget);
    });

    testWidgets('Tapping TopStatusStrip chips navigates to respective Weather and Alerts tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _TestMockWeatherService(
        rainfall: _sampleRainfall(mm: 8.5),
        alerts: _sampleAlerts(total: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the rain chip in TopStatusStrip
      await tester.tap(find.byKey(const Key('status_strip_rain_chip')));
      await tester.pumpAndSettle();

      // Should be on Weather & Alerts screen, Weather tab (index 0)
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
      expect(find.text('Precipitation Forecast'), findsOneWidget);

      // Return to Map
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();

      // Tap the alerts chip in TopStatusStrip
      await tester.tap(find.byKey(const Key('status_strip_alerts_chip')));
      await tester.pumpAndSettle();

      // Should be on Weather & Alerts screen, Disaster Alerts tab (index 1)
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
      expect(find.text('Heavy Rain Warning for Navi Mumbai'), findsOneWidget);
    });

    testWidgets('8. Alert count badge behavior on navigation destination', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Case A: 2 active alerts -> badge shows '2'
      final serviceWithAlerts = _TestMockWeatherService(
        rainfall: _sampleRainfall(),
        alerts: _sampleAlerts(total: 2),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: serviceWithAlerts),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);

      // Case B: 0 alerts -> badge not visible
      final serviceNoAlerts = _TestMockWeatherService(
        rainfall: _sampleRainfall(),
        alerts: _sampleAlerts(total: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: serviceNoAlerts),
        ),
      );
      await tester.pumpAndSettle();

      // Case C: alerts provider unavailable -> no misleading count badge
      const unavailableAlerts = AlertListResponse(
        provider: AlertProviderStatus(
          provider: 'sachet',
          status: 'unavailable',
          isCached: false,
          isStale: false,
          errorMessage: 'NDMA feed down',
          feedUrl: '',
        ),
        total: 5, // Even if total is positive in malformed payload, unavailable must suppress badge
        alerts: [],
        spatialFilterApplied: false,
      );

      final serviceUnavailable = _TestMockWeatherService(
        rainfall: _sampleRainfall(),
        alerts: unavailableAlerts,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: serviceUnavailable),
        ),
      );
      await tester.pumpAndSettle();

      // Should not show misleading '5' badge
      expect(find.text('5'), findsNothing);
    });
  });

  group('Phase 3: WeatherAlertsScreen & Tabs Content', () {
    testWidgets('3 & 4. Switching between Weather and Disaster Alerts sections renders weather info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final rain = _sampleRainfall(mm: 14.5);
      final alerts = _sampleAlerts(total: 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsScreen(
              initialRainfall: rain,
              initialAlerts: alerts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // --- Tab A: Weather ---
      expect(find.text('Precipitation Forecast'), findsOneWidget);
      expect(find.text('14.5 mm'), findsOneWidget);
      expect(find.text('Current Model Estimate (15m window)'), findsOneWidget);
      expect(find.text('Rolling 24-Hour Summary'), findsOneWidget);
      expect(find.text('45.0 mm'), findsOneWidget);
      expect(find.text('Next 2 Hours Forecast (IST)'), findsOneWidget);
      expect(find.text('Weather forecast data from Open-Meteo.com (Licensed under CC BY 4.0).'), findsOneWidget);

      // Switch to Disaster Alerts tab
      await tester.tap(find.text('Disaster Alerts'));
      await tester.pumpAndSettle();

      // --- Tab B: Disaster Alerts ---
      expect(find.text('Heavy Rain Warning for Navi Mumbai'), findsOneWidget);
      expect(find.text('SEVERE SEVERITY'), findsOneWidget);
      expect(find.text('Immediate Urgency'), findsOneWidget);
      expect(find.text('Official disaster warnings from NDMA SACHET (Common Alerting Protocol 1.2).'), findsOneWidget);

      // Switch back to Weather tab
      await tester.tap(find.text('Weather'));
      await tester.pumpAndSettle();

      expect(find.text('Precipitation Forecast'), findsOneWidget);
    });

    testWidgets('5. Displays disaster alert cards and expands instructions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final alerts = _sampleAlerts(total: 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsScreen(
              initialRainfall: _sampleRainfall(),
              initialAlerts: alerts,
              initialTabIndex: 1, // Start on Disaster Alerts tab
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heavy Rain Warning for Navi Mumbai'), findsOneWidget);
      expect(find.text('Affected Districts / Areas: Navi Mumbai, Thane'), findsOneWidget);
      expect(find.text('Show Instructions & Details'), findsOneWidget);

      // Tap to expand details
      await tester.tap(find.text('Show Instructions & Details'));
      await tester.pumpAndSettle();

      expect(find.text('Hide Details'), findsOneWidget);
      expect(
        find.text('Very heavy localized rainfall expected along Sion-Panvel Highway.'),
        findsOneWidget,
      );
      expect(
        find.text('Instruction: Avoid waterlogged areas and follow traffic diversions.'),
        findsOneWidget,
      );
    });

    testWidgets('6. Empty and unavailable states handled gracefully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Empty alerts
      final emptyAlerts = _sampleAlerts(total: 0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsScreen(
              initialRainfall: _sampleRainfall(),
              initialAlerts: emptyAlerts,
              initialTabIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Official Disaster Alerts'), findsOneWidget);
      expect(
        find.text('No government warnings broadcast in the NDMA SACHET feed for this region.'),
        findsOneWidget,
      );

      // Unavailable rainfall
      const unavailableRain = RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'unavailable',
          isCached: false,
          isStale: false,
          errorMessage: 'Open-Meteo connection timed out',
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        hourly: [],
        caveats: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: WeatherForecastView(
              rainfall: unavailableRain,
              rainfallError: 'Open-Meteo connection timed out',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rainfall forecast unavailable'), findsOneWidget);
      expect(find.text('Open-Meteo connection timed out'), findsOneWidget);

      // Unavailable alerts
      const unavailableAlerts = AlertListResponse(
        provider: AlertProviderStatus(
          provider: 'sachet',
          status: 'unavailable',
          isCached: false,
          isStale: false,
          errorMessage: 'NDMA CAP RSS feed offline',
          feedUrl: '',
        ),
        total: 0,
        alerts: [],
        spatialFilterApplied: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DisasterAlertsView(
              alerts: unavailableAlerts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alerts feed unavailable'), findsOneWidget);
      expect(find.text('NDMA CAP RSS feed offline'), findsOneWidget);
    });

    testWidgets('7. Displays stale-data indicators and fallback notices', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staleRain = _sampleRainfall(status: 'degraded', isStale: true);
      final staleAlerts = _sampleAlerts(status: 'degraded', isStale: true, total: 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsScreen(
              initialRainfall: staleRain,
              initialAlerts: staleAlerts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Weather tab stale warning
      expect(find.text('⚠ Stale Fallback'), findsOneWidget);
      expect(
        find.textContaining('Notice: Open-Meteo upstream is currently unreachable. Displaying cached forecast from'),
        findsOneWidget,
      );

      // Disaster Alerts tab stale warning
      await tester.tap(find.text('Disaster Alerts'));
      await tester.pumpAndSettle();

      expect(find.textContaining('⚠ Stale Fallback (1 Active)'), findsOneWidget);
      expect(
        find.textContaining('Notice: NDMA SACHET feed is unreachable. Displaying cached alerts from'),
        findsOneWidget,
      );
    });
  });

  group('Phase 3: Data and State Management (No Duplicate Requests)', () {
    testWidgets('9. Navigation and tab switching does not trigger duplicate requests',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _TestMockWeatherService(
        rainfall: _sampleRainfall(),
        alerts: _sampleAlerts(total: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationShell(weatherService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Initial load: 1 rainfall fetch, 1 alerts fetch
      expect(service.rainfallFetchCount, 1);
      expect(service.alertsFetchCount, 1);

      // Navigate to Weather & Alerts
      await tester.tap(find.text('Weather & Alerts').last);
      await tester.pumpAndSettle();

      // Still 1 each! Zero redundant fetches
      expect(service.rainfallFetchCount, 1);
      expect(service.alertsFetchCount, 1);

      // Switch tabs back and forth 4 times
      await tester.tap(find.text('Disaster Alerts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weather'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disaster Alerts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weather'));
      await tester.pumpAndSettle();

      // Still exactly 1 each!
      expect(service.rainfallFetchCount, 1);
      expect(service.alertsFetchCount, 1);

      // Navigate back to Map
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();

      expect(service.rainfallFetchCount, 1);
      expect(service.alertsFetchCount, 1);
    });

    test('WeatherService caching and deduplication for fetchOfficialAlerts', () async {
      final validAlertsPayload = jsonEncode({
        'provider': {
          'provider': 'sachet',
          'status': 'ok',
          'is_cached': false,
          'is_stale': false,
          'retrieved_at': '2026-08-15T12:00:00Z',
          'feed_url': 'https://sachet.ndma.gov.in',
        },
        'total': 0,
        'alerts': [],
        'spatial_filter_applied': false,
      });

      final mockClient = _CountingMockHttpClient((_) => http.Response(validAlertsPayload, 200));
      final service = WeatherService(client: mockClient);

      // First call fetches from network
      final res1 = await service.fetchOfficialAlerts();
      expect(res1.provider.status, 'ok');
      expect(mockClient.requestCount, 1);

      // Second call uses 5-minute memory cache
      final res2 = await service.fetchOfficialAlerts();
      expect(res2.provider.status, 'ok');
      expect(mockClient.requestCount, 1);

      // Concurrent calls deduplicated
      final concurrentResults = await Future.wait([
        service.fetchOfficialAlerts(),
        service.fetchOfficialAlerts(),
      ]);
      expect(concurrentResults.length, 2);
      expect(mockClient.requestCount, 1);

      // clearCache allows fresh network fetch
      service.clearCache();
      final res3 = await service.fetchOfficialAlerts();
      expect(res3.provider.status, 'ok');
      expect(mockClient.requestCount, 2);
    });
  });
}
