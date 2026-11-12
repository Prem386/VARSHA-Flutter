import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import '../../models/scenario.dart';
import '../scenarios/scenario_selector.dart';
import 'place_search_field.dart';
import 'route_comparison_view.dart';

class RoutePlannerSheet extends StatelessWidget {
  final SelectedLocation? origin;
  final SelectedLocation? destination;
  final RouteEndpointType activeTarget;
  final ValueChanged<RouteEndpointType> onSelectTarget;
  final ValueChanged<SelectedLocation> onSelectOrigin;
  final ValueChanged<SelectedLocation> onSelectDestination;
  final VoidCallback onSwap;
  final ValueChanged<RouteEndpointType> onClear;
  final bool isIdentical;
  final List<RoadRoute> routes;
  final String? selectedRouteId;
  final ValueChanged<String> onSelectRoute;
  final RouteStatus routeStatus;
  final String? routeError;
  final VoidCallback onPlanRoute;
  final VoidCallback onClearRoute;
  final Map<String, RouteRiskAssessment>? riskAssessments;
  final DemoScenarioId selectedScenarioId;
  final ValueChanged<DemoScenarioId> onSelectScenario;
  final ScrollController? scrollController;

  const RoutePlannerSheet({
    super.key,
    required this.origin,
    required this.destination,
    required this.activeTarget,
    required this.onSelectTarget,
    required this.onSelectOrigin,
    required this.onSelectDestination,
    required this.onSwap,
    required this.onClear,
    required this.isIdentical,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
    required this.routeStatus,
    required this.routeError,
    required this.onPlanRoute,
    required this.onClearRoute,
    this.riskAssessments,
    required this.selectedScenarioId,
    required this.onSelectScenario,
    this.scrollController,
  });

  bool get _canPlanRoute =>
      origin != null && destination != null && !isIdentical;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
      children: [
        // Section Heading
        Row(
          children: [
            Container(
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Plan your route',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Search a landmark or tap "Pick on map".',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 12),

        // Origin Field
        PlaceSearchField(
          endpointType: RouteEndpointType.origin,
          label: 'Origin',
          tagLetter: 'A',
          placeholder: 'Search landmark or click map (e.g. Vashi Station)',
          value: origin,
          onSelect: onSelectOrigin,
          onClear: () => onClear(RouteEndpointType.origin),
          isActiveTarget: activeTarget == RouteEndpointType.origin,
          onActivateTarget: () => onSelectTarget(RouteEndpointType.origin),
        ),

        // Swap Endpoints Button
        Center(
          child: InkWell(
            onTap: (origin != null || destination != null) ? onSwap : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderInteractive),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert, size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 4),
                  Text(
                    'Swap',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Destination Field
        PlaceSearchField(
          endpointType: RouteEndpointType.destination,
          label: 'Destination',
          tagLetter: 'B',
          placeholder: 'Where to? (e.g. Belapur CBD)',
          value: destination,
          onSelect: onSelectDestination,
          onClear: () => onClear(RouteEndpointType.destination),
          isActiveTarget: activeTarget == RouteEndpointType.destination,
          onActivateTarget: () => onSelectTarget(RouteEndpointType.destination),
        ),

        // Validation Error if Identical
        if (isIdentical)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.riskHigh.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.riskHigh.withAlpha(77)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: AppColors.riskHigh),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Origin and destination cannot be the same location. Please choose distinct coordinates.',
                    style: TextStyle(fontSize: 11, color: AppColors.riskHigh),
                  ),
                ),
              ],
            ),
          ),

        // Loading State
        if (routeStatus == RouteStatus.loading)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Querying public OSRM routing service for driving road geometry...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

        // Error State with Retry
        if (routeStatus == RouteStatus.error && routeError != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.riskHigh.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.riskHigh.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.riskHigh),
                    const SizedBox(width: 8),
                    const Text(
                      'Route retrieval failed:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.riskHigh),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  routeError!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _canPlanRoute ? onPlanRoute : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Retry Request', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),

        // Route Comparison View (when success)
        if (routeStatus == RouteStatus.success && routes.isNotEmpty)
          RouteComparisonView(
            routes: routes,
            selectedRouteId: selectedRouteId,
            onSelectRoute: onSelectRoute,
            onClearRoute: onClearRoute,
            riskAssessments: riskAssessments,
          ),

        // Empty State: Popular Route Presets
        if (routes.isEmpty && routeStatus == RouteStatus.idle) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: AppColors.amberText),
                    SizedBox(width: 8),
                    Text(
                      'Your route comparison will appear here.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Popular routes in Navi Mumbai:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Vashi → Belapur', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        onSelectOrigin(
                          const SelectedLocation(
                            label: 'Vashi Station',
                            coordinates: LatLng(19.0645, 72.9983),
                            source: 'curated',
                          ),
                        );
                        onSelectDestination(
                          const SelectedLocation(
                            label: 'CBD Belapur Station',
                            coordinates: LatLng(19.0185, 73.0385),
                            source: 'curated',
                          ),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('Airoli → Kharghar', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        onSelectOrigin(
                          const SelectedLocation(
                            label: 'Airoli Station',
                            coordinates: LatLng(19.1553, 72.9986),
                            source: 'curated',
                          ),
                        );
                        onSelectDestination(
                          const SelectedLocation(
                            label: 'Kharghar Station',
                            coordinates: LatLng(19.0435, 73.0683),
                            source: 'curated',
                          ),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('Nerul → Seawoods', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        onSelectOrigin(
                          const SelectedLocation(
                            label: 'Nerul Station',
                            coordinates: LatLng(19.0330, 73.0185),
                            source: 'curated',
                          ),
                        );
                        onSelectDestination(
                          const SelectedLocation(
                            label: 'Seawoods Grand Central',
                            coordinates: LatLng(19.0223, 73.0175),
                            source: 'curated',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Demo Mode Accordion
        Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              children: [
                const Text(
                  'Demo mode',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                if (selectedScenarioId != DemoScenarioId.baseline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberLight.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Demo Active',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.amberText),
                    ),
                  ),
              ],
            ),
            children: [
              ScenarioSelector(
                selectedScenarioId: selectedScenarioId,
                onSelectScenario: onSelectScenario,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Route Planning CTA Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_canPlanRoute && routeStatus != RouteStatus.loading)
                ? onPlanRoute
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (routeStatus == RouteStatus.loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    ),
                  )
                else
                  Text(
                    routeStatus == RouteStatus.success
                        ? 'Recalculate Routes'
                        : 'Plan Driving Routes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    routes.isNotEmpty ? '${routes.length} Options' : 'OSRM',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Status text caption
        Text(
          routeStatus == RouteStatus.loading
              ? 'Requesting road route alternatives from OSRM...'
              : routeStatus == RouteStatus.success
                  ? (routes.length > 1
                      ? '✓ ${routes.length} distinct road route candidates available for safety comparison.'
                      : '✓ 1 road route retrieved.')
                  : _canPlanRoute
                      ? '✓ Endpoints ready. Tap "Plan Driving Routes" to calculate path.'
                      : 'Select an origin and destination on the map to calculate a route.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: _canPlanRoute ? AppColors.riskNone : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
