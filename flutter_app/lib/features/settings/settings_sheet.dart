import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/weather/weather_service.dart';

class SettingsSheet extends StatefulWidget {
  final VoidCallback onConfigChanged;

  const SettingsSheet({super.key, required this.onConfigChanged});

  static void show(BuildContext context, {required VoidCallback onConfigChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SettingsSheet(onConfigChanged: onConfigChanged),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _apiController;
  late final TextEditingController _osrmController;
  bool _isCheckingHealth = false;
  String? _healthStatus;
  bool _isHealthOk = false;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: AppConfig.apiBaseUrl);
    _osrmController = TextEditingController(text: AppConfig.osrmRouterUrl);
    _checkHealth();
  }

  @override
  void dispose() {
    _apiController.dispose();
    _osrmController.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _healthStatus = null;
    });

    final weatherService = WeatherService();
    final ok = await weatherService.checkBackendHealth(customBaseUrl: _apiController.text);

    if (mounted) {
      setState(() {
        _isCheckingHealth = false;
        _isHealthOk = ok;
        _healthStatus = ok
            ? 'Backend connected (/api/v1/health OK)'
            : 'Backend unreachable. Verify server is running on ${_apiController.text}';
      });
    }
  }

  Future<void> _save() async {
    await AppConfig.setApiBaseUrl(_apiController.text);
    await AppConfig.setOsrmRouterUrl(_osrmController.text);
    widget.onConfigChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endpoint configuration saved.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _reset() async {
    await AppConfig.resetToDefaults();
    setState(() {
      _apiController.text = AppConfig.apiBaseUrl;
      _osrmController.text = AppConfig.osrmRouterUrl;
    });
    _checkHealth();
    widget.onConfigChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API & Network Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Configure FastAPI backend and routing services',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Health Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isHealthOk ? AppColors.riskNone.withAlpha(26) : AppColors.riskHigh.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHealthOk ? AppColors.riskNone.withAlpha(77) : AppColors.riskHigh.withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  _isCheckingHealth
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isHealthOk ? Icons.check_circle_outline : Icons.error_outline,
                          size: 18,
                          color: _isHealthOk ? AppColors.riskNone : AppColors.riskHigh,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _healthStatus ?? 'Checking backend connectivity...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isHealthOk ? AppColors.riskNone : AppColors.riskHigh,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isCheckingHealth ? null : _checkHealth,
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Recheck Health',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Backend API Base URL
            const Text(
              'FastAPI Backend Base URL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _apiController,
              decoration: const InputDecoration(
                hintText: 'e.g. http://10.0.2.2:8000 or http://127.0.0.1:8000',
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _checkHealth(),
            ),

            const SizedBox(height: 8),

            // Network Quick Presets
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Android Emulator (10.0.2.2:8000)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _apiController.text = 'http://10.0.2.2:8000';
                    _checkHealth();
                  },
                ),
                ActionChip(
                  label: const Text('Localhost (127.0.0.1:8000)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _apiController.text = 'http://127.0.0.1:8000';
                    _checkHealth();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // OSRM Router URL
            const Text(
              'OSRM Driving Router URL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _osrmController,
              decoration: const InputDecoration(
                hintText: 'e.g. https://router.project-osrm.org',
              ),
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset Defaults'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save & Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
