import 'package:latlong2/latlong.dart';

/// Pilot area constants for Navi Mumbai.
class PilotConstants {
  PilotConstants._();

  static const String pilotAreaName = 'Navi Mumbai';
  static const String pilotLabel = 'Pilot: Navi Mumbai';

  // Geographic center
  static const LatLng naviMumbaiCenter = LatLng(19.0330, 73.0297);
  static const double defaultZoom = 12.0;

  // Pilot region geographic bounding box (matches FastAPI grid)
  static const double minLat = 18.95;
  static const double maxLat = 19.20;
  static const double minLon = 72.95;
  static const double maxLon = 73.15;

  // OpenStreetMap tile layer parameters
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'varsha_flutter_app/1.0.0 (https://github.com)';
  static const String osmAttribution = '© OpenStreetMap contributors';

  // Prototype Disclaimers
  static const String disclaimerShort =
      'Simulated data prototype • Navi Mumbai pilot • Not for emergency navigation';
  static const String disclaimerFull =
      'All hazard locations, risk scores, and route assessments in this prototype are '
      'simulated for technical testing and civic validation. VARSHA does not claim '
      'real-time flood accuracy or guarantee road safety.';
  static const String osrmEstimateNotice =
      'Duration is an estimate from the routing engine and does not reflect live traffic or monsoon hazard delays.';
}
