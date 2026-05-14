import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Dark Color Tokens ────────────────────────────────────────────────────────
class AppColorsDark {
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

// ─── Light Color Tokens ───────────────────────────────────────────────────────
class AppColorsLight {
  static const bg = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const cardElevated = Color(0xFFF0F4FF);

  // Accents (same brand colours, slightly adjusted for legibility)
  static const gold = Color(0xFFD4920A);
  static const goldSoft = Color(0xFFB8860B);
  static const emerald = Color(0xFF00A87C);
  static const emeraldDark = Color(0xFF007A5C);
  static const red = Color(0xFFE03050);
  static const redDark = Color(0xFFB02040);
  static const blue = Color(0xFF2563EB);

  // Text
  static const textPrimary = Color(0xFF0F1520);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF8C9BB5);

  // Borders
  static const border = Color(0xFFE2E8F0);
  static const borderGlow = Color(0xFFCBD5E1);

  // Neutral
  static const neutral = Color(0xFFF1F5F9);
}

// ─── Legacy alias kept so existing screens compile without changes ─────────────
// Screens reference AppColors.xxx — we map those to dark-mode values.
// After the theme migration is complete you can replace all AppColors references
// with Theme.of(context).colorScheme / AppTheme.colorsOf(context).
class AppColors {
  // Backgrounds
  static const bg = AppColorsDark.bg;
  static const surface = AppColorsDark.surface;
  static const card = AppColorsDark.card;
  static const cardElevated = AppColorsDark.cardElevated;

  // Accents
  static const gold = AppColorsDark.gold;
  static const goldSoft = AppColorsDark.goldSoft;
  static const emerald = AppColorsDark.emerald;
  static const emeraldDark = AppColorsDark.emeraldDark;
  static const red = AppColorsDark.red;
  static const redDark = AppColorsDark.redDark;
  static const blue = AppColorsDark.blue;
  static const blueGlow = AppColorsDark.blueGlow;

  // Text
  static const textPrimary = AppColorsDark.textPrimary;
  static const textSecondary = AppColorsDark.textSecondary;
  static const textMuted = AppColorsDark.textMuted;

  // Borders
  static const border = AppColorsDark.border;
  static const borderGlow = AppColorsDark.borderGlow;

  // Neutral
  static const neutral = AppColorsDark.neutral;
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColorsDark.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColorsDark.gold,
          secondary: AppColorsDark.emerald,
          surface: AppColorsDark.surface,
          error: AppColorsDark.red,
          onPrimary: AppColorsDark.bg,
          onSecondary: AppColorsDark.bg,
          onSurface: AppColorsDark.textPrimary,
          outline: AppColorsDark.border,
          outlineVariant: AppColorsDark.borderGlow,
          tertiary: AppColorsDark.blue,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColorsDark.textPrimary,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColorsDark.textPrimary,
              letterSpacing: -0.5,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColorsDark.textPrimary,
            ),
            headlineMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorsDark.textPrimary,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColorsDark.textPrimary,
            ),
            bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColorsDark.textPrimary,
              height: 1.6,
            ),
            bodyMedium: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColorsDark.textSecondary,
              height: 1.5,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorsDark.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColorsDark.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColorsDark.border, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsDark.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColorsDark.textPrimary,
          ),
          iconTheme:
              const IconThemeData(color: AppColorsDark.textPrimary),
        ),
        switchTheme: SwitchThemeData(
          thumbColor:
              WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark.bg;
            }
            return AppColorsDark.textMuted;
          }),
          trackColor:
              WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark.gold;
            }
            return AppColorsDark.card;
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColorsDark.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColorsDark.textPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColorsDark.textSecondary,
            height: 1.5,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorsDark.cardElevated,
          contentTextStyle: GoogleFonts.inter(
            color: AppColorsDark.textPrimary,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerColor: AppColorsDark.border,
        dividerTheme:
            const DividerThemeData(color: AppColorsDark.border),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColorsDark.surface,
          selectedItemColor: AppColorsDark.gold,
          unselectedItemColor: AppColorsDark.textMuted,
        ),
        iconTheme:
            const IconThemeData(color: AppColorsDark.textSecondary),
      );

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColorsLight.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColorsLight.gold,
          secondary: AppColorsLight.emerald,
          surface: AppColorsLight.surface,
          error: AppColorsLight.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColorsLight.textPrimary,
          outline: AppColorsLight.border,
          outlineVariant: AppColorsLight.borderGlow,
          tertiary: AppColorsLight.blue,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColorsLight.textPrimary,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.textPrimary,
              letterSpacing: -0.5,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.textPrimary,
            ),
            headlineMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorsLight.textPrimary,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColorsLight.textPrimary,
            ),
            bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColorsLight.textPrimary,
              height: 1.6,
            ),
            bodyMedium: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColorsLight.textSecondary,
              height: 1.5,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorsLight.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColorsLight.card,
          elevation: 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColorsLight.border, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsLight.surface,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColorsLight.textPrimary,
          ),
          iconTheme: const IconThemeData(color: AppColorsLight.textPrimary),
        ),
        switchTheme: SwitchThemeData(
          thumbColor:
              WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColorsLight.textMuted;
          }),
          trackColor:
              WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsLight.gold;
            }
            return AppColorsLight.neutral;
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColorsLight.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColorsLight.textPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColorsLight.textSecondary,
            height: 1.5,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorsLight.cardElevated,
          contentTextStyle: GoogleFonts.inter(
            color: AppColorsLight.textPrimary,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerColor: AppColorsLight.border,
        dividerTheme:
            const DividerThemeData(color: AppColorsLight.border),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColorsLight.surface,
          selectedItemColor: AppColorsLight.gold,
          unselectedItemColor: AppColorsLight.textMuted,
        ),
        iconTheme:
            const IconThemeData(color: AppColorsLight.textSecondary),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the resolved card color for the current theme.
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.card
        : AppColorsLight.card;
  }

  /// Returns the resolved background color for the current theme.
  static Color bgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.bg
        : AppColorsLight.bg;
  }

  /// Returns the resolved border color for the current theme.
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.border
        : AppColorsLight.border;
  }

  /// Returns the resolved primary text color for the current theme.
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textPrimary
        : AppColorsLight.textPrimary;
  }

  /// Returns the resolved secondary text color for the current theme.
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textSecondary
        : AppColorsLight.textSecondary;
  }

  /// Returns the resolved muted text color for the current theme.
  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textMuted
        : AppColorsLight.textMuted;
  }

  /// Returns the resolved neutral color for the current theme.
  static Color neutral(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.neutral
        : AppColorsLight.neutral;
  }

  /// Returns the resolved gold/primary accent for the current theme.
  static Color gold(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.gold
        : AppColorsLight.gold;
  }

  /// Returns the resolved emerald/secondary accent for the current theme.
  static Color emerald(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.emerald
        : AppColorsLight.emerald;
  }

  /// Returns the resolved error/red color for the current theme.
  static Color red(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.red
        : AppColorsLight.red;
  }

  /// Returns the resolved blue/tertiary color for the current theme.
  static Color blue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.blue
        : AppColorsLight.blue;
  }
}
