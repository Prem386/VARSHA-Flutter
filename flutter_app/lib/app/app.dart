import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/map/map_screen.dart';
import '../services/routing/osrm_service.dart';
import '../services/weather/weather_service.dart';

class VarshaApp extends StatelessWidget {
  final WeatherService? weatherService;
  final OsrmService? osrmService;

  const VarshaApp({
    super.key,
    this.weatherService,
    this.osrmService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VARSHA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MapScreen(
        weatherService: weatherService,
        osrmService: osrmService,
      ),
    );
  }
}
