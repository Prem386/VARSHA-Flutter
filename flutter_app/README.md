# VARSHA Mobile (Flutter + Dart)

Monsoon risk monitoring and safe route assistance mobile application for Navi Mumbai, built with Flutter and Dart, connecting to the FastAPI backend.

---

## 1. Architecture & Directory Structure

```text
flutter_app/lib/
│
├── main.dart                       # App entrypoint (initializes SharedPreferences & AppConfig)
│
├── app/
│   ├── app.dart                    # VarshaApp MaterialApp configuration & global theme
│   └── routes.dart                 # Named route constants (/map, /settings)
│
├── core/
│   ├── config/
│   │   └── app_config.dart         # Dynamic API Base URL & OSRM URL with runtime persistence
│   ├── constants/
│   │   ├── app_colors.dart         # Neumorphic palette (#EFEFF2, #ECECEF, #2B2B30, #F5A623)
│   │   └── pilot_constants.dart    # Navi Mumbai bbox, center coordinates, pilot disclaimers
│   ├── errors/
│   │   └── app_exceptions.dart     # Typed domain exceptions (Weather, Places, Routing, Location)
│   └── theme/
│       └── app_theme.dart          # Material 3 theme data, input styles, chips, and typography
│
├── models/
│   ├── hazard.dart                 # HazardSeverity, HazardType, HazardLocation, Points A–E
│   ├── scenario.dart               # DemoScenarioId, 4 interactive scenarios (Baseline, Floods, Clear)
│   ├── place.dart                  # PlaceSuggestion, Geoapify DTO, 20 curated Navi Mumbai landmarks
│   ├── route.dart                  # SelectedLocation, RoadRoute, RouteStatus, distance/duration formatters
│   ├── risk_assessment.dart        # HazardProximityResult, RouteRiskAssessment, category (0-100)
│   ├── weather.dart                # RainfallResponse, NWP precipitation step, 6-hr forecast filter
│   └── alert.dart                  # AlertListResponse, NormalizedAlert, NDMA SACHET schemas
│
├── services/
│   ├── api/                        # HTTP client wrappers
│   ├── location/
│   │   └── location_service.dart   # Geolocator GPS wrapper with runtime permission checks
│   ├── places/
│   │   └── places_service.dart     # /api/v1/places/search with fallback to curated landmarks
│   ├── routing/
│   │   ├── corridors.dart          # Vashi-Belapur & Airoli-Vashi parallel route injectors
│   │   ├── hazard_proximity.dart   # Metric equirectangular point-to-segment distance engine
│   │   ├── osrm_service.dart       # OSRM driving engine with route alternatives & corridor logic
│   │   └── route_risk_scoring.dart # 0-100 risk score engine with stepped proximity multipliers
│   └── weather/
│       └── weather_service.dart    # /api/v1/rainfall (with 5-min cache) & /api/v1/alerts
│
└── features/
    ├── map/
    │   ├── endpoint_markers_layer.dart  # Visual 'A' (Origin) and 'B' (Destination) pin markers
    │   ├── hazard_markers_layer.dart    # Severity-colored water drop pins & tap inspection sheets
    │   ├── map_legend.dart              # Collapsible visual legend for map elements
    │   ├── map_screen.dart              # Interactive FlutterMap with DraggableScrollableSheet
    │   └── route_polyline_layer.dart    # Selected (blue) and alternative (slate dashed) polylines
    ├── routing/
    │   ├── place_search_field.dart      # Autocomplete search card with 'Pick on Map' toggle
    │   ├── route_comparison_view.dart   # Route candidate cards with trade-off badges (Safer, Fastest)
    │   ├── route_planner_sheet.dart     # Origin/Destination inputs, quick presets, search CTA
    │   └── route_risk_card.dart         # Explainable risk gauge with contributing hazards breakdown
    ├── scenarios/
    │   └── scenario_selector.dart       # Interactive scenario choice chips with simulated warnings
    ├── settings/
    │   └── settings_sheet.dart          # Base URL configuration modal with live /health ping test
    ├── shell/
    │   ├── about_sheet.dart             # About VARSHA modal with expandable pilot & methodology accordions
    │   ├── persistent_disclaimer.dart   # 40px persistent footer disclaimer with 'Learn more' link
    │   └── top_status_strip.dart        # Wordmark, pilot badge, live weather summary, alert count badge
    └── weather/
        └── weather_alerts_sheet.dart    # NWP 6-hour forecast carousel & NDMA SACHET disaster alerts
```

---

## 2. React to Flutter Component Mapping

