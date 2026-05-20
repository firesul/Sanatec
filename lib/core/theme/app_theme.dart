import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores extraída de Stitch (Tailwind Config)
  static const Color primary = Color(0xFFAB2E15);
  static const Color primaryContainer = Color(0xFFCD462B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFBFF);

  static const Color secondary = Color(0xFF00696D);
  static const Color secondaryContainer = Color(0xFF9DEDF1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF096E72);

  static const Color background = Color(0xFFFFF8F6);
  static const Color onBackground = Color(0xFF1E1B19);

  static const Color surface = Color(0xFFFFF8F6);
  static const Color onSurface = Color(0xFF1E1B19);
  static const Color surfaceVariant = Color(0xFFE9E1DE);
  static const Color onSurfaceVariant = Color(0xFF59413C);

  static const Color outline = Color(0xFF8D716B);
  static const Color outlineVariant = Color(0xFFE1BFB8);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        // Headlines utilizan Quicksand (fontFamily: headline-lg, xl, md)
        displayLarge: GoogleFonts.quicksand(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 40,
          color: primary,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01 * 32,
          color: primary,
        ),
        headlineMedium: GoogleFonts.quicksand(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        headlineSmall: GoogleFonts.quicksand(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        // Body y Labels utilizan Plus Jakarta Sans
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.01 * 14,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface, // equivalent to bg-surface-bright in HTML
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: onSurface),
        hintStyle: GoogleFonts.plusJakartaSans(color: outlineVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01 * 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
      ),
    );
  }
}
