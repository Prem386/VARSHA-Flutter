import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';
import '../../services/weather/weather_service.dart';
import 'disaster_alerts_view.dart';
import 'weather_forecast_view.dart';

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

  @override
  Widget build(BuildContext context) {
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
                    WeatherForecastView(
                      rainfall: _rainfall,
                      rainfallError: _rainfallError,
                      referenceTime: widget.referenceTime,
                      showNotice: true,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 14),
                    DisasterAlertsView(
                      alerts: _alerts,
                      alertsError: _alertsError,
                      isLoading: _isLoading,
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
}
