import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/scenario.dart';

/// Segmented scenario selector matching React ScenarioSelector.tsx.
class ScenarioSelector extends StatelessWidget {
  final DemoScenarioId selectedScenarioId;
  final ValueChanged<DemoScenarioId> onSelectScenario;

  const ScenarioSelector({
    super.key,
    required this.selectedScenarioId,
    required this.onSelectScenario,
  });

  @override
  Widget build(BuildContext context) {
    final scenarios = getAllDemoScenarios();
    final activeScenario = getDemoScenario(selectedScenarioId);
    final isNonBaseline = selectedScenarioId != DemoScenarioId.baseline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Demo Scenarios',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amberText,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '• Differential Risk Testing',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Text(
                activeScenario.hazards.isEmpty
                    ? '0 simulated hazards'
                    : '${activeScenario.hazards.length} simulated hazard${activeScenario.hazards.length > 1 ? "s" : ""}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Segmented choices
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: scenarios.map((scenario) {
                final isSelected = scenario.id == selectedScenarioId;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      scenario.shortLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.amberText : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onSelectScenario(scenario.id),
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.amberLight.withAlpha(51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.amber : AppColors.borderInteractive,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            activeScenario.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),

          if (isNonBaseline && activeScenario.notice != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberLight.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withAlpha(77)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amberText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeScenario.notice!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amberText,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
