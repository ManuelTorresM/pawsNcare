import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color primary = Color(0xFF436444); // Sage Green
  static const Color primaryContainer = Color(0xFF5B7D5B);
  static const Color primaryFixed = Color(0xFFC6EDC4);
  static const Color primaryFixedDim = Color(0xFFABD0A9);

  static const Color background = Color(0xFFFBF9F8); // Warm Cream
  static const Color surface = Color(0xFFFBF9F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3F3);
  static const Color surfaceContainer = Color(0xFFEFEDED);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E7);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E2);
  static const Color surfaceBright = Color(0xFFFBF9F8);
  static const Color surfaceDim = Color(0xFFDBD9D9);
  static const Color outlineVariant = Color(0xFFC2C8BE);
  static const Color onPrimaryContainer = Color(0xFFF7FFF2);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF012108);
  static const Color onPrimaryFixedVariant = Color(0xFF2B4F2D);
  static const Color onBackground = Color(0xFF1B1C1C);
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF424841);

  static const Color secondary = Color(0xFF5F5E5B); // Warm Stone
  static const Color secondaryContainer = Color(0xFFE5E2DD);

  static const Color tertiary = Color(0xFF9A402A); // Terracotta
  static const Color tertiaryContainer = Color(0xFFBA5740);
  static const Color tertiaryFixed = Color(0xFFFFDAD2);
  static const Color onTertiaryFixed = Color(0xFF3D0700);
  static const Color onTertiaryFixedVariant = Color(0xFF7E2B18);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF1C1B1B);
  static const Color darkSurface = Color(0xFF2A2826);
  static const Color darkOnSurface = Color(0xFFE5E2DD);
  static const Color darkOnSurfaceVariant = Color(0xFFC2C8BE);
  static const Color darkBorder = Color(0xFF383634);
  static const Color darkBorderHigh = Color(0xFF4A4846);
  static const Color darkHeaderSage = Color(0xFF2E4E30);

  // Status & Severity Color Tokens (Light Mode)
  static const Color statusAdministered = Color(0xFF2E7D32);
  static const Color statusAdministeredBg = Color(0xFFE6F4EA);

  static const Color statusOverdue = Color(0xFFE74C3C);
  static const Color statusOverdueBg = Color(0xFFFDEDEC);

  static const Color statusScheduled = Color(0xFFF39C12);
  static const Color statusScheduledBg = Color(0xFFFEF9E7);

  static const Color statusMild = Color(0xFF5D9CEC);
  static const Color statusMildBg = Color(0xFFEBF5FB);

  // Status & Severity Color Tokens (Dark Mode)
  static const Color statusAdministeredDark = Color(0xFF81C784);
  static const Color statusAdministeredDarkBg = Color(0xFF1B382B);

  static const Color statusOverdueDark = Color(0xFFFFB4A3);
  static const Color statusOverdueDarkBg = Color(0xFF5C2B1D);

  static const Color statusScheduledDark = Color(0xFFFFD580);
  static const Color statusScheduledDarkBg = Color(0xFF523B17);

  static const Color statusMildDark = Color(0xFF90CAF9);
  static const Color statusMildDarkBg = Color(0xFF1D3B5C);

  // Concept Color Tokens
  static const Color foodConcept = Color(0xFFD9A441);
  static const Color foodConceptDark = Color(0xFFFFB74D);

  static const Color waterConcept = Color(0xFF0288D1);
  static const Color waterConceptDark = Color(0xFF81D4FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        errorContainer: errorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: Color(0xFF737970),
        outlineVariant: Color(0xFFC2C8BE),
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 48,
          letterSpacing: -0.02,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.01,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC2C8BE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC2C8BE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryFixedDim,
        onPrimary: Color(0xFF012108),
        primaryContainer: primaryContainer,
        secondary: Color(0xFFC9C6C2),
        secondaryContainer: Color(0xFF474743),
        tertiary: Color(0xFFFFB4A3),
        tertiaryContainer: Color(0xFFBA5740),
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: Color(0xFF8D9387),
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 48,
              letterSpacing: -0.02,
              color: darkOnSurface,
            ),
            headlineLarge: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: darkOnSurface,
            ),
            headlineMedium: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: darkOnSurface,
            ),
            titleLarge: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: darkOnSurface,
            ),
            bodyLarge: GoogleFonts.inter(
              fontWeight: FontWeight.normal,
              fontSize: 18,
              color: darkOnSurface,
            ),
            bodyMedium: GoogleFonts.inter(
              fontWeight: FontWeight.normal,
              fontSize: 16,
              color: darkOnSurfaceVariant,
            ),
            labelLarge: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.01,
              color: darkOnSurface,
            ),
            labelSmall: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: darkOnSurfaceVariant,
            ),
          ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
