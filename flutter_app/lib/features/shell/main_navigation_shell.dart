import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert.dart';
import '../../models/weather.dart';
import '../../services/routing/osrm_service.dart';
import '../../services/weather/weather_service.dart';
import '../map/map_screen.dart';
import '../weather/weather_alerts_screen.dart';
import 'about_sheet.dart';
import 'persistent_disclaimer.dart';

/// Primary application shell providing permanent bottom navigation between
/// Map (primary) and Weather & Alerts screens, preserving screen state and
/// coordinating shared live weather/alert data.
class MainNavigationShell extends StatefulWidget {
  final WeatherService? weatherService;
  final OsrmService? osrmService;
  final int initialIndex;
  final int initialWeatherTabIndex;

  const MainNavigationShell({
    super.key,
    this.weatherService,
    this.osrmService,
    this.initialIndex = 0,
    this.initialWeatherTabIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  late int _weatherTabIndex;
  late final WeatherService _weatherService;
  late final OsrmService _osrmService;

  RainfallResponse? _rainfallData;
  AlertListResponse? _alertsData;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _weatherTabIndex = widget.initialWeatherTabIndex;
    _weatherService = widget.weatherService ?? WeatherService.shared;
    _osrmService = widget.osrmService ?? OsrmService();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _safeFetchRainfall(),
        _safeFetchAlerts(),
      ]);

      if (mounted) {
        setState(() {
          final rain = results[0] as RainfallResponse?;
          final alerts = results[1] as AlertListResponse?;
          if (rain != null) _rainfallData = rain;
          if (alerts != null) {
            _alertsData = alerts;
            _alertCount = alerts.total;
          }
        });
      }
    } finally {}
  }

  Future<RainfallResponse?> _safeFetchRainfall() async {
    try {
      return await _weatherService.fetchRainfallForecast();
    } catch (_) {
      return null;
    }
  }

  Future<AlertListResponse?> _safeFetchAlerts() async {
    try {
      return await _weatherService.fetchOfficialAlerts();
    } catch (_) {
      return null;
    }
  }

  void _onDataRefreshed(RainfallResponse rain, AlertListResponse alerts) {
    setState(() {
      _rainfallData = rain;
      _alertsData = alerts;
      _alertCount = alerts.total;
    });
  }

  void _navigateToWeather(int tabIndex) {
    setState(() {
      _currentIndex = 1;
      _weatherTabIndex = tabIndex;
    });
  }

  bool get _isAlertsUnavailable =>
      _alertsData != null && _alertsData!.provider.status == 'unavailable';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            MapScreen(
              weatherService: _weatherService,
              osrmService: _osrmService,
              showBottomDisclaimer: false,
              autoFetch: false,
              initialRainfall: _rainfallData,
              initialAlerts: _alertsData,
              onNavigateToWeather: _navigateToWeather,
              onDataRefreshed: _onDataRefreshed,
            ),
            WeatherAlertsScreen(
              weatherService: _weatherService,
              autoFetch: false,
              initialRainfall: _rainfallData,
              initialAlerts: _alertsData,
              initialTabIndex: _weatherTabIndex,
              onDataRefreshed: _onDataRefreshed,
              onBack: () => setState(() => _currentIndex = 0),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersistentDisclaimer(
              onLearnMore: () => AboutSheet.show(context),
            ),
            NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              height: 62,
              backgroundColor: AppColors.surface,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _alertCount > 0 && !_isAlertsUnavailable,
                    label: Text('$_alertCount'),
                    backgroundColor: AppColors.riskHigh,
                    textColor: Colors.white,
                    child: const Icon(Icons.cloud_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _alertCount > 0 && !_isAlertsUnavailable,
                    label: Text('$_alertCount'),
                    backgroundColor: AppColors.riskHigh,
                    textColor: Colors.white,
                    child: const Icon(Icons.cloud),
                  ),
                  label: 'Weather & Alerts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
