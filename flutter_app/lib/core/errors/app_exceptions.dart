/// Base exception for all VARSHA application errors.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Weather & alert service exception (FastAPI backend /api/v1/rainfall, /api/v1/alerts).
class WeatherApiException extends AppException {
  const WeatherApiException(super.message, [super.statusCode]);
}

/// Place search & geocoding exception (FastAPI backend /api/v1/places/search).
class PlaceSearchException extends AppException {
  const PlaceSearchException(super.message, [super.statusCode]);
}

/// OSRM road routing service exception.
class RoutingException extends AppException {
  const RoutingException(super.message, [super.statusCode]);
}

/// Location permission or sensor exception.
class LocationException extends AppException {
  const LocationException(super.message, [super.statusCode]);
}
