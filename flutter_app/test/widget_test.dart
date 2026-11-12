import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:varsha_flutter/app/app.dart';
import 'package:varsha_flutter/core/config/app_config.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/weather.dart';
import 'package:varsha_flutter/services/weather/weather_service.dart';

class FakeWeatherService extends WeatherService {
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

  testWidgets('VarshaApp smoke and navigation test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VarshaApp(weatherService: FakeWeatherService()),
    );
    await tester.pumpAndSettle();

    // Verify Google Maps-inspired initial search pill
    expect(find.text('Where to?'), findsOneWidget);

    // Verify Persistent Disclaimer Strip at bottom
    expect(find.text('Learn more'), findsOneWidget);

    // Tap "Learn more" to open About sheet
    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    // Verify About Sheet contents
    expect(find.text('About VARSHA'), findsOneWidget);
    expect(find.text('Simulated Data Notice'), findsOneWidget);
    expect(find.text('Navi Mumbai Pilot Focus'), findsOneWidget);
    expect(find.text('Weather & Disaster Intelligence'), findsOneWidget);
    expect(find.textContaining('predictive monsoon mobility'), findsWidgets);

    // Verify hackathon and outdated references are absent
    expect(find.textContaining('MY Bharat'), findsNothing);
    expect(find.textContaining('Hackathon'), findsNothing);
    expect(find.textContaining('college'), findsNothing);
    expect(find.textContaining('mini project'), findsNothing);

    // Scroll to verify product card at bottom
    await tester.scrollUntilVisible(
      find.text('VARSHA Monsoon Mobility'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('VARSHA Monsoon Mobility'), findsOneWidget);

    // Dismiss About sheet
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // Verify returned to main screen
    expect(find.text('About VARSHA'), findsNothing);
    expect(find.text('Where to?'), findsOneWidget);
  });
}
