import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get serif => GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get cursive => GoogleFonts.greatVibes(
        fontWeight: FontWeight.normal,
      );

  static TextStyle get sans => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
      );
      
  static TextStyle get bodoni => GoogleFonts.bodoniModa(
        fontWeight: FontWeight.w400,
      );
      
  static TextStyle get workSans => GoogleFonts.workSans(
        fontWeight: FontWeight.w400,
      );
}
