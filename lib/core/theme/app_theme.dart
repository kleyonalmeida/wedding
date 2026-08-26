import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.dark,
      ),
      textTheme: TextTheme(
        bodyMedium: AppTextStyles.sans,
        bodyLarge: AppTextStyles.sans,
        bodySmall: AppTextStyles.sans,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppTextStyles.sans.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: AppColors.dark,
        ),
        floatingLabelStyle: AppTextStyles.sans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: AppColors.primary,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8C7362), width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.dark, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.sans.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Color(0xFF2C2C2E),
        onSurface: Color(0xFFF5F5F5),
      ),
      textTheme: TextTheme(
        bodyMedium: AppTextStyles.sans.copyWith(color: const Color(0xFFF5F5F5)),
        bodyLarge: AppTextStyles.sans.copyWith(color: const Color(0xFFF5F5F5)),
        bodySmall: AppTextStyles.sans.copyWith(color: const Color(0xFFF5F5F5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppTextStyles.sans.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: const Color(0xFFF5F5F5),
        ),
        floatingLabelStyle: AppTextStyles.sans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: const Color(0xFFE5D5C8),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8C7362), width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF5F5F5), width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.sans.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }
}
