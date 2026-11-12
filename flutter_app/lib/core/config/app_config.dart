import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central configuration for API and routing endpoints.
///
/// Supports:
/// 1. Compile-time environment flags (--dart-define=API_BASE_URL=...)
/// 2. Platform-aware auto-discovery (10.0.2.2 for Android emulator, 127.0.0.1 for desktop/iOS)
/// 3. Persistent runtime override via SharedPreferences (accessible in Settings)
class AppConfig {
  static const String _prefKeyApiBaseUrl = 'varsha_custom_api_base_url';
  static const String _prefKeyOsrmUrl = 'varsha_custom_osrm_url';

  // Default values from environment or platform detection
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envOsrmUrl = String.fromEnvironment(
    'OSRM_ROUTER_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  static late SharedPreferences _prefs;
  static bool _initialized = false;

  /// Initialize persistent configuration.
  static Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Default API URL based on platform.
  static String get defaultPlatformBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator accesses host loopback via 10.0.2.2
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Fallback
    }
    return 'http://127.0.0.1:8000';
  }

  /// Current active FastAPI backend base URL.
  static String get apiBaseUrl {
    if (_initialized) {
      final custom = _prefs.getString(_prefKeyApiBaseUrl);
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim().replaceAll(RegExp(r'/+$'), '');
      }
    }
    return defaultPlatformBaseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// Updates the active backend base URL in SharedPreferences.
  static Future<void> setApiBaseUrl(String? url) async {
    if (!_initialized) return;
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_prefKeyApiBaseUrl);
    } else {
      await _prefs.setString(_prefKeyApiBaseUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
    }
  }

  /// Current active OSRM router URL.
  static String get osrmRouterUrl {
    if (_initialized) {
      final custom = _prefs.getString(_prefKeyOsrmUrl);
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim().replaceAll(RegExp(r'/+$'), '');
      }
    }
    return _envOsrmUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// Updates the active OSRM router URL in SharedPreferences.
  static Future<void> setOsrmRouterUrl(String? url) async {
    if (!_initialized) return;
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_prefKeyOsrmUrl);
    } else {
      await _prefs.setString(_prefKeyOsrmUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
    }
  }

  /// Reset all endpoint overrides to default.
  static Future<void> resetToDefaults() async {
    if (!_initialized) return;
    await _prefs.remove(_prefKeyApiBaseUrl);
    await _prefs.remove(_prefKeyOsrmUrl);
  }
}
