import 'package:flutter_test/flutter_test.dart';
import 'package:varsha_flutter/models/alert.dart';
import 'package:varsha_flutter/models/place.dart';
import 'package:varsha_flutter/models/weather.dart';

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
  });
}
