import 'package:flutter/material.dart';

/// Centralized color constants for the Student Support App.
/// Primary palette extracted from the login page design.
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primaryDarkBlue = Color(0xFF020065);
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryGold = Color(0xFFFDC50C);

  // Gradient Colors
  static const Color gradientStart = primaryDarkBlue;
  static const Color gradientMiddle = Color(0xFF010033);
  static const Color gradientEnd = primaryBlack;

  // Surface Colors
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardBackground = primaryWhite;

  // Text Colors
  static const Color textPrimary = primaryBlack;
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = primaryWhite;
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Feature Icon Colors (for home tiles)
  static const Color feedbackColor = Color(0xFF8B5CF6);
  static const Color complaintColor = Color(0xFFEC4899);
  static const Color syllabusColor = Color(0xFF06B6D4);
  static const Color resourcesColor = Color(0xFF10B981);
  static const Color attendanceColor = Color(0xFFF97316);
  static const Color noticesColor = Color(0xFF6366F1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), primaryGold, Color(0xFFE5A800)],
  );

  static LinearGradient cardGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
      ],
    );
  }
}
