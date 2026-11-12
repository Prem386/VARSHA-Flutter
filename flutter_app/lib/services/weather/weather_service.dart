import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/errors/app_exceptions.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';

class _RainfallCacheEntry {
  final RainfallResponse data;
  final DateTime timestamp;

  _RainfallCacheEntry(this.data, this.timestamp);
}

class _AlertsCacheEntry {
  final AlertListResponse data;
  final DateTime timestamp;

  _AlertsCacheEntry(this.data, this.timestamp);
}

class WeatherService {
  final http.Client _client;
  static const Duration cacheTtl = Duration(minutes: 5);

  /// Shared application-level instance preserving 5-minute cache across sheets.
  static final WeatherService shared = WeatherService();

  final Map<String, _RainfallCacheEntry> _rainfallCache = {};
  final Map<String, Future<RainfallResponse>> _inFlightRequests = {};
  final Map<String, _AlertsCacheEntry> _alertsCache = {};
  final Map<String, Future<AlertListResponse>> _inFlightAlertsRequests = {};

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Clears in-memory cache (for testing or explicit refresh).
  void clearCache() {
    _rainfallCache.clear();
    _inFlightRequests.clear();
    _alertsCache.clear();
    _inFlightAlertsRequests.clear();
  }

  /// Fetches rainfall forecast from FastAPI /api/v1/rainfall.
  Future<RainfallResponse> fetchRainfallForecast({
    double latitude = 19.0330,
    double longitude = 73.0297,
    int forecastHours = 24,
    String? customBaseUrl,
  }) async {
    final baseUrl = (customBaseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');
    final endpoint =
        '$baseUrl/api/v1/rainfall?latitude=$latitude&longitude=$longitude&forecast_hours=$forecastHours';

    // 1. Check in-memory 5-minute cache
    final cached = _rainfallCache[endpoint];
    if (cached != null && DateTime.now().difference(cached.timestamp) < cacheTtl) {
      return cached.data;
    }

    // 2. Reuse in-flight future for concurrent callers
    if (_inFlightRequests.containsKey(endpoint)) {
      return _inFlightRequests[endpoint]!;
    }

    final future = _executeRainfallRequest(endpoint);
    _inFlightRequests[endpoint] = future;

    try {
      return await future;
    } finally {
      _inFlightRequests.remove(endpoint);
    }
  }

  Future<RainfallResponse> _executeRainfallRequest(String endpoint) async {
    http.Response response;
    try {
      response = await _client.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const WeatherApiException(
        'Unable to connect to rainfall service. Verify backend is running.',
        0,
      );
    }

    if (response.statusCode != 200) {
      String detail = '';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errJson['detail'] is String) {
          detail = errJson['detail'] as String;
        }
      } catch (_) {}

      throw WeatherApiException(
        detail.isNotEmpty
            ? detail
            : 'Rainfall forecast service failed with status ${response.statusCode}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rainfall = RainfallResponse.fromJson(data);

    // Only cache if status is ok or degraded
    if (rainfall.provider.status == 'ok' || rainfall.provider.status == 'degraded') {
      _rainfallCache[endpoint] = _RainfallCacheEntry(rainfall, DateTime.now());
    }

    return rainfall;
  }

  /// Fetches official disaster alerts from FastAPI /api/v1/alerts (NDMA SACHET).
  Future<AlertListResponse> fetchOfficialAlerts({
    bool activeOnly = true,
    String? customBaseUrl,
  }) async {
    final baseUrl = (customBaseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');
    final endpoint = '$baseUrl/api/v1/alerts?active_only=$activeOnly';

    // 1. Check in-memory 5-minute cache
    final cached = _alertsCache[endpoint];
    if (cached != null && DateTime.now().difference(cached.timestamp) < cacheTtl) {
      return cached.data;
    }

    // 2. Reuse in-flight future for concurrent callers
    if (_inFlightAlertsRequests.containsKey(endpoint)) {
      return _inFlightAlertsRequests[endpoint]!;
    }

    final future = _executeAlertsRequest(endpoint);
    _inFlightAlertsRequests[endpoint] = future;

    try {
      return await future;
    } finally {
      _inFlightAlertsRequests.remove(endpoint);
    }
  }

  Future<AlertListResponse> _executeAlertsRequest(String endpoint) async {
    http.Response response;
    try {
      response = await _client.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const WeatherApiException(
        'Unable to connect to official alerts service. Verify backend is running.',
        0,
      );
    }

    if (response.statusCode != 200) {
      String detail = '';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errJson['detail'] is String) {
          detail = errJson['detail'] as String;
        }
      } catch (_) {}

      throw WeatherApiException(
        detail.isNotEmpty
            ? detail
            : 'Official alerts service failed with status ${response.statusCode}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final alerts = AlertListResponse.fromJson(data);

    // Only cache if status is ok or degraded
    if (alerts.provider.status == 'ok' || alerts.provider.status == 'degraded') {
      _alertsCache[endpoint] = _AlertsCacheEntry(alerts, DateTime.now());
    }

    return alerts;
  }

  /// Convenience health check method.
  Future<bool> checkBackendHealth({String? customBaseUrl}) async {
    final baseUrl = (customBaseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
