import 'package:latlong2/latlong.dart';

/// Provider operational status and cache metadata for NDMA SACHET alerts.
class AlertProviderStatus {
  final String provider;
  final String status; // 'ok' | 'degraded' | 'unavailable'
  final bool isCached;
  final bool isStale;
  final String? retrievedAt;
  final String? errorMessage;
  final String feedUrl;

  const AlertProviderStatus({
    required this.provider,
    required this.status,
    required this.isCached,
    required this.isStale,
    this.retrievedAt,
    this.errorMessage,
    required this.feedUrl,
  });

  factory AlertProviderStatus.fromJson(Map<String, dynamic> json) {
    return AlertProviderStatus(
      provider: json['provider'] as String? ?? 'sachet',
      status: json['status'] as String? ?? 'ok',
      isCached: json['is_cached'] as bool? ?? false,
      isStale: json['is_stale'] as bool? ?? false,
      retrievedAt: json['retrieved_at'] as String?,
      errorMessage: json['error_message'] as String?,
      feedUrl: json['feed_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'status': status,
    'is_cached': isCached,
    'is_stale': isStale,
    'retrieved_at': retrievedAt,
    'error_message': errorMessage,
    'feed_url': feedUrl,
  };
}

/// Geocoding key-value pair attached to CAP 1.2 alert.
class AlertGeocode {
  final String valueName;
  final String value;

  const AlertGeocode({required this.valueName, required this.value});

  factory AlertGeocode.fromJson(Map<String, dynamic> json) {
    return AlertGeocode(
      valueName: json['value_name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'value_name': valueName,
    'value': value,
  };
}

/// Normalized disaster warning record from NDMA SACHET.
class NormalizedAlert {
  final String provider;
  final String identifier;
  final String sender;
  final String? sent;
  final String status;
  final String msgType;
  final String? references;
  final String? category;
  final String? event;
  final String? headline;
  final String? description;
  final String? instruction;
  final String severity;
  final String urgency;
  final String certainty;
  final bool isActive;
  final String? effective;
  final String? onset;
  final String? expires;
  final String retrievedAt;
  final String? language;
  final List<String> alternateLanguages;
  final String? areaDescription;
  final List<AlertGeocode> geocodes;
  final String geometryType;
  final List<LatLng>? coordinates;
  final bool hasSpatialGeometry;
  final String? rawSeverity;
  final String? rawUrgency;
  final String? rawCertainty;
  final List<String> warnings;

  const NormalizedAlert({
    required this.provider,
    required this.identifier,
    required this.sender,
    this.sent,
    required this.status,
    required this.msgType,
    this.references,
    this.category,
    this.event,
    this.headline,
    this.description,
    this.instruction,
    required this.severity,
    required this.urgency,
    required this.certainty,
    required this.isActive,
    this.effective,
    this.onset,
    this.expires,
    required this.retrievedAt,
    this.language,
    required this.alternateLanguages,
    this.areaDescription,
    required this.geocodes,
    required this.geometryType,
    this.coordinates,
    required this.hasSpatialGeometry,
    this.rawSeverity,
    this.rawUrgency,
    this.rawCertainty,
    required this.warnings,
  });

  factory NormalizedAlert.fromJson(Map<String, dynamic> json) {
    final altLangList = json['alternate_languages'] as List<dynamic>? ?? [];
    final geocodesList = json['geocodes'] as List<dynamic>? ?? [];
    final warningsList = json['warnings'] as List<dynamic>? ?? [];
    final coordsList = json['coordinates'] as List<dynamic>?;

    List<LatLng>? parsedCoords;
    if (coordsList != null) {
      parsedCoords = coordsList
          .map((item) {
            final map = item as Map<String, dynamic>;
            return LatLng(
              (map['latitude'] as num).toDouble(),
              (map['longitude'] as num).toDouble(),
            );
          })
          .toList();
    }

    return NormalizedAlert(
      provider: json['provider'] as String? ?? 'sachet',
      identifier: json['identifier'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      sent: json['sent'] as String?,
      status: json['status'] as String? ?? '',
      msgType: json['msg_type'] as String? ?? '',
      references: json['references'] as String?,
      category: json['category'] as String?,
      event: json['event'] as String?,
      headline: json['headline'] as String?,
      description: json['description'] as String?,
      instruction: json['instruction'] as String?,
      severity: json['severity'] as String? ?? 'Unknown',
      urgency: json['urgency'] as String? ?? 'Unknown',
      certainty: json['certainty'] as String? ?? 'Unknown',
      isActive: json['is_active'] as bool? ?? true,
      effective: json['effective'] as String?,
      onset: json['onset'] as String?,
      expires: json['expires'] as String?,
      retrievedAt: json['retrieved_at'] as String? ?? '',
      language: json['language'] as String?,
      alternateLanguages: altLangList.map((e) => e.toString()).toList(),
      areaDescription: json['area_description'] as String?,
      geocodes: geocodesList
          .map((e) => AlertGeocode.fromJson(e as Map<String, dynamic>))
          .toList(),
      geometryType: json['geometry_type'] as String? ?? 'none',
      coordinates: parsedCoords,
      hasSpatialGeometry: json['has_spatial_geometry'] as bool? ?? false,
      rawSeverity: json['raw_severity'] as String?,
      rawUrgency: json['raw_urgency'] as String?,
      rawCertainty: json['raw_certainty'] as String?,
      warnings: warningsList.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'identifier': identifier,
    'sender': sender,
    'sent': sent,
    'status': status,
    'msg_type': msgType,
    'references': references,
    'category': category,
    'event': event,
    'headline': headline,
    'description': description,
    'instruction': instruction,
    'severity': severity,
    'urgency': urgency,
    'certainty': certainty,
    'is_active': isActive,
    'effective': effective,
    'onset': onset,
    'expires': expires,
    'retrieved_at': retrievedAt,
    'language': language,
    'alternate_languages': alternateLanguages,
    'area_description': areaDescription,
    'geocodes': geocodes.map((g) => g.toJson()).toList(),
    'geometry_type': geometryType,
    'coordinates': coordinates
        ?.map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
        .toList(),
    'has_spatial_geometry': hasSpatialGeometry,
    'raw_severity': rawSeverity,
    'raw_urgency': rawUrgency,
    'raw_certainty': rawCertainty,
    'warnings': warnings,
  };
}

/// Alert list response envelope from FastAPI /api/v1/alerts.
class AlertListResponse {
  final AlertProviderStatus provider;
  final int total;
  final List<NormalizedAlert> alerts;
  final bool spatialFilterApplied;
  final String? spatialFilterNote;

  const AlertListResponse({
    required this.provider,
    required this.total,
    required this.alerts,
    required this.spatialFilterApplied,
    this.spatialFilterNote,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) {
    final alertList = json['alerts'] as List<dynamic>? ?? [];
    return AlertListResponse(
      provider: AlertProviderStatus.fromJson(json['provider'] as Map<String, dynamic>? ?? {}),
      total: json['total'] as int? ?? 0,
      alerts: alertList
          .map((item) => NormalizedAlert.fromJson(item as Map<String, dynamic>))
          .toList(),
      spatialFilterApplied: json['spatial_filter_applied'] as bool? ?? false,
      spatialFilterNote: json['spatial_filter_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.toJson(),
    'total': total,
    'alerts': alerts.map((a) => a.toJson()).toList(),
    'spatial_filter_applied': spatialFilterApplied,
    'spatial_filter_note': spatialFilterNote,
  };
}
