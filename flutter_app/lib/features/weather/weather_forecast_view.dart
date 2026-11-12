import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/weather.dart';

/// Reusable Weather Forecast content widget displaying NWP precipitation,
/// 6-hour upcoming forecast, rolling 24-hour summary, and attribution.
class WeatherForecastView extends StatelessWidget {
  final RainfallResponse? rainfall;
  final String? rainfallError;
  final DateTime? referenceTime;
  final bool showNotice;
  final bool isLoading;

  const WeatherForecastView({
    super.key,
    this.rainfall,
    this.rainfallError,
    this.referenceTime,
    this.showNotice = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? effectiveRefTime = referenceTime;
    if (effectiveRefTime == null &&
        rainfall?.current?.timestamp != null &&
        rainfall!.current!.timestamp.isNotEmpty) {
      try {
        final raw = rainfall!.current!.timestamp;
        final normalized = raw.endsWith('Z') || RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(raw)
            ? raw
            : '${raw}Z';
        effectiveRefTime = DateTime.parse(normalized).toUtc();
      } catch (_) {}
    }
    if (effectiveRefTime == null &&
        rainfall?.provider.retrievedAt != null &&
        rainfall!.provider.retrievedAt!.isNotEmpty) {
      try {
        final raw = rainfall!.provider.retrievedAt!;
        final normalized = raw.endsWith('Z') || RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(raw)
            ? raw
            : '${raw}Z';
        effectiveRefTime = DateTime.parse(normalized).toUtc();
      } catch (_) {}
    }
    effectiveRefTime ??= DateTime.now().toUtc();

    final nextSixHours = selectNextSixForecastHours(rainfall?.hourly, effectiveRefTime);
    final isRainfallStale = rainfall?.provider.isStale == true ||
        rainfall?.provider.status == 'degraded';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Official Data Notice
        if (showNotice) ...[
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
        ],

        // 2. Section Header
        _buildSectionTitle(
          'Precipitation Forecast',
          subtitle: rainfall?.provider.retrievedAt != null
              ? (isRainfallStale
                  ? '⚠ Stale Fallback'
                  : 'Fetched: ${formatTimestampIst(rainfall!.provider.retrievedAt)}')
              : null,
        ),

        const SizedBox(height: 8),

        // 3. Error or Content
        if (rainfallError != null)
          _buildErrorCard('Rainfall forecast unavailable', rainfallError!)
        else if (isLoading && rainfall == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
          )
        else if (rainfall != null) ...[
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
                      'Notice: Open-Meteo upstream is currently unreachable. Displaying cached forecast from ${formatTimestampIst(rainfall!.provider.retrievedAt)}.',
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
                  rainfall!.current?.intervalSeconds != null
                      ? 'Current Model Estimate (${(rainfall!.current!.intervalSeconds / 60).round()}m window)'
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
                      rainfall!.current?.precipitationMm != null
                          ? '${rainfall!.current!.precipitationMm!.toStringAsFixed(1)} ${rainfall!.current!.unit}'
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
          if (rainfall!.summary != null) ...[
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
                      final summary = rainfall!.summary!;
                      final forecastHours = summary.forecastHours > 0 ? summary.forecastHours : 24;
                      final validHours = summary.validHours ??
                          (rainfall!.hourly.isNotEmpty
                              ? rainfall!.hourly.where((s) => s.precipitationMm != null).length
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

  static Widget _buildMetricTile(String label, String value) {
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

