import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/place.dart';
import 'package:varsha_flutter/models/weather.dart';
import 'package:varsha_flutter/services/weather/weather_service.dart';

class _MockHttpClient extends http.BaseClient {
  int requestCount = 0;
  final http.Response Function(http.BaseRequest request) handler;

  _MockHttpClient(this.handler);

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

void main() {
  group('Weather and Places Models & Parsing', () {
    test('RainfallResponse parsed correctly from API json', () {
      final json = {
        'provider': {
          'provider': 'open_meteo',
          'status': 'ok',
          'is_cached': false,
          'is_stale': false,
          'retrieved_at': '2026-11-12T07:00:00Z',
          'endpoint_url': 'https://api.open-meteo.com/v1/forecast',
        },
        'requested_coordinate': {'latitude': 19.033, 'longitude': 73.0297},
        'data_type': 'numerical_weather_prediction_precipitation',
        'is_model_derived': true,
        'is_physical_observation': false,
        'current': {
          'timestamp': '2026-11-12T07:00:00Z',
          'interval_seconds': 900,
          'precipitation_mm': 2.4,
          'unit': 'mm',
          'is_model_derived': true,
          'is_physical_observation': false,
          'interval_description': '15-minute evaluation window',
        },
        'hourly': [
          {
            'timestamp': '2026-11-12T08:00:00Z',
            'precipitation_mm': 1.2,
            'precipitation_probability_pct': 60.0,
            'interval_minutes': 60,
            'unit': 'mm',
            'is_model_derived': true,
          },
          {
            'timestamp': '2026-11-12T09:00:00Z',
            'precipitation_mm': 4.5,
            'precipitation_probability_pct': 85.0,
            'interval_minutes': 60,
            'unit': 'mm',
            'is_model_derived': true,
          },
        ],
        'summary': {
          'forecast_hours': 24,
          'total_precipitation_mm': 15.6,
          'max_hourly_precipitation_mm': 4.5,
          'max_probability_pct': 85.0,
          'valid_hours': 24,
          'is_complete': true,
        },
        'caveats': ['Model-derived numerical prediction'],
      };

      final response = RainfallResponse.fromJson(json);

      expect(response.provider.status, 'ok');
      expect(response.current?.precipitationMm, 2.4);
      expect(response.hourly.length, 2);
      expect(response.hourly[0].precipitationMm, 1.2);
      expect(response.hourly[0].precipitationProbabilityPct, 60.0);
      expect(response.summary?.totalPrecipitationMm, 15.6);
      expect(response.summary?.maxProbabilityPct, 85.0);
    });

    test('selectNextSixForecastHours filters strictly future hours chronologically', () {
      final steps = [
        const PrecipitationStep(
          timestamp: '2026-11-12T06:00:00Z',
          precipitationMm: 0.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T07:00:00Z',
          precipitationMm: 1.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T08:00:00Z',
          precipitationMm: 2.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T09:00:00Z',
          precipitationMm: 3.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
      ];

      // Reference time is 07:15 UTC -> currentHour cutoff is 07:00 UTC
      // Future steps must have timestamp > 07:00 (i.e. 08:00 and 09:00)
      final refTime = DateTime.parse('2026-11-12T07:15:00Z');
      final nextHours = selectNextSixForecastHours(steps, refTime);

      expect(nextHours.length, 2);
      expect(nextHours[0].timestamp, '2026-11-12T08:00:00Z');
      expect(nextHours[1].timestamp, '2026-11-12T09:00:00Z');
    });

    test('AlertListResponse parsed correctly from API json', () {
      final json = {
        'provider': {
          'provider': 'sachet',
          'status': 'ok',
          'is_cached': false,
          'is_stale': false,
          'feed_url': 'https://sachet.ndma.gov.in',
        },
        'total': 1,
        'alerts': [
          {
            'provider': 'sachet',
            'identifier': 'alert-001',
            'sender': 'IMD Mumbai',
            'status': 'Actual',
            'msg_type': 'Alert',
            'headline': 'Heavy Rainfall Warning for Thane and Raigad',
            'description': 'Very heavy rainfall expected in isolated places.',
            'instruction': 'Avoid waterlogged underpasses and coastal roads.',
            'severity': 'Severe',
            'urgency': 'Immediate',
            'certainty': 'Observed',
            'is_active': true,
            'effective': '2026-11-12T06:00:00Z',
            'expires': '2026-11-12T18:00:00Z',
            'retrieved_at': '2026-11-12T07:00:00Z',
            'alternate_languages': ['hi', 'mr'],
            'area_description': 'Thane, Navi Mumbai, Raigad districts',
            'geocodes': [
              {'value_name': 'district', 'value': 'Navi Mumbai'},
            ],
            'geometry_type': 'none',
            'has_spatial_geometry': false,
            'warnings': [],
          }
        ],
        'spatial_filter_applied': false,
      };

      final response = AlertListResponse.fromJson(json);

      expect(response.total, 1);
      expect(response.alerts.length, 1);
      final alert = response.alerts.first;
      expect(alert.identifier, 'alert-001');
      expect(alert.severity, 'Severe');
      expect(alert.sender, 'IMD Mumbai');
      expect(alert.headline, 'Heavy Rainfall Warning for Thane and Raigad');
      expect(alert.instruction, 'Avoid waterlogged underpasses and coastal roads.');
      expect(alert.areaDescription, 'Thane, Navi Mumbai, Raigad districts');
    });

    test('Curated landmark search matches by name and aliases', () {
      final vashiMatches = searchCuratedLandmarks('vashi');
      expect(vashiMatches.isNotEmpty, true);
      expect(vashiMatches.any((l) => l.name.contains('Vashi')), true);

      final aliasMatches = searchCuratedLandmarks('Moraj Circle');
      expect(aliasMatches.isNotEmpty, true);
      expect(aliasMatches.first.id, 'palm-beach-moraj');

      final emptyMatches = searchCuratedLandmarks('nonexistent place 12345');
      expect(emptyMatches.isEmpty, true);
    });

    test('selectNextSixForecastHours handles edge cases safely', () {
      // 1. Empty and null data
      expect(selectNextSixForecastHours(null), isEmpty);
      expect(selectNextSixForecastHours([]), isEmpty);

      final refTime = DateTime.parse('2026-11-12T07:00:00Z');

      // 2. Exact hour boundary: step at 07:00 is current hour and excluded; 08:00 is first future hour
      final boundarySteps = [
        const PrecipitationStep(
          timestamp: '2026-11-12T06:00:00Z',
          precipitationMm: 0.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T07:00:00Z',
          precipitationMm: 0.5,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T08:00:00Z',
          precipitationMm: 1.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
      ];
      final boundaryRes = selectNextSixForecastHours(boundarySteps, refTime);
      expect(boundaryRes.length, 1);
      expect(boundaryRes.first.timestamp, '2026-11-12T08:00:00Z');

      // 3. Out of order timestamps sorted chronologically
      final unorderedSteps = [
        const PrecipitationStep(
          timestamp: '2026-11-12T10:00:00Z',
          precipitationMm: 3.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T08:00:00Z',
          precipitationMm: 1.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T09:00:00Z',
          precipitationMm: 2.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
      ];
      final orderedRes = selectNextSixForecastHours(unorderedSteps, refTime);
      expect(orderedRes.map((s) => s.timestamp).toList(), [
        '2026-11-12T08:00:00Z',
        '2026-11-12T09:00:00Z',
        '2026-11-12T10:00:00Z',
      ]);

      // 4. Missing intervals (gap between 08:00 and 11:00)
      final gapSteps = [
        const PrecipitationStep(
          timestamp: '2026-11-12T08:00:00Z',
          precipitationMm: 1.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
        const PrecipitationStep(
          timestamp: '2026-11-12T11:00:00Z',
          precipitationMm: 4.0,
          intervalMinutes: 60,
          unit: 'mm',
          isModelDerived: true,
        ),
      ];
      final gapRes = selectNextSixForecastHours(gapSteps, refTime);
      expect(gapRes.length, 2);
      expect(gapRes[0].timestamp, '2026-11-12T08:00:00Z');
      expect(gapRes[1].timestamp, '2026-11-12T11:00:00Z');
    });

    test('IST time formatters correctly convert UTC timestamps', () {
      // 08:00 UTC + 5:30 = 13:30 -> 1:30 PM
      expect(formatHourSlotIst('2026-11-12T08:00:00Z'), '1:30 PM');

      // 07:30 UTC + 5:30 = 13:00 -> 1:00 PM
      expect(formatHourSlotIst('2026-11-12T07:30:00Z'), '1:00 PM');

      // 00:00 UTC + 5:30 = 05:30 -> 5:30 AM
      expect(formatHourSlotIst('2026-11-12T00:00:00Z'), '5:30 AM');

      // 18:30 UTC + 5:30 = 00:00 next day -> 12:00 AM
      expect(formatHourSlotIst('2026-11-12T18:30:00Z'), '12:00 AM');

      // Null and empty handling
      expect(formatHourSlotIst(null), '—');
      expect(formatHourSlotIst(''), '—');

      // Date timestamp format
      final tsStr = formatTimestampIst('2026-11-12T07:00:00Z');
      expect(tsStr, '12 Nov, 12:30 PM IST');
      expect(formatTimestampIst(null), 'Not specified');
    });
  });

  group('WeatherService Lifecycle & Caching', () {
    final validPayload = jsonEncode({
      'provider': {
        'provider': 'open_meteo',
        'status': 'ok',
        'is_cached': false,
        'is_stale': false,
        'retrieved_at': '2026-11-12T07:00:00Z',
        'endpoint_url': 'https://api.open-meteo.com/v1/forecast',
      },
      'requested_coordinate': {'latitude': 19.033, 'longitude': 73.0297},
      'data_type': 'numerical_weather_prediction_precipitation',
      'is_model_derived': true,
      'is_physical_observation': false,
      'current': {
        'timestamp': '2026-11-12T07:00:00Z',
        'interval_seconds': 900,
        'precipitation_mm': 1.5,
        'unit': 'mm',
        'is_model_derived': true,
        'is_physical_observation': false,
        'interval_description': '15m window',
      },
      'hourly': [],
      'caveats': [],
    });

    test('caches successful forecast and reuses it within TTL', () async {
      final mock = _MockHttpClient((_) => http.Response(validPayload, 200));
      final service = WeatherService(client: mock);

      final res1 = await service.fetchRainfallForecast();
      expect(res1.provider.status, 'ok');
      expect(mock.requestCount, 1);

      final res2 = await service.fetchRainfallForecast();
      expect(res2.provider.status, 'ok');
      expect(mock.requestCount, 1);
    });

    test('caches degraded / stale forecast', () async {
      final degradedPayload = jsonEncode({
        'provider': {
          'provider': 'open_meteo',
          'status': 'degraded',
          'is_cached': true,
          'is_stale': true,
          'retrieved_at': '2026-11-12T06:00:00Z',
          'endpoint_url': 'https://api.open-meteo.com/v1/forecast',
        },
        'requested_coordinate': {'latitude': 19.033, 'longitude': 73.0297},
        'data_type': 'numerical_weather_prediction_precipitation',
        'is_model_derived': true,
        'is_physical_observation': false,
        'hourly': [],
        'caveats': [],
      });

      final mock = _MockHttpClient((_) => http.Response(degradedPayload, 200));
      final service = WeatherService(client: mock);

      final res1 = await service.fetchRainfallForecast();
      expect(res1.provider.isStale, true);
      expect(mock.requestCount, 1);

      final res2 = await service.fetchRainfallForecast();
      expect(res2.provider.status, 'degraded');
      expect(mock.requestCount, 1);
    });

    test('does not cache unavailable forecast', () async {
      final unavailablePayload = jsonEncode({
        'provider': {
          'provider': 'open_meteo',
          'status': 'unavailable',
          'is_cached': false,
          'is_stale': false,
          'error_message': 'Upstream down',
          'endpoint_url': 'https://api.open-meteo.com/v1/forecast',
        },
        'requested_coordinate': {'latitude': 19.033, 'longitude': 73.0297},
        'data_type': 'numerical_weather_prediction_precipitation',
        'is_model_derived': true,
        'is_physical_observation': false,
        'hourly': [],
        'caveats': [],
      });

      final mock = _MockHttpClient((_) => http.Response(unavailablePayload, 200));
      final service = WeatherService(client: mock);

      final res1 = await service.fetchRainfallForecast();
      expect(res1.provider.status, 'unavailable');
      expect(mock.requestCount, 1);

      final res2 = await service.fetchRainfallForecast();
      expect(res2.provider.status, 'unavailable');
      expect(mock.requestCount, 2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      final mock = _MockHttpClient((_) => http.Response(validPayload, 200));
      final service = WeatherService(client: mock);

      final results = await Future.wait([
        service.fetchRainfallForecast(),
        service.fetchRainfallForecast(),
        service.fetchRainfallForecast(),
      ]);

      expect(results.length, 3);
      expect(mock.requestCount, 1);
    });
  });
}
