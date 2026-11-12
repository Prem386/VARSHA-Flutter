import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/pilot_constants.dart';

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AboutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About VARSHA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Predictive Monsoon Mobility & Route Safety System',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Overview
                    const Text(
                      'VARSHA is a predictive monsoon mobility and route safety application designed to evaluate urban flood risks, monitor weather conditions, and help users identify safer travel corridors.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Simulated Data Notice Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.riskModerate.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.riskModerate,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Simulated Data Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  PilotConstants.disclaimerFull,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3 Accordion Sections
                    _buildAccordion(
                      title: 'Navi Mumbai Pilot Focus',
                      content:
                          'Targeted monitoring for critical transit nodes across Vashi, Airoli, Belapur, and Kharghar, '
                          'focusing on flood-prone underpasses and low-lying coastal links.\n\n'
                          'Navi Mumbai was chosen for its high commuter density, vulnerable monsoon chokepoints '
                          '(such as the Turbhe Underpass and Kopar Khairane creek channels), and distinct alternative '
                          'corridors (Palm Beach Road vs. Thane-Belapur Highway).',
                      initiallyExpanded: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAccordion(
                      title: 'Simulated Monsoon Hazards',
                      content:
                          'Clearly marked synthetic flood reports, waterlogging severity indicators, and obstruction tags '
                          'designed to test community safety workflows responsibly.\n\n'
                          'Hazard pins carry High, Medium, or Low severity ratings with proximity decay models. They test '
                          'how commuter interfaces can prioritize safer detour choices without inducing panic.',
                    ),

                    const SizedBox(height: 12),

                    _buildAccordion(
                      title: 'Explainable Safety Scoring',
                      content:
                          'Transparent, rule-based risk evaluation that details why an alternative route is considered '
                          'safer, prioritizing commuter resilience over pure speed.\n\n'
                          'Every route receives a 0–100 risk score based on hazard severity and distance within a 100m proximity '
                          'threshold. Users can expand the breakdown on any route to see the exact hazards and points calculated.',
                    ),

                    const SizedBox(height: 12),

                    _buildAccordion(
                      title: 'Weather & Disaster Intelligence',
                      content:
                          'Real-time rainfall monitoring and forecast modeling powered by Open-Meteo NWP, alongside official '
                          'Common Alerting Protocol (CAP 1.2) emergency bulletins from NDMA SACHET to alert commuters to severe conditions.',
                    ),

                    const SizedBox(height: 24),

                    // Data Sources & Attribution
                    const Text(
                      'Data Sources & Attribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildAttributionItem(
                      'Base Map & Roads',
                      'OpenStreetMap contributors',
                    ),
                    _buildAttributionItem(
                      'Weather Prediction',
                      'Open-Meteo NWP API',
                    ),
                    _buildAttributionItem(
                      'Disaster Warnings',
                      'NDMA SACHET (CAP 1.2)',
                    ),
                    _buildAttributionItem('Routing Engine', 'OSRM Road Router'),
                    _buildAttributionItem(
                      'Forward Geocoding',
                      'Geoapify Places API',
                    ),

                    const SizedBox(height: 24),

                    // Product Information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight.withAlpha(38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.amber.withAlpha(77),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VARSHA Monsoon Mobility',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amberText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Predictive route safety and flood resilience system for municipal transit corridors.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
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
      },
    );
  }

  Widget _buildAccordion({
    required String title,
    required String content,
    bool initiallyExpanded = false,
  }) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            Text(
              content,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributionItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
