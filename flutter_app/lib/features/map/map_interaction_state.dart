/// Mutually exclusive interaction states for the Google Maps-inspired navigation flow.
enum MapInteractionState {
  /// State A: Clean map dominance with compact floating search header.
  initial,

  /// State B: Dedicated destination search mode with anchored autocomplete overlay.
  searchingDestination,

  /// State C: Destination resolved; active origin search with anchored autocomplete overlay.
  searchingOrigin,

  /// State 3: Explicit map-picking mode with crosshair and confirmation card.
  pickingOnMap,

  /// State C2: Both endpoints resolved, compact summary card ready for route planning.
  endpointsReady,

  /// State D1: Querying OSRM road routes from backend.
  routesLoading,

  /// State D2 / E: Routes calculated; horizontal route bubbles and compact bottom summary active.
  routesCalculated,

  /// State F: Bottom route sheet expanded to inspect detailed risk breakdown and scenarios.
  expandedDetails,

  /// State G: Contextual hazard card active over map without destroying route state.
  hazardInspection,
}

