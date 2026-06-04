import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ──────────────────────────────────────────────────────────────

class KarmaColors {
  // Primary gradient
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFF8B7CF6);
  static const primaryDark = Color(0xFF4A3CB5);

  // Accent
  static const accent = Color(0xFFFF6B9D);
  static const accentLight = Color(0xFFFF8FB4);

  // Semantic
  static const good = Color(0xFF00D2D3);
  static const goodLight = Color(0xFF55EFC4);
  static const negative = Color(0xFFFF6B6B);
  static const negativeLight = Color(0xFFFF8787);
  static const warning = Color(0xFFFECA57);

  // Surfaces (dark mode)
  static const background = Color(0xFF0D0D1A);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceLight = Color(0xFF25253D);
  static const surfaceLighter = Color(0xFF2D2D4A);
  static const card = Color(0xFF16213E);

  // Text
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB4B4CC);
  static const textHint = Color(0xFF6B6B8D);

  // Virtue colors
  static const kindness = Color(0xFFFF6B9D);
  static const discipline = Color(0xFF6C5CE7);
  static const honesty = Color(0xFF00D2D3);
  static const courage = Color(0xFFFF9F43);
  static const wisdom = Color(0xFFA29BFE);
  static const gratitude = Color(0xFF55EFC4);
  static const patience = Color(0xFF81ECEC);
  static const responsibility = Color(0xFFFF7979);
  static const humility = Color(0xFF74B9FF);
  static const compassion = Color(0xFFFD79A8);
  static const perseverance = Color(0xFFE17055);
  static const generosity = Color(0xFFFAB1A0);

  static Color getVirtueColor(String name) {
    switch (name.toLowerCase()) {
      case 'kindness': return kindness;
      case 'discipline': return discipline;
      case 'honesty': return honesty;
      case 'courage': return courage;
      case 'wisdom': return wisdom;
      case 'gratitude': return gratitude;
      case 'patience': return patience;
      case 'responsibility': return responsibility;
      case 'humility': return humility;
      case 'compassion': return compassion;
      case 'perseverance': return perseverance;
      case 'generosity': return generosity;
      default: return primary;
    }
  }
}

// ─── Theme ──────────────────────────────────────────────────────────────────────

class KarmaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KarmaColors.background,
      colorScheme: const ColorScheme.dark(
        primary: KarmaColors.primary,
        secondary: KarmaColors.accent,
        surface: KarmaColors.surface,
        error: KarmaColors.negative,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: KarmaColors.textPrimary,
        displayColor: KarmaColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: KarmaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: KarmaColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: KarmaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KarmaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KarmaColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KarmaColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: KarmaColors.textHint),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KarmaColors.surface,
        selectedItemColor: KarmaColors.primary,
        unselectedItemColor: KarmaColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KarmaColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KarmaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KarmaColors.surfaceLighter,
        contentTextStyle: const TextStyle(color: KarmaColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
