import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Cores adicionais não presentes no ColorScheme padrão
  static const Color secondaryFixed = Color(0xFFFFE088);
  static const Color onSecondaryFixed = Color(0xFF241A00);
  static const Color primaryFixed = Color(0xFFF7DECB);
  static const Color onPrimaryFixed = Color(0xFF26190E);

  static ThemeData get theme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6D5B4C),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFB8A291),
      onPrimaryContainer: Color(0xFF48392C),
      secondary: Color(0xFF735C00),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFED65B),
      onSecondaryContainer: Color(0xFF745C00),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFFBF9F8),
      onSurface: Color(0xFF1B1C1C),
      onSurfaceVariant: Color(0xFF4E453F),
      outline: Color(0xFF80756E),
      outlineVariant: Color(0xFFD1C4BB),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF6F3F2),
      surfaceContainer: Color(0xFFF0EDED),
      surfaceContainerHigh: Color(0xFFEAE8E7),
      surfaceContainerHighest: Color(0xFFE4E2E1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TextTheme(
        // headline-lg
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        // section-title
        headlineMedium: GoogleFonts.bodoniModa(
          fontSize: 27,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: colorScheme.onSurface,
        ),
        // body-md
        bodyMedium: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: colorScheme.onSurface,
        ),
        // label-caps
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 1.3,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFD3C3B6),
      onPrimary: Color(0xFF3B2E24),
      primaryContainer: Color(0xFF534438),
      onPrimaryContainer: Color(0xFFEFE0D3),
      secondary: Color(0xFFE7C13E),
      onSecondary: Color(0xFF3D3000),
      secondaryContainer: Color(0xFF584600),
      onSecondaryContainer: Color(0xFFFFE088),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF131313),
      onSurface: Color(0xFFE3E2E1),
      onSurfaceVariant: Color(0xFFD1C4BB),
      outline: Color(0xFF9A8F87),
      outlineVariant: Color(0xFF4E453F),
      surfaceContainerLowest: Color(0xFF0E0E0E),
      surfaceContainerLow: Color(0xFF1B1B1B),
      surfaceContainer: Color(0xFF202020),
      surfaceContainerHigh: Color(0xFF2A2A2A),
      surfaceContainerHighest: Color(0xFF353535),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TextTheme(
        // headline-lg
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        // section-title
        headlineMedium: GoogleFonts.bodoniModa(
          fontSize: 27,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: colorScheme.onSurface,
        ),
        // body-md
        bodyMedium: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: colorScheme.onSurface,
        ),
        // label-caps
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 1.3,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
