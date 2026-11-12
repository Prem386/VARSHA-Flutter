import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/route.dart';
import '../routing/place_search_field.dart';

/// Google Maps-inspired floating search and directions header.
/// Dynamically transitions across interaction states:
/// - State A: Single "Where to?" search pill with quick telemetry chips.
/// - State B: Dedicated destination search field with autofocus & autocomplete.
/// - State C: Compact directions header prompting origin selection.
/// - State D: Both endpoints resolved with compact summary & "Plan Route" CTA.
/// - State E: Routes calculated summary header coordinated directly above route bubbles.
class FloatingSearchPanel extends StatelessWidget {
  final SelectedLocation? origin;
  final SelectedLocation? destination;
  final RouteEndpointType activeTarget;
  final bool isPickOnMapActive;
  final bool isIdentical;
  final ValueChanged<RouteEndpointType> onSelectTarget;
  final ValueChanged<SelectedLocation> onSelectOrigin;
  final ValueChanged<SelectedLocation> onSelectDestination;
  final VoidCallback onSwap;
  final ValueChanged<RouteEndpointType> onClear;

  // Interaction flow state
  final bool isSearchingDestination;
  final List<RoadRoute>? routes;
  final VoidCallback? onStartSearchDestination;
  final VoidCallback? onCancelSearch;
  final VoidCallback? onPlanRoute;
  final VoidCallback? onClearRoute;
  final VoidCallback? onStartSearchOrigin;

  // Weather & alerts telemetry actions
  final String? rainSummary;
  final int alertCount;
  final VoidCallback? onOpenWeather;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenSettings;

  // Backward compatibility flag for standalone unit tests
  final bool forceFullInputs;

  const FloatingSearchPanel({
    super.key,
    required this.origin,
    required this.destination,
    required this.activeTarget,
    required this.isPickOnMapActive,
    this.isIdentical = false,
    required this.onSelectTarget,
    required this.onSelectOrigin,
    required this.onSelectDestination,
    required this.onSwap,
    required this.onClear,
    this.isSearchingDestination = false,
    this.routes,
    this.onStartSearchDestination,
    this.onCancelSearch,
    this.onPlanRoute,
    this.onClearRoute,
    this.onStartSearchOrigin,
    this.rainSummary,
    this.alertCount = 0,
    this.onOpenWeather,
    this.onOpenAlerts,
    this.onOpenSettings,
    this.forceFullInputs = false,
  });

  bool get _hasRoutes => routes != null && routes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // ponytail: fallback to full 2-field view only when explicitly forced or unconfigured unit tests
    if (forceFullInputs ||
        (onStartSearchDestination == null &&
            origin == null &&
            destination == null &&
            !isSearchingDestination)) {
      return _buildFullInputsCard(context);
    }

    // State E: Routes calculated header
    if (_hasRoutes) {
      return _buildRoutesCalculatedHeader(context);
    }

    // State D: Both endpoints selected, ready to plan
    if (origin != null && destination != null) {
      return _buildEndpointsReadyHeader(context);
    }

    // State C: Destination selected, choosing origin
    if (destination != null && origin == null) {
      return _buildSearchingOriginHeader(context);
    }

    // State B: Actively searching destination
    if (isSearchingDestination) {
      return _buildDestinationSearchHeader(context);
    }

