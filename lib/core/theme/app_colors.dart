import 'package:flutter/material.dart';

/// Triply Stays brand colors
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryOrange = Color(0xFFFB8500);
  static const Color primaryDark = Color(0xFF2D3748);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFBF5);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, Color(0xFFFF9500)],
  );
}
