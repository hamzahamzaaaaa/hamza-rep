import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color gold = Color(0xFFFFC107); // Vibrant Deep Gold
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color destructive = Color(0xFFEF4444);

  // Dynamic Colors (Non-const)
  static Color background = const Color(0xFF000000);
  static Color surface = const Color(0xFF000000);
  static Color muted = const Color(0xFF111111);
  static Color textPrimary = Colors.white;
  static Color textSecondary = const Color(0xFFAAAAAA);

  // Static constant versions for use in constant widgets/styles
  static const Color backgroundDefault = Color(0xFF000000);
  static const Color surfaceDefault = Color(0xFF000000);
  static const Color mutedDefault = Color(0xFF111111);
  static const Color textPrimaryDefault = Colors.white;
  static const Color textSecondaryDefault = Color(0xFFAAAAAA);

  static void setToLight() {
    background = const Color(0xFFF5F5F5);
    surface = Colors.white;
    muted = const Color(0xFFE0E0E0);
    textPrimary = const Color(0xFF212121);
    textSecondary = const Color(0xFF757575);
  }

  static void setToDark() {
    background = const Color(0xFF000000); // Updated to pitch black
    surface = const Color(0xFF000000); // Updated to pitch black
    muted = const Color(0xFF111111);
    textPrimary = Colors.white;
    textSecondary = const Color(0xFFAAAAAA);
  }

  static void setToDeepBlack() {
    background = Colors.black;
    surface = Colors.black; 
    muted = const Color(0xFF111111);
    textPrimary = Colors.white;
    textSecondary = const Color(0xFFAAAAAA);
  }
}
