import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Floating collapsible legend matching React MapView legend overlay.
class MapLegend extends StatefulWidget {
  final bool hasAlternativeRoutes;

  const MapLegend({super.key, this.hasAlternativeRoutes = false});

  @override
  State<MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<MapLegend> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Pill
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Legend',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 8),

                  const Text(
                    'Route Elements:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    badge: _buildBadge('A', AppColors.originGreen),
                    label: 'Origin (Start)',
                  ),
                  _buildLegendItem(
                    badge: _buildBadge('B', AppColors.destinationPurple),
                    label: 'Destination (End)',
                  ),
                  _buildLegendItem(
                    badge: Container(width: 14, height: 3, color: AppColors.routePrimary),
                    label: 'Selected Route',
                  ),
                  if (widget.hasAlternativeRoutes)
                    _buildLegendItem(
                      badge: Container(
                        width: 14,
                        height: 3,
                        color: AppColors.routeAlternative,
                      ),
                      label: 'Alternative Route',
                    ),

                  const SizedBox(height: 8),

                  const Text(
                    'Simulated Hazards:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    badge: _buildDot(AppColors.riskHigh),
                    label: 'High Severity',
                  ),
                  _buildLegendItem(
                    badge: _buildDot(AppColors.riskModerate),
                    label: 'Medium Severity',
                  ),
                  _buildLegendItem(
                    badge: _buildDot(AppColors.riskLow),
                    label: 'Low Severity',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Widget badge, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, alignment: Alignment.center, child: badge),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBadge(String letter, Color color) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
