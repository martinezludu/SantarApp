import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía: Syne para títulos/números (carácter fuerte), Inter para UI.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.syne(
          fontSize: 40, fontWeight: FontWeight.w800, color: primary),
      displayMedium: GoogleFonts.syne(
          fontSize: 32, fontWeight: FontWeight.w800, color: primary),
      headlineMedium: GoogleFonts.syne(
          fontSize: 26, fontWeight: FontWeight.w800, color: primary),
      titleLarge: GoogleFonts.syne(
          fontSize: 20, fontWeight: FontWeight.w700, color: primary),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: primary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: primary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: secondary),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
