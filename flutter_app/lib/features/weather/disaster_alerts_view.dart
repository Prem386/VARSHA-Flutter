import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';

/// Reusable Disaster Alerts content widget displaying active NDMA SACHET alerts,
/// severity and urgency badges, affected areas, and expandable instructions.
class DisasterAlertsView extends StatefulWidget {
  final AlertListResponse? alerts;
  final String? alertsError;
  final bool isLoading;

  const DisasterAlertsView({
    super.key,
    this.alerts,
    this.alertsError,
    this.isLoading = false,
  });

  @override
  State<DisasterAlertsView> createState() => _DisasterAlertsViewState();
}

class _DisasterAlertsViewState extends State<DisasterAlertsView> {
  String? _expandedAlertId;

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
      case 'severe':
        return AppColors.riskHigh;
      case 'moderate':
        return AppColors.riskModerate;
      case 'minor':
        return AppColors.riskLow;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = widget.alerts;
    final isAlertsStale = alerts?.provider.isStale == true ||
        alerts?.provider.status == 'degraded';
    final isAlertsUnavailable = alerts?.provider.status == 'unavailable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Section Title
        _buildSectionTitle(
          'Official Disaster Warnings',
          subtitle: alerts != null
              ? (isAlertsStale
                  ? '⚠ Stale Fallback (${alerts.total} Active)'
                  : '${alerts.total} Active Warning${alerts.total == 1 ? '' : 's'}')
              : null,
        ),

        const SizedBox(height: 8),

        // 2. Error Card or Loading or Content
        if (widget.alertsError != null || isAlertsUnavailable)
          _buildErrorCard(
            'Alerts feed unavailable',
            widget.alertsError ?? alerts?.provider.errorMessage ?? 'Official alerts provider unavailable',
          )
        else if (widget.isLoading && alerts == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
          )
        else if (alerts != null) ...[
          // Stale / Degraded Warning Banner
          if (isAlertsStale)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.riskModerate.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.riskModerate.withAlpha(77)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.riskModerate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice: NDMA SACHET feed is unreachable. Displaying cached alerts from ${formatTimestampIst(alerts.provider.retrievedAt)}.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          if (alerts.total == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.riskNone, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Active Official Disaster Alerts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'No government warnings broadcast in the NDMA SACHET feed for this region.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.alerts.map((alert) {
              final isExpanded = _expandedAlertId == alert.identifier;
              final sevColor = _getSeverityColor(alert.severity);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sevColor.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sevColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${alert.severity.toUpperCase()} SEVERITY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: sevColor,
                                  ),
                                ),
                              ),
                              if (alert.event != null && alert.event!.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.routePrimary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    alert.event!.trim(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.routePrimary,
                                    ),
                                  ),
                                ),
                              if (alert.urgency.trim().isNotEmpty &&
                                  alert.urgency.trim().toLowerCase() != 'unknown')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.amberText.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${alert.urgency.trim()} Urgency',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amberText,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alert.sender,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.headline ?? '${alert.event ?? "Emergency"} Advisory',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (alert.areaDescription != null && alert.areaDescription!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Affected Districts / Areas: ${alert.areaDescription}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                    if (alert.effective != null || alert.expires != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                children: [
                                  if (alert.effective != null) ...[
                                    const TextSpan(
                                      text: 'Effective: ',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                    TextSpan(text: formatTimestampIst(alert.effective)),
                                  ],
                                  if (alert.effective != null && alert.expires != null)
                                    const TextSpan(text: ' • '),
                                  if (alert.expires != null) ...[
                                    const TextSpan(
                                      text: 'Expires: ',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                    TextSpan(text: formatTimestampIst(alert.expires)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (alert.description != null || alert.instruction != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedAlertId = isExpanded ? null : alert.identifier;
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              isExpanded ? 'Hide Details' : 'Show Instructions & Details',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberText,
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.amberText,
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 8),
                        if (alert.description != null)
                          Text(
                            alert.description!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        if (alert.instruction != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Instruction: ${alert.instruction}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              );
            }),

          // NDMA SACHET Attribution
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              'Official disaster warnings from NDMA SACHET (Common Alerting Protocol 1.2).',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildErrorCard(String title, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.riskHigh.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.riskHigh.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.riskHigh, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.riskHigh)),
                Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

