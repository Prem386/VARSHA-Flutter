import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsha_flutter/core/theme/app_theme.dart';
import 'package:varsha_flutter/features/routing/route_risk_card.dart';
import 'package:varsha_flutter/features/scenarios/scenario_selector.dart';
import 'package:varsha_flutter/features/weather/weather_alerts_sheet.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/hazard.dart';
import 'package:varsha_flutter/models/risk_assessment.dart';
import 'package:varsha_flutter/models/scenario.dart';
import 'package:varsha_flutter/models/weather.dart';

void main() {
  group('RouteRiskCard Widget Tests', () {
    testWidgets('renders score 0 and low risk safely', (WidgetTester tester) async {
      const assessment = RouteRiskAssessment(
        routeId: 'route-test-1',
        status: 'success',
        result: RouteRiskScoreResult(
          score: 0,
          riskCategory: RouteRiskCategory.low,
          evaluatedHazardCount: 5,
          includedHazardCount: 0,
          thresholdMeters: 100.0,
          contributions: [],
          summaryExplanation: 'No hazards nearby',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: RouteRiskCard(assessment: assessment),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(
        find.text('No simulated hazards detected within 100m proximity threshold.'),
        findsOneWidget,
      );
    });

    testWidgets('renders high score and contributing hazards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const contribution = HazardRiskContribution(
        hazardId: 'hazard-1',
        hazardName: 'Turbhe Underpass Inundation',
        severity: HazardSeverity.high,
        distanceMeters: 15.0,
        baseWeight: 35.0,
        proximityMultiplier: 1.0,
        scoreContribution: 35.0,
        explanation: '35 base wt x 1.0 (<=25m) = 35.0 pts',
      );

      const assessment = RouteRiskAssessment(
        routeId: 'route-test-2',
        status: 'success',
        result: RouteRiskScoreResult(
          score: 35,
          riskCategory: RouteRiskCategory.moderate,
          evaluatedHazardCount: 5,
          includedHazardCount: 1,
          thresholdMeters: 100.0,
          contributions: [contribution],
          summaryExplanation: '1 hazard nearby',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: RouteRiskCard(assessment: assessment),
          ),
        ),
      );

      expect(find.text('35'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);

      // Expand details
      await tester.tap(find.text('Contributing Hazards (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Turbhe Underpass Inundation'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('15.0m from route'), findsOneWidget);
      expect(find.text('+35.0 pts'), findsOneWidget);
    });
  });

  group('ScenarioSelector Widget Tests', () {
    testWidgets('renders all scenarios and triggers onSelect', (WidgetTester tester) async {
      DemoScenarioId selectedId = DemoScenarioId.baseline;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScenarioSelector(
              selectedScenarioId: selectedId,
              onSelectScenario: (scenarioId) {
                selectedId = scenarioId;
              },
            ),
          ),
        ),
      );

      expect(find.text('Demo Scenarios'), findsOneWidget);
      expect(find.text('Baseline'), findsOneWidget);
      expect(find.text('Flood on Highway'), findsOneWidget);
      expect(find.text('Flood on West Bypass'), findsOneWidget);
      expect(find.text('All Clear'), findsOneWidget);

      // Tap "Flood on Highway"
      await tester.tap(find.text('Flood on Highway'));
      await tester.pumpAndSettle();

      expect(selectedId, DemoScenarioId.floodHighway);
    });
  });

  group('WeatherAlertsSheet Widget Tests', () {
    testWidgets('renders precipitation cards and active disaster alerts', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now().toUtc();
      final rainfall = RainfallResponse(
        provider: const RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'ok',
          isCached: false,
          isStale: false,
          retrievedAt: '2026-08-15T12:00:00Z',
          endpointUrl: 'https://api.open-meteo.com/v1/forecast',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        current: const CurrentRainfall(
          timestamp: '2026-08-15T12:00:00Z',
          intervalSeconds: 900,
          precipitationMm: 14.5,
          unit: 'mm',
          isModelDerived: true,
          isPhysicalObservation: false,
          intervalDescription: 'Past 15 minutes',
        ),
        hourly: [
          PrecipitationStep(
            timestamp: now.add(const Duration(hours: 1)).toIso8601String(),
            precipitationMm: 8.2,
            precipitationProbabilityPct: 80,
            intervalMinutes: 60,
            unit: 'mm',
            isModelDerived: true,
          ),
          PrecipitationStep(
            timestamp: now.add(const Duration(hours: 2)).toIso8601String(),
            precipitationMm: 18.0,
            precipitationProbabilityPct: 95,
            intervalMinutes: 60,
            unit: 'mm',
            isModelDerived: true,
          ),
        ],
        summary: const RainfallSummary(
          forecastHours: 24,
          totalPrecipitationMm: 65.0,
          maxHourlyPrecipitationMm: 22.0,
          maxProbabilityPct: 95,
          isComplete: true,
        ),
        caveats: [],
      );

      final alerts = AlertListResponse(
        provider: const AlertProviderStatus(
          provider: 'sachet',
          status: 'ok',
          isCached: false,
          isStale: false,
          retrievedAt: '2026-08-15T12:00:00Z',
          feedUrl: 'https://sachet.ndma.gov.in',
        ),
        total: 1,
        alerts: const [
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'SACHET-MUM-2026-08',
            sender: 'NDMA',
            status: 'Actual',
            msgType: 'Alert',
            severity: 'Severe',
            urgency: 'Immediate',
            certainty: 'Observed',
            isActive: true,
            headline: 'Flash Flood Warning for Navi Mumbai',
            description: 'Intense precipitation expected over Thane-Belapur corridor.',
            instruction: 'Avoid low-lying subways and Palm Beach road underpasses.',
            areaDescription: 'Navi Mumbai & Thane district',
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: rainfall,
              initialAlerts: alerts,
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('NWP Forecast & Official Alerts'), findsOneWidget);

      // Verify Rainfall Metrics
      expect(find.text('14.5 mm'), findsOneWidget);
      expect(find.text('65.0 mm'), findsOneWidget);
      expect(find.text('Total Expected'), findsOneWidget);

      // Verify SACHET Alert Card
      expect(find.text('Official Disaster Warnings'), findsOneWidget);
      expect(find.text('Flash Flood Warning for Navi Mumbai'), findsOneWidget);
      expect(find.text('SEVERE SEVERITY'), findsOneWidget);

      // Tap to expand alert instructions
      await tester.tap(find.text('Show Instructions & Details'));
      await tester.pumpAndSettle();

      expect(
        find.text('Instruction: Avoid low-lying subways and Palm Beach road underpasses.'),
        findsOneWidget,
      );
    });

    testWidgets('displays Unavailable for null rainfall and 0.0 mm for genuine zero', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test A: Null precipitation
      final nullRain = const RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'ok',
          isCached: false,
          isStale: false,
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        current: CurrentRainfall(
          timestamp: '2026-11-12T07:00:00Z',
          intervalSeconds: 900,
          precipitationMm: null, // Null value!
          unit: 'mm',
          isModelDerived: true,
          isPhysicalObservation: false,
          intervalDescription: 'Past 15 minutes',
        ),
        hourly: [],
        caveats: [],
      );

      final emptyAlerts = const AlertListResponse(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: nullRain,
              initialAlerts: emptyAlerts,
            ),
          ),
        ),
      );

      // Null should display 'Unavailable', NOT '0.0 mm'
      expect(find.text('Unavailable'), findsWidgets);
      expect(find.text('0.0 mm'), findsNothing);

      // Test B: Genuine zero precipitation
      final zeroRain = const RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'ok',
          isCached: false,
          isStale: false,
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        current: CurrentRainfall(
          timestamp: '2026-11-12T07:00:00Z',
          intervalSeconds: 900,
          precipitationMm: 0.0, // Genuine zero!
          unit: 'mm',
          isModelDerived: true,
          isPhysicalObservation: false,
          intervalDescription: 'Past 15 minutes',
        ),
        hourly: [],
        caveats: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: zeroRain,
              initialAlerts: emptyAlerts,
            ),
          ),
        ),
      );

      // Genuine zero must display '0.0 mm'
      expect(find.text('0.0 mm'), findsOneWidget);
    });

    testWidgets('displays stale fallback warning banner when data is degraded or stale', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staleRain = const RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'degraded',
          isCached: true,
          isStale: true,
          retrievedAt: '2026-11-12T06:00:00Z',
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        current: CurrentRainfall(
          timestamp: '2026-11-12T06:00:00Z',
          intervalSeconds: 900,
          precipitationMm: 3.5,
          unit: 'mm',
          isModelDerived: true,
          isPhysicalObservation: false,
          intervalDescription: 'Past 15 minutes',
        ),
        hourly: [],
        caveats: [],
      );

      final emptyAlerts = const AlertListResponse(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: staleRain,
              initialAlerts: emptyAlerts,
            ),
          ),
        ),
      );

      expect(find.text('⚠ Stale Fallback'), findsOneWidget);
      expect(
        find.textContaining('Notice: Open-Meteo upstream is currently unreachable.'),
        findsOneWidget,
      );
    });

    testWidgets('displays incomplete forecast notice and Open-Meteo attribution', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final incompleteRain = const RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'ok',
          isCached: false,
          isStale: false,
          retrievedAt: '2026-11-12T07:00:00Z',
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        current: CurrentRainfall(
          timestamp: '2026-11-12T07:00:00Z',
          intervalSeconds: 900,
          precipitationMm: 1.0,
          unit: 'mm',
          isModelDerived: true,
          isPhysicalObservation: false,
          intervalDescription: 'Past 15 minutes',
        ),
        hourly: [],
        summary: RainfallSummary(
          forecastHours: 24,
          validHours: 18,
          isComplete: false, // Incomplete forecast!
          totalPrecipitationMm: 12.0,
          maxHourlyPrecipitationMm: 3.5,
          maxProbabilityPct: 80,
        ),
        caveats: [],
      );

      final emptyAlerts = const AlertListResponse(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: incompleteRain,
              initialAlerts: emptyAlerts,
            ),
          ),
        ),
      );

      expect(find.text('Total Expected (Partial: 18/24h)'), findsOneWidget);
      expect(
        find.textContaining('* Incomplete forecast: 6 of 24 hourly intervals were missing'),
        findsOneWidget,
      );
      expect(
        find.text('Weather forecast data from Open-Meteo.com (Licensed under CC BY 4.0).'),
        findsOneWidget,
      );
    });

    testWidgets('displays error card when weather provider status is unavailable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unavailableRain = const RainfallResponse(
        provider: RainfallProviderStatus(
          provider: 'open-meteo',
          status: 'unavailable',
          isCached: false,
          isStale: false,
          errorMessage: 'Open-Meteo upstream is unreachable (503)',
          endpointUrl: '',
        ),
        requestedCoordinate: {'lat': 19.033, 'lon': 73.0297},
        dataType: 'hourly',
        isModelDerived: true,
        isPhysicalObservation: false,
        hourly: [],
        caveats: [],
      );

      final emptyAlerts = const AlertListResponse(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialRainfall: unavailableRain,
              initialAlerts: emptyAlerts,
            ),
          ),
        ),
      );

      expect(find.text('Rainfall forecast unavailable'), findsOneWidget);
      expect(find.text('Open-Meteo upstream is unreachable (503)'), findsOneWidget);
    });

    testWidgets('renders alert event badge and urgency badge, skipping unknown urgency', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final alerts = AlertListResponse(
        provider: const AlertProviderStatus(
          provider: 'sachet',
          status: 'ok',
          isCached: false,
          isStale: false,
          feedUrl: '',
        ),
        total: 2,
        alerts: const [
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'alert-1',
            sender: 'IMD Mumbai',
            status: 'Actual',
            msgType: 'Alert',
            event: 'Flash Flood',
            headline: 'Flash flood alert',
            severity: 'Extreme',
            urgency: 'Immediate',
            certainty: 'Observed',
            isActive: true,
            retrievedAt: '2026-11-12T07:00:00Z',
            alternateLanguages: [],
            geocodes: [],
            geometryType: 'none',
            hasSpatialGeometry: false,
            warnings: [],
          ),
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'alert-2',
            sender: 'IMD Mumbai',
            status: 'Actual',
            msgType: 'Alert',
            event: 'Heavy Rain',
            headline: 'Heavy rain alert',
            severity: 'Moderate',
            urgency: 'Unknown',
            certainty: 'Likely',
            isActive: true,
            retrievedAt: '2026-11-12T07:00:00Z',
            alternateLanguages: [],
            geocodes: [],
            geometryType: 'none',
            hasSpatialGeometry: false,
            warnings: [],
          ),
        ],
        spatialFilterApplied: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialAlerts: alerts,
            ),
          ),
        ),
      );

      // Event badges
      expect(find.text('Flash Flood'), findsOneWidget);
      expect(find.text('Heavy Rain'), findsOneWidget);

      // Urgency badges
      expect(find.text('Immediate Urgency'), findsOneWidget);
      expect(find.text('Unknown Urgency'), findsNothing);

      // Attribution
      expect(
        find.text('Official disaster warnings from NDMA SACHET (Common Alerting Protocol 1.2).'),
        findsOneWidget,
      );
    });

    testWidgets('renders effective and expiry timestamps formatted in IST and handles missing timestamps', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final alerts = AlertListResponse(
        provider: const AlertProviderStatus(
          provider: 'sachet',
          status: 'ok',
          isCached: false,
          isStale: false,
          feedUrl: '',
        ),
        total: 2,
        alerts: const [
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'alert-both',
            sender: 'IMD',
            status: 'Actual',
            msgType: 'Alert',
            event: 'Cyclone',
            headline: 'Cyclone warning',
            severity: 'Severe',
            urgency: 'Expected',
            certainty: 'Observed',
            isActive: true,
            effective: '2026-08-15T12:00:00Z',
            expires: '2026-08-15T18:00:00Z',
            retrievedAt: '2026-08-15T12:00:00Z',
            alternateLanguages: [],
            geocodes: [],
            geometryType: 'none',
            hasSpatialGeometry: false,
            warnings: [],
          ),
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'alert-expires-only',
            sender: 'IMD',
            status: 'Actual',
            msgType: 'Alert',
            headline: 'Advisory without effective date',
            severity: 'Minor',
            urgency: 'Future',
            certainty: 'Possible',
            isActive: true,
            effective: null,
            expires: '2026-08-16T06:30:00Z',
            retrievedAt: '2026-08-15T12:00:00Z',
            alternateLanguages: [],
            geocodes: [],
            geometryType: 'none',
            hasSpatialGeometry: false,
            warnings: [],
          ),
        ],
        spatialFilterApplied: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialAlerts: alerts,
            ),
          ),
        ),
      );

      // Verify formatted IST timeline strings
      expect(find.textContaining('Effective: 15 Aug, 5:30 PM IST'), findsOneWidget);
      expect(find.textContaining('Expires: 15 Aug, 11:30 PM IST'), findsOneWidget);
      expect(find.textContaining('Expires: 16 Aug, 12:00 PM IST'), findsOneWidget);
    });

    testWidgets('displays stale alert warning banner when alert feed is degraded or stale', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staleAlerts = AlertListResponse(
        provider: const AlertProviderStatus(
          provider: 'sachet',
          status: 'degraded',
          isCached: true,
          isStale: true,
          retrievedAt: '2026-11-12T05:00:00Z',
          feedUrl: 'https://sachet.ndma.gov.in',
        ),
        total: 1,
        alerts: const [
          NormalizedAlert(
            provider: 'sachet',
            identifier: 'cached-alert',
            sender: 'NDMA',
            status: 'Actual',
            msgType: 'Alert',
            headline: 'Cached Warning',
            severity: 'Moderate',
            urgency: 'Expected',
            certainty: 'Likely',
            isActive: true,
            retrievedAt: '2026-11-12T05:00:00Z',
            alternateLanguages: [],
            geocodes: [],
            geometryType: 'none',
            hasSpatialGeometry: false,
            warnings: [],
          ),
        ],
        spatialFilterApplied: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialAlerts: staleAlerts,
            ),
          ),
        ),
      );

      expect(find.textContaining('⚠ Stale Fallback'), findsOneWidget);
      expect(
        find.textContaining('Notice: NDMA SACHET feed is unreachable. Displaying cached alerts from 12 Nov, 10:30 AM IST.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error card when alerts provider status is unavailable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unavailableAlerts = const AlertListResponse(
        provider: AlertProviderStatus(
          provider: 'sachet',
          status: 'unavailable',
          isCached: false,
          isStale: false,
          errorMessage: 'NDMA SACHET CAP RSS feed connection timed out',
          feedUrl: 'https://sachet.ndma.gov.in',
        ),
        total: 0,
        alerts: [],
        spatialFilterApplied: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeatherAlertsSheet(
              initialAlerts: unavailableAlerts,
            ),
          ),
        ),
      );

      expect(find.text('Alerts feed unavailable'), findsOneWidget);
      expect(find.text('NDMA SACHET CAP RSS feed connection timed out'), findsOneWidget);
      expect(find.text('No Active Official Disaster Alerts'), findsNothing);
    });
  });
}
