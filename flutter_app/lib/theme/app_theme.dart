// NEW FILE — App Theme
// Color palette and ThemeData for the Smart Road Monitor app

import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // COLOR PALETTE
  // ============================================================

  static const Color primary = Color(0xFF77B6EA);
  static const Color primaryDark = Color(0xFF5A9BD5);
  static const Color primaryLight = Color(0xFFA3D1F5);
  static const Color background = Color(0xFFE8EEF2);
  static const Color cardColor = Color(0xFFC7D3DD);
  static const Color secondary = Color(0xFFD6C9C9);
  static const Color textColor = Color(0xFF37393A);
  static const Color textLight = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Status colors
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusAssigned = Color(0xFF60A5FA);
  static const Color statusInProgress = Color(0xFFA78BFA);
  static const Color statusCompleted = Color(0xFF4ADE80);

  // ============================================================
  // CATEGORY COLORS
  // ============================================================

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'pothole':
        return const Color(0xFFF87171);
      case 'road_obstruction':
        return const Color(0xFFFBBF24);
      case 'water_logging':
        return const Color(0xFF60A5FA);
      case 'broken_streetlight':
        return const Color(0xFFA78BFA);
      case 'garbage':
        return const Color(0xFF4ADE80);
      default:
        return primary;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'assigned':
        return statusAssigned;
      case 'in_progress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      default:
        return textLight;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'assigned':
        return Icons.person_add;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'pothole':
        return Icons.warning_rounded;
      case 'road_obstruction':
        return Icons.remove_road;
      case 'water_logging':
        return Icons.water;
      case 'broken_streetlight':
        return Icons.lightbulb_outline;
      case 'garbage':
        return Icons.delete_outline;
      default:
        return Icons.report;
    }
  }

  // ============================================================
  // THEME DATA
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',

      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: white,
        error: danger,
        onPrimary: white,
        onSecondary: white,
        onSurface: textColor,
        onError: white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      cardTheme: CardTheme(
        color: white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: textLight.withOpacity(0.6)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