| Original React Component (`frontend/src/`) | New Flutter Component (`flutter_app/lib/`) | Purpose |
| :--- | :--- | :--- |
| `components/StatusStrip.tsx` | `features/shell/top_status_strip.dart` | Header bar: brand wordmark, live rain summary, alert badge, action triggers |
| `components/PersistentDisclaimer.tsx` | `features/shell/persistent_disclaimer.dart` | Persistent advisory bar anchored at bottom |
| `components/AboutDrawer.tsx` | `features/shell/about_sheet.dart` | Modal sheet explaining Navi Mumbai pilot, simulation, and scoring |
| `components/WeatherModal.tsx` | `features/weather/weather_alerts_sheet.dart` | Sheet with 6-hr NWP rain forecast and SACHET alerts |
| `components/ScenarioControls.tsx` | `features/scenarios/scenario_selector.dart` | Choice chips switching simulated hazard sets |
| `components/RoutePlanner.tsx` | `features/routing/route_planner_sheet.dart` | Route planning bottom sheet with quick presets |
| `components/RouteCard.tsx` | `features/routing/route_comparison_view.dart` | Candidate cards with distance, duration, risk tags |
| `components/RiskScoreGauge.tsx` | `features/routing/route_risk_card.dart` | 0–100 risk score meter with explainable hazards |
| `components/Map.tsx` | `features/map/map_screen.dart` | Interactive map screen coordinating layers and sheets |
| `components/HazardMarkers.tsx` | `features/map/hazard_markers_layer.dart` | Color-coded severity markers with detail sheet |
| `components/RoutePolyline.tsx` | `features/map/route_polyline_layer.dart` | Selected route & alternative route polylines |
| `components/MapLegend.tsx` | `features/map/map_legend.dart` | Floating legend for hazards and routes |
| `services/routing/hazardProximity.ts` | `services/routing/hazard_proximity.dart` | Metric distance calculation engine |
| `services/routing/routeRiskScoring.ts` | `services/routing/route_risk_scoring.dart` | Stepped proximity weighting (1.0, 0.75, 0.5) |
| `services/routing/corridors.ts` | `services/routing/corridors.dart` | Vashi-Belapur & Airoli-Vashi alternative injections |
| `services/routing/osrmService.ts` | `services/routing/osrm_service.dart` | OSRM driving API caller with fallback logic |
| `services/api/placesService.ts` | `services/places/places_service.dart` | Geocoding service with curated fallback |
| `services/api/weatherService.ts` | `services/weather/weather_service.dart` | Ingestion of `/api/v1/rainfall` & `/api/v1/alerts` |

---

## 3. Backend API Base URL Configuration

The application supports multiple environments out of the box without code modifications:

### A. Android Emulator
Android emulators run on an isolated virtual network where `10.0.2.2` routes to host `localhost`.
- **Default Base URL**: `http://10.0.2.2:8000`

### B. Physical Android / iOS Device
Physical devices connected over the same Wi-Fi network cannot resolve `localhost`.
- Connect your phone and PC to the same Wi-Fi network.
- Find your PC's local IP address (e.g. `ipconfig` on Windows, look for `IPv4 Address`: `192.168.1.50`).
- **Base URL**: `http://192.168.1.50:8000`

### C. Desktop (Windows / macOS / Linux)
Desktop targets run directly on the host machine.
- **Base URL**: `http://127.0.0.1:8000`

### D. Production Deployment
Set your hosted backend URL:
- **Base URL**: `https://api.varsha.example.com`

### Runtime & Build-Time Configuration:
1. **In-App Settings Sheet**: Tap the Settings gear icon in the top header. You can edit the Base URL or click one-tap presets ("Android Emulator", "Localhost", "LAN Host") and test the connection with the "Test Connection" button (`/api/v1/health`). Settings are persisted via `SharedPreferences`.
2. **Build-Time Flag**: You can also supply the URL at compile time:
   ```bash
   flutter run --dart-define=VARSHA_API_URL=http://10.0.2.2:8000
   ```

---

## 4. Running the Project

### Prerequisites
- Flutter SDK (3.24.0 or later)
- Dart SDK (3.5.0 or later)
- Android Studio / Android SDK (for Android build)
- Python 3.11+ (for backend)

### Starting the Backend
From project root:
```bash
cd backend
.venv\Scripts\activate   # Windows
# or: source .venv/bin/activate (Linux/Mac)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Running Flutter App
From `flutter_app/`:
```bash
flutter pub get
flutter run
```

### Running Tests and Static Analysis
```bash
flutter analyze
flutter test
```

---

## 5. Guide for Java Developers Learning Flutter & Dart

If you have a Java background, here is how Dart and Flutter concepts map to what you already know:

### 1. Object-Oriented Syntax
- **Classes & Inheritance**: Dart classes use `class Foo extends Bar implements Baz`. Dart does not have an `interface` keyword; every class implicitly defines an interface.
- **Constructors**: Dart uses concise parameter assignment: `MyClass({required this.name, this.age = 0});` directly initializes fields without boilerplate `this.name = name;` assignment bodies.
- **Null Safety**: Types are non-nullable by default (`String` cannot be null). Append `?` for nullable types (`String?`), identical to Kotlin or Java with `@Nullable`.

### 2. Async Programming: `Future` vs Java `CompletableFuture`
- In Java: `CompletableFuture.supplyAsync(() -> fetch()).thenApply(...)`
- In Dart: `async` / `await` syntax operates identically to modern asynchronous patterns:
  ```dart
  Future<RainfallResponse> fetchRainfall() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/rainfall'));
    if (response.statusCode == 200) {
      return RainfallResponse.fromJson(jsonDecode(response.body));
    }
    throw WeatherApiException('Failed to load rainfall');
  }
  ```

### 3. Declarative UI vs Imperative UI (Swing / Android XML)
- In Java Swing or traditional Android Views, you create UI objects once and mutate them imperatively (`textView.setText("Hello")`).
- In Flutter, UI is **declarative**: `UI = f(State)`.
- When state changes, you call `setState(() { ... })`, and Flutter re-runs the `build(BuildContext context)` method to describe what the screen should look like now. Flutter's lightweight virtual element tree efficiently recalculates only the changed parts.

### 4. `StatelessWidget` vs `StatefulWidget`
- **`StatelessWidget`**: Immutable component whose display depends entirely on constructor arguments (e.g. `RouteRiskCard`, `PersistentDisclaimer`).
- **`StatefulWidget`**: Component that owns internal mutable state that can change over time (e.g. `MapScreen`, `RoutePlannerSheet`).

### 5. `BuildContext`
- Analogous to Android's `Context` or a tree locator in Java UI frameworks. It represents the widget's location in the global element hierarchy and is used to look up themes, media queries (screen size), and navigation routes:
  ```dart
  final theme = Theme.of(context);
  final screenSize = MediaQuery.of(context).size;
  ```
