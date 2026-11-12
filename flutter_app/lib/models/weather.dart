/// Provider operational status and cache metadata for rainfall forecasts.
class RainfallProviderStatus {
  final String provider;
  final String status; // 'ok' | 'degraded' | 'unavailable'
  final bool isCached;
  final bool isStale;
  final String? retrievedAt;
  final String? errorMessage;
  final String endpointUrl;

  const RainfallProviderStatus({
    required this.provider,
    required this.status,
    required this.isCached,
    required this.isStale,
    this.retrievedAt,
    this.errorMessage,
    required this.endpointUrl,
  });

  factory RainfallProviderStatus.fromJson(Map<String, dynamic> json) {
    return RainfallProviderStatus(
      provider: json['provider'] as String? ?? 'open_meteo',
      status: json['status'] as String? ?? 'ok',
      isCached: json['is_cached'] as bool? ?? false,
      isStale: json['is_stale'] as bool? ?? false,
      retrievedAt: json['retrieved_at'] as String?,
      errorMessage: json['error_message'] as String?,
      endpointUrl: json['endpoint_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'status': status,
    'is_cached': isCached,
    'is_stale': isStale,
    'retrieved_at': retrievedAt,
    'error_message': errorMessage,
    'endpoint_url': endpointUrl,
  };
}

/// Recent model precipitation estimate over a 15-minute evaluation window.
class CurrentRainfall {
  final String timestamp;
  final int intervalSeconds;
  final double? precipitationMm;
  final String unit;
  final bool isModelDerived;
  final bool isPhysicalObservation;
  final String intervalDescription;

  const CurrentRainfall({
    required this.timestamp,
    required this.intervalSeconds,
    this.precipitationMm,
    required this.unit,
    required this.isModelDerived,
    required this.isPhysicalObservation,
    required this.intervalDescription,
  });

  factory CurrentRainfall.fromJson(Map<String, dynamic> json) {
    return CurrentRainfall(
      timestamp: json['timestamp'] as String? ?? '',
      intervalSeconds: json['interval_seconds'] as int? ?? 900,
      precipitationMm: (json['precipitation_mm'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'mm',
      isModelDerived: json['is_model_derived'] as bool? ?? true,
      isPhysicalObservation: json['is_physical_observation'] as bool? ?? false,
      intervalDescription: json['interval_description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'interval_seconds': intervalSeconds,
    'precipitation_mm': precipitationMm,
    'unit': unit,
    'is_model_derived': isModelDerived,
    'is_physical_observation': isPhysicalObservation,
    'interval_description': intervalDescription,
  };
}

/// Hourly precipitation interval step in NWP forecast.
class PrecipitationStep {
  final String timestamp;
  final double? precipitationMm;
  final double? precipitationProbabilityPct;
  final int intervalMinutes;
  final String unit;
  final bool isModelDerived;

  const PrecipitationStep({
    required this.timestamp,
    this.precipitationMm,
    this.precipitationProbabilityPct,
    required this.intervalMinutes,
    required this.unit,
    required this.isModelDerived,
  });

  factory PrecipitationStep.fromJson(Map<String, dynamic> json) {
    return PrecipitationStep(
      timestamp: json['timestamp'] as String? ?? '',
      precipitationMm: (json['precipitation_mm'] as num?)?.toDouble(),
      precipitationProbabilityPct: (json['precipitation_probability_pct'] as num?)?.toDouble(),
      intervalMinutes: json['interval_minutes'] as int? ?? 60,
      unit: json['unit'] as String? ?? 'mm',
      isModelDerived: json['is_model_derived'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'precipitation_mm': precipitationMm,
    'precipitation_probability_pct': precipitationProbabilityPct,
    'interval_minutes': intervalMinutes,
    'unit': unit,
    'is_model_derived': isModelDerived,
  };
}

/// Rolling 24-hour summary metrics.
class RainfallSummary {
  final int forecastHours;
  final double? totalPrecipitationMm;
  final double? maxHourlyPrecipitationMm;
  final double? maxProbabilityPct;
  final int? validHours;
  final bool isComplete;

  const RainfallSummary({
    required this.forecastHours,
    this.totalPrecipitationMm,
    this.maxHourlyPrecipitationMm,
    this.maxProbabilityPct,
    this.validHours,
    required this.isComplete,
  });

  factory RainfallSummary.fromJson(Map<String, dynamic> json) {
    return RainfallSummary(
      forecastHours: json['forecast_hours'] as int? ?? 24,
      totalPrecipitationMm: (json['total_precipitation_mm'] as num?)?.toDouble(),
      maxHourlyPrecipitationMm: (json['max_hourly_precipitation_mm'] as num?)?.toDouble(),
      maxProbabilityPct: (json['max_probability_pct'] as num?)?.toDouble(),
      validHours: json['valid_hours'] as int?,
      isComplete: json['is_complete'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'forecast_hours': forecastHours,
    'total_precipitation_mm': totalPrecipitationMm,
    'max_hourly_precipitation_mm': maxHourlyPrecipitationMm,
    'max_probability_pct': maxProbabilityPct,
    'valid_hours': validHours,
    'is_complete': isComplete,
  };
}

/// Top-level rainfall forecast response from FastAPI /api/v1/rainfall.
class RainfallResponse {
  final RainfallProviderStatus provider;
  final Map<String, double> requestedCoordinate;
  final String dataType;
  final bool isModelDerived;
  final bool isPhysicalObservation;
  final CurrentRainfall? current;
  final List<PrecipitationStep> hourly;
  final RainfallSummary? summary;
  final List<String> caveats;

  const RainfallResponse({
    required this.provider,
    required this.requestedCoordinate,
    required this.dataType,
    required this.isModelDerived,
    required this.isPhysicalObservation,
    this.current,
    required this.hourly,
    this.summary,
    required this.caveats,
  });

  factory RainfallResponse.fromJson(Map<String, dynamic> json) {
    final coordJson = json['requested_coordinate'] as Map<String, dynamic>? ?? {};
    final hourlyList = json['hourly'] as List<dynamic>? ?? [];
    final caveatsList = json['caveats'] as List<dynamic>? ?? [];

    return RainfallResponse(
      provider: RainfallProviderStatus.fromJson(json['provider'] as Map<String, dynamic>? ?? {}),
      requestedCoordinate: {
        'latitude': (coordJson['latitude'] as num?)?.toDouble() ?? 0.0,
        'longitude': (coordJson['longitude'] as num?)?.toDouble() ?? 0.0,
      },
      dataType: json['data_type'] as String? ?? 'numerical_weather_prediction_precipitation',
      isModelDerived: json['is_model_derived'] as bool? ?? true,
      isPhysicalObservation: json['is_physical_observation'] as bool? ?? false,
      current: json['current'] != null
          ? CurrentRainfall.fromJson(json['current'] as Map<String, dynamic>)
          : null,
      hourly: hourlyList
          .map((item) => PrecipitationStep.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] != null
          ? RainfallSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      caveats: caveatsList.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.toJson(),
    'requested_coordinate': requestedCoordinate,
    'data_type': dataType,
    'is_model_derived': isModelDerived,
    'is_physical_observation': isPhysicalObservation,
    'current': current?.toJson(),
    'hourly': hourly.map((h) => h.toJson()).toList(),
    'summary': summary?.toJson(),
    'caveats': caveats,
  };
}

/// Chronologically filters upcoming future hours from hourly forecast.
/// Matches the current-hour boundary rule from React selectNextSixForecastHours.
List<PrecipitationStep> selectNextSixForecastHours(
  List<PrecipitationStep>? hourly, [
  DateTime? referenceTime,
]) {
  if (hourly == null || hourly.isEmpty) return [];

  final validWithDates = <MapEntry<PrecipitationStep, DateTime>>[];
  for (final step in hourly) {
    try {
      final parsed = DateTime.parse(
        step.timestamp.endsWith('Z') || step.timestamp.contains('+')
            ? step.timestamp
            : '${step.timestamp}Z',
      );
      validWithDates.add(MapEntry(step, parsed));
    } catch (_) {
      // Skip invalid timestamp
    }
  }

  if (validWithDates.isEmpty) return [];

  // Sort chronologically
  validWithDates.sort((a, b) => a.value.compareTo(b.value));

  // Determine current hour cutoff
  DateTime? cutoff;
  if (referenceTime != null) {
    cutoff = DateTime.utc(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
      referenceTime.hour,
    );
  }

  final futureSteps = cutoff != null
      ? validWithDates.where((e) => e.value.isAfter(cutoff!)).toList()
      : validWithDates;

  return futureSteps.take(6).map((e) => e.key).toList();
}
