import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── Color Tokens ──────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const bg = Color(0xFF080B14);
  static const surface = Color(0xFF0F1520);
  static const card = Color(0xFF141C2B);
  static const cardElevated = Color(0xFF1A2235);

  // Accents
  static const gold = Color(0xFFF2B705);
  static const goldSoft = Color(0xFFD4A017);
  static const emerald = Color(0xFF00C896);
  static const emeraldDark = Color(0xFF00A07A);
  static const red = Color(0xFFFF4D6A);
  static const redDark = Color(0xFFCC3352);
  static const blue = Color(0xFF3B82F6);
  static const blueGlow = Color(0xFF1D4ED8);

  // Text
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8C9BB5);
  static const textMuted = Color(0xFF4A5568);

  // Borders
  static const border = Color(0xFF1E2D47);
  static const borderGlow = Color(0xFF2A3F63);

  // Neutral
  static const neutral = Color(0xFF243047);
}

/// ─── Theme ─────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.emerald,
          surface: AppColors.surface,
          error: AppColors.red,
          onPrimary: AppColors.bg,
          onSecondary: AppColors.bg,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            headlineMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            bodyMedium: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        dividerColor: AppColors.border,
        dividerTheme: const DividerThemeData(color: AppColors.border),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        colorScheme: ColorScheme.light(
          primary: AppColors.goldSoft,
          secondary: AppColors.emerald,
          surface: Colors.white,
          error: AppColors.red,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F1520),
          ),
        ),
      );
}
