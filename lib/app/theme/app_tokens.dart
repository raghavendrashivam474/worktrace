import 'package:flutter/material.dart';

/// Centralized design tokens for the Worktrace design system.
///
/// All visual values flow from here. Feature screens should reference
/// these tokens through ThemeData rather than hard-coding values.
class AppColors {
  AppColors._();

  /// Primary brand color — a focused blue representing clarity and trace.
  static const Color primary = Color(0xFF1A73E8);

  /// Secondary accent — a teal-green for continuity and progress.
  static const Color secondary = Color(0xFF00897B);

  // ── Semantic: Light ──
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1F1F1F);
  static const Color lightOnSurfaceVariant = Color(0xFF5F6368);
  static const Color lightBorder = Color(0xFFDADCE0);

  // ── Semantic: Dark ──
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFE8EAED);
  static const Color darkOnSurfaceVariant = Color(0xFF9AA0A6);
  static const Color darkBorder = Color(0xFF3C4043);

  // ── Status ──
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
}

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppShapes {
  AppShapes._();

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;
}