    // State A: Initial clean map "Where to?" search pill
    return _buildInitialSearchPill(context);
  }

  // --- STATE A: Initial Compact Top Branding + "Where to?" Floating Surface ---
  Widget _buildInitialSearchPill(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top row — App identity & actions (restored un-squished comfortable height)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // Left: VARSHA brand name
                const Text(
                  'VARSHA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),

                const Spacer(),

                // Right: Telemetry chips & Settings
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rain telemetry chip
                    InkWell(
                      key: const Key('status_strip_rain_chip'),
                      onTap: onOpenWeather,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 11,
                              color: AppColors.routePrimary,
                            ),
                            const SizedBox(width: 2.5),
                            Text(
                              rainSummary?.split('·').first.trim() ?? '0.0 mm',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),

                    // Alert count badge chip
                    InkWell(
                      key: const Key('status_strip_alerts_chip'),
                      onTap: onOpenAlerts,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: alertCount > 0
                              ? AppColors.riskHigh.withAlpha(30)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: alertCount > 0
                                ? AppColors.riskHigh.withAlpha(120)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              alertCount > 0
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_none,
                              size: 11,
                              color: alertCount > 0
                                  ? AppColors.riskHigh
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$alertCount active',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: alertCount > 0
                                    ? AppColors.riskHigh
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (onOpenSettings != null) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Settings',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onOpenSettings,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Subtle divider between identity row and search row
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.borderSubtle,
          ),

          // 2. Bottom row — Destination search tap field (Google Maps-style height & ergonomics)
          InkWell(
            onTap: onStartSearchDestination,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Where to?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE B: Dedicated Destination Search Header ---
  Widget _buildDestinationSearchHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: (isPickOnMapActive &&
                  activeTarget == RouteEndpointType.destination)
              ? AppColors.amber.withAlpha(180)
              : AppColors.borderSubtle,
          width: (isPickOnMapActive &&
                  activeTarget == RouteEndpointType.destination)
              ? 1.5
              : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Cancel search',
            onPressed: onCancelSearch,
          ),
          Expanded(
            child: PlaceSearchField(
              isCompact: true,
              autofocus: true,
              endpointType: RouteEndpointType.destination,
              label: 'Destination',
              tagLetter: 'B',
              placeholder: 'Where to? (e.g. Belapur CBD)',
              value: destination,
              onSelect: onSelectDestination,
              onClear: () => onClear(RouteEndpointType.destination),
              isActiveTarget:
                  isPickOnMapActive &&
                  activeTarget == RouteEndpointType.destination,
              onActivateTarget: () =>
                  onSelectTarget(RouteEndpointType.destination),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE C: Origin Search Header (Destination Selected) ---
  Widget _buildSearchingOriginHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: (isPickOnMapActive && activeTarget == RouteEndpointType.origin)
              ? AppColors.amber.withAlpha(180)
              : AppColors.borderSubtle,
          width:
              (isPickOnMapActive && activeTarget == RouteEndpointType.origin)
                  ? 1.5
                  : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Origin Input
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                tooltip: 'Back to search',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => onClear(RouteEndpointType.destination),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: PlaceSearchField(
                  isCompact: true,
                  autofocus: true,
                  endpointType: RouteEndpointType.origin,
                  label: 'Origin',
                  tagLetter: 'A',
                  placeholder: 'Choose starting point (e.g. Vashi)',
                  value: origin,
                  onSelect: onSelectOrigin,
                  onClear: () => onClear(RouteEndpointType.origin),
                  isActiveTarget:
                      isPickOnMapActive &&
                      activeTarget == RouteEndpointType.origin,
                  onActivateTarget: () =>
                      onSelectTarget(RouteEndpointType.origin),
                ),
              ),
            ],
          ),

          // Divider with Swap
          _buildDividerWithSwap(),

          // Destination display row (editable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.destinationPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Destination',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: onStartSearchDestination,
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      destination!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.routePrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Clear destination',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => onClear(RouteEndpointType.destination),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE D: Both Endpoints Ready Header ---
  Widget _buildEndpointsReadyHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isIdentical
              ? AppColors.riskHigh.withAlpha(120)
              : AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Origin
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                tooltip: 'Clear all',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  onClear(RouteEndpointType.origin);
                  onClear(RouteEndpointType.destination);
                },
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.originGreen,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Origin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => onClear(RouteEndpointType.origin),
                  child: Text(
                    origin!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear origin',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => onClear(RouteEndpointType.origin),
              ),
            ],
          ),

          // Divider with Swap
          _buildDividerWithSwap(),

          // Row 2: Destination
          Row(
            children: [
              const SizedBox(width: 32),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.destinationPurple,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Destination',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => onClear(RouteEndpointType.destination),
                  child: Text(
                    destination!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear destination',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => onClear(RouteEndpointType.destination),
              ),
            ],
          ),

          if (isIdentical) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.riskHigh.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.riskHigh.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 12,
                    color: AppColors.riskHigh,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Origin and destination cannot be the same location.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.riskHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Plan Route Action Button
          const SizedBox(height: 6),
          ElevatedButton.icon(
            key: const Key('plan_route_button'),
            onPressed: isIdentical ? null : onPlanRoute,
            icon: const Icon(Icons.directions, size: 16),
            label: const Text(
              'Plan Route',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE E: Routes Calculated Compact Header ---
  Widget _buildRoutesCalculatedHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Clear route',
            onPressed: onClearRoute,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.originGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        origin?.label ?? 'Origin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.destinationPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'B',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        destination?.label ?? 'Destination',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, size: 20),
            tooltip: 'Swap endpoints',
            onPressed: onSwap,
          ),
        ],
      ),
    );
  }

  // --- Fallback Full 2-field View for backward compatibility ---
  Widget _buildFullInputsCard(BuildContext context) {
    final bool isOriginTargetActive =
        isPickOnMapActive && activeTarget == RouteEndpointType.origin;
    final bool isDestinationTargetActive =
        isPickOnMapActive && activeTarget == RouteEndpointType.destination;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: (isOriginTargetActive || isDestinationTargetActive)
              ? AppColors.amber.withAlpha(180)
              : AppColors.borderSubtle,
          width:
              (isOriginTargetActive || isDestinationTargetActive) ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlaceSearchField(
            isCompact: true,
            endpointType: RouteEndpointType.origin,
            label: 'Origin',
            tagLetter: 'A',
            placeholder: 'Search origin (e.g. Vashi Station)',
            value: origin,
            onSelect: onSelectOrigin,
            onClear: () => onClear(RouteEndpointType.origin),
            isActiveTarget: isOriginTargetActive,
            onActivateTarget: () => onSelectTarget(RouteEndpointType.origin),
          ),
          _buildDividerWithSwap(),
          PlaceSearchField(
            isCompact: true,
            endpointType: RouteEndpointType.destination,
            label: 'Destination',
            tagLetter: 'B',
            placeholder: 'Where to? (e.g. Belapur CBD)',
            value: destination,
            onSelect: onSelectDestination,
            onClear: () => onClear(RouteEndpointType.destination),
            isActiveTarget: isDestinationTargetActive,
            onActivateTarget: () =>
                onSelectTarget(RouteEndpointType.destination),
          ),
          if (isIdentical)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.riskHigh.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.riskHigh.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 12,
                    color: AppColors.riskHigh,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Origin and destination cannot be the same location.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.riskHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDividerWithSwap() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const Expanded(
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          InkWell(
            onTap: (origin != null || destination != null) ? onSwap : null,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Swap',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
        ],
      ),
    );
  }
}
