import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';
import '../../services/weather/weather_service.dart';
import 'disaster_alerts_view.dart';
import 'weather_forecast_view.dart';

/// Dedicated Weather & Alerts screen providing Numerical Weather Prediction forecasts,
/// rainfall accumulation estimates, and official NDMA SACHET disaster warnings.
class WeatherAlertsScreen extends StatefulWidget {
  final WeatherService? weatherService;
  final RainfallResponse? initialRainfall;
  final AlertListResponse? initialAlerts;
  final DateTime? referenceTime;
  final int initialTabIndex;
  final bool autoFetch;
  final void Function(RainfallResponse rain, AlertListResponse alerts)? onDataRefreshed;
  final VoidCallback? onBack;

  const WeatherAlertsScreen({
    super.key,
    this.weatherService,
    this.initialRainfall,
    this.initialAlerts,
    this.referenceTime,
    this.initialTabIndex = 0,
    this.autoFetch = true,
    this.onDataRefreshed,
    this.onBack,
  });

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final WeatherService _weatherService;

  RainfallResponse? _rainfall;
  AlertListResponse? _alerts;
  bool _isLoading = false;
  String? _rainfallError;
  String? _alertsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
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

    if ((_rainfall == null || _alerts == null) && widget.autoFetch) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(WeatherAlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 1));
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool force = false}) async {
    if (force) {
      _weatherService.clearCache();
    }

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
    final alertCount = _alerts?.total ?? 0;
    final isAlertsUnavailable = _alerts?.provider.status == 'unavailable' || _alertsError != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Weather & Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        leading: widget.onBack != null || Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Map',
                onPressed: widget.onBack ?? () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadData(force: true),
            tooltip: 'Refresh Weather and Alerts',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description Banner & TabBar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provides weather conditions, rainfall forecasts and official disaster warnings for Navi Mumbai.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.amber,
                  indicatorWeight: 3,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.water_drop_outlined, size: 20),
                      text: 'Weather',
                    ),
                    Tab(
                      icon: Badge(
                        isLabelVisible: alertCount > 0 && !isAlertsUnavailable,
                        label: Text('$alertCount'),
                        backgroundColor: AppColors.riskHigh,
                        textColor: Colors.white,
                        child: const Icon(Icons.warning_amber_rounded, size: 20),
                      ),
                      text: 'Disaster Alerts',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar Content Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Weather
                RefreshIndicator(
                  onRefresh: () => _loadData(force: true),
                  color: AppColors.amber,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      WeatherForecastView(
                        rainfall: _rainfall,
                        rainfallError: _rainfallError,
                        referenceTime: widget.referenceTime,
                        showNotice: true,
                        isLoading: _isLoading && _rainfall == null,
                      ),
                    ],
                  ),
                ),

                // Tab 1: Disaster Alerts
                RefreshIndicator(
                  onRefresh: () => _loadData(force: true),
                  color: AppColors.amber,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DisasterAlertsView(
                        alerts: _alerts,
                        alertsError: _alertsError,
                        isLoading: _isLoading && _alerts == null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
