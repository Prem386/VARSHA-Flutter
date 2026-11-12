import 'package:latlong2/latlong.dart';

/// Suggestion item returned from backend Geoapify search or curated directory.
class PlaceSuggestion {
  final String id;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String source; // 'geoapify' | 'curated'
  final String? category;
  final String? locality;

  const PlaceSuggestion({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.category,
    this.locality,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      source: json['source'] as String? ?? 'geoapify',
      category: json['category'] as String?,
      locality: json['locality'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'formatted_address': formattedAddress,
    'latitude': latitude,
    'longitude': longitude,
    'source': source,
    'category': category,
    'locality': locality,
  };
}

/// Response payload from FastAPI /api/v1/places/search.
class PlaceSearchResponse {
  final String query;
  final int total;
  final List<PlaceSuggestion> results;
  final String source;
  final bool cached;

  const PlaceSearchResponse({
    required this.query,
    required this.total,
    required this.results,
    required this.source,
    required this.cached,
  });

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['results'] as List<dynamic>? ?? [];
    return PlaceSearchResponse(
      query: json['query'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      results: rawList
          .map((item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>))
          .where((item) =>
              item.latitude >= -90 &&
              item.latitude <= 90 &&
              item.longitude >= -180 &&
              item.longitude <= 180)
          .toList(),
      source: json['source'] as String? ?? 'geoapify',
      cached: json['cached'] as bool? ?? false,
    );
  }
}

/// Curated local landmark for offline search and reliable fallback.
class Landmark {
  final String id;
  final String name;
  final String locality;
  final String category;
  final LatLng coordinates;
  final List<String> aliases;

  const Landmark({
    required this.id,
    required this.name,
    required this.locality,
    required this.category,
    required this.coordinates,
    this.aliases = const [],
  });

  PlaceSuggestion toSuggestion() {
    return PlaceSuggestion(
      id: id,
      name: name,
      formattedAddress: '$locality • $category',
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      source: 'curated',
      category: category,
      locality: locality,
    );
  }
}

/// Curated Navi Mumbai landmark directory matching React landmarks.ts.
const List<Landmark> naviMumbaiLandmarks = [
  Landmark(
    id: 'vashi-stn',
    name: 'Vashi Railway Station',
    locality: 'Vashi',
    category: 'Transit Hub',
    coordinates: LatLng(19.0645, 72.9983),
    aliases: ['Vashi Station', 'Vashi Stn', 'Vashi Local'],
  ),
  Landmark(
    id: 'vashi-sec17',
    name: 'Vashi Sector 17',
    locality: 'Vashi',
    category: 'Commercial',
    coordinates: LatLng(19.0760, 72.9985),
    aliases: ['Sector 17 Vashi', 'Vashi Plaza', 'Sector 17', 'Sec 17', 'Vashi Sec 17'],
  ),
  Landmark(
    id: 'apmc-market',
    name: 'APMC Market',
    locality: 'Vashi',
    category: 'Commercial',
    coordinates: LatLng(19.0754, 73.0076),
    aliases: ['Vashi APMC', 'Dana Bandar Navi Mumbai', 'Grain Market'],
  ),
  Landmark(
    id: 'sanpada-stn',
    name: 'Sanpada Railway Station',
    locality: 'Sanpada',
    category: 'Transit Hub',
    coordinates: LatLng(19.0655, 73.0108),
    aliases: ['Sanpada Station'],
  ),
  Landmark(
    id: 'palm-beach-moraj',
    name: 'Palm Beach Road (Moraj Circle)',
    locality: 'Sanpada',
    category: 'Arterial Corridor',
    coordinates: LatLng(19.0635, 73.0062),
    aliases: ['Moraj Circle', 'Palm Beach Road Entry'],
  ),
  Landmark(
    id: 'turbhe-naka',
    name: 'Turbhe Naka',
    locality: 'Turbhe',
    category: 'Junction',
    coordinates: LatLng(19.0620, 73.0180),
    aliases: ['Turbhe Circle', 'Turbhe Naka Junction'],
  ),
  Landmark(
    id: 'turbhe-stn',
    name: 'Turbhe Railway Station',
    locality: 'Turbhe',
    category: 'Transit Hub',
    coordinates: LatLng(19.0736, 73.0125),
    aliases: ['Turbhe Station', 'Turbhe MIDC'],
  ),
  Landmark(
    id: 'juinagar-stn',
    name: 'Juinagar Railway Station',
    locality: 'Juinagar',
    category: 'Transit Hub',
    coordinates: LatLng(19.0556, 73.0182),
    aliases: ['Juinagar Station'],
  ),
  Landmark(
    id: 'nerul-stn',
    name: 'Nerul Railway Station',
    locality: 'Nerul',
    category: 'Transit Hub',
    coordinates: LatLng(19.0336, 73.0163),
    aliases: ['Nerul Station', 'Nerul LP'],
  ),
  Landmark(
    id: 'dy-patil-stadium',
    name: 'DY Patil Stadium',
    locality: 'Nerul',
    category: 'Landmark',
    coordinates: LatLng(19.0435, 73.0255),
    aliases: ['DY Patil Sports Stadium', 'Nerul Stadium'],
  ),
  Landmark(
    id: 'seawoods-stn',
    name: 'Seawoods–Darave Railway Station',
    locality: 'Seawoods',
    category: 'Transit Hub',
    coordinates: LatLng(19.0215, 73.0177),
    aliases: ['Seawoods Grand Central', 'Seawoods Station', 'Darave'],
  ),
  Landmark(
    id: 'belapur-stn',
    name: 'CBD Belapur Railway Station',
    locality: 'CBD Belapur',
    category: 'Transit Hub',
    coordinates: LatLng(19.0185, 73.0385),
    aliases: ['Belapur Station', 'CBD Belapur Stn', 'Belapur Local'],
  ),
  Landmark(
    id: 'belapur-cbd',
    name: 'Belapur CBD (Konkan Bhavan)',
    locality: 'CBD Belapur',
    category: 'Civic & Commercial',
    coordinates: LatLng(19.0178, 73.0416),
    aliases: ['Konkan Bhavan', 'Belapur Sector 11', 'CIDCO Bhavan'],
  ),
  Landmark(
    id: 'kharghar-stn',
    name: 'Kharghar Railway Station',
    locality: 'Kharghar',
    category: 'Transit Hub',
    coordinates: LatLng(19.0256, 73.0645),
    aliases: ['Kharghar Station', 'Hiranandani Kharghar Link'],
  ),
  Landmark(
    id: 'kharghar-utsav',
    name: 'Kharghar Utsav Chowk',
    locality: 'Kharghar',
    category: 'Landmark',
    coordinates: LatLng(19.0375, 73.0682),
    aliases: ['Utsav Chowk', 'Kharghar Circle', 'Shilp Chowk Vicinity'],
  ),
  Landmark(
    id: 'kopar-khairane-stn',
    name: 'Kopar Khairane Railway Station',
    locality: 'Kopar Khairane',
    category: 'Transit Hub',
    coordinates: LatLng(19.0968, 73.0094),
    aliases: ['Kopar Khairane Stn', 'Koparkhairane'],
  ),
  Landmark(
    id: 'ghansoli-stn',
    name: 'Ghansoli Railway Station',
    locality: 'Ghansoli',
    category: 'Transit Hub',
    coordinates: LatLng(19.1245, 73.0042),
    aliases: ['Ghansoli Station', 'Reliance Corporate Park Area'],
  ),
  Landmark(
    id: 'rabale-stn',
    name: 'Rabale Railway Station',
    locality: 'Rabale',
    category: 'Transit Hub',
    coordinates: LatLng(19.1386, 73.0028),
    aliases: ['Rabale Station', 'Rabale MIDC'],
  ),
  Landmark(
    id: 'airoli-stn',
    name: 'Airoli Railway Station',
    locality: 'Airoli',
    category: 'Transit Hub',
    coordinates: LatLng(19.1578, 72.9975),
    aliases: ['Airoli Station'],
  ),
  Landmark(
    id: 'airoli-toll',
    name: 'Airoli Bridge / Mulund Link',
    locality: 'Airoli',
    category: 'Highway Connection',
    coordinates: LatLng(19.1550, 72.9920),
    aliases: ['Airoli Toll', 'Airoli Creek Bridge', 'Mulund Airoli Link'],
  ),
];

/// Popular presets shown on empty search focus.
final List<Landmark> popularLandmarks = [
  naviMumbaiLandmarks[0], // Vashi Stn
  naviMumbaiLandmarks[11], // CBD Belapur Stn
  naviMumbaiLandmarks[13], // Kharghar Stn
  naviMumbaiLandmarks[18], // Airoli Stn
];

/// Curated landmark search with prefix prioritizing.
List<Landmark> searchCuratedLandmarks(String query, {int limit = 6}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final prefixMatches = <Landmark>[];
  final otherMatches = <Landmark>[];

  for (final landmark in naviMumbaiLandmarks) {
    final nameLower = landmark.name.toLowerCase();
    final localityLower = landmark.locality.toLowerCase();
    final categoryLower = landmark.category.toLowerCase();
    final aliasesJoined = landmark.aliases.map((a) => a.toLowerCase()).join(' ');
    final allSearchable = '$nameLower $localityLower $categoryLower $aliasesJoined';

    if (nameLower.startsWith(q) || localityLower.startsWith(q)) {
      prefixMatches.add(landmark);
    } else if (allSearchable.contains(q) ||
        (tokens.length > 1 && tokens.every((t) => allSearchable.contains(t)))) {
      otherMatches.add(landmark);
    }
  }

  return [...prefixMatches, ...otherMatches].take(limit).toList();
}

Landmark? getCuratedLandmarkById(String id) {
  try {
    return naviMumbaiLandmarks.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
}
