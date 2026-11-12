import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/risk_assessment.dart';
import '../../models/route.dart';
import '../../models/scenario.dart';
import '../scenarios/scenario_selector.dart';
import 'route_comparison_view.dart';

/// Expandable and collapsible route-planning card.
/// In collapsed state, displays a compact 75–95px summary / CTA.
/// In expanded state, provides corridor presets, scenario selection, and detailed route comparisons.
class RoutePlannerSheet extends StatelessWidget {
  final SelectedLocation? origin;
  final SelectedLocation? destination;
  final RouteEndpointType? activeTarget;
  final ValueChanged<RouteEndpointType>? onSelectTarget;
  final ValueChanged<SelectedLocation> onSelectOrigin;
  final ValueChanged<SelectedLocation> onSelectDestination;
  final VoidCallback? onSwap;
  final ValueChanged<RouteEndpointType>? onClear;
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
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const RoutePlannerSheet({
    super.key,
    required this.origin,
    required this.destination,
    this.activeTarget,
    this.onSelectTarget,
    required this.onSelectOrigin,
    required this.onSelectDestination,
    this.onSwap,
    this.onClear,
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
    this.isExpanded = true,
    this.onToggleExpand,
  });

  bool get _canPlanRoute =>
      origin != null && destination != null && !isIdentical;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isExpanded) ...[
          // Header Row with collapse action
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      routes.isNotEmpty ? 'Route options' : 'Plan your route',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Collapse planner',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onToggleExpand,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
        ],
        Expanded(
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: isExpanded ? 16 : 0,
              right: isExpanded ? 16 : 0,
              top: isExpanded ? 10 : 0,
              bottom: isExpanded ? 24 : 0,
            ),
            children: isExpanded
                ? _buildExpandedItems(context)
                : [_buildCollapsedContent(context)],
          ),
        ),
      ],
    );
  }

  // --- Collapsed States (75-95px tall) ---

  Widget _buildCollapsedContent(BuildContext context) {
    // 1. Route Calculated State: show active route metrics and expand action
    if (routes.isNotEmpty) {
      return _buildCollapsedRouteCalculated(context);
    }

    // 2. Endpoints Selected State: show readiness + compact Plan Route action
    if (origin != null && destination != null) {
      return _buildCollapsedEndpointsReady(context);
    }

    // 3. Default Initial Collapsed State
    return _buildCollapsedDefault(context);
  }

  Widget _buildCollapsedDefault(BuildContext context) {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.amber.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: AppColors.amberText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Plan your route',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Choose your start and destination above',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_up,
                size: 22,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Expand planner',
              onPressed: onToggleExpand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedEndpointsReady(BuildContext context) {
    if (isIdentical) {
      return InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.error_outline, size: 20, color: AppColors.riskHigh),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Invalid route endpoints',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.riskHigh,
                      ),
                    ),
                    Text(
                      'Origin and destination cannot be the same',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.riskNone,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Endpoints ready',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${origin!.label} → ${destination!.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_canPlanRoute && routeStatus != RouteStatus.loading)
                ? onPlanRoute
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: routeStatus == RouteStatus.loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Plan Route',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Expand options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onToggleExpand,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedRouteCalculated(BuildContext context) {
    final activeRoute = routes.firstWhere(
      (r) => r.id == selectedRouteId,
      orElse: () => routes.first,
    );
    final assessment = riskAssessments?[activeRoute.id];
    final category = assessment?.result?.riskCategory;
    final score = assessment?.result?.score;
    final durationStr = formatDuration(activeRoute.durationSeconds);
    final distanceStr = formatDistance(activeRoute.distanceMeters);

    Color categoryColor = AppColors.routePrimary;
    if (category == RouteRiskCategory.none) {
      categoryColor = AppColors.riskNone;
    }
    if (category == RouteRiskCategory.low) {
      categoryColor = AppColors.riskLow;
    }
    if (category == RouteRiskCategory.moderate) {
      categoryColor = AppColors.riskModerate;
    }
    if (category == RouteRiskCategory.high ||
        category == RouteRiskCategory.veryHigh) {
      categoryColor = AppColors.riskHigh;
    }

    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.navigation_rounded,
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        durationStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($distanceStr)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (category != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category == RouteRiskCategory.none
                                ? 'Clear'
                                : (score != null
                                      ? '${category.displayName} (${score.toInt()})'
                                      : category.displayName),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: categoryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    routes.length > 1
                        ? '${activeRoute.label ?? "Route 1"} • ${routes.length} options (tap to compare)'
                        : (activeRoute.label ?? 'OSRM driving route'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_up,
                size: 22,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Expand route details',
              onPressed: onToggleExpand,
            ),
          ],
        ),
      ),
    );
  }

  // --- Expanded Content ---

  List<Widget> _buildExpandedItems(BuildContext context) {
    return [
      // Endpoint Summary Strip
      if (origin != null || destination != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          origin != null
                              ? origin!.label
                              : 'Set origin on map/search',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: origin != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          destination != null
                              ? destination!.label
                              : 'Set destination on map/search',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: destination != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.riskHigh,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Origin and destination cannot be the same location. Please choose distinct coordinates.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.riskHigh,
                          ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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
                        children: const [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppColors.riskHigh,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Route retrieval failed:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.riskHigh,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routeError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _canPlanRoute ? onPlanRoute : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Retry Request',
                            style: TextStyle(fontSize: 11),
                          ),
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
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: AppColors.amberText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your route comparison will appear here.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Popular routes in Navi Mumbai:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text(
                              'Vashi → Belapur',
                              style: TextStyle(fontSize: 11),
                            ),
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
                            label: const Text(
                              'Airoli → Kharghar',
                              style: TextStyle(fontSize: 11),
                            ),
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
                            label: const Text(
                              'Nerul → Seawoods',
                              style: TextStyle(fontSize: 11),
                            ),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedScenarioId != DemoScenarioId.baseline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberLight.withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Demo Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.amberText,
                            ),
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
                  onPressed:
                      (_canPlanRoute && routeStatus != RouteStatus.loading)
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(128),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          routes.isNotEmpty
                              ? '${routes.length} Options'
                              : 'OSRM',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
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
                  color: _canPlanRoute
                      ? AppColors.riskNone
                      : AppColors.textMuted,
                ),
              ),
            ];
          }
        }
