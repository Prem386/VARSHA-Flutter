import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';
import '../../services/weather/weather_service.dart';

class WeatherAlertsSheet extends StatefulWidget {
  final WeatherService? weatherService;
  final RainfallResponse? initialRainfall;
  final AlertListResponse? initialAlerts;
  final DateTime? referenceTime;
  final void Function(RainfallResponse rain, AlertListResponse alerts)? onDataRefreshed;

  const WeatherAlertsSheet({
    super.key,
    this.weatherService,
    this.initialRainfall,
    this.initialAlerts,
    this.referenceTime,
    this.onDataRefreshed,
  });

  static void show(
    BuildContext context, {
    WeatherService? weatherService,
    RainfallResponse? initialRainfall,
    AlertListResponse? initialAlerts,
    DateTime? referenceTime,
    void Function(RainfallResponse rain, AlertListResponse alerts)? onDataRefreshed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => WeatherAlertsSheet(
        weatherService: weatherService,
        initialRainfall: initialRainfall,
        initialAlerts: initialAlerts,
        referenceTime: referenceTime,
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
    _weatherService = widget.weatherService ?? WeatherService.shared;
    _rainfall = widget.initialRainfall;
    _alerts = widget.initialAlerts;

    if (_rainfall != null && _rainfall!.provider.status == 'unavailable') {
      _rainfallError = _rainfall!.provider.errorMessage ??
          'Rainfall forecast unavailable from upstream provider';
    }

    if (_alerts != null && _alerts!.provider.status == 'unavailable') {
      _alertsError = _alerts!.provider.errorMessage ??
          'Official alerts provider unavailable';
    }

    if (_rainfall == null || _alerts == null) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(WeatherAlertsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRainfall != oldWidget.initialRainfall) {
      setState(() {
        _rainfall = widget.initialRainfall;
        if (_rainfall != null && _rainfall!.provider.status == 'unavailable') {
          _rainfallError = _rainfall!.provider.errorMessage ??
              'Rainfall forecast unavailable from upstream provider';
        } else if (_rainfall != null) {
          _rainfallError = null;
        }
      });
    }
    if (widget.initialAlerts != oldWidget.initialAlerts) {
      setState(() {
        _alerts = widget.initialAlerts;
        if (_alerts != null && _alerts!.provider.status == 'unavailable') {
          _alertsError = _alerts!.provider.errorMessage ??
              'Official alerts provider unavailable';
        } else if (_alerts != null) {
          _alertsError = null;
        }
      });
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
      final res = await _weatherService.fetchRainfallForecast();
      if (res.provider.status == 'unavailable') {
        if (mounted) {
          setState(() {
            _rainfallError = res.provider.errorMessage ??
                'Rainfall forecast unavailable from upstream provider';
          });
        }
        return null;
      }
      return res;
    } catch (e) {
      if (mounted) setState(() => _rainfallError = e.toString());
      return null;
    }
  }

  Future<AlertListResponse?> _safeFetchAlerts() async {
    try {
      final res = await _weatherService.fetchOfficialAlerts();
      if (res.provider.status == 'unavailable') {
        if (mounted) {
          setState(() {
            _alertsError = res.provider.errorMessage ??
                'Official alerts provider unavailable';
          });
        }
        return null;
      }
      return res;
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
    DateTime? effectiveRefTime = widget.referenceTime;
    if (effectiveRefTime == null &&
        _rainfall?.current?.timestamp != null &&
        _rainfall!.current!.timestamp.isNotEmpty) {
      try {
        final raw = _rainfall!.current!.timestamp;
        final normalized = raw.endsWith('Z') || RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(raw)
            ? raw
            : '${raw}Z';
        effectiveRefTime = DateTime.parse(normalized).toUtc();
      } catch (_) {}
    }
    if (effectiveRefTime == null &&
        _rainfall?.provider.retrievedAt != null &&
        _rainfall!.provider.retrievedAt!.isNotEmpty) {
      try {
        final raw = _rainfall!.provider.retrievedAt!;
        final normalized = raw.endsWith('Z') || RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(raw)
            ? raw
            : '${raw}Z';
        effectiveRefTime = DateTime.parse(normalized).toUtc();
      } catch (_) {}
    }
    effectiveRefTime ??= DateTime.now().toUtc();

    final nextSixHours = selectNextSixForecastHours(_rainfall?.hourly, effectiveRefTime);
    final isRainfallStale = _rainfall?.provider.isStale == true ||
        _rainfall?.provider.status == 'degraded';
    final isAlertsStale = _alerts?.provider.isStale == true ||
        _alerts?.provider.status == 'degraded';
    final isAlertsUnavailable = _alerts?.provider.status == 'unavailable';

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
                      padding: const EdgeInsets.all(12),
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

                    const SizedBox(height: 14),

                    // --- SECTION 1: PRECIPITATION FORECAST ---
                    _buildSectionTitle(
                      'Precipitation Forecast',
                      subtitle: _rainfall?.provider.retrievedAt != null
                          ? (isRainfallStale
                              ? '⚠ Stale Fallback'
                              : 'Fetched: ${formatTimestampIst(_rainfall!.provider.retrievedAt)}')
                          : null,
                    ),

                    const SizedBox(height: 8),

                    if (_rainfallError != null)
                      _buildErrorCard('Rainfall forecast unavailable', _rainfallError!)
                    else if (_rainfall != null) ...[
                      // Stale / Degraded Warning Banner
                      if (isRainfallStale)
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
                                  'Notice: Open-Meteo upstream is currently unreachable. Displaying cached forecast from ${formatTimestampIst(_rainfall!.provider.retrievedAt)}.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Current Model Window
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _rainfall!.current?.intervalSeconds != null
                                  ? 'Current Model Estimate (${(_rainfall!.current!.intervalSeconds / 60).round()}m window)'
                                  : 'Current Model Estimate (15m window)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _rainfall!.current?.precipitationMm != null
                                      ? '${_rainfall!.current!.precipitationMm!.toStringAsFixed(1)} ${_rainfall!.current!.unit}'
                                      : 'Unavailable',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
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

                      const SizedBox(height: 12),

                      // Next Hours Horizontal Carousel
                      if (nextSixHours.isNotEmpty) ...[
                        Text(
                          'Next ${nextSixHours.length} Hours Forecast (IST)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                              final timeLabel = formatHourSlotIst(step.timestamp);

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

                      const SizedBox(height: 12),

                      // 24-Hour Horizon Summary
                      if (_rainfall!.summary != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
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
                              Builder(
                                builder: (context) {
                                  final summary = _rainfall!.summary!;
                                  final forecastHours = summary.forecastHours > 0 ? summary.forecastHours : 24;
                                  final validHours = summary.validHours ??
                                      (_rainfall!.hourly.isNotEmpty
                                          ? _rainfall!.hourly.where((s) => s.precipitationMm != null).length
                                          : null);
                                  final isComplete = summary.isComplete;
                                  final totalLabel = !isComplete && validHours != null
                                      ? 'Total Expected (Partial: $validHours/${forecastHours}h)'
                                      : 'Total Expected';
                                  final probValue = summary.maxProbabilityPct;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildMetricTile(
                                              totalLabel,
                                              summary.totalPrecipitationMm != null
                                                  ? '${summary.totalPrecipitationMm!.toStringAsFixed(1)} mm'
                                                  : 'Unavailable',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildMetricTile(
                                              'Peak 1-Hour',
                                              summary.maxHourlyPrecipitationMm != null
                                                  ? '${summary.maxHourlyPrecipitationMm!.toStringAsFixed(1)} mm'
                                                  : 'Unavailable',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Max Probability',
                                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: Stack(
                                                          alignment: Alignment.center,
                                                          children: [
                                                            const CircularProgressIndicator(
                                                              value: 1.0,
                                                              strokeWidth: 3,
                                                              valueColor: AlwaysStoppedAnimation(AppColors.borderSubtle),
                                                            ),
                                                            if (probValue != null && probValue > 0)
                                                              CircularProgressIndicator(
                                                                value: (probValue / 100.0).clamp(0.0, 1.0),
                                                                strokeWidth: 3,
                                                                valueColor: const AlwaysStoppedAnimation(AppColors.amberText),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        probValue != null ? '${probValue.round()}%' : '—',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isComplete && validHours != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            '* Incomplete forecast: ${forecastHours - validHours} of $forecastHours hourly intervals were missing from upstream model output.',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.riskModerate,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Text(
                            '24-hour summary unavailable for this forecast coordinate.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ],

                      // Open-Meteo Attribution
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 2),
                        child: Text(
                          'Weather forecast data from Open-Meteo.com (Licensed under CC BY 4.0).',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // --- SECTION 2: OFFICIAL DISASTER ALERTS ---
                    _buildSectionTitle(
                      'Official Disaster Warnings',
                      subtitle: _alerts != null
                          ? (isAlertsStale
                              ? '⚠ Stale Fallback (${_alerts!.total} Active)'
                              : '${_alerts!.total} Active Warning${_alerts!.total == 1 ? '' : 's'}')
                          : null,
                    ),

                    const SizedBox(height: 8),

                    if (_alertsError != null || isAlertsUnavailable)
                      _buildErrorCard(
                        'Alerts feed unavailable',
                        _alertsError ?? _alerts?.provider.errorMessage ?? 'Official alerts provider unavailable',
                      )
                    else if (_alerts != null) ...[
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
                                  'Notice: NDMA SACHET feed is unreachable. Displaying cached alerts from ${formatTimestampIst(_alerts!.provider.retrievedAt)}.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                          if (alert.urgency.trim().isNotEmpty && alert.urgency.trim().toLowerCase() != 'unknown')
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
