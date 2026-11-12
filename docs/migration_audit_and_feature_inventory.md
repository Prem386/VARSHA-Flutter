# VARSHA: React to Flutter Migration Audit & Feature Inventory

## 1. Executive Summary

This document records the exhaustive audit of the original React + TypeScript frontend (`C:\Users\Prem\Desktop\VARSHA\frontend`) and defines the feature-by-feature implementation map in the Flutter + Dart mobile application (`flutter_app/`).

The original hackathon repository was kept 100% untouched.
The FastAPI backend (`backend/`) was kept 100% untouched and verified against all 159 pytest unit tests.

---

## 2. Frontend Source Audit (`VARSHA/frontend/`)

### 2.1 Dependencies & Technology Stack
* **Framework**: React 18 with TypeScript (`package.json`)
* **Styling**: Tailwind CSS with custom neumorphic tokens (`#EFEFF2` surface, `#ECECEF` background, `#2B2B30` text primary, `#F5A623` amber accent)
* **Icons**: Lucide React
* **Maps**: Leaflet + React-Leaflet with OpenStreetMap raster tiles
* **Geocoding & Autocomplete**: Geoapify forward geocoding API proxied through backend `/api/v1/places/search`
* **Routing**: OSRM (Open Source Routing Machine) public driving demo server (`https://router.project-osrm.org`)
* **Weather & Alerts**: Custom FastAPI backend endpoints (`/api/v1/rainfall`, `/api/v1/alerts`)
* **Firebase**: Optional Firebase Auth / Analytics scaffolded in package.json but not integrated into core MVP views.

### 2.2 Component & Hook Inventory
| React Source File | Purpose | Flutter Migration Target |
| :--- | :--- | :--- |
| `src/components/StatusStrip.tsx` | Header bar showing app title, pilot badge, live rain summary, alert counter, settings and about triggers. | `lib/features/shell/top_status_strip.dart` |
| `src/components/PersistentDisclaimer.tsx` | Fixed bottom advisory strip emphasizing Navi Mumbai pilot and simulated data notice. | `lib/features/shell/persistent_disclaimer.dart` |
| `src/components/AboutDrawer.tsx` | Slide-over drawer explaining pilot scope, simulated flood points, and risk calculation methodology. | `lib/features/shell/about_sheet.dart` |
| `src/components/WeatherModal.tsx` | Modal dialog displaying NWP rainfall forecast (6-hr cards, 24-hr metrics) and NDMA SACHET disaster warnings. | `lib/features/weather/weather_alerts_sheet.dart` |
| `src/components/ScenarioControls.tsx` | Choice chip buttons allowing quick switching between simulated weather/hazard states. | `lib/features/scenarios/scenario_selector.dart` |
| `src/components/RoutePlanner.tsx` | Form inputs for Origin/Destination, landmark presets, map-picking toggle, and find routes button. | `lib/features/routing/route_planner_sheet.dart` |
| `src/components/RouteCard.tsx` | Comparison card for route alternatives with distance, duration, risk category, and trade-off badges. | `lib/features/routing/route_comparison_view.dart` |
| `src/components/RiskScoreGauge.tsx` | Radial gauge / badge showing 0–100 risk score and itemized list of hazards contributing to route risk. | `lib/features/routing/route_risk_card.dart` |
| `src/components/Map.tsx` | Leaflet map container handling tile layer, panning, marker overlays, polyline rendering, and tap listeners. | `lib/features/map/map_screen.dart` |
| `src/components/HazardMarkers.tsx` | Visual markers for flood points with severity-coded colors and popup details. | `lib/features/map/hazard_markers_layer.dart` |
| `src/components/RoutePolyline.tsx` | Leaflet polylines for active route (solid blue) and alternative routes (dashed slate). | `lib/features/map/route_polyline_layer.dart` |
| `src/components/MapLegend.tsx` | Floating collapsible legend explaining hazard pins, route lines, and safety categories. | `lib/features/map/map_legend.dart` |
| `src/services/routing/hazardProximity.ts` | Equirectangular distance calculation from route polyline segments to hazard coordinates. | `lib/services/routing/hazard_proximity.dart` |
| `src/services/routing/routeRiskScoring.ts` | Explainable risk algorithm applying severity weights and distance multipliers (1.0, 0.75, 0.5). | `lib/services/routing/route_risk_scoring.dart` |
| `src/services/routing/corridors.ts` | Parallel corridor waypoint injection (Vashi-Belapur Palm Beach Rd, Airoli-Vashi West Bypass). | `lib/services/routing/corridors.dart` |
| `src/services/routing/osrmService.ts` | OSRM driving API caller with candidate deduplication and waypoint fallback. | `lib/services/routing/osrm_service.dart` |
| `src/services/api/placesService.ts` | Forward geocoding client with 20 curated Navi Mumbai landmarks fallback. | `lib/services/places/places_service.dart` |
| `src/services/api/weatherService.ts` | Client for `/api/v1/rainfall` (5-min cache) and `/api/v1/alerts`. | `lib/services/weather/weather_service.dart` |

