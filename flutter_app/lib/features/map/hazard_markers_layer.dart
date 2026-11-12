import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hazard.dart';

/// Layer rendering simulated hazards on the map with interactive inspection dialogs.
class HazardMarkersLayer extends StatelessWidget {
  final List<HazardLocation> hazards;

  const HazardMarkersLayer({super.key, required this.hazards});

  Color _getSeverityColor(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.high:
        return AppColors.riskHigh;
      case HazardSeverity.medium:
        return AppColors.riskModerate;
      case HazardSeverity.low:
        return AppColors.riskLow;
    }
  }

  void _showHazardDetails(BuildContext context, HazardLocation hazard) {
    final sevColor = _getSeverityColor(hazard.severity);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sevColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${hazard.severity.displayName.toUpperCase()} SEVERITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: sevColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SIMULATED DATA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                hazard.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hazard.area,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 14),

              // Info Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hazard Type', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            hazard.hazardType.displayName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Coordinates', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${hazard.coordinates.latitude.toStringAsFixed(4)}° N, ${hazard.coordinates.longitude.toStringAsFixed(4)}° E',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                hazard.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('⚠️ ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        'Illustrative scenario for testing • Not a verified live incident',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: hazards.map((hazard) {
        final sevColor = _getSeverityColor(hazard.severity);
        final size = hazard.severity == HazardSeverity.high ? 26.0 : 22.0;

        return Marker(
          point: hazard.coordinates,
          width: size + 16,
          height: size + 16,
          child: GestureDetector(
            onTap: () => _showHazardDetails(context, hazard),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer soft pulsing halo
                  Container(
                    width: size + 8,
                    height: size + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sevColor.withAlpha(38),
                    ),
                  ),
                  // Middle raised border
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  // Center solid severity dot
                  Container(
                    width: size - 8,
                    height: size - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sevColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
