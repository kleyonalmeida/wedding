import 'package:flutter/material.dart';

ThemeData giftsTheme(BuildContext context) {
  final base = Theme.of(context);
  final dark = base.brightness == Brightness.dark;
  final colors = base.colorScheme.copyWith(
    primary: dark ? const Color(0xFFdac2b0) : const Color(0xFF6d5b4c),
    onPrimary: dark ? const Color(0xFF26190e) : Colors.white,
    secondary: dark ? const Color(0xFFe9c349) : const Color(0xFF735c00),
    surface: dark ? const Color(0xFF2c2c2e) : Colors.white,
    onSurface: dark ? const Color(0xFFf1efee) : const Color(0xFF1b1c1c),
    surfaceContainerHigh:
        dark ? const Color(0xFF38383a) : const Color(0xFFeae8e7),
    surfaceContainerLow:
        dark ? const Color(0xFF242426) : const Color(0xFFf6f3f2),
    onSurfaceVariant: dark ? const Color(0xFFd1c4bb) : const Color(0xFF4e453f),
  );
  return base.copyWith(
    colorScheme: colors,
    textTheme: base.textTheme.apply(fontFamily: 'Work Sans'),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans', fontSize: 12, letterSpacing: 1.5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )),
  );
}