---

## 3. Backend API Contract Inventory (`backend/app/`)

### 3.1 Health Check (`/api/v1/health`)
* **Method**: `GET`
* **Response**: `{"status": "healthy", "service": "varsha-backend", "version": "1.0.0"}`
* **Flutter Integration**: Pinged directly in `SettingsSheet` to verify connectivity between device/emulator and backend.

### 3.2 Weather & Rainfall (`/api/v1/rainfall`)
* **Method**: `GET`
* **Query Params**: `lat` (float), `lon` (float)
* **Response Schema**:
  * `current`: `{"precipitation_mm": float, "condition": string, "temperature_c": float, ...}`
  * `forecast`: array of `{"timestamp": ISO8601, "precipitation_mm": float, "risk_category": string}`
  * `summary_24h`: `{"total_precipitation_mm": float, "max_hourly_rate_mm": float, ...}`
  * `provider_status`: status and latency
* **Flutter Integration**: Parsed into `RainfallResponse`, cached in-memory for 5 minutes with in-flight deduplication in `WeatherService`.

### 3.3 NDMA SACHET Disaster Alerts (`/api/v1/alerts`)
* **Method**: `GET`
* **Query Params**: `lat` (float), `lon` (float)
* **Response Schema**:
  * `alerts`: array of `{"id": string, "identifier": string, "severity": string, "headline": string, "description": string, "instruction": string, "area_description": string, ...}`
  * `provider_status`: operational metadata
* **Flutter Integration**: Parsed into `AlertListResponse`, displayed with warning badges and expandable instructions in `WeatherAlertsSheet`.

### 3.4 Forward Geocoding & Landmarks (`/api/v1/places/search`)
* **Method**: `GET`
* **Query Params**: `query` (string), `focus_lat` (float), `focus_lon` (float)
* **Response Schema**:
  * `results`: array of `{"name": string, "formatted_address": string, "lat": float, "lon": float, "confidence": float, "source": string}`
* **Flutter Integration**: Consumed by `PlacesService`. When offline or if query fails, automatically falls back to searching 20 curated Navi Mumbai landmarks (Vashi Station, Belapur CBD, Palm Beach Road, Kharghar, Nerul, etc.).

---

## 4. Algorithmic Equivalence Verification

### 4.1 Hazard Proximity Calculation
* **Equirectangular Projection**:
  $$\Delta x = (\text{lon}_2 - \text{lon}_1) \cdot \frac{\pi}{180} \cdot R \cdot \cos\left(\frac{\text{lat}_1 + \text{lat}_2}{2} \cdot \frac{\pi}{180}\right)$$
  $$\Delta y = (\text{lat}_2 - \text{lat}_1) \cdot \frac{\pi}{180} \cdot R$$
  with $R = 6,371,000\text{ m}$.
* **Segment Projection**:
  Projection scalar $t = \frac{\mathbf{AP} \cdot \mathbf{AB}}{\|\mathbf{AB}\|^2}$ clamped to $[0, 1]$.
* **Threshold**:
  Default threshold is $100.0\text{ m}$ (inclusive: $d \le 100.0$).

### 4.2 Route Risk Scoring Formula
* **Severity Base Weights**:
  * `low`: 10
  * `medium`: 20
  * `high`: 35
* **Stepped Proximity Multipliers**:
  * $d \le 25\text{ m} \implies 1.0$
  * $25\text{ m} < d \le 50\text{ m} \implies 0.75$
  * $50\text{ m} < d \le 100\text{ m} \implies 0.5$
  * $d > 100\text{ m} \implies 0.0$
* **Aggregation**:
  * Individual hazard contribution: $C_i = W_i \times M_i$.
  * Total risk score: $S = \min\left(100, \left\lfloor \sum C_i \right\rceil\right)$.
  * Risk Categories:
    * `0–24`: Low (Green)
    * `25–49`: Moderate (Amber)
    * `50–74`: High (Orange)
    * `75–100`: Severe (Red)

### 4.3 Corridor Injection & Alternatives
* If OSRM returns only 1 route candidate, the app matches start/end against known arterial corridors:
  * **Vashi to Belapur Corridor**: Injects Palm Beach Road waypoint (`19.0410, 73.0135`).
  * **Airoli to Vashi Corridor**: Injects Kopar Khairane West Bypass waypoint (`19.1025, 73.0035`).
* Distinct candidate threshold:
  Route alternatives are retained only if $\Delta\text{distance} > 250\text{ m}$, $\Delta\text{duration} > 45\text{ s}$, or polyline midpoint separation $> 75\text{ m}$.
