import 'package:flutter/material.dart';

/// Neon-arcade colour palette for Type Racer.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0B0F1E); // deep navy
  static const Color surface = Color(0xFF141B33); // cards
  static const Color surfaceHigh = Color(0xFF1C2545); // inputs, chips

  // Accents
  static const Color cyan = Color(0xFF00E5FF); // primary
  static const Color magenta = Color(0xFFFF2E93); // secondary
  static const Color yellow = Color(0xFFFFD60A); // highlights / countdown
  static const Color green = Color(0xFF39FF88); // correct
  static const Color red = Color(0xFFFF4D5E); // error

  // Text
  static const Color textPrimary = Color(0xFFEAF0FF);
  static const Color textMuted = Color(0xFF8A94B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, Color(0xFF3D7BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [magenta, Color(0xFFFF7A3D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient titleGradient = LinearGradient(
    colors: [cyan, magenta],
  );

  /// One colour per lane so each racer looks different.
  static const List<Color> laneColors = [cyan, magenta, yellow, green, Color(0xFFB388FF)];
}
