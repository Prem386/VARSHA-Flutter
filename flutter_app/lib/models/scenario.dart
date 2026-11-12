import 'package:latlong2/latlong.dart';
import 'hazard.dart';

enum DemoScenarioId {
  baseline('baseline', 'Baseline'),
  floodHighway('flood-highway', 'Flood on Highway'),
  floodWestBypass('flood-west-bypass', 'Flood on West Bypass'),
  allClear('all-clear', 'All Clear');

  final String id;
  final String shortLabel;
  const DemoScenarioId(this.id, this.shortLabel);

  static DemoScenarioId fromString(String val) {
    switch (val) {
      case 'flood-highway':
        return DemoScenarioId.floodHighway;
      case 'flood-west-bypass':
        return DemoScenarioId.floodWestBypass;
      case 'all-clear':
        return DemoScenarioId.allClear;
      case 'baseline':
      default:
        return DemoScenarioId.baseline;
    }
  }
}

class DemoScenario {
  final DemoScenarioId id;
  final String name;
  final String shortLabel;
  final String description;
  final String? notice;
  final List<HazardLocation> hazards;
  final bool isSynthetic;

  const DemoScenario({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    this.notice,
    required this.hazards,
    required this.isSynthetic,
  });
}

const String syntheticScenarioNotice =
    'DEMO SCENARIO ACTIVE — SYNTHETIC HAZARDS, NOT LIVE CONDITIONS';

const String allClearExplanation =
    'Empty demo dataset showing 0 simulated hazards. This does NOT represent '
    'verified road safety or the absence of real-world monsoon hazards.';

/// High-severity hazard directly along Sion-Panvel Highway in Turbhe/Sanpada section.
const HazardLocation simulatedHighwayFloodHazard = HazardLocation(
  id: 'sim-scenario-hwy-flood',
  name: 'Simulated Inundation — Sion-Panvel Highway',
  area: 'Turbhe / Sanpada Highway Section (Demo Scenario)',
  coordinates: LatLng(19.0597, 73.0193),
  hazardType: HazardType.submergedRoad,
  severity: HazardSeverity.high,
  description:
      'Simulated high-severity highway carriageway submergence modeled to demonstrate '
      'differential risk scoring along the Sion-Panvel arterial corridor.',
  isSimulated: true,
);

/// High-severity hazard directly along Thane-Belapur Road in Mahape/Kopar Khairane section.
const HazardLocation simulatedWestBypassCorridorHazard = HazardLocation(
  id: 'sim-scenario-tb-flood',
  name: 'Simulated Flooded Underpass — Thane-Belapur Road',
  area: 'Mahape / Kopar Khairane Arterial (Demo Scenario)',
  coordinates: LatLng(19.0922, 73.0176),
  hazardType: HazardType.floodedUnderpass,
  severity: HazardSeverity.high,
  description:
      'Simulated high-severity underpass inundation along Thane-Belapur Road modeled '
      'to demonstrate West Bypass as a lower-risk alternative during an Airoli–Vashi journey.',
  isSimulated: true,
);

final Map<DemoScenarioId, DemoScenario> demoScenarios = {
  DemoScenarioId.baseline: const DemoScenario(
    id: DemoScenarioId.baseline,
    name: 'Baseline Simulated Hazards',
    shortLabel: 'Baseline',
    description: 'Standard prototype simulated hazards across Navi Mumbai transit nodes.',
    hazards: simulatedHazards,
    isSynthetic: false,
  ),
  DemoScenarioId.floodHighway: const DemoScenario(
    id: DemoScenarioId.floodHighway,
    name: 'Flood on Highway',
    shortLabel: 'Flood on Highway',
    description:
        'Simulated flood on Sion-Panvel Highway (Vashi–Belapur journey), '
        'demonstrating Palm Beach Road as a lower-risk alternative.',
    notice:
        '$syntheticScenarioNotice. Simulated high-severity submergence placed on Sion-Panvel Highway corridor.',
    hazards: [simulatedHighwayFloodHazard],
    isSynthetic: true,
  ),
  DemoScenarioId.floodWestBypass: const DemoScenario(
    id: DemoScenarioId.floodWestBypass,
    name: 'Flood on West Bypass',
    shortLabel: 'Flood on West Bypass',
    description:
        'Simulated flood affecting Thane-Belapur Road route during an Airoli–Vashi journey, '
        'demonstrating West Bypass as a lower-risk alternative.',
    notice:
        '$syntheticScenarioNotice. Simulated high-severity underpass flood affecting Thane-Belapur Road route.',
    hazards: [simulatedWestBypassCorridorHazard],
    isSynthetic: true,
  ),
  DemoScenarioId.allClear: const DemoScenario(
    id: DemoScenarioId.allClear,
    name: 'All Clear',
    shortLabel: 'All Clear',
    description:
        'Empty hazard dataset showing zero nearby simulated hazards for baseline validation.',
    notice: '$syntheticScenarioNotice. $allClearExplanation',
    hazards: [],
    isSynthetic: true,
  ),
};

DemoScenario getDemoScenario(DemoScenarioId id) {
  return demoScenarios[id] ?? demoScenarios[DemoScenarioId.baseline]!;
}

List<DemoScenario> getAllDemoScenarios() {
  return [
    demoScenarios[DemoScenarioId.baseline]!,
    demoScenarios[DemoScenarioId.floodHighway]!,
    demoScenarios[DemoScenarioId.floodWestBypass]!,
    demoScenarios[DemoScenarioId.allClear]!,
  ];
}
