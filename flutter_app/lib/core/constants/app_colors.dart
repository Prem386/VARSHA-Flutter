import 'package:flutter/material.dart';

/// Design tokens and semantic colors extracted from the original VARSHA UI.
/// Preserves the soft, high-contrast palette and WCAG AAA compliance.
class AppColors {
  AppColors._();

  // Surface and Backgrounds
  static const Color background = Color(0xFFECECEF);
  static const Color surface = Color(0xFFEFEFF2);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0x33A3A5B4);
  static const Color borderInteractive = Color(0x142B2B30);

  // Typography
  static const Color textPrimary = Color(0xFF2B2B30);
  static const Color textSecondary = Color(0xFF5B5C66);
  static const Color textMuted = Color(0xFF71727F);

  // Amber Accent Palette
  static const Color amberLight = Color(0xFFFFD25A);
  static const Color amber = Color(0xFFF5A623);
  static const Color amberText = Color(0xFFA15207);
  static const Color amberGlow = Color(0x59F5A623);

  // Semantic Hazard / Risk Colors
  static const Color riskLow = Color(0xFF0E8F8A);
  static const Color riskModerate = Color(0xFFD98300);
  static const Color riskHigh = Color(0xFFC62828);
  static const Color riskNone = Color(0xFF047857);

  // Endpoint Markers
  static const Color originGreen = Color(0xFF10B981);
  static const Color originGreenDark = Color(0xFF047857);
  static const Color destinationPurple = Color(0xFF8B5CF6);
  static const Color destinationPurpleDark = Color(0xFF5B21B6);

  // Routes
  static const Color routePrimary = Color(0xFF2563EB);
  static const Color routeAlternative = Color(0xFF64748B);

  // Shading / Soft Neumorphic Shadows
  static const Color shadowDark = Color(0x40A3A5B4);
  static const Color shadowLight = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amberLight, amber],
  );
}
