import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/pilot_constants.dart';

/// 40px Persistent Disclaimer Strip matching the React application footer.
class PersistentDisclaimer extends StatelessWidget {
  final VoidCallback onLearnMore;

  const PersistentDisclaimer({super.key, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                PilotConstants.disclaimerShort,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLearnMore,
              child: const Text(
                'Learn more',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberText,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
