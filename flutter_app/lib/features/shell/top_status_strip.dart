import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Top 56px status strip matching React status-strip banner.
/// Features VARSHA brand, pilot badge, live rain summary, alert count, refresh action, and about trigger.
class TopStatusStrip extends StatelessWidget implements PreferredSizeWidget {
  final String rainSummary;
  final int alertCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenWeather;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenSettings;

  const TopStatusStrip({
    super.key,
    required this.rainSummary,
    required this.alertCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenWeather,
    required this.onOpenAbout,
    required this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          // Left: Brand Wordmark & Pilot Chip
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VARSHA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  'Pilot: Navi Mumbai',
                  style: TextStyle(
                    color: AppColors.riskNone,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Right: Action Chips & Buttons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Rain Forecast Chip
                InkWell(
                  onTap: onOpenWeather,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderInteractive),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.routePrimary),
                        const SizedBox(width: 4),
                        Text(
                          rainSummary,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Alerts Chip
                InkWell(
                  onTap: onOpenWeather,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: alertCount > 0 ? AppColors.riskHigh.withAlpha(26) : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: alertCount > 0 ? AppColors.riskHigh.withAlpha(77) : AppColors.borderInteractive,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: alertCount > 0 ? AppColors.riskHigh : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alertCount > 0 ? '$alertCount active' : '0 active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: alertCount > 0 ? AppColors.riskHigh : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Refresh Button
                IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  tooltip: 'Refresh Weather and Alerts',
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18, color: AppColors.textPrimary),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                ),

                // Settings Button
                IconButton(
                  onPressed: onOpenSettings,
                  tooltip: 'Backend API Settings',
                  icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.textPrimary),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                ),

                // About Button
                IconButton(
                  onPressed: onOpenAbout,
                  tooltip: 'About VARSHA',
                  icon: const Icon(Icons.info_outline, size: 18, color: AppColors.textPrimary),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
