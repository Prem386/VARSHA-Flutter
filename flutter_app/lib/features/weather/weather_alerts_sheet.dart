import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';
import '../../services/weather/weather_service.dart';

class WeatherAlertsSheet extends StatefulWidget {
  final RainfallResponse? initialRainfall;
  final AlertListResponse? initialAlerts;
  final void Function(RainfallResponse rain, AlertListResponse alerts)? onDataRefreshed;

  const WeatherAlertsSheet({
    super.key,
    this.initialRainfall,
    this.initialAlerts,
    this.onDataRefreshed,
  });

  static void show(
    BuildContext context, {
    RainfallResponse? initialRainfall,
    AlertListResponse? initialAlerts,
    void Function(RainfallResponse rain, AlertListResponse alerts)? onDataRefreshed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => WeatherAlertsSheet(
        initialRainfall: initialRainfall,
        initialAlerts: initialAlerts,
        onDataRefreshed: onDataRefreshed,
      ),
    );
  }

  @override
  State<WeatherAlertsSheet> createState() => _WeatherAlertsSheetState();
}

class _WeatherAlertsSheetState extends State<WeatherAlertsSheet> {
  late final WeatherService _weatherService;
  RainfallResponse? _rainfall;
  AlertListResponse? _alerts;
  bool _isLoading = false;
  String? _rainfallError;
  String? _alertsError;
  String? _expandedAlertId;

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService();
    _rainfall = widget.initialRainfall;
    _alerts = widget.initialAlerts;

    if (_rainfall == null || _alerts == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _rainfallError = null;
      _alertsError = null;
    });

    try {
      final freshRain = await _safeFetchRainfall();
      final freshAlerts = await _safeFetchAlerts();

      if (mounted) {
        setState(() {
          if (freshRain != null) _rainfall = freshRain;
          if (freshAlerts != null) _alerts = freshAlerts;
        });

        if (freshRain != null && freshAlerts != null) {
          widget.onDataRefreshed?.call(freshRain, freshAlerts);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<RainfallResponse?> _safeFetchRainfall() async {
    try {
      return await _weatherService.fetchRainfallForecast();
    } catch (e) {
      if (mounted) setState(() => _rainfallError = e.toString());
      return null;
    }
  }

  Future<AlertListResponse?> _safeFetchAlerts() async {
    try {
      return await _weatherService.fetchOfficialAlerts();
    } catch (e) {
      if (mounted) setState(() => _alertsError = e.toString());
      return null;
    }
  }

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
    final nextSixHours = selectNextSixForecastHours(_rainfall?.hourly);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NWP Forecast & Official Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Navi Mumbai NWP Forecast • NDMA SACHET Warnings',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isLoading ? null : _loadData,
                      tooltip: 'Refresh Data',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSubtle),

              // Content Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Official Data Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: AppColors.amberText),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Official Data & Geographic Scope: Rainfall is a model-derived forecast for Navi Mumbai. '
                              'Official disaster warnings reflect active broadcasts from the NDMA SACHET feed.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SECTION 1: PRECIPITATION FORECAST ---
                    _buildSectionTitle(
                      'Precipitation Forecast',
                      subtitle: _rainfall?.provider.retrievedAt != null
                          ? 'Model Horizon (Open-Meteo)'
                          : null,
                    ),

                    const SizedBox(height: 10),

                    if (_rainfallError != null)
                      _buildErrorCard('Rainfall forecast unavailable', _rainfallError!)
                    else if (_rainfall != null) ...[
                      // Current Model Window
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Model Estimate (15m window)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _rainfall!.current?.precipitationMm != null
                                      ? '${_rainfall!.current!.precipitationMm!.toStringAsFixed(1)} ${_rainfall!.current!.unit}'
                                      : '0.0 mm',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.routePrimary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'NWP Model-derived',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.routePrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Accumulation over preceding 15 min evaluation interval. Not an instantaneous rate.',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Next 6 Hours Horizontal Carousel
                      if (nextSixHours.isNotEmpty) ...[
                        const Text(
                          'Next 6 Hours Forecast',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 124,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: nextSixHours.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final step = nextSixHours[index];
                              String timeLabel = step.timestamp;
                              try {
                                final dt = DateTime.parse(
                                  step.timestamp.endsWith('Z') ? step.timestamp : '${step.timestamp}Z',
                                ).toLocal();
                                final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                                final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                                timeLabel = '$hour:00 $ampm';
                              } catch (_) {}

                              return Container(
                                width: 96,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      timeLabel,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step.precipitationMm != null
                                          ? '${step.precipitationMm!.toStringAsFixed(1)} mm'
                                          : '—',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.precipitationProbabilityPct != null
                                          ? '${step.precipitationProbabilityPct!.round()}% prob'
                                          : '—',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.amberText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 24-Hour Horizon Summary
                      if (_rainfall!.summary != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rolling 24-Hour Summary',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricTile(
                                      'Total Expected',
                                      _rainfall!.summary!.totalPrecipitationMm != null
                                          ? '${_rainfall!.summary!.totalPrecipitationMm!.toStringAsFixed(1)} mm'
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricTile(
                                      'Peak 1-Hour',
                                      _rainfall!.summary!.maxHourlyPrecipitationMm != null
                                          ? '${_rainfall!.summary!.maxHourlyPrecipitationMm!.toStringAsFixed(1)} mm'
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricTile(
                                      'Max Probability',
                                      _rainfall!.summary!.maxProbabilityPct != null
                                          ? '${_rainfall!.summary!.maxProbabilityPct!.round()}%'
                                          : '—',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 28),

                    // --- SECTION 2: OFFICIAL DISASTER ALERTS ---
                    _buildSectionTitle(
                      'Official Disaster Warnings',
                      subtitle: _alerts != null ? '${_alerts!.total} Active Warnings' : null,
                    ),

                    const SizedBox(height: 10),

                    if (_alertsError != null)
                      _buildErrorCard('Alerts feed unavailable', _alertsError!)
                    else if (_alerts != null) ...[
                      if (_alerts!.total == 0)
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
                        ..._alerts!.alerts.map((alert) {
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
                                    const Spacer(),
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
                                if (alert.areaDescription != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Areas: ${alert.areaDescription}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
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

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title, String detail) {
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
