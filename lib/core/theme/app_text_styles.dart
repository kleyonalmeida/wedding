import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get serif => GoogleFonts.playfairDisplay(
        color: AppColors.dark,
      );

  static TextStyle get cursive => GoogleFonts.greatVibes(
        color: AppColors.primary,
      );

  static TextStyle get sans => GoogleFonts.workSans(
        color: AppColors.dark,
      );
}
