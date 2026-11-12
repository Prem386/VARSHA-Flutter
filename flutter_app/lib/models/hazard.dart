import 'package:latlong2/latlong.dart';

enum HazardSeverity {
  low,
  medium,
  high;

  static HazardSeverity fromString(String val) {
    switch (val.toLowerCase()) {
      case 'high':
        return HazardSeverity.high;
      case 'medium':
      case 'moderate':
        return HazardSeverity.medium;
      case 'low':
      default:
        return HazardSeverity.low;
    }
  }

  String get displayName {
    switch (this) {
      case HazardSeverity.high:
        return 'High';
      case HazardSeverity.medium:
        return 'Medium';
      case HazardSeverity.low:
        return 'Low';
    }
  }
}

enum HazardType {
  waterlogging,
  floodedUnderpass,
  submergedRoad,
  trafficObstruction;

  static HazardType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'flooded_underpass':
      case 'floodedunderpass':
        return HazardType.floodedUnderpass;
      case 'submerged_road':
      case 'submergedroad':
        return HazardType.submergedRoad;
      case 'traffic_obstruction':
      case 'trafficobstruction':
        return HazardType.trafficObstruction;
      case 'waterlogging':
      default:
        return HazardType.waterlogging;
    }
  }

  String get displayName {
    switch (this) {
      case HazardType.waterlogging:
        return 'Waterlogging';
      case HazardType.floodedUnderpass:
        return 'Flooded Underpass';
      case HazardType.submergedRoad:
        return 'Submerged Road';
      case HazardType.trafficObstruction:
        return 'Traffic Obstruction';
    }
  }
}

/// Simulated hazard location model representing monitored monsoon chokepoints.
class HazardLocation {
  final String id;
  final String name;
  final String area;
  final LatLng coordinates;
  final HazardType hazardType;
  final HazardSeverity severity;
  final String description;
  final bool isSimulated;

  const HazardLocation({
    required this.id,
    required this.name,
    required this.area,
    required this.coordinates,
    required this.hazardType,
    required this.severity,
    required this.description,
    this.isSimulated = true,
  });

  factory HazardLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return HazardLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      area: json['area'] as String,
      coordinates: LatLng(
        (coords[0] as num).toDouble(),
        (coords[1] as num).toDouble(),
      ),
      hazardType: HazardType.fromString(json['hazardType'] as String),
      severity: HazardSeverity.fromString(json['severity'] as String),
      description: json['description'] as String,
      isSimulated: json['isSimulated'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'area': area,
    'coordinates': [coordinates.latitude, coordinates.longitude],
    'hazardType': hazardType.name,
    'severity': severity.name,
    'description': description,
    'isSimulated': isSimulated,
  };
}

/// Curated baseline simulated hazards across Navi Mumbai.
/// Matches the original React hazardData.ts dataset exactly.
const List<HazardLocation> simulatedHazards = [
  HazardLocation(
    id: 'sim-haz-01',
    name: 'Illustrative Waterlogging Point A',
    area: 'Vashi Sector 17 Vicinity (Illustrative)',
    coordinates: LatLng(19.0760, 72.9985),
    hazardType: HazardType.waterlogging,
    severity: HazardSeverity.medium,
    description:
        'Simulated stormwater accumulation along curb lanes causing vehicular slowdown.',
    isSimulated: true,
  ),
  HazardLocation(
    id: 'sim-haz-02',
    name: 'Illustrative Flooded Underpass Scenario B',
    area: 'Airoli Transit Link (Illustrative)',
    coordinates: LatLng(19.1550, 72.9990),
    hazardType: HazardType.floodedUnderpass,
    severity: HazardSeverity.high,
    description:
        'Simulated severe water ingress in low-lying railway underpass; modeled as impassable.',
    isSimulated: true,
  ),
  HazardLocation(
    id: 'sim-haz-03',
    name: 'Illustrative Traffic Obstruction Point C',
    area: 'Turbhe Naka Junction (Illustrative)',
    coordinates: LatLng(19.0620, 73.0180),
    hazardType: HazardType.trafficObstruction,
    severity: HazardSeverity.low,
    description:
        'Simulated temporary lane obstruction caused by drainage runoff management.',
    isSimulated: true,
  ),
  HazardLocation(
    id: 'sim-haz-04',
    name: 'Illustrative Waterlogging Point D',
    area: 'Nerul Palm Beach Vicinity (Illustrative)',
    coordinates: LatLng(19.0320, 73.0180),
    hazardType: HazardType.waterlogging,
    severity: HazardSeverity.high,
    description:
        'Simulated high-tide tidal backflow inundating outer lanes during heavy downpour.',
    isSimulated: true,
  ),
  HazardLocation(
    id: 'sim-haz-05',
    name: 'Illustrative Submerged Road Scenario E',
    area: 'CBD Belapur Creek Approach (Illustrative)',
    coordinates: LatLng(19.0180, 73.0420),
    hazardType: HazardType.submergedRoad,
    severity: HazardSeverity.medium,
    description:
        'Simulated standing water across carriageway with reduced traction.',
    isSimulated: true,
  ),
];
