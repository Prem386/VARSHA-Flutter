import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hazard.dart';

/// Contextual floating card displaying inspected hazard details without breaking navigation flow.
class HazardContextCard extends StatelessWidget {
  final HazardLocation hazard;
  final VoidCallback onClose;

  const HazardContextCard({
    super.key,
    required this.hazard,
    required this.onClose,
  });

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

  @override
  Widget build(BuildContext context) {
    final sevColor = _getSeverityColor(hazard.severity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: sevColor.withAlpha(100), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Severity Badge & Dismiss Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${hazard.severity.displayName.toUpperCase()} HAZARD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: sevColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SIMULATED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                tooltip: 'Close hazard details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Hazard Title
          Text(
            hazard.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${hazard.area} • ${hazard.hazardType.displayName}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            hazard.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

