import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Mobile-first compact status strip matching VARSHA brand identity.
/// Features VARSHA brand, pilot badge, live rain summary, alert count, refresh action, and about trigger.
class TopStatusStrip extends StatelessWidget implements PreferredSizeWidget {
  final String rainSummary;
  final int alertCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenWeather;
  final VoidCallback? onOpenAlerts;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenSettings;

  const TopStatusStrip({
    super.key,
    required this.rainSummary,
    required this.alertCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenWeather,
    this.onOpenAlerts,
    required this.onOpenAbout,
    required this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 2 : 2,
        bottom: 2,
        left: 10,
        right: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.borderSubtle),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Text(
                    'Pilot: Navi Mumbai',
                    style: TextStyle(
                      color: AppColors.riskNone,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 6),

            // Right: Action Chips & Telemetry Buttons
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rain Forecast Chip
                    InkWell(
                      key: const Key('status_strip_rain_chip'),
                      onTap: onOpenWeather,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderInteractive),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 12, color: AppColors.routePrimary),
                            const SizedBox(width: 3),
                            Text(
                              rainSummary,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Alerts Chip
                    InkWell(
                      key: const Key('status_strip_alerts_chip'),
                      onTap: onOpenAlerts ?? onOpenWeather,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                              size: 12,
                              color: alertCount > 0 ? AppColors.riskHigh : AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              alertCount > 0 ? '$alertCount active' : '0 active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: alertCount > 0 ? AppColors.riskHigh : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Refresh Button
                    IconButton(
                      onPressed: isRefreshing ? null : onRefresh,
                      tooltip: 'Refresh Weather and Alerts',
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16, color: AppColors.textPrimary),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),

                    // Settings Button
                    IconButton(
                      onPressed: onOpenSettings,
                      tooltip: 'Backend API Settings',
                      icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.textPrimary),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),

                    // About Button
                    IconButton(
                      onPressed: onOpenAbout,
                      tooltip: 'About VARSHA',
                      icon: const Icon(Icons.info_outline, size: 16, color: AppColors.textPrimary),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
