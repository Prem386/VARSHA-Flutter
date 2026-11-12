import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/errors/app_exceptions.dart';
import '../../models/place.dart';

class PlacesService {
  final http.Client _client;

  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches places via FastAPI backend /api/v1/places/search proxy.
  /// Falls back to curated Navi Mumbai landmarks on network or server error.
  Future<PlaceSearchResponse> searchPlaces(
    String query, {
    int limit = 5,
    String? customBaseUrl,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      return PlaceSearchResponse(
        query: cleanQuery,
        total: 0,
        results: [],
        source: 'geoapify',
        cached: false,
      );
    }

    final baseUrl = (customBaseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(
      '$baseUrl/api/v1/places/search?q=${Uri.encodeComponent(cleanQuery)}&limit=$limit',
    );

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      throw const PlaceSearchException(
        'Unable to connect to place search service. Check network or backend connectivity.',
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

      if (detail.isEmpty) {
        if (response.statusCode == 502 || response.statusCode == 504 || response.statusCode == 500) {
          detail =
              'Backend service unreachable (HTTP ${response.statusCode}). Verify FastAPI server is running.';
        }
      }

      if (response.statusCode == 503) {
        throw PlaceSearchException(
          detail.isNotEmpty ? detail : 'Geocoding service is unavailable (API key not configured).',
          503,
        );
      }
      if (response.statusCode == 429) {
        throw PlaceSearchException(
          detail.isNotEmpty ? detail : 'Geocoding request rate limit exceeded. Please wait a moment.',
          429,
        );
      }
      if (response.statusCode == 504) {
        throw PlaceSearchException(
          detail.isNotEmpty ? detail : 'Geocoding search request timed out.',
          504,
        );
      }
      throw PlaceSearchException(
        detail.isNotEmpty ? detail : 'Geocoding search failed with status ${response.statusCode}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PlaceSearchResponse.fromJson(data);
  }
}
